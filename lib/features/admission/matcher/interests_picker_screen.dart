import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/high_school_certificate.dart';
import '../models/matcher_input.dart';
import '../widgets/admission_app_bar.dart';
import 'matcher_results_screen.dart';
import 'widgets/interest_chip_grid.dart';

/// شاشة اختيار الاهتمامات — الخطوة الثانية في المساعد.
///
/// هذه هي المدخلة الوحيدة التي لا تستطيع الشهادة توفيرها: المعدل يقول ما
/// **يستطيع** الطالب دخوله، والاهتمامات تقول ما **يريد** دراسته. المساعد
/// الذي يرتّب بالمعدل وحده ليس مساعد اختيار تخصص بل قائمة عتبات.
class InterestsPickerScreen extends StatefulWidget {
  final HighSchoolCertificate certificate;

  const InterestsPickerScreen({super.key, required this.certificate});

  @override
  State<InterestsPickerScreen> createState() => _InterestsPickerScreenState();
}

class _InterestsPickerScreenState extends State<InterestsPickerScreen> {
  final Set<String> _selected = {};

  /// حدّ أعلى ستة: اختيار كل الاهتمامات يجعل كل التخصصات متطابقة، فيفقد
  /// الترتيب قدرته على التمييز بينها.
  static const int _maxSelection = 6;

  /// حدّ أدنى واحد: بلا اهتمام واحد على الأقل يصبح وزن الستين نقطة صفراً
  /// لكل التخصصات، ويتحوّل المساعد إلى فحص أهلية مكرّر.
  static const int _minSelection = 1;

  bool get _canContinue => _selected.length >= _minSelection;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < _maxSelection) {
        _selected.add(id);
      }
    });
  }

  void _continue() {
    if (!_canContinue) return;

    final input = MatcherInput(
      certificate: widget.certificate,
      interests: _selected.toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MatcherResultsScreen(input: input)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.matcher.interests_title'.tr()),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              children: [
                Text(
                  'admission.matcher.interests_hint'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                InterestChipGrid(
                  selected: _selected,
                  onToggle: _toggle,
                  maxSelection: _maxSelection,
                ),
                const SizedBox(height: 20),
                InterestCounter(
                  selectedCount: _selected.length,
                  maxSelection: _maxSelection,
                  minSelection: _minSelection,
                ),
              ],
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: FilledButton.icon(
        onPressed: _canContinue ? _continue : null,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text('admission.matcher.show_results'.tr()),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
