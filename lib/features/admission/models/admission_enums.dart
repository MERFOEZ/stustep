/// تعدادات موديول القبول الجامعي.
///
/// قاعدة إلزامية: كل تعداد يُخزَّن في Firestore **كنص إنجليزي ثابت** (`code`)
/// وليس كرقم (`index`). سبب ذلك أن الفهرس الرقمي يتغيّر عند إضافة قيمة جديدة
/// في منتصف التعداد، فتتلف كل البيانات المخزَّنة مسبقاً.
///
/// كل تعداد يوفّر:
///   • `code`      → القيمة المخزَّنة في Firestore
///   • `labelKey`  → مفتاح الترجمة للعرض (لا نخزّن نصاً مترجماً أبداً)
///   • `fromCode`  → تحويل آمن مع قيمة افتراضية عند وصول قيمة غير معروفة
library;

/// نوع شهادة الثانوية.
enum CertificateType {
  yemeniGeneral('yemeni_general'),
  azhari('azhari'),
  technicalDiploma('technical_diploma'),
  foreignEquivalent('foreign_equivalent');

  const CertificateType(this.code);

  final String code;

  String get labelKey => 'admission.certificate_type.$code';

  /// الشهادات الأجنبية وحدها تحتاج معادلة من وزارة التربية.
  bool get needsEquivalency => this == CertificateType.foreignEquivalent;

  static CertificateType fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => CertificateType.yemeniGeneral,
  );
}

/// المسار الدراسي داخل الشهادة.
enum HighSchoolTrack {
  scientific('scientific'),
  literary('literary'),
  commercial('commercial'),
  technical('technical');

  const HighSchoolTrack(this.code);

  final String code;

  String get labelKey => 'admission.track.$code';

  static HighSchoolTrack fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => HighSchoolTrack.scientific,
  );
}

/// سلّم الدرجات المستخدم في الشهادة.
///
/// التعداد يملك عملية التحويل الخاصة به للسلالم الرقمية،
/// أما سلّم التقديرات فيحتاج جدول تحويل خارجياً يوفّره `CertificateService`.
enum GpaScale {
  percentage('percentage', 100),
  gpa4('gpa4', 4),
  gpa5('gpa5', 5),
  grade('grade', null);

  const GpaScale(this.code, this.maxValue);

  final String code;

  /// أعلى قيمة ممكنة في هذا السلّم — `null` لسلّم التقديرات غير الرقمي.
  final num? maxValue;

  String get labelKey => 'admission.gpa_scale.$code';

  bool get isNumeric => maxValue != null;

  /// تحويل قيمة من هذا السلّم إلى نسبة مئوية موحّدة (0 – 100).
  ///
  /// يُعيد `null` لسلّم التقديرات لأنه يحتاج جدول تحويل من الإعدادات.
  double? toPercentage(double value) {
    final max = maxValue;
    if (max == null) return null;
    if (value <= 0) return 0;
    final normalized = (value / max) * 100;
    return normalized > 100 ? 100 : normalized;
  }

  static GpaScale fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => GpaScale.percentage,
  );
}

/// مستوى أهلية الطالب للقبول في كلية أو قسم.
enum EligibilityLevel {
  eligible('eligible'),
  borderline('borderline'),
  notEligible('not_eligible');

  const EligibilityLevel(this.code);

  final String code;

  String get labelKey => 'admission.eligibility.$code';

  static EligibilityLevel fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => EligibilityLevel.notEligible,
  );
}

/// حالة توفّر السكن.
enum HousingStatus {
  available('available'),
  full('full');

  const HousingStatus(this.code);

  final String code;

  String get labelKey => 'admission.housing_status.$code';

  static HousingStatus fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => HousingStatus.available,
  );
}

/// الفئة المستهدفة بالسكن.
enum HousingGender {
  male('male'),
  female('female'),
  family('family');

  const HousingGender(this.code);

  final String code;

  String get labelKey => 'admission.housing_gender.$code';

  static HousingGender fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => HousingGender.male,
  );
}

/// نوع نموذج الاختبار.
enum ExamPaperType {
  midterm('midterm'),
  finalExam('final'),
  quiz('quiz'),
  model('model');

  const ExamPaperType(this.code);

  final String code;

  String get labelKey => 'admission.paper_type.$code';

  static ExamPaperType fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => ExamPaperType.model,
  );
}

/// حالة مراجعة المحتوى الذي يضيفه المستخدمون (السكنات والنماذج).
///
/// الحقل موجود منذ الآن حتى يمكن تفعيل المراجعة لاحقاً من قواعد الأمان
/// دون أي ترحيل للبيانات.
enum ModerationStatus {
  published('published'),
  pending('pending'),
  rejected('rejected');

  const ModerationStatus(this.code);

  final String code;

  String get labelKey => 'admission.moderation.$code';

  static ModerationStatus fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => ModerationStatus.published,
  );
}
