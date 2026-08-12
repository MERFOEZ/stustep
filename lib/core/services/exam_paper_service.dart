import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/admission_enums.dart';
import '../../features/admission/models/exam_paper_model.dart';
import '../../features/admission/models/upload_file.dart';
import 'admission_collections.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// خدمة نماذج الاختبارات — رفع ملفات PDF وقراءتها وحذفها.
///
/// تتبع نفس التزامات `HousingService`: الملكية (`uploadedBy`) تُكتب من جلسة
/// المصادقة لا من الواجهة، وحالة المراجعة لا تُرسَل في التحديث إطلاقاً.
///
/// **فرق جوهري عن نظام تنزيل الفيديو القائم في المشروع:**
/// ذلك النظام يبني معرّف الملف من `title.hashCode`، فأي تعديل على العنوان
/// يجعل الملف المنزَّل يتيماً على جهاز المستخدم بلا مالك. هنا نستخدم معرّف
/// وثيقة Firestore وهو ثابت أبدياً (`ExamPaperModel.localFileName`).
class ExamPaperService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ExamPaperService _instance = ExamPaperService._internal();

  factory ExamPaperService() => _instance;

  ExamPaperService._internal();

  /// أقصى حجم ملف مقبول — عشرة ميغابايت.
  ///
  /// الحد ليس تعسفياً: الملف الأكبر يفشل رفعه غالباً على اتصال الطالب،
  /// ورفضه مبكراً برسالة واضحة أفضل من انتظار دقيقتين ثم فشل مبهم.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AdmissionCollections.examPapers);

  // ===================== القراءة =====================

  /// بث حيّ لنماذج كلية واحدة.
  ///
  /// شرط `where` واحد فقط والترتيب في الذاكرة — لا فهرس مركّب.
  Stream<List<ExamPaperModel>> watchByCollege(String collegeId) {
    return _collection
        .where('collegeId', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(ExamPaperModel.fromFirestore)
              .where(
                (item) => item.moderationStatus != ModerationStatus.rejected,
              )
              .toList();
          _sortByNewest(items);
          return items;
        });
  }

  /// نماذج المستخدم الحالي — لإدارتها وحذفها.
  Stream<List<ExamPaperModel>> watchMyPapers() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _collection.where('uploadedBy', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(ExamPaperModel.fromFirestore).toList();
      _sortByNewest(items);
      return items;
    });
  }

  void _sortByNewest(List<ExamPaperModel> items) {
    items.sort((a, b) {
      final left = a.uploadedAt;
      final right = b.uploadedAt;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
  }

  // ===================== الكتابة =====================

  /// رفع نموذج جديد.
  ///
  /// الملف يُرفع أولاً ثم تُكتب الوثيقة: العكس كان سيُنتج وثيقة برابط فارغ
  /// إن فشل الرفع، وهي أسوأ من فشل واضح يُعيد المستخدم المحاولة عليه.
  Future<String?> upload({
    required ExamPaperModel paper,
    required UploadFile file,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return null;

    try {
      final fileSize = file.sizeBytes;
      if (fileSize > maxFileSizeBytes) {
        debugPrint('ExamPaperService: file too large ($fileSize bytes)');
        return null;
      }

      final url = await StorageService().uploadPdf(file);

      final data = paper.toFirestore()
        ..['fileUrl'] = url
        ..['fileSizeBytes'] = fileSize
        ..['uploadedBy'] = user.uid
        ..['uploadedByName'] = user.displayName ?? ''
        ..['uploadedAt'] = FieldValue.serverTimestamp();

      final reference = await _collection.add(data);
      return reference.id;
    } catch (e) {
      debugPrint('ExamPaperService: failed to upload paper: $e');
      return null;
    }
  }

  /// زيادة عدّاد التنزيلات.
  ///
  /// نستخدم `FieldValue.increment` لا قراءةً فزيادةً فكتابة: العملية الأخيرة
  /// تفقد تنزيلات متزامنة من عدة أجهزة، والأولى ذرّية على الخادم.
  /// الفشل هنا لا يُبلَّغ للمستخدم لأنه إحصاء لا يمسّ وظيفته.
  Future<void> incrementDownloads(String paperId) async {
    try {
      await _collection.doc(paperId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('ExamPaperService: failed to count download: $e');
    }
  }

  Future<bool> delete(String paperId) async {
    try {
      await _collection.doc(paperId).delete();
      return true;
    } catch (e) {
      debugPrint('ExamPaperService: failed to delete $paperId: $e');
      return false;
    }
  }

  // ===================== الفلترة (منطق خالص) =====================

  /// تطبيق فلاتر النماذج في الذاكرة — قابل للاختبار بلا شبكة.
  ///
  /// `departmentId` بقيمة `null` في الوثيقة يعني «نموذج عام للكلية»، وهذه
  /// النماذج **تظهر دائماً** مهما كان القسم المختار: نموذج رياضيات عام
  /// ينفع طالب الهندسة وطالب الحاسوب معاً، وإخفاؤه خسارة بلا سبب.
  static List<ExamPaperModel> applyFilters(
    List<ExamPaperModel> items, {
    String? departmentId,
    ExamPaperType? type,
    int? year,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return items.where((item) {
      if (departmentId != null &&
          item.departmentId != null &&
          item.departmentId != departmentId) {
        return false;
      }
      if (type != null && item.type != type) return false;
      if (year != null && item.year != year) return false;

      if (normalizedQuery.isNotEmpty) {
        final haystack = '${item.title} ${item.courseName ?? ''}'
            .toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }

      return true;
    }).toList();
  }

  /// السنوات المتاحة في مجموعة نماذج، تنازلياً — تُغذّي قائمة الفلترة.
  static List<int> availableYears(List<ExamPaperModel> items) {
    final years = items
        .map((item) => item.year)
        .where((year) => year > 0)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }
}
