import 'package:cloud_firestore/cloud_firestore.dart';

/// دليل التخصص — يُخزَّن في مجموعة الظل `department_guides`.
///
/// معرّف الوثيقة **مطابق تماماً** لمعرّف وثيقة القسم في `departments`
/// (علاقة 1:1). سبب هذا التصميم أن وثائق الأقسام يُدخلها الفريق يدوياً من
/// Firebase Console ويستخدمها زملاء آخرون، فإضافة حقول داخلها تعرّضها للمسح
/// عند أي إعادة استيراد. مجموعة الظل تعزل بياناتنا تماماً، والقراءة تتم
/// بمعرّف معلوم مسبقاً فلا تحتاج فهرساً ولا استعلاماً.
class DepartmentGuideModel {
  /// نفس قيمة معرّف الوثيقة — مكرر داخل البيانات لأغراض التحقق.
  final String departmentId;

  /// مُزال التطبيع عمداً لتفادي قراءة إضافية من `departments`.
  final String collegeId;

  final String description;
  final List<String> coreSubjects;
  final List<String> skills;
  final List<String> careers;

  /// معرّفات إنجليزية ثابتة من `InterestCatalog` — تُغذّي مساعد اختيار التخصص.
  final List<String> interestTags;

  final int studyYears;
  final String degreeAwarded;
  final String? heroImage;

  /// ترتيب العرض — يُغني عن `orderBy` مركّب يتطلب فهرساً.
  final int orderIndex;

  final Timestamp? updatedAt;

  const DepartmentGuideModel({
    required this.departmentId,
    required this.collegeId,
    required this.description,
    this.coreSubjects = const [],
    this.skills = const [],
    this.careers = const [],
    this.interestTags = const [],
    this.studyYears = 4,
    this.degreeAwarded = '',
    this.heroImage,
    this.orderIndex = 0,
    this.updatedAt,
  });

  /// هل الدليل مكتمل البيانات؟ يُستخدم كأحد مكوّنات نقاط المطابقة.
  bool get isComplete =>
      description.isNotEmpty &&
      coreSubjects.isNotEmpty &&
      skills.isNotEmpty &&
      careers.isNotEmpty;

  factory DepartmentGuideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DepartmentGuideModel(
      departmentId: data['departmentId'] as String? ?? doc.id,
      collegeId: data['collegeId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      coreSubjects: _stringList(data['coreSubjects']),
      skills: _stringList(data['skills']),
      careers: _stringList(data['careers']),
      interestTags: _stringList(data['interestTags']),
      studyYears: (data['studyYears'] as num?)?.toInt() ?? 4,
      degreeAwarded: data['degreeAwarded'] as String? ?? '',
      heroImage: data['heroImage'] as String?,
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'departmentId': departmentId,
      'collegeId': collegeId,
      'description': description,
      'coreSubjects': coreSubjects,
      'skills': skills,
      'careers': careers,
      'interestTags': interestTags,
      'studyYears': studyYears,
      'degreeAwarded': degreeAwarded,
      if (heroImage != null) 'heroImage': heroImage,
      'orderIndex': orderIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
