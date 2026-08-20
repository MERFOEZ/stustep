import 'admission_enums.dart';

/// سبب واحد لعدم استيفاء شرط من شروط القبول.
///
/// نحتفظ بالسبب كرمز + قيم، لا كنص جاهز، حتى يُعرض بلغة المستخدم الحالية
/// ويبقى قابلاً للاختبار بلا اعتماد على الترجمة.
class EligibilityReason {
  /// رمز السبب: `certificate_type` · `track` · `gpa` · `certificate_age`
  /// · `equivalency` · `subject_grade`
  final String code;

  /// القيمة المطلوبة (مثل الحد الأدنى للمعدل).
  final String? required;

  /// القيمة الفعلية لدى الطالب.
  final String? actual;

  /// اسم المادة عند كون السبب متعلقاً بدرجة مادة.
  final String? subjectName;

  const EligibilityReason({
    required this.code,
    this.required,
    this.actual,
    this.subjectName,
  });

  String get labelKey => 'admission.reason.$code';
}

/// نتيجة التحقق من أهلية شهادة الطالب لكلية أو قسم.
///
/// المبدأ: لا يوجد رفض مبهم أبداً — كل رفض يحمل أسبابه المحددة.
class CertificateEligibility {
  final EligibilityLevel level;

  /// أسباب عدم الاستيفاء — فارغة عند الأهلية الكاملة.
  final List<EligibilityReason> failedReasons;

  /// الفارق بين معدل الطالب والحد الأدنى المطلوب.
  /// قيمة سالبة تعني أن الطالب أقل من الحد.
  final double gapToMinGpa;

  /// معدل الطالب بعد التطبيع إلى نسبة مئوية.
  final double normalizedGpa;

  /// الحد الأدنى المطلوب فعلياً بعد تطبيق الاستثناءات.
  final double requiredGpa;

  const CertificateEligibility({
    required this.level,
    this.failedReasons = const [],
    this.gapToMinGpa = 0,
    this.normalizedGpa = 0,
    this.requiredGpa = 0,
  });

  bool get isEligible => level == EligibilityLevel.eligible;

  bool get isBorderline => level == EligibilityLevel.borderline;

  Map<String, dynamic> toMap() {
    return {
      'level': level.code,
      'gapToMinGpa': gapToMinGpa,
      'normalizedGpa': normalizedGpa,
      'requiredGpa': requiredGpa,
      'failedReasons': failedReasons.map((reason) => reason.code).toList(),
    };
  }
}
