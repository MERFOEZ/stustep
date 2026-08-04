import 'entrance_exam_model.dart';
import 'subject_requirement.dart';

/// الشروط النهائية المطبَّقة على قسم بعينه، بعد دمج شروط الكلية مع استثناء
/// القسم إن وُجد.
///
/// وجود هذا النموذج يمنع تكرار منطق الدمج في كل شاشة أو خدمة تحتاج «الشرط
/// الفعلي»، ويجعل التحقق من الأهلية في المرحلة 4 يعمل على مدخل واحد واضح.
class EffectiveRequirement {
  final String collegeId;

  /// `null` يعني أن الشروط على مستوى الكلية كاملة.
  final String? departmentId;

  final List<String> acceptedCertificates;
  final List<String> allowedTracks;

  /// الحد الأدنى للمعدل بالنسبة المئوية بعد تطبيق ترتيب الأسبقية.
  final double minGpa;

  final int? maxCertificateAgeYears;
  final bool requiresEquivalency;
  final List<SubjectRequirement> subjectRequirements;
  final List<EntranceExamModel> entranceExams;
  final List<String> requiredDocuments;

  const EffectiveRequirement({
    required this.collegeId,
    this.departmentId,
    this.acceptedCertificates = const [],
    this.allowedTracks = const [],
    this.minGpa = 0,
    this.maxCertificateAgeYears,
    this.requiresEquivalency = false,
    this.subjectRequirements = const [],
    this.entranceExams = const [],
    this.requiredDocuments = const [],
  });

  bool acceptsCertificate(String certificateCode) =>
      acceptedCertificates.isEmpty ||
      acceptedCertificates.contains(certificateCode);

  bool acceptsTrack(String trackCode) =>
      allowedTracks.isEmpty || allowedTracks.contains(trackCode);
}
