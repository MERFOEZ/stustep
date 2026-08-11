import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/major_matcher_service.dart';
import '../models/high_school_certificate.dart';
import '../models/matcher_dataset.dart';
import '../models/matcher_input.dart';
import '../models/matcher_outcome.dart';
import '../models/subject_catalog.dart';
import '../widgets/admission_app_bar.dart';
import 'widgets/what_if_sliders.dart';

/// محاكي «ماذا لو؟» — إعادة حساب الفرص لحظياً على شهادة افتراضية.
///
/// **لماذا هذه الشاشة هي أهم ما في الموديول؟**
///
/// المراحل السابقة تجيب سؤال «هل أنا مقبول؟» — وهو سؤال ماضٍ لا يملك
/// الطالب تغيير جوابه. هذه الشاشة تجيب سؤالاً مختلفاً تماماً: **«ماذا
/// أفعل؟»** — وهو السؤال الوحيد الذي يقود إلى فعل. الطالب يحرّك معدله
/// درجتين فيرى بالاسم أي التخصصات تنفتح له، فيعرف بالضبط ما يستحق جهده.
///
/// **لماذا الحساب فوري بلا انتظار؟**
/// لأن كل البيانات محمّلة في [MatcherDataset] من الشاشة السابقة، وخوارزمية
/// الترتيب دالة خالصة تعمل في الذاكرة. كل حركة إصبع تُعيد تقييم خمسة عشر
/// تخصصاً بصفر قراءة من Firestore وصفر طلب شبكة.
class WhatIfScreen extends StatefulWidget {
  final MatcherInput input;
  final MatcherDataset dataset;

  /// حصيلة الوضع الحالي — المرجع الذي تُقارَن به كل السيناريوهات.
  final MatcherOutcome baseline;

  const WhatIfScreen({
    super.key,
    required this.input,
    required this.dataset,
    required this.baseline,
  });

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  late double _gpa;
  late Map<String, double> _subjectGrades;

  WhatIfOutcome _outcome = WhatIfOutcome.unchanged;

  HighSchoolCertificate get _original => widget.input.certificate;

  @override
  void initState() {
    super.initState();
    _resetValues();
    _recalculate();
  }

  void _resetValues() {
    _gpa = _original.gpa;
    _subjectGrades = Map<String, double>.from(_original.subjectGrades);
  }

  /// الحد الأعلى لشريط المعدل حسب سلّم الشهادة.
  ///
  /// سلّم التقديرات (`grade`) لا يملك `maxValue` لأنه غير رياضي، وقيمه
  /// فئات من 1 إلى 4 — فنستخدم 4 حداً أعلى له تحديداً.
  double get _gpaMax => (_original.gpaScale.maxValue ?? 4).toDouble();

  double get _gpaMin => _original.gpaScale.maxValue == null ? 1 : 0;

  /// الشهادة الافتراضية المبنية من قيم الأشرطة الحالية.
  HighSchoolCertificate get _simulatedCertificate =>
      _original.copyWith(gpa: _gpa, subjectGrades: _subjectGrades);

  /// إعادة الحساب — تُستدعى عند كل حركة شريط.
  ///
  /// بلا تأخير (debounce) عمداً: عدد التخصصات بالعشرات لا بالآلاف، وتكلفة
  /// إعادة الترتيب في الذاكرة أقل من تكلفة إطار عرض واحد. إضافة تأخير هنا
  /// كانت ستُفقد المحاكي إحساسه الفوري بلا مكسب في الأداء.
  void _recalculate() {
    final outcome = MajorMatcherService().simulate(
      input: widget.input,
      dataset: widget.dataset,
      baseline: widget.baseline,
      modifiedCertificate: _simulatedCertificate,
    );
    setState(() => _outcome = outcome);
  }

  void _onGpaChanged(double value) {
    _gpa = value;
    _recalculate();
  }

  void _onSubjectChanged(String code, double value) {
    _subjectGrades = {..._subjectGrades, code: value};
    _recalculate();
  }

  void _reset() {
    _resetValues();
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(
        title: 'admission.matcher.what_if'.tr(),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'admission.matcher.whatif_reset'.tr(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _buildIntro(context),
          const SizedBox(height: 18),
          WhatIfSummary(outcome: _outcome),
          const SizedBox(height: 20),
          _buildControls(context),
          const SizedBox(height: 22),
          WhatIfImpactList(items: _outcome.unlocked, isGain: true),
          WhatIfImpactList(items: _outcome.lost, isGain: false),
          if (!_outcome.hasChange) _buildNoChangeHint(context),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 19,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'admission.matcher.whatif_intro'.tr(),
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WhatIfSlider(
            label: 'admission.certificate.gpa'.tr(),
            icon: Icons.grade_rounded,
            value: _gpa,
            originalValue: _original.gpa,
            min: _gpaMin,
            max: _gpaMax,
            onChanged: _onGpaChanged,
            fractionDigits: 1,
          ),
          ..._buildSubjectSliders(),
        ],
      ),
    );
  }

  /// أشرطة المواد — **للمواد التي أدخل الطالب درجتها فقط**.
  ///
  /// قرار دقيق: محرّك الأهلية يفرّق بين «درجة أقل من المطلوب» و«درجة غير
  /// مُدخلة». لو عرضنا شريطاً لمادة لم يُدخلها الطالب، لكان تحريكه من صفر
  /// يعني ضمناً أنه أدخلها بدرجة صفر — فيتحوّل سبب رفض من «معلومة ناقصة»
  /// إلى «درجة راسبة»، وهما حالتان مختلفتان تماماً في تفسير النتيجة.
  List<Widget> _buildSubjectSliders() {
    final entered = SubjectCatalog.all
        .where((subject) => _original.subjectGrades.containsKey(subject.code))
        .toList();

    if (entered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            'admission.matcher.whatif_no_subjects'.tr(),
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ];
    }

    return entered.map((subject) {
      return WhatIfSlider(
        label: subject.labelKey.tr(),
        icon: subject.icon,
        value: _subjectGrades[subject.code] ?? 0,
        originalValue: _original.subjectGrades[subject.code] ?? 0,
        min: 0,
        max: 100,
        onChanged: (value) => _onSubjectChanged(subject.code, value),
        fractionDigits: 0,
      );
    }).toList();
  }

  Widget _buildNoChangeHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'admission.matcher.whatif_no_change'.tr(),
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
