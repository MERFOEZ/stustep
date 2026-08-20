import '../../features/admission/models/admission_enums.dart';
import '../../features/admission/models/certificate_eligibility.dart';
import '../../features/admission/models/effective_requirement.dart';
import '../../features/admission/models/high_school_certificate.dart';
import '../../features/admission/models/major_suggestion.dart';
import 'certificate_service.dart';

/// محرّك التحقق من أهلية شهادة الثانوية لكلية أو قسم.
///
/// **منطق خالص بلا أي اتصال بـ Firestore أو الشبكة** — يستقبل الشهادة
/// والشرط الفعلي ويُعيد النتيجة. هذا يجعله أهم قطعة قابلة لاختبار الوحدة
/// في المشروع كله، ويُختبر فعلياً في المرحلة 8.
///
/// المبدأ الحاكم: **لا يوجد رفض مبهم أبداً.** كل رفض يحمل قائمة أسبابه
/// المحددة مع القيمة المطلوبة والقيمة الفعلية.
class EligibilityEvaluator {
  static final EligibilityEvaluator _instance =
      EligibilityEvaluator._internal();

  factory EligibilityEvaluator() => _instance;

  EligibilityEvaluator._internal();

  final CertificateService _certificateService = CertificateService();

  /// تطبيق الشروط الستة بالتسلسل على شهادة واحدة.
  ///
  /// [gradeBands] جدول تحويل التقديرات القادم من الإعدادات، اختياري.
  /// [referenceYear] سنة المقارنة لحساب عمر الشهادة، اختيارية للاختبار.
  CertificateEligibility evaluate({
    required HighSchoolCertificate certificate,
    required EffectiveRequirement requirement,
    Map<int, double>? gradeBands,
    int? referenceYear,
  }) {
    final reasons = <EligibilityReason>[];

    final normalizedGpa = _certificateService.normalize(
      certificate,
      gradeBands: gradeBands,
    );
    final requiredGpa = requirement.minGpa;
    final gap = normalizedGpa - requiredGpa;

    // (1) نوع الشهادة
    if (!requirement.acceptsCertificate(certificate.type.code)) {
      reasons.add(
        EligibilityReason(
          code: 'certificate_type',
          required: requirement.acceptedCertificates.join(', '),
          actual: certificate.type.code,
        ),
      );
    }

    // (2) المسار الدراسي
    if (!requirement.acceptsTrack(certificate.track.code)) {
      reasons.add(
        EligibilityReason(
          code: 'track',
          required: requirement.allowedTracks.join(', '),
          actual: certificate.track.code,
        ),
      );
    }

    // (3) المعدل بعد التطبيع
    final gpaFailed = normalizedGpa < requiredGpa;
    if (gpaFailed) {
      reasons.add(
        EligibilityReason(
          code: 'gpa',
          required: requiredGpa.toStringAsFixed(1),
          actual: normalizedGpa.toStringAsFixed(1),
        ),
      );
    }

    // (4) صلاحية سنة التخرج
    if (!_certificateService.isWithinAllowedAge(
      certificate,
      requirement.maxCertificateAgeYears,
      referenceYear: referenceYear,
    )) {
      reasons.add(
        EligibilityReason(
          code: 'certificate_age',
          required: '${requirement.maxCertificateAgeYears}',
          actual: '${certificate.graduationYear}',
        ),
      );
    }

    // (5) المعادلة للشهادات الأجنبية
    if (!_certificateService.satisfiesEquivalency(
      certificate,
      requirement.requiresEquivalency,
    )) {
      reasons.add(const EligibilityReason(code: 'equivalency'));
    }

    // (6) درجات المواد المشترطة
    reasons.addAll(_checkSubjects(certificate, requirement));

    return CertificateEligibility(
      level: _resolveLevel(reasons: reasons, gpaFailed: gpaFailed, gap: gap),
      failedReasons: reasons,
      gapToMinGpa: gap,
      normalizedGpa: normalizedGpa,
      requiredGpa: requiredGpa,
    );
  }

  /// فحص درجات المواد المشترطة.
  ///
  /// نفرّق بين حالتين لا يجوز خلطهما: درجة **أقل** من المطلوب، ودرجة
  /// **غير مُدخلة** أصلاً. الأولى رفض حقيقي، والثانية نقص معلومة يجب
  /// إخبار الطالب به بوضوح بدل إيهامه بأنه مرفوض.
  List<EligibilityReason> _checkSubjects(
    HighSchoolCertificate certificate,
    EffectiveRequirement requirement,
  ) {
    final reasons = <EligibilityReason>[];

    for (final subject in requirement.subjectRequirements) {
      final grade = certificate.subjectGrades[subject.subjectCode];

      if (grade == null) {
        reasons.add(
          EligibilityReason(
            code: 'subject_missing',
            required: subject.minGrade.toStringAsFixed(0),
            subjectName: subject.subjectName,
          ),
        );
        continue;
      }

      if (grade < subject.minGrade) {
        reasons.add(
          EligibilityReason(
            code: 'subject_grade',
            required: subject.minGrade.toStringAsFixed(0),
            actual: grade.toStringAsFixed(0),
            subjectName: subject.subjectName,
          ),
        );
      }
    }

    return reasons;
  }

  /// تحديد مستوى الأهلية.
  ///
  /// «قريب من الشرط» حالة خاصة ومحدودة: تُمنح فقط إذا كان **المعدل هو
  /// السبب الوحيد** وكان الفارق ضمن الهامش المسموح. أي سبب آخر يعني رفضاً
  /// كاملاً، لأن نوع الشهادة أو المسار لا يقبلان أنصاف حلول.
  EligibilityLevel _resolveLevel({
    required List<EligibilityReason> reasons,
    required bool gpaFailed,
    required double gap,
  }) {
    if (reasons.isEmpty) return EligibilityLevel.eligible;

    final onlyGpaFailed = gpaFailed && reasons.length == 1;
    final withinBorderlineMargin = gap.abs() <= MatcherWeights.borderlineGpaGap;

    if (onlyGpaFailed && withinBorderlineMargin) {
      return EligibilityLevel.borderline;
    }
    return EligibilityLevel.notEligible;
  }
}
