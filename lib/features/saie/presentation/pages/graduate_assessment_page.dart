/// StuStep — Graduate Assessment Page
///
/// Structured questionnaire for graduates.
/// Collects: major, experience, target field, skills, barrier.
/// On completion → saves AssessmentResult → creates Conversation → AI Chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stustep/features/saie_core/models/assessment_result.dart';
import 'package:stustep/features/saie_core/models/user_role.dart';
import 'package:stustep/features/saie_core/services/assessment_service.dart';
import 'package:stustep/features/saie_core/services/conversation_service.dart';
import 'package:stustep/features/saie_core/services/user_service.dart';
import 'package:stustep/features/saie/presentation/pages/ai_advisor_page.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data helpers
// ─────────────────────────────────────────────────────────────────────────────

const _majors = [
  'هندسة', 'طب', 'صيدلة', 'قانون', 'اقتصاد وإدارة أعمال',
  'علوم حاسوب وتقنية معلومات', 'محاسبة', 'تربية وتعليم',
  'إعلام وعلاقات عامة', 'هندسة معمارية', 'زراعة', 'أخرى',
];

const _experienceLevels = [
  'بدون خبرة',
  'أقل من سنة',
  '1–2 سنة',
  '3–5 سنوات',
  'أكثر من 5 سنوات',
];

const _targetFields = [
  'قطاع حكومي',
  'قطاع خاص',
  'منظمات دولية وإنسانية',
  'ريادة أعمال / مشروع خاص',
  'عمل عن بُعد / فريلانس',
  'دراسات عليا',
];

const _kSkillOptions = [
  'مهارات تقنية وبرمجة',
  'إدارة المشاريع',
  'التواصل والعرض',
  'اللغة الإنجليزية',
  'التحليل والبيانات',
  'المحاسبة والمالية',
  'التسويق الرقمي',
  'التصميم الجرافيكي',
  'القيادة وإدارة الفرق',
  'البحث الأكاديمي',
];

const _barriers = [
  'لا توجد فرص مناسبة في تخصصي',
  'أفتقر لخبرة عملية',
  'لا أعرف كيف أبدأ',
  'شبكة علاقات محدودة',
  'أحتاج مهارات إضافية',
  'أبحث عن عمل خارج اليمن',
];

// ─────────────────────────────────────────────────────────────────────────────
// GraduateAssessmentPage
// ─────────────────────────────────────────────────────────────────────────────

class GraduateAssessmentPage extends ConsumerStatefulWidget {
  const GraduateAssessmentPage({super.key});

  @override
  ConsumerState<GraduateAssessmentPage> createState() =>
      _GraduateAssessmentPageState();
}

class _GraduateAssessmentPageState
    extends ConsumerState<GraduateAssessmentPage> {
  int _step = 0;
  bool _saving = false;

  String? _major;
  String? _experience;
  String? _targetField;
  final Set<String> _selectedSkills = {};
  String? _barrier;

  static const _accent = Color(0xFF27AE60);

  // ── Steps ──────────────────────────────────────────────────────────────────

  List<_Step> get _steps => [
        _Step(
          title: 'ما تخصصك الجامعي؟',
          subtitle: 'اختر أقرب تخصص لما درسته',
          child: _OptionGrid(
            options: _majors,
            selected: _major != null ? {_major!} : {},
            accent: _accent,
            onTap: (v) => setState(() => _major = v),
          ),
          isComplete: _major != null,
        ),
        _Step(
          title: 'ما مستوى خبرتك العملية؟',
          subtitle: 'بعد التخرج',
          child: _OptionList(
            options: _experienceLevels,
            selected: _experience,
            accent: _accent,
            onTap: (v) => setState(() => _experience = v),
          ),
          isComplete: _experience != null,
        ),
        _Step(
          title: 'ما المجال الذي تستهدفه؟',
          subtitle: 'أين تريد العمل؟',
          child: _OptionList(
            options: _targetFields,
            selected: _targetField,
            accent: _accent,
            onTap: (v) => setState(() => _targetField = v),
          ),
          isComplete: _targetField != null,
        ),
        _Step(
          title: 'ما أبرز مهاراتك؟',
          subtitle: 'اختر حتى 3 مهارات',
          child: _MultiOptionGrid(
            options: _kSkillOptions,
            selected: Set<String>.from(_selectedSkills),
            accent: _accent,
            maxSelect: 3,
            onTap: (v) => setState(() {
              if (_selectedSkills.contains(v)) {
                _selectedSkills.remove(v);
              } else if (_selectedSkills.length < 3) {
                _selectedSkills.add(v);
              }
            }),
          ),
          isComplete: _selectedSkills.isNotEmpty,
        ),
        _Step(
          title: 'ما أكبر عائق تواجهه؟',
          subtitle: 'كن صريحاً — هذا يساعدنا في توجيهك',
          child: _OptionList(
            options: _barriers,
            selected: _barrier,
            accent: _accent,
            onTap: (v) => setState(() => _barrier = v),
          ),
          isComplete: _barrier != null,
        ),
      ];

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final userSvc = const UserService();
      final assessSvc = const AssessmentService();
      final convSvc = const ConversationService();

      final user = await userSvc.getOrCreate();
      final assessmentId = const Uuid().v4();

      final result = AssessmentResult(
        assessmentId: assessmentId,
        userId: user.userId,
        role: UserRole.graduate,
        completedAt: DateTime.now(),
        data: {
          'major': _major,
          'experience_years': _experience,
          'target_field': _targetField,
          'skills': _selectedSkills.toList(),
          'barrier': _barrier,
        },
      );

      await assessSvc.save(result);

      final conv = await convSvc.create(
        userId: user.userId,
        assessmentId: assessmentId,
        role: UserRole.graduate,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => AiAdvisorPage(
            conversation: conv,
            assessment: result,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final progress = (_step + 1) / _steps.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1620),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    GestureDetector(
                      onTap: _prev,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('السابق',
                            style: TextStyle(
                                color: Color(0xFF7FA8C9), fontSize: 13)),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent.withAlpha(60)),
                    ),
                    child: Text(
                      'للخريجين • ${_step + 1}/${_steps.length}',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Question
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF7FA8C9), fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: step.child,
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: FilledButton(
                onPressed: (step.isComplete && !_saving) ? _next : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: Colors.white.withAlpha(15),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _step == _steps.length - 1
                            ? 'ابدأ المحادثة مع المستشار'
                            : 'التالي',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step model
// ─────────────────────────────────────────────────────────────────────────────

class _Step {
  const _Step({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isComplete,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final bool isComplete;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared option widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.options,
    required this.selected,
    required this.accent,
    required this.onTap,
  });
  final List<String> options;
  final String? selected;
  final Color accent;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((o) {
        final sel = o == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onTap(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: sel ? accent.withAlpha(35) : const Color(0xFF111E2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? accent : Colors.white.withAlpha(20),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel ? accent : Colors.white.withAlpha(50),
                          width: 2),
                      color: sel ? accent : Colors.transparent,
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 13)
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    o,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: sel ? Colors.white : const Color(0xFFB0C4D8),
                      fontSize: 15,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.accent,
    required this.onTap,
  });
  final List<String> options;
  final Set<String> selected;
  final Color accent;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        final sel = selected.contains(o);
        return GestureDetector(
          onTap: () => onTap(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? accent.withAlpha(35) : const Color(0xFF111E2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? accent : Colors.white.withAlpha(20),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Text(
              o,
              style: TextStyle(
                color: sel ? accent : const Color(0xFFB0C4D8),
                fontSize: 13.5,
                fontWeight:
                    sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MultiOptionGrid extends StatelessWidget {
  const _MultiOptionGrid({
    required this.options,
    required this.selected,
    required this.accent,
    required this.maxSelect,
    required this.onTap,
  });
  final List<String> options;
  final Set<String> selected;
  final Color accent;
  final int maxSelect;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'تم الاختيار: ${selected.length}/$maxSelect',
          style: TextStyle(color: accent, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: options.map((o) {
            final sel = selected.contains(o);
            final disabled = !sel && selected.length >= maxSelect;
            return GestureDetector(
              onTap: disabled ? null : () => onTap(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? accent.withAlpha(35)
                      : disabled
                          ? const Color(0xFF0D1620)
                          : const Color(0xFF111E2B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? accent
                        : Colors.white.withAlpha(disabled ? 8 : 20),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  o,
                  style: TextStyle(
                    color: sel
                        ? accent
                        : disabled
                            ? Colors.white.withAlpha(40)
                            : const Color(0xFFB0C4D8),
                    fontSize: 13.5,
                    fontWeight:
                        sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
