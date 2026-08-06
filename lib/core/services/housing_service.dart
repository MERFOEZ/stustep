import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/admission_enums.dart';
import '../../features/admission/models/housing_model.dart';
import 'admission_collections.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// خدمة السكنات الطلابية — **أول خدمة كتابة في الموديول**.
///
/// كل ما سبقها كان قراءة فقط، لذلك تحمل هذه الخدمة مسؤوليات جديدة:
/// رفع الصور، وإسناد الملكية، والتحقق من الصلاحية قبل التعديل والحذف.
///
/// ⚠️ التحقق هنا **من جهة العميل فقط**، وهو حاجز واجهة لا حاجز أمني.
/// الحاجز الحقيقي هو قواعد Firestore في المرحلة 8: الإنشاء يشترط تطابق
/// `createdBy` مع هوية صاحب الطلب، والتعديل والحذف يقتصران على المالك.
class HousingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  static final HousingService _instance = HousingService._internal();

  factory HousingService() => _instance;

  HousingService._internal();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AdmissionCollections.housings);

  // ===================== القراءة =====================

  /// بث حيّ لكل السكنات المنشورة، مرتّبة بالأحدث.
  ///
  /// الترتيب في الذاكرة لا عبر `orderBy` تفادياً لفهرس مركّب مع شرط
  /// حالة المراجعة، التزاماً بنمط المشروع.
  Stream<List<HousingModel>> watchHousings() {
    return _collection.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(HousingModel.fromFirestore)
          .where(
            (item) => item.moderationStatus == ModerationStatus.published,
          )
          .toList();
      items.sort(_byNewest);
      return items;
    });
  }

  /// إعلانات المستخدم الحالي — تشمل غير المنشور حتى يرى صاحبه حالته.
  Stream<List<HousingModel>> watchMyHousings(String uid) {
    return _collection.where('createdBy', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(HousingModel.fromFirestore).toList();
      items.sort(_byNewest);
      return items;
    });
  }

  Future<HousingModel?> getHousing(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      return doc.exists ? HousingModel.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('HousingService: failed to load $id: $e');
      return null;
    }
  }

  // ===================== الكتابة =====================

  /// إضافة إعلان سكن جديد.
  ///
  /// ترتيب العمليات مقصود: تُرفع الصور **قبل** كتابة الوثيقة، حتى لا يظهر
  /// إعلان بصور معطوبة إذا فشل الرفع في منتصفه.
  Future<String?> addHousing({
    required HousingModel housing,
    List<File> images = const [],
    void Function(int completed, int total)? onImageProgress,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    try {
      final urls = images.isEmpty
          ? <String>[]
          : await _storage.uploadMultiple(images, onProgress: onImageProgress);

      final data = housing.toFirestore()
        ..['images'] = urls
        ..['createdBy'] = user.uid
        ..['createdByName'] =
            user.displayName ?? user.email?.split('@').first ?? 'Student'
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp()
        ..['viewCount'] = 0;

      final doc = await _collection.add(data);
      return doc.id;
    } catch (e) {
      debugPrint('HousingService: failed to add housing: $e');
      return null;
    }
  }

  /// تعديل إعلان قائم — مع إمكانية إضافة صور جديدة للصور الحالية.
  Future<bool> updateHousing({
    required HousingModel housing,
    List<File> newImages = const [],
    void Function(int completed, int total)? onImageProgress,
  }) async {
    if (!_isOwner(housing)) return false;

    try {
      final uploaded = newImages.isEmpty
          ? <String>[]
          : await _storage.uploadMultiple(
              newImages,
              onProgress: onImageProgress,
            );

      final data = housing.toFirestore()
        ..['images'] = [...housing.images, ...uploaded]
        ..['updatedAt'] = FieldValue.serverTimestamp();

      // لا نسمح بتغيير المالك أو عدّاد المشاهدات من مسار التعديل.
      data.remove('createdBy');
      data.remove('createdByName');
      data.remove('viewCount');

      await _collection.doc(housing.id).update(data);
      return true;
    } catch (e) {
      debugPrint('HousingService: failed to update ${housing.id}: $e');
      return false;
    }
  }

  /// تبديل حالة التوفّر — العملية الأكثر تكراراً لصاحب السكن.
  Future<bool> toggleStatus(HousingModel housing) async {
    if (!_isOwner(housing)) return false;

    final next = housing.isAvailable
        ? HousingStatus.full
        : HousingStatus.available;
    try {
      await _collection.doc(housing.id).update({
        'status': next.code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('HousingService: failed to toggle ${housing.id}: $e');
      return false;
    }
  }

  Future<bool> deleteHousing(HousingModel housing) async {
    if (!_isOwner(housing)) return false;

    try {
      await _collection.doc(housing.id).delete();
      return true;
    } catch (e) {
      debugPrint('HousingService: failed to delete ${housing.id}: $e');
      return false;
    }
  }

  /// زيادة عدّاد المشاهدات.
  ///
  /// نستخدم `FieldValue.increment` لا قراءةً ثم كتابة، لأن الأخيرة تفقد
  /// زيادات المستخدمين المتزامنين. والفشل هنا يُبتلع عمداً: عدّاد مشاهدات
  /// لا يستحق إزعاج المستخدم برسالة خطأ.
  Future<void> incrementView(String id) async {
    try {
      await _collection.doc(id).update({'viewCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('HousingService: failed to increment view $id: $e');
    }
  }

  bool _isOwner(HousingModel housing) =>
      housing.isOwnedBy(AuthService().currentUser?.uid);

  static int _byNewest(HousingModel a, HousingModel b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }
}
