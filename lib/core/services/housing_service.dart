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
/// كل ما سبقها يقرأ بيانات رسمية يدخلها الفريق. هذه أول مجموعة يكتب فيها
/// المستخدمون أنفسهم، ولذلك تحمل ثلاثة التزامات لم تكن مطلوبة قبلها:
///
///   1. **الملكية:** كل وثيقة تحمل `createdBy` بمعرّف صاحبها. قواعد الأمان
///      في `firestore.rules` مبنية على هذا الحقل تحديداً، والخدمة لا تكتبه
///      من مدخلات الواجهة بل من هوية المستخدم الحالية — فلا يمكن انتحاله.
///
///   2. **حالة المراجعة:** يكتبها المُنشئ مرة واحدة عند الإنشاء، ولا تُرسَل
///      إطلاقاً في التحديث. القاعدة على الخادم ترفض تغييرها، وحذفها من جسم
///      التحديث يمنع فشلاً متوقعاً بدل انتظار رفض الخادم.
///
///   3. **الفلترة في الذاكرة:** الفلاتر (الحالة، الفئة، السعر، المسافة)
///      تُطبَّق بعد القراءة لا في الاستعلام. السبب أن الجمع بين أكثر من شرط
///      `where` وترتيب يفرض فهرساً مركّباً، والموديول ملتزم بصفر فهارس.
class HousingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final HousingService _instance = HousingService._internal();

  factory HousingService() => _instance;

  HousingService._internal();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AdmissionCollections.housings);

  // ===================== القراءة =====================

  /// بث حيّ لكل السكنات المنشورة، مرتّبة بالأحدث في الذاكرة.
  Stream<List<HousingModel>> watchHousings() {
    return _collection.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(HousingModel.fromFirestore)
          .where((item) => item.moderationStatus != ModerationStatus.rejected)
          .toList();
      _sortByNewest(items);
      return items;
    });
  }

  /// إعلانات المستخدم الحالي.
  ///
  /// شرط `where` واحد بلا ترتيب — الترتيب في الذاكرة، فلا فهرس مركّب.
  Stream<List<HousingModel>> watchMyHousings() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _collection.where('createdBy', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(HousingModel.fromFirestore).toList();
      _sortByNewest(items);
      return items;
    });
  }

  Future<HousingModel?> getById(String housingId) async {
    try {
      final doc = await _collection.doc(housingId).get();
      return doc.exists ? HousingModel.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('HousingService: failed to load $housingId: $e');
      return null;
    }
  }

  void _sortByNewest(List<HousingModel> items) {
    items.sort((a, b) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }

  // ===================== الكتابة =====================

  /// إنشاء إعلان سكن جديد بعد رفع صوره.
  ///
  /// ترتيب العمليات مقصود: **الصور تُرفع أولاً ثم تُكتب الوثيقة**. العكس
  /// كان سيُنتج إعلاناً بلا صور إن فشل الرفع، وهو أسوأ من فشل واضح يُعيد
  /// المحاولة عليه المستخدم.
  Future<String?> create({
    required HousingModel housing,
    List<File> images = const [],
    void Function(int completed, int total)? onUploadProgress,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    try {
      final urls = images.isEmpty
          ? const <String>[]
          : await StorageService().uploadMultiple(
              images.take(StorageService.maxImageCount).toList(),
              onProgress: onUploadProgress,
            );

      // الملكية تُؤخذ من جلسة المصادقة لا من الواجهة — لا انتحال ممكن.
      final data = housing.toFirestore()
        ..['images'] = urls
        ..['createdBy'] = user.uid
        ..['createdByName'] = user.displayName ?? ''
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      final reference = await _collection.add(data);
      return reference.id;
    } catch (e) {
      debugPrint('HousingService: failed to create housing: $e');
      return null;
    }
  }

  /// تحديث إعلان قائم.
  ///
  /// `createdBy` و`moderationStatus` و`createdAt` **لا تُرسَل إطلاقاً**:
  /// الأول لأن نقل الملكية غير مسموح، والثاني لأن اعتماد المحتوى قرار
  /// المشرف وحده، والثالث لأن تاريخ الإنشاء لا يتغيّر بالتعديل.
  Future<bool> update({
    required String housingId,
    required HousingModel housing,
    List<File> newImages = const [],
  }) async {
    try {
      final data = housing.toFirestore()
        ..remove('createdBy')
        ..remove('createdByName')
        ..remove('moderationStatus');

      if (newImages.isNotEmpty) {
        final urls = await StorageService().uploadMultiple(
          newImages.take(StorageService.maxImageCount).toList(),
        );
        data['images'] = [...housing.images, ...urls]
            .take(StorageService.maxImageCount)
            .toList();
      }

      data['updatedAt'] = FieldValue.serverTimestamp();
      await _collection.doc(housingId).update(data);
      return true;
    } catch (e) {
      debugPrint('HousingService: failed to update $housingId: $e');
      return false;
    }
  }

  /// تبديل حالة التوفّر — العملية الأكثر تكراراً لصاحب السكن.
  ///
  /// أُفردت بدالة خاصة بدل تمرير النموذج كاملاً، لأن تحديث حقل واحد أرخص
  /// ولا يخاطر بالكتابة فوق حقول عدّلها المالك من جهاز آخر.
  Future<bool> toggleStatus({
    required String housingId,
    required HousingStatus status,
  }) async {
    try {
      await _collection.doc(housingId).update({
        'status': status.code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('HousingService: failed to toggle status $housingId: $e');
      return false;
    }
  }

  Future<bool> delete(String housingId) async {
    try {
      await _collection.doc(housingId).delete();
      return true;
    } catch (e) {
      debugPrint('HousingService: failed to delete $housingId: $e');
      return false;
    }
  }

  // ===================== الفلترة (منطق خالص) =====================

  /// تطبيق الفلاتر في الذاكرة — قابل للاختبار بلا شبكة.
  static List<HousingModel> applyFilters(
    List<HousingModel> items, {
    HousingStatus? status,
    HousingGender? gender,
    double? maxPrice,
    double? maxDistanceKm,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return items.where((item) {
      if (status != null && item.status != status) return false;
      if (gender != null && item.gender != gender) return false;

      // السكن بلا سعر معلن لا يُستبعَد بفلتر السعر: غياب المعلومة ليس
      // دليلاً على تجاوزها، واستبعاده كان سيُخفي خيارات صالحة.
      final price = item.priceMonthly;
      if (maxPrice != null && price != null && price > maxPrice) return false;

      if (maxDistanceKm != null &&
          item.distanceKm > 0 &&
          item.distanceKm > maxDistanceKm) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final haystack =
            '${item.name} ${item.addressText} ${item.description}'
                .toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }

      return true;
    }).toList();
  }
}
