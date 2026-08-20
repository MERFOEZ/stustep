import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/major_matcher_service.dart';
import '../../../core/services/matcher_result_service.dart';
import '../guide/department_guide_screen.dart';
import '../guide/widgets/guide_visuals.dart';
import '../models/major_suggestion.dart';
import '../models/matcher_dataset.dart';
import '../models/matcher_input.dart';
import '../models/matcher_outcome.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'what_if_screen.dart';
import 'widgets/matcher_summary_bar.dart';
import 'widgets/suggestion_card.dart';

/// شاشة نتائج مساعد اختيار التخصص.
///
/// تعرض كل التخصصات مرتّبة تنازلياً بالنتيجة المركّبة، لا المؤهَّل منها فقط.
/// قرار مقصود: إخفاء التخصص غير المؤهَّل يحرم الطالب من معرفة أن أقرب
/// أحلامه إليه يبعد ثلاث درجات فقط — وهي المعلومة التي يبني عليها قراره.
/// المرشِّح في الأعلى يترك له الخيار، والشارة الملوّنة تمنع الالتباس.
class MatcherResultsScreen extends StatefulWidget {
  final MatcherInput input;

  const MatcherResultsScreen({super.key, required this.input});

  @override
  State<MatcherResultsScreen> createState() => _MatcherResultsScreenState();
}

/// ما تحتاجه الشاشة من تشغيل واحد: الحصيلة والبيانات التي أنتجتها.
///
/// نحتفظ بالبيانات لا بالحصيلة وحدها، لأن محاكي «ماذا لو؟» يعيد الترتيب
/// عليها مباشرة في الذاكرة بلا أي قراءة جديدة من Firestore.
class _ResultsBundle {
  final MatcherOutcome outcome;
  final MatcherDataset dataset;

  const _ResultsBundle(this.outcome, this.dataset);
}

class _MatcherResultsScreenState extends State<MatcherResultsScreen> {
  late Future<_ResultsBundle> _future;

  /// عرض المؤهَّل فقط — مطفأ افتراضياً حتى يرى الطالب الصورة كاملة أولاً.
  bool _eligibleOnly = false;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _future = _run();
  }

  Future<_ResultsBundle> _run() async {
    final service = MajorMatcherService();
    final dataset = await service.loadDataset();
    final outcome = service.rank(input: widget.input, dataset: dataset);
    return _ResultsBundle(outcome, dataset);
  }

  void _retry() => setState(() => _future = _run());

  /// حفظ الحصيلة في `users/{uid}/matcher_results`.
  ///
  /// الحفظ ميزة لا شرط: الزائر غير المسجَّل يستخدم المساعد كاملاً، وتفشل
  /// عملية الحفظ وحدها بصمت مع إبلاغه برسالة واضحة.
  Future<void> _save(MatcherOutcome outcome) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await MatcherResultService().save(
      input: widget.input,
      outcome: outcome,
    );

    if (!mounted) return;
    setState(() => _saved = success);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'admission.matcher.saved'.tr()
              : 'admission.matcher.save_failed'.tr(),
        ),
      ),
    );
  }

  void _openGuide(MajorSuggestion suggestion, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepartmentGuideScreen(
          department: suggestion.department,
          collegeName: suggestion.collegeName,
          gradient: GuideVisuals.gradientAt(index),
        ),
      ),
    );
  }

  void _openWhatIf(_ResultsBundle bundle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhatIfScreen(
          input: widget.input,
          dataset: bundle.dataset,
          baseline: bundle.outcome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.matcher.results_title'.tr()),
      body: FutureBuilder<_ResultsBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdmissionLoadingState(
              message: 'admission.matcher.calculating'.tr(),
            );
          }
          if (snapshot.hasError) {
            return AdmissionErrorState(onRetry: _retry);
          }

          final bundle = snapshot.data;
          if (bundle == null || bundle.outcome.isEmpty) {
            return AdmissionEmptyState(
              icon: Icons.psychology_outlined,
              message: 'admission.matcher.no_results'.tr(),
            );
          }

          return _buildResults(context, bundle);
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context, _ResultsBundle bundle) {
    final outcome = bundle.outcome;
    final visible = _eligibleOnly
        ? outcome.suggestions
              .where((item) => item.eligibility.isEligible)
              .toList()
        : outcome.suggestions;

    return Column(
      children: [
        MatcherSummaryBar(
          outcome: outcome,
          eligibleOnly: _eligibleOnly,
          onEligibleOnlyChanged: (value) =>
              setState(() => _eligibleOnly = value),
        ),
        Expanded(
          child: visible.isEmpty
              ? AdmissionEmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  message: 'admission.matcher.no_eligible'.tr(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final suggestion = visible[index];
                    return SuggestionCard(
                      suggestion: suggestion,
                      rank: index + 1,
                      onOpenGuide: () => _openGuide(suggestion, index),
                    );
                  },
                ),
        ),
        _buildBottomBar(context, bundle),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, _ResultsBundle bundle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: () => _openWhatIf(bundle),
              icon: const Icon(Icons.tune_rounded, size: 19),
              label: Text(
                'admission.matcher.what_if'.tr(),
                style: const TextStyle(fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _saved ? null : () => _save(bundle.outcome),
              icon: Icon(
                _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                size: 18,
              ),
              label: Text(
                _saved
                    ? 'admission.matcher.saved_short'.tr()
                    : 'admission.matcher.save'.tr(),
                style: const TextStyle(fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
