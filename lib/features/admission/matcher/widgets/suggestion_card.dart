import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/interest_tag.dart';
import '../../models/major_suggestion.dart';
import '../../widgets/eligibility_visuals.dart';
import 'score_breakdown_view.dart';

/// بطاقة اقتراح تخصص واحد.
///
/// تعرض أربع معلومات لا يجوز فصل أي منها عن الأخرى:
///   1. الترتيب والنتيجة — «ما موقع هذا التخصص بين الخيارات؟»
///   2. شارة الأهلية — «هل أستطيع دخوله أصلاً؟»
///   3. الاهتمامات المطابقة — «لماذا اقتُرح عليّ أنا تحديداً؟»
///   4. تفصيل النقاط عند التوسيع — «من أين جاء هذا الرقم؟»
///
/// عرض النتيجة بلا شارة أهلية كان سيُوهم الطالب بأن أعلى القائمة متاح له،
/// وعرض الأهلية بلا سبب التطابق كان سيجعل الترتيب يبدو عشوائياً.
class SuggestionCard extends StatefulWidget {
  final MajorSuggestion suggestion;

  /// ترتيب الاقتراح في القائمة، يبدأ من 1.
  final int rank;

  /// فتح صفحة التخصص في دليل المرحلة 3 — إعادة استخدام لا إعادة بناء.
  final VoidCallback onOpenGuide;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.rank,
    required this.onOpenGuide,
  });

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;
    final accent = EligibilityVisuals.color(suggestion.eligibility.level);

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context, accent),
            if (suggestion.matchedInterests.isNotEmpty)
              _buildMatchedInterests(context),
            _buildFooter(context, accent),
            if (_expanded) _buildBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    final suggestion = widget.suggestion;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRankBadge(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.department.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion.collegeName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                EligibilityBadge(
                  level: suggestion.eligibility.level,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ScoreCircle(score: suggestion.score, color: accent),
        ],
      ),
    );
  }

  /// رقم الترتيب — الثلاثة الأوائل بلون مميّز.
  Widget _buildRankBadge(BuildContext context) {
    final isTopThree = widget.rank <= 3;
    final primary = Theme.of(context).primaryColor;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTopThree
            ? primary.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${widget.rank}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isTopThree ? primary : Colors.grey.shade600,
        ),
      ),
    );
  }

  /// رقائق الاهتمامات التي تطابقت فعلاً — سبب الاقتراح بلغة الطالب.
  Widget _buildMatchedInterests(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admission.matcher.matched_because'.tr(),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.suggestion.matchedInterests.map((id) {
              final tag = InterestCatalog.byId(id);
              if (tag == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tag.icon,
                      size: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tag.labelKey.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color accent) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.help_outline_rounded,
                size: 17,
              ),
              label: Text(
                'admission.matcher.why'.tr(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: Colors.grey.withValues(alpha: 0.18),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: widget.onOpenGuide,
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: Text(
                'admission.matcher.open_guide'.tr(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: ScoreBreakdownView(breakdown: widget.suggestion.breakdown),
    );
  }
}
