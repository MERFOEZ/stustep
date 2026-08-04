import 'high_school_certificate.dart';
import 'interest_tag.dart';

/// مدخلات مساعد اختيار التخصص.
///
/// كائن خالص لا علاقة له بـ Firestore — يُبنى من الشاشة ويُمرَّر إلى
/// `MajorMatcherService`. فصله عن النماذج المخزَّنة يجعل منطق الاقتراح
/// قابلاً للاختبار بلا أي اتصال بالشبكة.
class MatcherInput {
  final HighSchoolCertificate certificate;

  /// معرّفات الاهتمامات المختارة من `InterestCatalog`.
  final List<String> interests;

  /// تقييد الاقتراحات بكليات بعينها — فارغة تعني كل الكليات.
  final List<String> preferredCollegeIds;

  const MatcherInput({
    required this.certificate,
    this.interests = const [],
    this.preferredCollegeIds = const [],
  });

  bool get isValid => certificate.gpa > 0 && interests.isNotEmpty;

  MatcherInput copyWith({
    HighSchoolCertificate? certificate,
    List<String>? interests,
    List<String>? preferredCollegeIds,
  }) {
    return MatcherInput(
      certificate: certificate ?? this.certificate,
      interests: interests ?? this.interests,
      preferredCollegeIds: preferredCollegeIds ?? this.preferredCollegeIds,
    );
  }

  factory MatcherInput.fromMap(Map<String, dynamic> map) {
    final rawInterests = map['interests'];
    return MatcherInput(
      certificate: HighSchoolCertificate.fromMap(
        Map<String, dynamic>.from(map['certificate'] as Map? ?? {}),
      ),
      interests: rawInterests is List
          ? InterestCatalog.sanitize(
              rawInterests.map((item) => item.toString()),
            )
          : const [],
      preferredCollegeIds: map['preferredCollegeIds'] is List
          ? (map['preferredCollegeIds'] as List)
                .map((item) => item.toString())
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'certificate': certificate.toMap(),
      'interests': interests,
      'preferredCollegeIds': preferredCollegeIds,
    };
  }
}
