/// SPEA – RIASEC (Holland) Assessment Page
///
/// Presents 36 behavioural-interest questions (6 per Holland type).
/// Scoring: أوافق بشدة=5 / أوافق=4 / محايد=3 / لا أوافق=2 / لا أوافق بشدة=1
/// After submission → results screen → seeds AiAdvisorPage with RIASEC context.
library;

import 'dart:math';

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
// RIASEC Type definitions
// ─────────────────────────────────────────────────────────────────────────────

enum _Type {
  R(
    code: 'R',
    nameAr: 'واقعي',
    fullNameAr: 'Realistic',
    descAr:
        'تفضّل العمل مع الأدوات والآلات والأشياء الملموسة. تميل للأنشطة العملية وتستمتع ببناء وإصلاح الأشياء. تُجيد التعامل مع المعدات التقنية وتفضّل النتائج الملموسة.',
    tags: ['عملي', 'يدوي', 'تقني', 'ميكانيكي'],
    color: Color(0xFFE74C3C),
  ),
  I(
    code: 'I',
    nameAr: 'بحثي',
    fullNameAr: 'Investigative',
    descAr:
        'تستمتع بالتفكير والتحليل والبحث العلمي. تحب حل المشكلات المعقدة واستكشاف الأفكار الجديدة. تتميّز بالفضول الفكري والقدرة على الملاحظة الدقيقة والاستنتاج المنطقي.',
    tags: ['تحليلي', 'فضولي', 'علمي', 'منطقي'],
    color: Color(0xFF8E44AD),
  ),
  A(
    code: 'A',
    nameAr: 'فني',
    fullNameAr: 'Artistic',
    descAr:
        'تميل للإبداع والتعبير الفني. تستمتع بالأنشطة التي تتطلب خيالاً وابتكاراً وذوقاً جمالياً. تبحث عن الحرية في التعبير وتكره الروتين والقيود.',
    tags: ['مبدع', 'خيالي', 'مبتكر', 'تعبيري'],
    color: Color(0xFFE67E22),
  ),
  S(
    code: 'S',
    nameAr: 'اجتماعي',
    fullNameAr: 'Social',
    descAr:
        'تفضّل العمل مع الناس ومساعدتهم. تستمتع بالتعليم والإرشاد والعمل ضمن فريق. تتميّز بالقدرة على التواصل الفعّال والتعاطف مع الآخرين.',
    tags: ['متعاون', 'مساعد', 'ودود', 'متعاطف'],
    color: Color(0xFF27AE60),
  ),
  E(
    code: 'E',
    nameAr: 'مقدام',
    fullNameAr: 'Enterprising',
    descAr:
        'تميل للقيادة والتأثير والإقناع. تستمتع باتخاذ القرارات وإدارة المشاريع وتحقيق الأهداف. تتحمّل المخاطر المحسوبة وتسعى للتميّز والنجاح.',
    tags: ['قيادي', 'طموح', 'مؤثر', 'حازم'],
    color: Color(0xFFF39C12),
  ),
  C(
    code: 'C',
    nameAr: 'تقليدي',
    fullNameAr: 'Conventional',
    descAr:
        'تفضّل العمل المنظم والدقيق. تستمتع بالتعامل مع البيانات والأرقام واتباع الإجراءات المحددة. تتميّز بالانتباه للتفاصيل والالتزام بالمعايير.',
    tags: ['منظّم', 'دقيق', 'منهجي', 'موثوق'],
    color: Color(0xFF16A085),
  );

  const _Type({
    required this.code,
    required this.nameAr,
    required this.fullNameAr,
    required this.descAr,
    required this.tags,
    required this.color,
  });

  final String code;
  final String nameAr;
  final String fullNameAr;
  final String descAr;
  final List<String> tags;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Questions – 36 items (6 per type) from the O*NET / Holland standard
// ─────────────────────────────────────────────────────────────────────────────

class _Q {
  const _Q(this.text, this.type);
  final String text;
  final _Type type;
}

const _kQuestions = <_Q>[
  // ── R ──
  _Q('أستمتع بإصلاح الأجهزة والمعدات بيدي', _Type.R),
  _Q('أفضّل العمل في الهواء الطلق على العمل في مكتب', _Type.R),
  _Q('أجد متعة في تشغيل الآلات والأدوات التقنية', _Type.R),
  _Q('أحب بناء الأشياء وتجميعها بنفسي', _Type.R),
  _Q('أستمتع بأعمال الزراعة والعناية بالنباتات', _Type.R),
  _Q('أفضّل العمل الجسدي النشط على الجلوس خلف مكتب', _Type.R),

  // ── I ──
  _Q('أستمتع بحل المسائل الرياضية والعلمية المعقدة', _Type.I),
  _Q('أحب إجراء التجارب واختبار الفرضيات العلمية', _Type.I),
  _Q('أقضي وقتاً في البحث وقراءة المقالات العلمية', _Type.I),
  _Q('أحب تحليل البيانات والإحصاءات لاستخلاص النتائج', _Type.I),
  _Q('أجذبني التساؤل عن طبيعة الكون والظواهر الطبيعية', _Type.I),
  _Q('أستمتع بدراسة كيفية عمل الأشياء من الداخل', _Type.I),

  // ── A ──
  _Q('أستمتع بالرسم والتصوير والأعمال الفنية', _Type.A),
  _Q('أحب الكتابة الإبداعية والتعبير الأدبي', _Type.A),
  _Q('أجد نفسي مفتوناً بالموسيقى والفنون المسرحية', _Type.A),
  _Q('أفضّل المهام التي تتيح لي الإبداع على المهام الروتينية', _Type.A),
  _Q('أستمتع بتصميم الأشياء وتحسين مظهرها الجمالي', _Type.A),
  _Q('أشعر بالرضا عندما أعبّر عن أفكاري بطريقة إبداعية', _Type.A),

  // ── S ──
  _Q('أستمتع بمساعدة الآخرين في حل مشكلاتهم الشخصية', _Type.S),
  _Q('أحب تعليم الآخرين وشرح الأفكار لهم', _Type.S),
  _Q('أشعر بالرضا عندما أتطوع لخدمة المجتمع', _Type.S),
  _Q('أفضّل العمل ضمن فريق على العمل بمفردي', _Type.S),
  _Q('أجد متعة في الاستماع إلى مشاكل الآخرين وتقديم الدعم لهم', _Type.S),
  _Q('أستمتع بالأنشطة التي تجمع الناس وتعزز التعاون بينهم', _Type.S),

  // ── E ──
  _Q('أشعر بالحماس عند إقناع الآخرين برأيي', _Type.E),
  _Q('أستمتع بقيادة المجموعات وتنظيم الأنشطة', _Type.E),
  _Q('أحب التفاوض والدفاع عن وجهات نظري', _Type.E),
  _Q('أجد نفسي مرتاحاً عند اتخاذ قرارات مهمة تحت الضغط', _Type.E),
  _Q('أستمتع بتخطيط المشاريع التجارية وإدارتها', _Type.E),
  _Q('أحب المنافسة والسعي للفوز في التحديات', _Type.E),

  // ── C ──
  _Q('أستمتع بترتيب الملفات والبيانات بشكل منظم', _Type.C),
  _Q('أحب العمل وفق أنظمة وإجراءات واضحة ومحددة', _Type.C),
  _Q('أجد متعة في التحقق من الأرقام والتأكد من دقة الحسابات', _Type.C),
  _Q('أفضّل المهام ذات التعليمات الواضحة على المهام المفتوحة', _Type.C),
  _Q('أستمتع بإعداد الجداول والتقارير والوثائق المنظمة', _Type.C),
  _Q('أحب الالتزام بالمواعيد والجداول الزمنية بدقة', _Type.C),
];

// ─────────────────────────────────────────────────────────────────────────────
// Major database – Yemen universities
// ─────────────────────────────────────────────────────────────────────────────

class _Major {
  const _Major({
    required this.nameAr,
    required this.hollandCode,
    required this.category,
    required this.universities,
    required this.skills,
    required this.color,
  });
  final String nameAr;
  final String hollandCode;
  final String category;
  final int universities;
  final List<String> skills;
  final Color color;
}

const _kMajors = <_Major>[
  // ── الطب والعلوم الصحية ──
  _Major(
    nameAr: 'الطب والجراحة',
    hollandCode: 'ISR',
    category: 'الطب والعلوم الصحية',
    universities: 8,
    skills: ['التشخيص الطبي', 'التفكير النقدي', 'الرعاية الصحية', 'الأناتومي', 'الفيزيولوجيا'],
    color: Color(0xFF8E44AD),
  ),
  _Major(
    nameAr: 'الصيدلة',
    hollandCode: 'ICR',
    category: 'الطب والعلوم الصحية',
    universities: 6,
    skills: ['الكيمياء الدوائية', 'فارماكولوجيا', 'الدقة', 'الرعاية الصيدلانية', 'التحليل'],
    color: Color(0xFF16A085),
  ),
  _Major(
    nameAr: 'التمريض',
    hollandCode: 'SIR',
    category: 'الطب والعلوم الصحية',
    universities: 7,
    skills: ['الرعاية الصحية', 'التواصل', 'الإسعافات الأولية', 'التعاطف', 'العمل الجماعي'],
    color: Color(0xFF27AE60),
  ),
  _Major(
    nameAr: 'المختبرات الطبية',
    hollandCode: 'IRC',
    category: 'الطب والعلوم الصحية',
    universities: 5,
    skills: ['التحليل المختبري', 'الدقة', 'الكيمياء الحيوية', 'الأجهزة الطبية', 'المنهجية'],
    color: Color(0xFF2980B9),
  ),

  // ── الهندسة والتقنية ──
  _Major(
    nameAr: 'هندسة الحاسوب',
    hollandCode: 'RIC',
    category: 'الهندسة والتقنية',
    universities: 9,
    skills: ['البرمجة', 'حل المشكلات', 'الخوارزميات', 'الشبكات', 'الأنظمة المدمجة'],
    color: Color(0xFFE74C3C),
  ),
  _Major(
    nameAr: 'الهندسة المدنية',
    hollandCode: 'RIE',
    category: 'الهندسة والتقنية',
    universities: 7,
    skills: ['التصميم الإنشائي', 'إدارة المشاريع', 'الميكانيكا التطبيقية', 'المساحة', 'AutoCAD'],
    color: Color(0xFFE67E22),
  ),
  _Major(
    nameAr: 'الهندسة الكهربائية',
    hollandCode: 'RCI',
    category: 'الهندسة والتقنية',
    universities: 6,
    skills: ['الدوائر الكهربائية', 'الإلكترونيات', 'أنظمة الطاقة', 'التحكم الآلي', 'الفيزياء'],
    color: Color(0xFFF39C12),
  ),
  _Major(
    nameAr: 'علوم الحاسوب',
    hollandCode: 'IRC',
    category: 'الهندسة والتقنية',
    universities: 10,
    skills: ['البرمجة', 'الذكاء الاصطناعي', 'قواعد البيانات', 'التحليل', 'الخوارزميات'],
    color: Color(0xFF8E44AD),
  ),

  // ── الاقتصاد والإدارة ──
  _Major(
    nameAr: 'إدارة الأعمال',
    hollandCode: 'ESC',
    category: 'الاقتصاد والإدارة',
    universities: 12,
    skills: ['القيادة', 'التخطيط الاستراتيجي', 'التفاوض', 'إدارة الفرق', 'التسويق'],
    color: Color(0xFFF39C12),
  ),
  _Major(
    nameAr: 'المحاسبة',
    hollandCode: 'CES',
    category: 'الاقتصاد والإدارة',
    universities: 11,
    skills: ['المحاسبة المالية', 'التدقيق', 'الضرائب', 'Excel', 'الدقة والتنظيم'],
    color: Color(0xFF16A085),
  ),
  _Major(
    nameAr: 'الاقتصاد والمالية',
    hollandCode: 'ICE',
    category: 'الاقتصاد والإدارة',
    universities: 8,
    skills: ['التحليل الاقتصادي', 'الإحصاء', 'الأسواق المالية', 'النمذجة', 'البحث'],
    color: Color(0xFF2980B9),
  ),

  // ── القانون والشريعة ──
  _Major(
    nameAr: 'القانون والشريعة',
    hollandCode: 'ESI',
    category: 'القانون والاجتماع',
    universities: 9,
    skills: ['البحث القانوني', 'التحليل', 'الخطابة', 'الكتابة القانونية', 'التفاوض'],
    color: Color(0xFFE74C3C),
  ),
  _Major(
    nameAr: 'الخدمة الاجتماعية',
    hollandCode: 'SAE',
    category: 'القانون والاجتماع',
    universities: 5,
    skills: ['التواصل', 'حل النزاعات', 'الدعم النفسي', 'العمل المجتمعي', 'التعاطف'],
    color: Color(0xFF27AE60),
  ),

  // ── التربية والتعليم ──
  _Major(
    nameAr: 'التربية وعلم النفس',
    hollandCode: 'SIA',
    category: 'التربية والتعليم',
    universities: 10,
    skills: ['التدريس', 'التواصل', 'الصبر', 'تصميم المناهج', 'علم نفس الأطفال'],
    color: Color(0xFF27AE60),
  ),
  _Major(
    nameAr: 'اللغة الإنجليزية وآدابها',
    hollandCode: 'ASI',
    category: 'التربية والتعليم',
    universities: 8,
    skills: ['الترجمة', 'الكتابة الأكاديمية', 'التدريس', 'الأدب', 'اللغويات'],
    color: Color(0xFFE67E22),
  ),

  // ── الإعلام والصحافة ──
  _Major(
    nameAr: 'الإعلام والصحافة',
    hollandCode: 'AES',
    category: 'الإعلام والاتصال',
    universities: 6,
    skills: ['الكتابة الصحفية', 'التصوير', 'التحرير', 'التواصل', 'الإنتاج الإعلامي'],
    color: Color(0xFFE67E22),
  ),

  // ── العلوم الطبيعية ──
  _Major(
    nameAr: 'علم الأحياء',
    hollandCode: 'ISR',
    category: 'العلوم الطبيعية',
    universities: 7,
    skills: ['بيولوجيا الخلية', 'الوراثة', 'التجارب المعملية', 'التحليل', 'المجهر'],
    color: Color(0xFF27AE60),
  ),

  // ── الزراعة ──
  _Major(
    nameAr: 'الزراعة والثروة السمكية',
    hollandCode: 'RIS',
    category: 'الزراعة والبيئة',
    universities: 4,
    skills: ['إدارة المزارع', 'الري', 'الثروة الحيوانية', 'البيئة الزراعية', 'المياه'],
    color: Color(0xFF16A085),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper functions
// ─────────────────────────────────────────────────────────────────────────────

Map<_Type, int> _computeScores(List<int> answers, List<_Q> questions) {
  final scores = {for (final t in _Type.values) t: 0};
  for (var i = 0; i < answers.length && i < questions.length; i++) {
    scores[questions[i].type] = scores[questions[i].type]! + answers[i];
  }
  return scores;
}

List<MapEntry<_Type, int>> _sortedTypes(Map<_Type, int> scores) =>
    scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

String _hollandCode(List<MapEntry<_Type, int>> sorted) =>
    sorted.take(3).map((e) => e.key.code).join();


// Major recommendation algorithm
double _majorMatch(Map<_Type, int> scores, _Major major) {
  const typeIndex = {
    'R': _Type.R,
    'I': _Type.I,
    'A': _Type.A,
    'S': _Type.S,
    'E': _Type.E,
    'C': _Type.C,
  };
  final maxScore = 30.0;
  var total = 0.0;
  var weight = 0.0;
  for (var i = 0; i < major.hollandCode.length; i++) {
    final letter = major.hollandCode[i];
    final t = typeIndex[letter];
    if (t != null) {
      final w = 3.0 - i;
      total += (scores[t]! / maxScore) * w;
      weight += w;
    }
  }
  return weight > 0 ? (total / weight) * 100 : 0;
}

List<(double, _Major)> _rankedMajors(Map<_Type, int> scores) {
  final ranked = _kMajors
      .map((m) => (_majorMatch(scores, m), m))
      .toList()
    ..sort((a, b) => b.$1.compareTo(a.$1));
  return ranked;
}

Color _matchColor(double pct) {
  if (pct >= 70) return const Color(0xFF27AE60);
  if (pct >= 50) return const Color(0xFF2196F3);
  return const Color(0xFFE67E22);
}

String _matchLabel(double pct) {
  if (pct >= 70) return 'توافق ممتاز';
  if (pct >= 50) return 'توافق جيد';
  return 'توافق معقول';
}

// ─────────────────────────────────────────────────────────────────────────────
// RiasecAssessmentPage — entry widget
// ─────────────────────────────────────────────────────────────────────────────

class RiasecAssessmentPage extends StatefulWidget {
  const RiasecAssessmentPage({super.key});

  @override
  State<RiasecAssessmentPage> createState() => _RiasecAssessmentPageState();
}

class _RiasecAssessmentPageState extends State<RiasecAssessmentPage> {
  late final List<_Q> _questions;
  late List<int> _answers;
  int _current = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Shuffle question order on every new assessment
    _questions = List<_Q>.from(_kQuestions)..shuffle(Random());
    _answers = List.filled(_questions.length, 0);
  }

  void _answer(int val) {
    setState(() => _answers[_current] = val);
  }

  void _next() {
    if (_answers[_current] == 0) return;
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      setState(() => _submitted = true);
    }
  }

  void _prev() {
    if (_current > 0) setState(() => _current--);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ResultsScreen(answers: List.unmodifiable(_answers), questions: _questions);
    }
    return _QuestionScreen(
      index: _current,
      total: _questions.length,
      question: _questions[_current],
      selected: _answers[_current],
      onAnswer: _answer,
      onNext: _next,
      onPrev: _current > 0 ? _prev : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuestionScreen
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionScreen extends StatelessWidget {
  const _QuestionScreen({
    required this.index,
    required this.total,
    required this.question,
    required this.selected,
    required this.onAnswer,
    required this.onNext,
    this.onPrev,
  });

  final int index;
  final int total;
  final _Q question;
  final int selected;
  final void Function(int) onAnswer;
  final VoidCallback onNext;
  final VoidCallback? onPrev;

  static const _labels = [
    (5, 'أوافق بشدة'),
    (4, 'أوافق'),
    (3, 'محايد'),
    (2, 'لا أوافق'),
    (1, 'لا أوافق بشدة'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = question.type;
    final progress = (index + 1) / total;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1620),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Back button
                  if (onPrev != null)
                    GestureDetector(
                      onTap: onPrev,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'السابق',
                          style: TextStyle(
                              color: Color(0xFF7FA8C9), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  const Spacer(),

                  // Progress counter
                  Text(
                    'السؤال ${index + 1} / $total',
                    style: const TextStyle(
                        color: Color(0xFF7FA8C9), fontSize: 13),
                  ),

                  const Spacer(),

                  // Holland type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.color.withAlpha(80)),
                    ),
                    child: Text(
                      '${t.code} – ${t.nameAr}',
                      style: TextStyle(
                          color: t.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation<Color>(t.color),
                ),
              ),
            ),

            const Spacer(),

            // ── Type icon ───────────────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: t.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  t.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Question text ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                question.text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(),

            // ── Answer options ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _labels.map((pair) {
                  final val = pair.$1;
                  final label = pair.$2;
                  final isSelected = selected == val;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => onAnswer(val),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? t.color.withAlpha(40)
                              : const Color(0xFF111E2B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? t.color
                                : Colors.white.withAlpha(20),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? t.color
                                      : Colors.white.withAlpha(60),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? t.color
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const Spacer(),
                            Text(
                              label,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFB0C4D8),
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Next button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  if (onPrev != null) ...[
                    OutlinedButton(
                      onPressed: onPrev,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7FA8C9),
                        side: BorderSide(
                            color: Colors.white.withAlpha(30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('السابق'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: selected != 0 ? onNext : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.color,
                        disabledBackgroundColor:
                            Colors.white.withAlpha(15),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        index == total - 1 ? 'عرض النتائج' : 'التالي',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResultsScreen
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsScreen extends ConsumerStatefulWidget {
  const _ResultsScreen({
    required this.answers,
    required this.questions,
  });
  final List<int> answers;
  final List<_Q> questions;

  @override
  ConsumerState<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<_ResultsScreen> {
  bool _navigating = false;

  Future<void> _startChat() async {
    if (_navigating) return;
    setState(() => _navigating = true);

    final scores = _computeScores(widget.answers, widget.questions);
    final sorted = _sortedTypes(scores);
    final code = _hollandCode(sorted);

    // Build top_types string for assessment data
    final topTypes = sorted.take(3).map((e) => e.key.name).join('-');

    // Persist structured assessment result
    final userSvc = const UserService();
    final assessSvc = const AssessmentService();
    final convSvc = const ConversationService();

    final user = await userSvc.getOrCreate();
    final assessmentId = const Uuid().v4();

    final result = AssessmentResult(
      assessmentId: assessmentId,
      userId: user.userId,
      role: UserRole.student,
      completedAt: DateTime.now(),
      data: {
        'R': scores[_Type.R] ?? 0,
        'I': scores[_Type.I] ?? 0,
        'A': scores[_Type.A] ?? 0,
        'S': scores[_Type.S] ?? 0,
        'E': scores[_Type.E] ?? 0,
        'C': scores[_Type.C] ?? 0,
        'holland_code': code,
        'top_types': topTypes,
      },
    );

    await assessSvc.save(result);
    final conv = await convSvc.create(
      userId: user.userId,
      assessmentId: assessmentId,
      role: UserRole.student,
    );

    if (!mounted) return;

    // ⚠️ The roleIntroMessage shown to the user must NOT contain any
    // methodology names (Holland, RIASEC, ERI...). The assessment data
    // is passed internally via AssessmentResult and used in the system prompt.
    const userFacingIntro =
        'مرحباً! 👋 أنا سيرا، مستشارتك في منصة StuStep.\n\n'
        'لقد انتهيت من الاستبيان الخاص بك، وسأساعدك الآن في اكتشاف '
        'التخصص الجامعي الأنسب بناءً على ميولك واهتماماتك.\n\n'
        'ما الذي تودّ أن نبدأ بمناقشته؟';

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (ctx, anim, _) => AiAdvisorPage(
          conversation: conv,
          assessment: result,
          roleIntroMessage: userFacingIntro,
        ),
        transitionsBuilder: (_, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scores = _computeScores(widget.answers, widget.questions);
    final sorted = _sortedTypes(scores);
    final code = _hollandCode(sorted);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1620),
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'نموذج هولاند RIASEC',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'نتيجة تقييمك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رمز هولاند الخاص بك',
                    style: const TextStyle(
                        color: Color(0xFF7FA8C9), fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Holland code display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withAlpha(60),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: code.split('').map((letter) {
                          final t = _Type.values
                              .firstWhere((t) => t.code == letter);
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Text(
                                  letter,
                                  style: TextStyle(
                                    color: t.color,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  t.nameAr,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Dimension cards ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final en = sorted[i];
                  final t = en.key;
                  final score = en.value;
                  final isTop = i < 3;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111E2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTop
                              ? t.color.withAlpha(80)
                              : Colors.white.withAlpha(12),
                          width: isTop ? 1.5 : 1,
                        ),
                        boxShadow: isTop
                            ? [
                                BoxShadow(
                                  color: t.color.withAlpha(25),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: t.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$score',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    t.nameAr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    t.fullNameAr,
                                    style: const TextStyle(
                                      color: Color(0xFF7FA8C9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: t.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    t.code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 30.0,
                              minHeight: 6,
                              backgroundColor: Colors.white.withAlpha(15),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(t.color),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t.descAr,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              color: Color(0xFFB0C4D8),
                              fontSize: 12.5,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: t.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: t.color.withAlpha(30),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: t.color,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          if (isTop) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  i == 0
                                      ? 'النمط الأول'
                                      : i == 1
                                          ? 'النمط الثاني'
                                          : 'النمط الثالث',
                                  style: TextStyle(
                                    color: t.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            ),
          ),

          // ── Stats footer ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111E2B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'حجم التحليل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'تم تحليل إجاباتك باستخدام نموذج هولاند (RIASEC) — O*NET Standard.',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Color(0xFF7FA8C9),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat('36', 'سؤال'),
                        _Stat('6', 'أنماط'),
                        _Stat('${_kQuestions.length}', 'إجابة'),
                        _Stat(code, 'رمزك'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Majors recommendations ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _MajorsSection(scores: scores),
            ),
          ),

          // ── CTA button ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: FilledButton(
                onPressed: _navigating ? null : _startChat,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _navigating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ابدأ المحادثة مع المستشار الذكي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MajorsSection — top 3 Yemen majors
// ─────────────────────────────────────────────────────────────────────────────

class _MajorsSection extends StatelessWidget {
  const _MajorsSection({required this.scores});
  final Map<_Type, int> scores;

  @override
  Widget build(BuildContext context) {
    final ranked = _rankedMajors(scores).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'بناءً على رمز هولاند',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            const Row(
              children: [
                Text(
                  'أفضل التخصصات لك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.star_rounded,
                    color: Color(0xFFF39C12), size: 22),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            'تخصصات متوفرة في الجامعات اليمنية',
            style: TextStyle(color: Color(0xFF7FA8C9), fontSize: 12),
          ),
        ),
        const SizedBox(height: 14),
        for (var idx = 0; idx < ranked.length; idx++)
          _MajorCard(
            rank: idx + 1,
            pct: ranked[idx].$1,
            major: ranked[idx].$2,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MajorCard
// ─────────────────────────────────────────────────────────────────────────────

class _MajorCard extends StatelessWidget {
  const _MajorCard({
    required this.rank,
    required this.pct,
    required this.major,
  });

  final int rank;
  final double pct;
  final _Major major;

  @override
  Widget build(BuildContext context) {
    final mColor = _matchColor(pct);
    final mLabel = _matchLabel(pct);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111E2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: rank == 1
                ? major.color.withAlpha(100)
                : Colors.white.withAlpha(15),
            width: rank == 1 ? 1.5 : 1,
          ),
          boxShadow: rank == 1
              ? [
                  BoxShadow(
                    color: major.color.withAlpha(30),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: mColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: mColor.withAlpha(80), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${pct.round()}%',
                            style: TextStyle(
                              color: mColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mLabel,
                        style: TextStyle(
                          color: mColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (rank == 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF39C12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '⭐ الأنسب',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              major.nameAr,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: major.color.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: major.color.withAlpha(80)),
                              ),
                              child: Text(
                                major.hollandCode,
                                style: TextStyle(
                                  color: major.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              major.category,
                              style: const TextStyle(
                                color: Color(0xFF7FA8C9),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withAlpha(12), height: 1),

            // ── Stats ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded,
                      color: Color(0xFF7FA8C9), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${major.universities} جامعة يمنية',
                    style: const TextStyle(
                      color: Color(0xFF7FA8C9),
                      fontSize: 11.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: major.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Skills ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      'أهم المهارات المطلوبة:',
                      style: TextStyle(
                        color: Color(0xFF7FA8C9),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: major.skills.take(4).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: major.color.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: major.color.withAlpha(50)),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: major.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Stat
// ─────────────────────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7FA8C9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
