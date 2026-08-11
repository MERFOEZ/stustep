import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/major_suggestion.dart';

/// عرض تفصيل نقاط الاقتراح — الأربعة مكوّنات كأشرطة نسبية.
///
/// **هذه الودجت هي جواب سؤال المناقشة الأهم:** «كيف رتّبت النتائج؟»
///
/// الترتيب الذي لا يستطيع صاحبه شرحه ليس خوارزمية بل حدس. لذلك لا نكتفي
/// بعرض رقم النتيجة، بل نُظهر من أين جاء: كم نقطة من الاهتمامات، وكم من
/// المعدل، وكم من توافق الشهادة، وكم من اكتمال بيانات التخصص. الطالب يرى
/// السبب، والمناقش يرى المنطق.
class ScoreBreakdownView extends StatelessWidget {
  final SuggestionBreakdown breakdown;

  const ScoreBreakdownView({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BreakdownBar(
          labelKey: 'admission.matcher.factor.interests',
          value: breakdown.interestScore,
          maxValue: MatcherWeights.interests,
          color: const Color(0xFF6200EE),
          icon: Icons.favorite_rounded,
        ),
        _BreakdownBar(
          labelKey: 'admission.matcher.factor.gpa_fit',
          value: breakdown.gpaFitScore,
          maxValue: MatcherWeights.gpaFit,
          color: const Color(0xFF00C853),
          icon: Icons.grade_rounded,
        ),
        _BreakdownBar(
          labelKey: 'admission.matcher.factor.certificate_fit',
          value: breakdown.certificateFitScore,
          maxValue: MatcherWeights.certificateFit,
          color: const Color(0xFF304FFE),
          icon: Icons.badge_rounded,
        ),
        _BreakdownBar(
          labelKey: 'admission.matcher.factor.completeness',
          value: breakdown.completenessScore,
          maxValue: MatcherWeights.completeness,
          color: const Color(0xFFFF6D00),
          icon: Icons.menu_book_rounded,
        ),
      ],
    );
  }
}

/// شريط مكوّن واحد: اسمه، ونسبته من وزنه الأقصى، وقيمته الرقمية.
class _BreakdownBar extends StatelessWidget {
  final String labelKey;
  final double value;
  final double maxValue;
  final Color color;
  final IconData icon;

  const _BreakdownBar({
    required this.labelKey,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // الحماية من القسمة على صفر لو عُدِّلت الأوزان مستقبلاً.
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  labelKey.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                // نعرض المكتسب من الوزن الأقصى، لا النسبة المئوية وحدها،
                // حتى يفهم الطالب أن الاهتمامات وزنها 60 والمعدل 25.
                '${value.toStringAsFixed(0)} / ${maxValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// دائرة النتيجة الإجمالية من 100.
class ScoreCircle extends StatelessWidget {
  final double score;
  final Color color;
  final double size;

  const ScoreCircle({
    super.key,
    required this.score,
    required this.color,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
