import 'subject_requirement.dart';

/// استثناء قسم بعينه على شروط الكلية.
///
/// لماذا مصفوفة مضمّنة داخل وثيقة الشروط وليست مجموعة مستقلة؟
/// لأن الاستثناءات تُقرأ **دائماً مع وثيقة الكلية ولا يُستعلم عنها منفردة**،
/// وعددها أقل من عدد أقسام الكلية (< 20). هذا يختلف عن مصفوفة `lectures`
/// في المشروع القائم التي يُستعلم عن عناصرها منفردة وتحتاج معرّفات مستقرة،
/// ولذلك كان تضمينها قراراً خاطئاً بينما التضمين هنا هو القرار الصحيح.
class DepartmentAdmissionOverride {
  final String departmentId;

  /// `null` يعني: لا استثناء، استخدم قيمة الكلية.
  final double? minGpa;
  final List<String>? allowedTracks;
  final List<String>? acceptedCertificates;

  final List<String> extraExamCodes;
  final List<SubjectRequirement> subjectRequirements;

  const DepartmentAdmissionOverride({
    required this.departmentId,
    this.minGpa,
    this.allowedTracks,
    this.acceptedCertificates,
    this.extraExamCodes = const [],
    this.subjectRequirements = const [],
  });

  factory DepartmentAdmissionOverride.fromMap(Map<String, dynamic> map) {
    return DepartmentAdmissionOverride(
      departmentId: map['departmentId'] as String? ?? '',
      minGpa: (map['minGpa'] as num?)?.toDouble(),
      allowedTracks: _nullableStringList(map['allowedTracks']),
      acceptedCertificates: _nullableStringList(map['acceptedCertificates']),
      extraExamCodes: _nullableStringList(map['extraExamCodes']) ?? const [],
      subjectRequirements: SubjectRequirement.listFrom(
        map['subjectRequirements'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      if (minGpa != null) 'minGpa': minGpa,
      if (allowedTracks != null) 'allowedTracks': allowedTracks,
      if (acceptedCertificates != null)
        'acceptedCertificates': acceptedCertificates,
      'extraExamCodes': extraExamCodes,
      'subjectRequirements': subjectRequirements
          .map((item) => item.toMap())
          .toList(),
    };
  }

  static List<DepartmentAdmissionOverride> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => DepartmentAdmissionOverride.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }
    return const [];
  }

  static List<String>? _nullableStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }
}
