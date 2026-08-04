import 'package:cloud_firestore/cloud_firestore.dart';

import 'department_admission_override.dart';
import 'effective_requirement.dart';
import 'entrance_exam_model.dart';
import 'subject_requirement.dart';

/// شروط القبول لكلية — مجموعة الظل `admission_requirements`.
/// معرّف الوثيقة **مطابق** لمعرّف وثيقة الكلية في `colleges` (علاقة 1:1).
class AdmissionRequirementModel {
  final String collegeId;
  final String academicYear;

  /// أنواع شهادات الثانوية المقبولة (رموز `CertificateType`).
  final List<String> acceptedCertificates;

  /// المسارات المقبولة (رموز `HighSchoolTrack`).
  final List<String> allowedTracks;

  /// الحد الأدنى العام للمعدل — بالنسبة المئوية دائماً (المرجع الموحّد).
  final double minGpa;

  /// حد أدنى مختلف لكل مسار.
  final Map<String, double> minGpaByTrack;

  /// حد أدنى مختلف لكل نوع شهادة — له الأسبقية على المسار.
  final Map<String, double> minGpaByCertificate;

  /// أقصى عمر مسموح للشهادة بالسنوات — `null` يعني بلا قيد.
  final int? maxCertificateAgeYears;

  /// اشتراط معادلة وزارة التربية للشهادات الأجنبية.
  final bool requiresEquivalency;

  final List<SubjectRequirement> subjectRequirements;
  final List<String> requiredDocuments;
  final List<EntranceExamModel> entranceExams;
  final List<DepartmentAdmissionOverride> departmentOverrides;

  final String? notes;
  final Timestamp? applicationOpensAt;
  final Timestamp? applicationClosesAt;

  const AdmissionRequirementModel({
    required this.collegeId,
    this.academicYear = '',
    this.acceptedCertificates = const [],
    this.allowedTracks = const [],
    this.minGpa = 0,
    this.minGpaByTrack = const {},
    this.minGpaByCertificate = const {},
    this.maxCertificateAgeYears,
    this.requiresEquivalency = false,
    this.subjectRequirements = const [],
    this.requiredDocuments = const [],
    this.entranceExams = const [],
    this.departmentOverrides = const [],
    this.notes,
    this.applicationOpensAt,
    this.applicationClosesAt,
  });

  /// هل باب التقديم مفتوح في اللحظة الحالية؟
  bool isApplicationOpen(DateTime now) {
    final opens = applicationOpensAt?.toDate();
    final closes = applicationClosesAt?.toDate();
    if (opens == null || closes == null) return true;
    return !now.isBefore(opens) && !now.isAfter(closes);
  }

  DepartmentAdmissionOverride? overrideFor(String? departmentId) {
    if (departmentId == null) return null;
    for (final item in departmentOverrides) {
      if (item.departmentId == departmentId) return item;
    }
    return null;
  }

  /// الحد الأدنى الفعلي للمعدل حسب ترتيب الأسبقية المعتمد:
  ///
  ///   استثناء القسم ← minGpaByCertificate ← minGpaByTrack ← minGpa
  double effectiveMinGpa({
    String? departmentId,
    String? certificateCode,
    String? trackCode,
  }) {
    final departmentOverride = overrideFor(departmentId);
    if (departmentOverride?.minGpa != null) return departmentOverride!.minGpa!;

    final byCertificate = minGpaByCertificate[certificateCode];
    if (byCertificate != null) return byCertificate;

    final byTrack = minGpaByTrack[trackCode];
    if (byTrack != null) return byTrack;

    return minGpa;
  }

  /// دمج شروط الكلية مع استثناء القسم في مدخل واحد جاهز للتحقق.
  EffectiveRequirement effectiveFor({
    String? departmentId,
    String? certificateCode,
    String? trackCode,
  }) {
    final departmentOverride = overrideFor(departmentId);
    final extraCodes = departmentOverride?.extraExamCodes ?? const <String>[];

    return EffectiveRequirement(
      collegeId: collegeId,
      departmentId: departmentId,
      acceptedCertificates:
          departmentOverride?.acceptedCertificates ?? acceptedCertificates,
      allowedTracks: departmentOverride?.allowedTracks ?? allowedTracks,
      minGpa: effectiveMinGpa(
        departmentId: departmentId,
        certificateCode: certificateCode,
        trackCode: trackCode,
      ),
      maxCertificateAgeYears: maxCertificateAgeYears,
      requiresEquivalency: requiresEquivalency,
      subjectRequirements: [
        ...subjectRequirements,
        ...?departmentOverride?.subjectRequirements,
      ],
      entranceExams: entranceExams
          .where((exam) => exam.isRequired || extraCodes.contains(exam.code))
          .toList(),
      requiredDocuments: requiredDocuments,
    );
  }

  factory AdmissionRequirementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdmissionRequirementModel(
      collegeId: data['collegeId'] as String? ?? doc.id,
      academicYear: data['academicYear'] as String? ?? '',
      acceptedCertificates: _stringList(data['acceptedCertificates']),
      allowedTracks: _stringList(data['allowedTracks']),
      minGpa: (data['minGpa'] as num?)?.toDouble() ?? 0,
      minGpaByTrack: _numberMap(data['minGpaByTrack']),
      minGpaByCertificate: _numberMap(data['minGpaByCertificate']),
      maxCertificateAgeYears: (data['maxCertificateAgeYears'] as num?)?.toInt(),
      requiresEquivalency: data['requiresEquivalency'] as bool? ?? false,
      subjectRequirements: SubjectRequirement.listFrom(
        data['subjectRequirements'],
      ),
      requiredDocuments: _stringList(data['requiredDocuments']),
      entranceExams: EntranceExamModel.listFrom(data['entranceExams']),
      departmentOverrides: DepartmentAdmissionOverride.listFrom(
        data['departmentOverrides'],
      ),
      notes: data['notes'] as String?,
      applicationOpensAt: data['applicationOpensAt'] is Timestamp
          ? data['applicationOpensAt'] as Timestamp
          : null,
      applicationClosesAt: data['applicationClosesAt'] is Timestamp
          ? data['applicationClosesAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'collegeId': collegeId,
      'academicYear': academicYear,
      'acceptedCertificates': acceptedCertificates,
      'allowedTracks': allowedTracks,
      'minGpa': minGpa,
      'minGpaByTrack': minGpaByTrack,
      'minGpaByCertificate': minGpaByCertificate,
      if (maxCertificateAgeYears != null)
        'maxCertificateAgeYears': maxCertificateAgeYears,
      'requiresEquivalency': requiresEquivalency,
      'subjectRequirements': subjectRequirements
          .map((item) => item.toMap())
          .toList(),
      'requiredDocuments': requiredDocuments,
      'entranceExams': entranceExams.map((item) => item.toMap()).toList(),
      'departmentOverrides': departmentOverrides
          .map((item) => item.toMap())
          .toList(),
      if (notes != null) 'notes': notes,
      if (applicationOpensAt != null) 'applicationOpensAt': applicationOpensAt,
      if (applicationClosesAt != null)
        'applicationClosesAt': applicationClosesAt,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }

  static Map<String, double> _numberMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), (item as num?)?.toDouble() ?? 0),
      );
    }
    return const {};
  }
}
