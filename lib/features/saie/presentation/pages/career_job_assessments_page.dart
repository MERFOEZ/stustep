/// StuStep — Career Changer Assessment Page
///
/// Structured questionnaire for career changers.
/// Collects: current field, target field, years experience, reason, skills.
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

const _accent = Color(0xFF7D3C98);

const _fields = [
  'تقنية المعلومات والبرمجة',
  'الطب والصحة',
  'الهندسة',
  'التعليم والتدريب',
  'المحاسبة والمالية',
  'التسويق والمبيعات',
  'القانون',
  'الإدارة والموارد البشرية',
  'الإعلام والصحافة',
  'الزراعة',
  'العمل الإنساني والمنظمات',
  'أخرى',
];

const _experienceLevels = [
  'أقل من سنة',
  '1–3 سنوات',
  '4–7 سنوات',
  'أكثر من 7 سنوات',
];

const _reasons = [
  'الراتب غير مناسب',
  'لا يوجد تطور مهني',
  'اكتشفت شغفاً جديداً',
  'ظروف العمل صعبة',
  'الطلب على مجالي ينخفض',
  'أريد تأثيراً اجتماعياً أكبر',
  'فرصة عمل أفضل في مجال آخر',
];

const _kCareerSkillOptions = [
  'إدارة المشاريع',
  'التواصل والتفاوض',
  'تحليل البيانات',
  'البرمجة',
  'القيادة',
  'اللغة الإنجليزية',
  'التسويق الرقمي',
  'البحث والتوثيق',
  'الكتابة الإبداعية',
  'العمل الميداني',
];

class CareerChangerAssessmentPage extends ConsumerStatefulWidget {
  const CareerChangerAssessmentPage({super.key});

  @override
  ConsumerState<CareerChangerAssessmentPage> createState() =>
      _CareerChangerAssessmentPageState();
}

class _CareerChangerAssessmentPageState
    extends ConsumerState<CareerChangerAssessmentPage> {
  int _step = 0;
  bool _saving = false;

  String? _currentField;
  String? _targetField;
  String? _experience;
  String? _reason;
  final Set<String> _selectedSkills = {};

  List<_Step> get _steps => [
        _Step(
          title: 'ما مجالك الحالي أو الأخير؟',
          subtitle: 'المجال الذي تعمل فيه أو عملت فيه',
          child: _FieldGrid(
            options: _fields,
            selected: _currentField != null ? {_currentField!} : {},
            accent: _accent,
            onTap: (v) => setState(() => _currentField = v),
          ),
          isComplete: _currentField != null,
        ),
        _Step(
          title: 'ما المجال الذي تريد الانتقال إليه؟',
          subtitle: 'هدفك المهني الجديد',
          child: _FieldGrid(
            options: _fields,
            selected: _targetField != null ? {_targetField!} : {},
            accent: _accent,
            onTap: (v) => setState(() => _targetField = v),
          ),
          isComplete: _targetField != null,
        ),
        _Step(
          title: 'كم سنة خبرتك الإجمالية؟',
          subtitle: 'في أي مجال كانت',
          child: _ListOptions(
            options: _experienceLevels,
            selected: _experience,
            accent: _accent,
            onTap: (v) => setState(() => _experience = v),
          ),
          isComplete: _experience != null,
        ),
        _Step(
          title: 'ما السبب الرئيسي للتغيير؟',
          subtitle: 'كن صريحاً — هذا يساعدنا في وضع خطة مناسبة',
          child: _ListOptions(
            options: _reasons,
            selected: _reason,
            accent: _accent,
            onTap: (v) => setState(() => _reason = v),
          ),
          isComplete: _reason != null,
        ),
        _Step(
          title: 'ما المهارات التي اكتسبتها؟',
          subtitle: 'اختر حتى 4 مهارات',
          child: _MultiGrid(
            options: _kCareerSkillOptions,
            selected: Set<String>.from(_selectedSkills),
            accent: _accent,
            maxSelect: 4,
            onTap: (v) => setState(() {
              if (_selectedSkills.contains(v)) {
                _selectedSkills.remove(v);
              } else if (_selectedSkills.length < 4) {
                _selectedSkills.add(v);
              }
            }),
          ),
          isComplete: _selectedSkills.isNotEmpty,
        ),
      ];

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
      final user = await const UserService().getOrCreate();
      final assessmentId = const Uuid().v4();

      final result = AssessmentResult(
        assessmentId: assessmentId,
        userId: user.userId,
        role: UserRole.careerChanger,
        completedAt: DateTime.now(),
        data: {
          'current_field': _currentField,
          'target_field': _targetField,
          'years_experience': _experience,
          'reason': _reason,
          'skills': _selectedSkills.toList(),
        },
      );

      await const AssessmentService().save(result);
      final conv = await const ConversationService().create(
        userId: user.userId,
        assessmentId: assessmentId,
        role: UserRole.careerChanger,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) =>
              AiAdvisorPage(conversation: conv, assessment: result),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return Scaffold(
      backgroundColor: const Color(0xFF0D1620),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              total: _steps.length,
              label: 'محوّل المسار',
              accent: _accent,
              onPrev: _step > 0 ? _prev : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _steps.length,
                  minHeight: 4,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                Text(step.title,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(step.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF7FA8C9), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: step.child,
              ),
            ),
            _NextButton(
              label: _step == _steps.length - 1
                  ? 'ابدأ المحادثة مع المستشار'
                  : 'التالي',
              enabled: step.isComplete && !_saving,
              saving: _saving,
              accent: _accent,
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job Seeker Assessment Page
// ─────────────────────────────────────────────────────────────────────────────

const _jsAccent = Color(0xFFBA4A00);

const _educationLevels = [
  'ثانوية عامة',
  'دبلوم',
  'بكالوريوس',
  'ماجستير',
  'دكتوراه',
  'شهادات مهنية فقط',
];

const _jobFields = [
  'تقنية المعلومات',
  'التسويق الرقمي',
  'الإدارة والموارد البشرية',
  'المحاسبة والمالية',
  'الهندسة',
  'الصحة والطب',
  'التعليم والتدريب',
  'العمل الإنساني',
  'الإعلام والتصميم',
  'المبيعات وخدمة العملاء',
  'القانون',
  'أخرى',
];

const _searchDurations = [
  'أقل من شهر',
  '1–3 أشهر',
  '3–6 أشهر',
  'أكثر من 6 أشهر',
];

const _workTypes = [
  'حضوري داخل اليمن',
  'عمل عن بُعد (أي دولة)',
  'عمل في دول الخليج',
  'مختلط',
];

const _jsSkills = [
  'Microsoft Office',
  'اللغة الإنجليزية',
  'إدارة وسائل التواصل',
  'برمجة وتطوير',
  'تصميم جرافيك',
  'كتابة محتوى',
  'تحليل بيانات',
  'مبيعات وتفاوض',
  'خدمة عملاء',
  'إدارة مشاريع',
];

class JobSeekerAssessmentPage extends ConsumerStatefulWidget {
  const JobSeekerAssessmentPage({super.key});

  @override
  ConsumerState<JobSeekerAssessmentPage> createState() =>
      _JobSeekerAssessmentPageState();
}

class _JobSeekerAssessmentPageState
    extends ConsumerState<JobSeekerAssessmentPage> {
  int _step = 0;
  bool _saving = false;

  String? _education;
  String? _targetField;
  final Set<String> _selectedSkills = {};
  String? _searchDuration;
  String? _workType;

  List<_Step> get _steps => [
        _Step(
          title: 'ما أعلى مؤهل دراسي لديك؟',
          subtitle: '',
          child: _ListOptions(
            options: _educationLevels,
            selected: _education,
            accent: _jsAccent,
            onTap: (v) => setState(() => _education = v),
          ),
          isComplete: _education != null,
        ),
        _Step(
          title: 'في أي مجال تبحث عن عمل؟',
          subtitle: 'اختر المجال الذي تستهدفه',
          child: _FieldGrid(
            options: _jobFields,
            selected: _targetField != null ? {_targetField!} : {},
            accent: _jsAccent,
            onTap: (v) => setState(() => _targetField = v),
          ),
          isComplete: _targetField != null,
        ),
        _Step(
          title: 'ما مهاراتك الأساسية؟',
          subtitle: 'اختر حتى 4 مهارات',
          child: _MultiGrid(
            options: _jsSkills,
            selected: Set<String>.from(_selectedSkills),
            accent: _jsAccent,
            maxSelect: 4,
            onTap: (v) => setState(() {
              if (_selectedSkills.contains(v)) {
                _selectedSkills.remove(v);
              } else if (_selectedSkills.length < 4) {
                _selectedSkills.add(v);
              }
            }),
          ),
          isComplete: _selectedSkills.isNotEmpty,
        ),
        _Step(
          title: 'كم مدة بحثك عن عمل؟',
          subtitle: '',
          child: _ListOptions(
            options: _searchDurations,
            selected: _searchDuration,
            accent: _jsAccent,
            onTap: (v) => setState(() => _searchDuration = v),
          ),
          isComplete: _searchDuration != null,
        ),
        _Step(
          title: 'ما نوع العمل الذي تفضله؟',
          subtitle: '',
          child: _ListOptions(
            options: _workTypes,
            selected: _workType,
            accent: _jsAccent,
            onTap: (v) => setState(() => _workType = v),
          ),
          isComplete: _workType != null,
        ),
      ];

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
      final user = await const UserService().getOrCreate();
      final assessmentId = const Uuid().v4();

      final result = AssessmentResult(
        assessmentId: assessmentId,
        userId: user.userId,
        role: UserRole.jobSeeker,
        completedAt: DateTime.now(),
        data: {
          'education': _education,
          'target_field': _targetField,
          'skills': _selectedSkills.toList(),
          'search_duration': _searchDuration,
          'work_type': _workType,
        },
      );

      await const AssessmentService().save(result);
      final conv = await const ConversationService().create(
        userId: user.userId,
        assessmentId: assessmentId,
        role: UserRole.jobSeeker,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) =>
              AiAdvisorPage(conversation: conv, assessment: result),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return Scaffold(
      backgroundColor: const Color(0xFF0D1620),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              total: _steps.length,
              label: 'باحث عن عمل',
              accent: _jsAccent,
              onPrev: _step > 0 ? _prev : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _steps.length,
                  minHeight: 4,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation<Color>(_jsAccent),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                Text(step.title,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4)),
                if (step.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(step.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF7FA8C9), fontSize: 13)),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: step.child,
              ),
            ),
            _NextButton(
              label: _step == _steps.length - 1
                  ? 'ابدأ المحادثة مع المستشار'
                  : 'التالي',
              enabled: step.isComplete && !_saving,
              saving: _saving,
              accent: _jsAccent,
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers (used by both pages above)
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

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.total,
    required this.label,
    required this.accent,
    this.onPrev,
  });
  final int step;
  final int total;
  final String label;
  final Color accent;
  final VoidCallback? onPrev;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          if (onPrev != null)
            GestureDetector(
              onTap: onPrev,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withAlpha(60)),
            ),
            child: Text(
              '$label • ${step + 1}/$total',
              style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.enabled,
    required this.saving,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final bool enabled;
  final bool saving;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: Colors.white.withAlpha(15),
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ListOptions extends StatelessWidget {
  const _ListOptions({
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
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color:
                    sel ? accent.withAlpha(35) : const Color(0xFF111E2B),
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
                          color:
                              sel ? accent : Colors.white.withAlpha(50),
                          width: 2),
                      color: sel ? accent : Colors.transparent,
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 13)
                        : null,
                  ),
                  const Spacer(),
                  Text(o,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: sel
                            ? Colors.white
                            : const Color(0xFFB0C4D8),
                        fontSize: 15,
                        fontWeight: sel
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  sel ? accent.withAlpha(35) : const Color(0xFF111E2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? accent : Colors.white.withAlpha(20),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Text(o,
                style: TextStyle(
                  color: sel ? accent : const Color(0xFFB0C4D8),
                  fontSize: 13.5,
                  fontWeight:
                      sel ? FontWeight.bold : FontWeight.normal,
                )),
          ),
        );
      }).toList(),
    );
  }
}

class _MultiGrid extends StatelessWidget {
  const _MultiGrid({
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
        Text('تم الاختيار: ${selected.length}/$maxSelect',
            style: TextStyle(color: accent, fontSize: 12)),
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
                child: Text(o,
                    style: TextStyle(
                      color: sel
                          ? accent
                          : disabled
                              ? Colors.white.withAlpha(40)
                              : const Color(0xFFB0C4D8),
                      fontSize: 13.5,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
