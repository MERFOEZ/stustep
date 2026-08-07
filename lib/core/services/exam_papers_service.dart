import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/admission_enums.dart';
import '../../features/admission/models/exam_paper_model.dart';
import 'admission_collections.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// خدمة نماذج الاختبارات على Firestore.
///
/// مسؤولة عن البيانات فقط. أما تنزيل الملفات وحفظها وفتحها فمسؤولية
/// `PaperDownloadsService` — الفصل مقصود لأن الأولى تتعامل مع الشبكة
/// وقاعدة البيانات والثانية مع نظام الملفات المحلي.
class ExamPapersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  static final ExamPapersService _instance = ExamPapersService._internal();

  factory ExamPapersService() => _instance;

  ExamPapersService._internal();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AdmissionCollections.examPapers);

  // ===================== القراءة =====================

  /// نماذج كلية واحدة.
  ///
  /// `collegeId` هو شرط `where` الوحيد، وبقية الفلاتر (التخصص والسنة
  /// والنوع) تُطبَّق في الذاكرة تفادياً للفهارس المركّبة.
  Stream<List<ExamPaperModel>> watchByCollege(String collegeId) {
    return _collection
        .where('collegeId', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(ExamPaperModel.fromFirestore)
              .where(
                (item) =>
                    item.moderationStatus == ModerationStatus.published,
              )
              .toList();
          items.sort(_byNewest);
          return items;
        });
  }

  /// رفوعات المستخدم الحالي — تشمل غير المنشور حتى يرى صاحبه حالته.
  Stream<List<ExamPaperModel>> watchMyUploads(String uid) {
    return _collection.where('uploadedBy', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(ExamPaperModel.fromFirestore).toList();
      items.sort(_byNewest);
      return items;
    });
  }

  // ===================== الكتابة =====================

  /// رفع نموذج جديد.
  ///
  /// كما في السكنات: يُرفع الملف **قبل** كتابة الوثيقة، فلا يظهر نموذج
  /// برابط معطوب إذا فشل الرفع.
  Future<String?> uploadPaper({
    required ExamPaperModel paper,
    required File file,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    try {
      final url = await _storage.uploadPdf(file);
      final size = await file.length();

      final data = paper.toFirestore()
        ..['fileUrl'] = url
        ..['fileSizeBytes'] = size
        ..['uploadedBy'] = user.uid
        ..['uploadedByName'] =
            user.displayName ?? user.email?.split('@').first ?? 'Student'
        ..['uploadedAt'] = FieldValue.serverTimestamp()
        ..['downloadCount'] = 0;

      final doc = await _collection.add(data);
      return doc.id;
    } catch (e) {
      debugPrint('ExamPapersService: upload failed: $e');
      return null;
    }
  }

  /// حذف نموذج — للمالك فقط.
  ///
  /// ⚠️ فحص من جهة العميل. الحاجز الحقيقي قواعد الأمان في المرحلة 8.
  Future<bool> deletePaper(ExamPaperModel paper) async {
    if (!paper.isOwnedBy(AuthService().currentUser?.uid)) return false;
    try {
      await _collection.doc(paper.id).delete();
      return true;
    } catch (e) {
      debugPrint('ExamPapersService: delete failed ${paper.id}: $e');
      return false;
    }
  }

  /// زيادة عدّاد التنزيلات — ذرّية، وفشلها لا يُزعج المستخدم.
  Future<void> incrementDownloadCount(String paperId) async {
    try {
      await _collection.doc(paperId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('ExamPapersService: counter failed $paperId: $e');
    }
  }

  /// السنوات المتاحة للاختيار عند الرفع.
  static List<int> availableYears({int span = 12}) {
    final current = DateTime.now().year;
    return List<int>.generate(span, (index) => current - index);
  }

  static int _byNewest(ExamPaperModel a, ExamPaperModel b) {
    if (a.year != b.year) return b.year.compareTo(a.year);
    final aTime = a.uploadedAt;
    final bTime = b.uploadedAt;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }
}
