import 'admission_enums.dart';

/// شهادة الثانوية التي يدخلها الطالب.
///
/// قرار تصميمي مهم: يُخزَّن المعدل **بقيمته الأصلية مع سلّمه** (`gpa` +
/// `gpaScale`) ولا تُخزَّن القيمة المطبَّعة. سبب ذلك أن معدل «3.6» بلا سلّم
/// لا معنى له، وأن تخزين النسبة المطبَّعة فقط يفقد القيمة الأصلية ويمنع
/// تصحيح جدول التحويل لاحقاً. التطبيع يحدث لحظة المقارنة فقط.
class HighSchoolCertificate {
  final CertificateType type;
  final HighSchoolTrack track;

  /// المعدل بقيمته الأصلية كما أدخلها الطالب.
  final double gpa;

  /// السلّم الذي تنتمي إليه قيمة `gpa`.
  final GpaScale gpaScale;

  final int graduationYear;

  /// هل حصل الطالب على معادلة الشهادة من وزارة التربية؟
  final bool hasEquivalency;

  /// درجات المواد بالنسبة المئوية — المفتاح `subjectCode`.
  /// تُستخدم للتحقق من `SubjectRequirement`.
  final Map<String, double> subjectGrades;

  const HighSchoolCertificate({
    required this.type,
    required this.track,
    required this.gpa,
    required this.gpaScale,
    required this.graduationYear,
    this.hasEquivalency = false,
    this.subjectGrades = const {},
  });

  /// المعدل محوّلاً إلى نسبة مئوية موحّدة.
  ///
  /// يُعيد `null` لسلّم التقديرات لأنه يحتاج جدول تحويل من الإعدادات،
  /// وهو ما يوفّره `CertificateService`.
  double? get normalizedPercentage => gpaScale.toPercentage(gpa);

  /// عمر الشهادة بالسنوات مقارنةً بسنة مرجعية.
  int ageInYears(int referenceYear) => referenceYear - graduationYear;

  HighSchoolCertificate copyWith({
    CertificateType? type,
    HighSchoolTrack? track,
    double? gpa,
    GpaScale? gpaScale,
    int? graduationYear,
    bool? hasEquivalency,
    Map<String, double>? subjectGrades,
  }) {
    return HighSchoolCertificate(
      type: type ?? this.type,
      track: track ?? this.track,
      gpa: gpa ?? this.gpa,
      gpaScale: gpaScale ?? this.gpaScale,
      graduationYear: graduationYear ?? this.graduationYear,
      hasEquivalency: hasEquivalency ?? this.hasEquivalency,
      subjectGrades: subjectGrades ?? this.subjectGrades,
    );
  }

  factory HighSchoolCertificate.fromMap(Map<String, dynamic> map) {
    final rawGrades = map['subjectGrades'];
    return HighSchoolCertificate(
      type: CertificateType.fromCode(map['type'] as String?),
      track: HighSchoolTrack.fromCode(map['track'] as String?),
      gpa: (map['gpa'] as num?)?.toDouble() ?? 0,
      gpaScale: GpaScale.fromCode(map['gpaScale'] as String?),
      graduationYear: (map['graduationYear'] as num?)?.toInt() ?? 0,
      hasEquivalency: map['hasEquivalency'] as bool? ?? false,
      subjectGrades: rawGrades is Map
          ? rawGrades.map(
              (key, value) => MapEntry(
                key.toString(),
                (value as num?)?.toDouble() ?? 0,
              ),
            )
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.code,
      'track': track.code,
      'gpa': gpa,
      'gpaScale': gpaScale.code,
      'graduationYear': graduationYear,
      'hasEquivalency': hasEquivalency,
      if (subjectGrades.isNotEmpty) 'subjectGrades': subjectGrades,
    };
  }
}
