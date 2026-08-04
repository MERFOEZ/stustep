import 'certificate_eligibility.dart';
import 'department_guide_model.dart';
import 'department_summary.dart';

/// اقتراح تخصص واحد ناتج عن مساعد اختيار التخصص.
class MajorSuggestion {
  final DepartmentSummary department;
  final DepartmentGuideModel? guide;
  final String collegeName;

  /// النتيجة النهائية من 100.
  final double score;

  /// تفصيل النقاط لعرضه للطالب وشرح سبب الترتيب.
  final SuggestionBreakdown breakdown;

  /// الاهتمامات التي تطابقت فعلياً — تُعرض كرقائق تحت الاقتراح.
  final List<String> matchedInterests;

  final CertificateEligibility eligibility;

  const MajorSuggestion({
    required this.department,
    required this.collegeName,
    required this.score,
    required this.breakdown,
    required this.eligibility,
    this.guide,
    this.matchedInterests = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'departmentId': department.id,
      'departmentName': department.name,
      'collegeId': department.collegeId,
      'score': score,
      'matchedInterests': matchedInterests,
      'eligibility': eligibility.toMap(),
    };
  }
}

/// تفصيل مكوّنات النتيجة.
///
/// الأوزان المعتمدة: الاهتمامات 60، ملاءمة المعدل 25، توافق الشهادة
/// والمسار 10، اكتمال بيانات الدليل 5.
class SuggestionBreakdown {
  final double interestScore;
  final double gpaFitScore;
  final double certificateFitScore;
  final double completenessScore;

  const SuggestionBreakdown({
    this.interestScore = 0,
    this.gpaFitScore = 0,
    this.certificateFitScore = 0,
    this.completenessScore = 0,
  });

  double get total =>
      interestScore + gpaFitScore + certificateFitScore + completenessScore;

  Map<String, dynamic> toMap() {
    return {
      'interestScore': interestScore,
      'gpaFitScore': gpaFitScore,
      'certificateFitScore': certificateFitScore,
      'completenessScore': completenessScore,
      'total': total,
    };
  }
}

/// الأوزان المعتمدة في حساب النتيجة.
///
/// عزلها في مكان واحد يجعلها قابلة للضبط والاختبار دون البحث عنها داخل
/// منطق الحساب.
class MatcherWeights {
  const MatcherWeights._();

  static const double interests = 60;
  static const double gpaFit = 25;
  static const double certificateFit = 10;
  static const double completeness = 5;

  /// الفارق المسموح به لاعتبار الطالب «قريباً من الشرط».
  static const double borderlineGpaGap = 3;
}
