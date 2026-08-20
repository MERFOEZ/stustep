import 'package:cloud_firestore/cloud_firestore.dart';

import 'admission_enums.dart';

/// نموذج اختبار مرفوع كملف PDF — مجموعة `exam_papers`.
class ExamPaperModel {
  final String id;
  final String title;
  final String fileUrl;
  final String fileName;
  final int fileSizeBytes;

  /// حقل الفلترة الوحيد في الاستعلام — بقية الفلاتر تُطبَّق في الذاكرة
  /// تفادياً للفهارس المركّبة، التزاماً بنمط المشروع القائم.
  final String collegeId;

  /// `null` يعني أن النموذج يخص الكلية كاملة لا قسماً بعينه.
  final String? departmentId;

  final String? courseName;
  final int year;
  final String term;
  final ExamPaperType type;

  final String uploadedBy;
  final String uploadedByName;
  final Timestamp? uploadedAt;

  final int downloadCount;
  final ModerationStatus moderationStatus;

  const ExamPaperModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.collegeId,
    required this.uploadedBy,
    this.fileName = '',
    this.fileSizeBytes = 0,
    this.departmentId,
    this.courseName,
    this.year = 0,
    this.term = '',
    this.type = ExamPaperType.model,
    this.uploadedByName = '',
    this.uploadedAt,
    this.downloadCount = 0,
    this.moderationStatus = ModerationStatus.published,
  });

  bool isOwnedBy(String? uid) => uid != null && uid == uploadedBy;

  /// اسم الملف المحلي بعد التنزيل.
  ///
  /// نستخدم معرّف Firestore لأنه ثابت أبدياً، تفادياً لخطأ النظام القائم
  /// الذي يبني معرّف الملف من `title.hashCode` فتصبح الملفات يتيمة عند أي
  /// تعديل على العنوان.
  String get localFileName => 'paper_$id.pdf';

  String get formattedSize {
    if (fileSizeBytes <= 0) return '—';
    final sizeMb = fileSizeBytes / (1024 * 1024);
    if (sizeMb >= 1) return '${sizeMb.toStringAsFixed(1)} MB';
    final sizeKb = fileSizeBytes / 1024;
    return '${sizeKb.toStringAsFixed(0)} KB';
  }

  factory ExamPaperModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamPaperModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt() ?? 0,
      collegeId: data['collegeId'] as String? ?? '',
      departmentId: data['departmentId'] as String?,
      courseName: data['courseName'] as String?,
      year: (data['year'] as num?)?.toInt() ?? 0,
      term: data['term'] as String? ?? '',
      type: ExamPaperType.fromCode(data['type'] as String?),
      uploadedBy: data['uploadedBy'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      uploadedAt: data['uploadedAt'] is Timestamp
          ? data['uploadedAt'] as Timestamp
          : null,
      downloadCount: (data['downloadCount'] as num?)?.toInt() ?? 0,
      moderationStatus: ModerationStatus.fromCode(
        data['moderationStatus'] as String?,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'collegeId': collegeId,
      if (departmentId != null) 'departmentId': departmentId,
      if (courseName != null) 'courseName': courseName,
      'year': year,
      'term': term,
      'type': type.code,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'downloadCount': downloadCount,
      'moderationStatus': moderationStatus.code,
    };
  }
}
