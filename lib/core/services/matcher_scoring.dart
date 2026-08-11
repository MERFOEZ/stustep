import '../../features/admission/models/certificate_eligibility.dart';
import '../../features/admission/models/department_guide_model.dart';
import '../../features/admission/models/effective_requirement.dart';
import '../../features/admission/models/high_school_certificate.dart';
import '../../features/admission/models/major_suggestion.dart';

/// نتيجة مطابقة الاهتمامات مع الوسوم المطابقة فعلياً.
///
/// نُعيد الوسوم المطابقة لا الرقم وحده، لأن الواجهة تعرضها للطالب كسبب
/// ملموس للترتيب: «اقتُرح عليك لأنك تحب البرمجة والرياضيات».
class InterestMatch {
  final double score;
  final List<String> matched;

  const InterestMatch({required this.score, required this.matched});

  static const InterestMatch none = InterestMatch(score: 0, matched: []);
}

/// دوال حساب نقاط اقتراح التخصص — **منطق خالص بلا أي حالة أو شبكة**.
///
/// عُزلت عن خدمة المطابقة عمداً حتى تُختبَر كل دالة على حدة بمدخلات صريحة.
/// هذا هو الجزء الذي يُسأل عنه في المناقشة: «كيف رتّبت النتائج؟» — والجواب
/// يجب أن يكون رقماً قابلاً للتتبّع لا حدساً.
///
/// الأوزان مجموعها 100 وتُقرأ من [MatcherWeights]:
///   الاهتمامات 60 · ملاءمة المعدل 25 · توافق الشهادة 10 · اكتمال الدليل 5
class MatcherScoring {
  const MatcherScoring._();

  /// وزن شقّي مطابقة الاهتمامات.
  ///
  /// **التغطية** تقيس: كم من اهتمامات الطالب يلبّيها هذا التخصص؟
  /// **الدقة** تقيس: كم من وسوم التخصص تخصّ الطالب فعلاً؟
  ///
  /// لماذا لا نكتفي بالتغطية؟ لأن تخصصاً وسم نفسه بكل الاهتمامات الأربعة
  /// عشر كان سيحقق تغطية كاملة لكل طالب ويتصدّر القائمة دائماً. إدخال
  /// الدقة بوزن الربع يعاقب هذا التوسيم المفرط دون أن يطغى على المقصد
  /// الأساسي وهو خدمة اهتمام الطالب.
  static const double _coverageShare = 0.75;
  static const double _precisionShare = 0.25;

  /// نقاط مطابقة الاهتمامات (من 60).
  static InterestMatch interestScore(
    List<String> studentInterests,
    List<String> departmentTags,
  ) {
    if (studentInterests.isEmpty || departmentTags.isEmpty) {
      return InterestMatch.none;
    }

    final tagSet = departmentTags.toSet();
    final matched = studentInterests.where(tagSet.contains).toList();
    if (matched.isEmpty) return InterestMatch.none;

    final coverage = matched.length / studentInterests.length;
    final precision = matched.length / tagSet.length;
    final blended = (coverage * _coverageShare) + (precision * _precisionShare);

    return InterestMatch(
      score: blended * MatcherWeights.interests,
      matched: matched,
    );
  }

  /// نقاط ملاءمة المعدل (من 25) — مشتقّة مباشرة من نتيجة محرّك الأهلية.
  ///
  /// لا نعيد حساب المعدل هنا إطلاقاً. المحرّك هو المرجع الوحيد للأهلية،
  /// وهذه الدالة تترجم حكمه إلى نقاط فقط. أي منطق موازٍ كان سيسمح بأن
  /// يتناقض ترتيب الاقتراح مع شارة الأهلية المعروضة على البطاقة نفسها.
  static double gpaFitScore(CertificateEligibility eligibility) {
    if (eligibility.isEligible) return MatcherWeights.gpaFit;
    // «قريب من الشرط» يستحق نصف النقاط: الفرصة قائمة لكنها ليست مضمونة.
    if (eligibility.isBorderline) return MatcherWeights.gpaFit / 2;
    return 0;
  }

  /// نقاط توافق نوع الشهادة والمسار (من 10).
  ///
  /// شرطان مستقلان بوزن متساوٍ: قبول نوع الشهادة، وقبول المسار الدراسي.
  static double certificateFitScore(
    HighSchoolCertificate certificate,
    EffectiveRequirement requirement,
  ) {
    var score = 0.0;
    const half = MatcherWeights.certificateFit / 2;

    if (requirement.acceptsCertificate(certificate.type.code)) score += half;
    if (requirement.acceptsTrack(certificate.track.code)) score += half;

    return score;
  }

  /// نقاط اكتمال بيانات الدليل (من 5).
  ///
  /// ليست حكماً على جودة التخصص بل على جودة **بياناتنا عنه**. تخصص بلا
  /// دليل لا نستطيع أن نشرح للطالب لماذا يناسبه، فلا يصحّ أن يتصدّر تخصصاً
  /// موثّقاً بالكامل عند تساوي بقية العوامل.
  static double completenessScore(DepartmentGuideModel? guide) {
    if (guide == null) return 0;
    if (guide.isComplete) return MatcherWeights.completeness;
    return MatcherWeights.completeness * 0.4;
  }

  /// تجميع المكوّنات الأربعة في تفصيل واحد.
  static SuggestionBreakdown breakdown({
    required InterestMatch interest,
    required CertificateEligibility eligibility,
    required HighSchoolCertificate certificate,
    required EffectiveRequirement requirement,
    required DepartmentGuideModel? guide,
  }) {
    return SuggestionBreakdown(
      interestScore: interest.score,
      gpaFitScore: gpaFitScore(eligibility),
      certificateFitScore: certificateFitScore(certificate, requirement),
      completenessScore: completenessScore(guide),
    );
  }
}
