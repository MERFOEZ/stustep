import '../../features/admission/models/admission_enums.dart';
import '../../features/admission/models/high_school_certificate.dart';

/// خدمة التعامل مع شهادة الثانوية.
///
/// خدمة **منطق خالص بلا أي اتصال بـ Firestore أو الشبكة**، وهذا مقصود:
/// تطبيع المعدلات هو أكثر جزء يستحق اختبار وحدة في الموديول، وعزله عن
/// طبقة البيانات يجعله قابلاً للاختبار مباشرة في المرحلة 8.
class CertificateService {
  static final CertificateService _instance = CertificateService._internal();

  factory CertificateService() => _instance;

  CertificateService._internal();

  /// جدول تحويل التقديرات الافتراضي.
  ///
  /// في سلّم التقديرات (`GpaScale.grade`) تحمل قيمة `gpa` **رقم الفئة**:
  /// 1 = ممتاز · 2 = جيد جداً · 3 = جيد · 4 = مقبول.
  /// هذا الجدول يمكن تجاوزه بقيم من `app_config/certificates`.
  static const Map<int, double> defaultGradeBands = {
    1: 95,
    2: 85,
    3: 75,
    4: 65,
  };

  /// تحويل معدل الشهادة إلى نسبة مئوية موحّدة (0 – 100).
  ///
  /// السلالم الرقمية يحوّلها التعداد نفسه، وسلّم التقديرات يحتاج جدولاً
  /// خارجياً لأنه غير رياضي.
  double normalize(
    HighSchoolCertificate certificate, {
    Map<int, double>? gradeBands,
  }) {
    final direct = certificate.normalizedPercentage;
    if (direct != null) return direct;

    final bands = (gradeBands == null || gradeBands.isEmpty)
        ? defaultGradeBands
        : gradeBands;
    final band = certificate.gpa.round();
    return bands[band] ?? 0;
  }

  /// تحويل قيمة مفردة دون الحاجة لبناء كائن شهادة كامل.
  double normalizeValue(
    double value,
    GpaScale scale, {
    Map<int, double>? gradeBands,
  }) {
    final direct = scale.toPercentage(value);
    if (direct != null) return direct;

    final bands = (gradeBands == null || gradeBands.isEmpty)
        ? defaultGradeBands
        : gradeBands;
    return bands[value.round()] ?? 0;
  }

  /// هل الشهادة ما زالت ضمن مدة الصلاحية التي تشترطها الكلية؟
  ///
  /// `maxAgeYears` بقيمة `null` يعني عدم وجود قيد زمني.
  bool isWithinAllowedAge(
    HighSchoolCertificate certificate,
    int? maxAgeYears, {
    int? referenceYear,
  }) {
    if (maxAgeYears == null) return true;
    final year = referenceYear ?? DateTime.now().year;
    final age = certificate.ageInYears(year);
    if (age < 0) return false;
    return age <= maxAgeYears;
  }

  /// هل المعادلة متوفرة متى كانت مشترطة؟
  bool satisfiesEquivalency(
    HighSchoolCertificate certificate,
    bool requiresEquivalency,
  ) {
    if (!requiresEquivalency) return true;
    if (!certificate.type.needsEquivalency) return true;
    return certificate.hasEquivalency;
  }

  /// التحقق من صحة قيمة المعدل ضمن حدود سلّمها.
  bool isGpaValueValid(double value, GpaScale scale) {
    if (value <= 0) return false;
    final max = scale.maxValue;
    if (max == null) return value >= 1 && value <= 4;
    return value <= max;
  }

  /// السنوات المتاحة للاختيار في واجهة إدخال الشهادة.
  List<int> availableGraduationYears({int span = 15, int? referenceYear}) {
    final current = referenceYear ?? DateTime.now().year;
    return List<int>.generate(span, (index) => current - index);
  }
}
