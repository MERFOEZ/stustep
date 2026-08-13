import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/major_suggestion.dart';
import '../../models/matcher_outcome.dart';
import '../../widgets/eligibility_visuals.dart';

/// شريط تمرير لقيمة واحدة في المحاكي، مع إظهار قيمتها الأصلية للمقارنة.
///
/// إظهار القيمة الأصلية بجانب المعدَّلة مقصود: الطالب يحتاج أن يرى أن ما
/// يجرّبه فرضية لا واقع، وأن يعرف حجم الفارق الذي يفترضه على نفسه.
class WhatIfSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double originalValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// خانات عشرية العرض — المعدل بخانة، ودرجات المواد بلا خانات.
  final int fractionDigits;

  const WhatIfSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.originalValue,
    required this.min,
    required this.max,
    required this.onChanged,
    this.fractionDigits = 1,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final difference = value - originalValue;
    final hasChanged = difference.abs() > 0.001;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(fractionDigits),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              if (hasChanged) ...[
                const SizedBox(width: 6),
                _buildDeltaChip(difference),
              ],
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaChip(double difference) {
    final isGain = difference > 0;
    final color = isGain ? const Color(0xFF00A152) : const Color(0xFFD32F2F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isGain ? '+' : ''}${difference.toStringAsFixed(fractionDigits)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// ملخّص أثر السيناريو: عدد الفرص قبل وبعد، وصافي التغيّر.
class WhatIfSummary extends StatelessWidget {
  final WhatIfOutcome outcome;

  const WhatIfSummary({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    final delta = outcome.delta;
    final color = delta > 0
        ? const Color(0xFF00A152)
        : (delta < 0 ? const Color(0xFFD32F2F) : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _buildCount(
            context,
            value: outcome.eligibleBefore,
            labelKey: 'admission.matcher.whatif_before',
          ),
          Icon(Icons.arrow_forward_rounded, color: color, size: 20),
          _buildCount(
            context,
            value: outcome.eligibleAfter,
            labelKey: 'admission.matcher.whatif_after',
            color: color,
          ),
          if (delta != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '${delta > 0 ? '+' : ''}$delta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCount(
    BuildContext context, {
    required int value,
    required String labelKey,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            labelKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// قائمة التخصصات التي انفتحت أو أُغلقت نتيجة السيناريو.
///
/// هذه القائمة هي جوهر المحاكي. الرقم وحده («صار عندك 7 بدل 4») معلومة
/// جافة؛ أما الأسماء («انفتح لك: التمريض، المختبرات، الصيدلة») فهي ما
/// يحوّل السيناريو إلى قرار.
class WhatIfImpactList extends StatelessWidget {
  final List<MajorSuggestion> items;
  final bool isGain;

  const WhatIfImpactList({
    super.key,
    required this.items,
    required this.isGain,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final color = isGain ? const Color(0xFF00A152) : const Color(0xFFD32F2F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isGain
                  ? Icons.lock_open_rounded
                  : EligibilityVisuals.icon(items.first.eligibility.level),
              size: 17,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              (isGain
                      ? 'admission.matcher.whatif_unlocked'
                      : 'admission.matcher.whatif_lost')
                  .tr(namedArgs: {'count': '${items.length}'}),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.department.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.collegeName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'admission.matcher.required_gpa'.tr(
                    namedArgs: {
                      'gpa': item.eligibility.requiredGpa.toStringAsFixed(0),
                    },
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
