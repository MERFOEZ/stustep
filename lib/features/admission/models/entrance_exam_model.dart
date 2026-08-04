/// اختبار قبول تشترطه كلية أو قسم.
class EntranceExamModel {
  /// معرّف إنجليزي ثابت للاختبار (مثل `medical_aptitude`).
  final String code;

  final String name;
  final String description;
  final bool isRequired;

  /// المواد التي يغطيها الاختبار.
  final List<String> subjects;

  const EntranceExamModel({
    required this.code,
    required this.name,
    this.description = '',
    this.isRequired = true,
    this.subjects = const [],
  });

  factory EntranceExamModel.fromMap(Map<String, dynamic> map) {
    final rawSubjects = map['subjects'];
    return EntranceExamModel(
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isRequired: map['isRequired'] as bool? ?? true,
      subjects: rawSubjects is List
          ? rawSubjects.map((item) => item.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'isRequired': isRequired,
      'subjects': subjects,
    };
  }

  static List<EntranceExamModel> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => EntranceExamModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    return const [];
  }
}
