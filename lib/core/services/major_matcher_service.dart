import 'package:flutter/foundation.dart';

import '../../features/admission/models/admission_requirement_model.dart';
import '../../features/admission/models/department_summary.dart';
import '../../features/admission/models/effective_requirement.dart';
import '../../features/admission/models/high_school_certificate.dart';
import '../../features/admission/models/major_suggestion.dart';
import '../../features/admission/models/matcher_dataset.dart';
import '../../features/admission/models/matcher_input.dart';
import '../../features/admission/models/matcher_outcome.dart';
import 'academic_guide_service.dart';
import 'admission_service.dart';
import 'app_config_service.dart';
import 'eligibility_evaluator.dart';
import 'matcher_scoring.dart';

/// مساعد اختيار التخصص — يرتّب كل تخصصات الجامعة حسب ملاءمتها للطالب.
///
/// الخدمة مقسومة عمداً إلى نصفين:
///
///   • [loadDataset] — الجزء الوحيد الذي يلمس الشبكة. يُنفَّذ مرة واحدة.
///   • [rank] — **دالة خالصة** تستقبل بيانات جاهزة وتُعيد ترتيباً. لا تعرف
///     Firestore ولا `async` ولا الوقت الحالي إلا بتمريره صراحةً.
///
/// هذا التقسيم ليس ترفاً معمارياً، بل هو ما يجعل شيئين ممكنين:
/// اختبار الخوارزمية آلياً بلا إنترنت، وتشغيل محاكي «ماذا لو؟» عشرات
/// المرات في الثانية بصفر قراءة إضافية من قاعدة البيانات.
class MajorMatcherService {
  static final MajorMatcherService _instance = MajorMatcherService._internal();

  factory MajorMatcherService() => _instance;

  MajorMatcherService._internal();

  final EligibilityEvaluator _evaluator = EligibilityEvaluator();

  MatcherDataset? _cache;

  // ===================== الجزء المتصل بالشبكة =====================

  /// تحميل كل ما يحتاجه المطابق دفعة واحدة.
  ///
  /// القراءات الخمس تُنفَّذ **بالتوازي** لا بالتسلسل: لا يعتمد أي منها على
  /// نتيجة الآخر، فتنفيذها تسلسلياً كان سيضاعف زمن الانتظار بلا سبب.
  Future<MatcherDataset> loadDataset({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;

    try {
      // نطلق الخمسة معاً ثم ننتظرها، بدل `await` متتالية. كل واحدة مستقلة
      // عن الأخرى، فتنفيذها تسلسلياً كان سيجمع أزمنتها بلا فائدة.
      final guideService = AcademicGuideService();
      final departmentsFuture = guideService.getAllDepartments(
        forceRefresh: forceRefresh,
      );
      final guidesFuture = guideService.getAllGuides(
        forceRefresh: forceRefresh,
      );
      final collegesFuture = guideService.getColleges(
        forceRefresh: forceRefresh,
      );
      final requirementsFuture = AdmissionService().getAllRequirements(
        forceRefresh: forceRefresh,
      );
      final certificatesFuture = AppConfigService().getCertificatesConfig(
        forceRefresh: forceRefresh,
      );

      _cache = MatcherDataset.build(
        departments: await departmentsFuture,
        guides: await guidesFuture,
        requirements: await requirementsFuture,
        colleges: await collegesFuture,
        gradeBands: (await certificatesFuture).gradeBands,
      );
    } catch (e) {
      debugPrint('MajorMatcherService: failed to load dataset: $e');
      _cache = MatcherDataset.empty;
    }

    return _cache!;
  }

  /// تحميل البيانات ثم الترتيب — الواجهة التي تستدعيها الشاشات.
  Future<MatcherOutcome> suggest(
    MatcherInput input, {
    bool forceRefresh = false,
  }) async {
    final dataset = await loadDataset(forceRefresh: forceRefresh);
    return rank(input: input, dataset: dataset);
  }

  void clearCache() => _cache = null;

  // ===================== الجزء الخالص (قابل للاختبار) =====================

  /// ترتيب كل التخصصات حسب ملاءمتها — **بلا أي اتصال بالشبكة**.
  ///
  /// [referenceYear] تُمرَّر في الاختبارات لتثبيت حساب عمر الشهادة، وإلا
  /// كانت نتيجة الاختبار تتغيّر بتغيّر السنة الميلادية.
  MatcherOutcome rank({
    required MatcherInput input,
    required MatcherDataset dataset,
    int? referenceYear,
  }) {
    if (dataset.isEmpty) return MatcherOutcome.empty;

    final certificate = input.certificate;
    final preferred = input.preferredCollegeIds.toSet();
    final suggestions = <MajorSuggestion>[];
    var skipped = 0;

    for (final department in dataset.departments) {
      // تقييد بكليات مفضّلة إن اختار الطالب ذلك.
      if (preferred.isNotEmpty && !preferred.contains(department.collegeId)) {
        continue;
      }

      final requirements = dataset.requirementsByCollege[department.collegeId];
      if (requirements == null) {
        // لا شروط منشورة لهذه الكلية — لا يجوز الحكم، ولا يجوز الإخفاء
        // الصامت. نعدّها ونُبلغ عنها في الحصيلة.
        skipped++;
        continue;
      }

      suggestions.add(
        _buildSuggestion(
          department: department,
          requirements: requirements,
          dataset: dataset,
          input: input,
          certificate: certificate,
          referenceYear: referenceYear,
        ),
      );
    }

    // الترتيب تنازلياً بالنتيجة المركّبة. الأهلية داخلة فيها بوزن 25،
    // والواجهة تعرض شارة الأهلية على كل بطاقة ومرشِّحاً للمؤهَّل فقط —
    // فلا يُخفى على الطالب اقتراح قوي لمجرد أن معدله أقل بدرجتين.
    suggestions.sort((a, b) => b.score.compareTo(a.score));

    return MatcherOutcome(
      suggestions: suggestions,
      skippedForMissingRequirements: skipped,
      totalDepartments: dataset.departments.length,
    );
  }

  /// بناء اقتراح واحد: الشرط الفعلي ← حكم الأهلية ← النقاط.
  MajorSuggestion _buildSuggestion({
    required DepartmentSummary department,
    required AdmissionRequirementModel requirements,
    required MatcherDataset dataset,
    required MatcherInput input,
    required HighSchoolCertificate certificate,
    required int? referenceYear,
  }) {
    final guide = dataset.guidesByDepartment[department.id];

    final EffectiveRequirement requirement = requirements.effectiveFor(
      departmentId: department.id,
      certificateCode: certificate.type.code,
      trackCode: certificate.track.code,
    );

    final eligibility = _evaluator.evaluate(
      certificate: certificate,
      requirement: requirement,
      gradeBands: dataset.gradeBands,
      referenceYear: referenceYear,
    );

    final interest = MatcherScoring.interestScore(
      input.interests,
      guide?.interestTags ?? const [],
    );

    final breakdown = MatcherScoring.breakdown(
      interest: interest,
      eligibility: eligibility,
      certificate: certificate,
      requirement: requirement,
      guide: guide,
    );

    return MajorSuggestion(
      department: department,
      collegeName: dataset.collegeNames[department.collegeId] ?? '',
      score: breakdown.total,
      breakdown: breakdown,
      eligibility: eligibility,
      guide: guide,
      matchedInterests: interest.matched,
    );
  }

  // ===================== محاكي «ماذا لو؟» =====================

  /// إعادة الترتيب بشهادة معدَّلة، ثم مقارنتها بالحصيلة الأصلية.
  ///
  /// هذه هي الدالة التي تحوّل التطبيق من «يعرض شروطاً» إلى «أداة قرار»:
  /// لا تكتفي بإخبار الطالب أن معدله ارتفع، بل تقول له **ما الذي انفتح له
  /// بالضبط** نتيجة ذلك.
  WhatIfOutcome simulate({
    required MatcherInput input,
    required MatcherDataset dataset,
    required MatcherOutcome baseline,
    required HighSchoolCertificate modifiedCertificate,
    int? referenceYear,
  }) {
    final modified = rank(
      input: input.copyWith(certificate: modifiedCertificate),
      dataset: dataset,
      referenceYear: referenceYear,
    );

    return WhatIfOutcome.compare(before: baseline, after: modified);
  }
}
