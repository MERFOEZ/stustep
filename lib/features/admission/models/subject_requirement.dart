/// اشتراط حد أدنى في مادة بعينها داخل شهادة الثانوية.
///
/// مثال واقعي: كلية الطب تشترط 80% في الأحياء والكيمياء، وكلية الهندسة
/// تشترط 75% في الرياضيات والفيزياء — وهذا شرط مستقل عن المعدل العام.
class SubjectRequirement {
  /// معرّف إنجليزي ثابت للمادة (مثل `math`, `physics`, `biology`).
  final String subjectCode;

  /// الاسم المعروض كما ورد في مصدر البيانات.
  final String subjectName;

  /// الحد الأدنى المطلوب بالنسبة المئوية (0 – 100).
  final double minGrade;

  const SubjectRequirement({
    required this.subjectCode,
    required this.subjectName,
    required this.minGrade,
  });

  factory SubjectRequirement.fromMap(Map<String, dynamic> map) {
    return SubjectRequirement(
      subjectCode: map['subjectCode'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      minGrade: (map['minGrade'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'minGrade': minGrade,
    };
  }

  static List<SubjectRequirement> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => SubjectRequirement.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }
    return const [];
  }
}
