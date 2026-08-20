// SAIE — ProfileSummaryCard Widget
//
// Displays a compact summary of the StudentCognitiveProfile.
// Uses ProfileStatistics — no AI logic, pure rendering.

import 'package:flutter/material.dart';
import 'package:stustep/features/saie/profile/profile_statistics.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

class ProfileSummaryCard extends StatelessWidget {
  final StudentCognitiveProfile profile;
  final bool isRtl;

  const ProfileSummaryCard({
    super.key,
    required this.profile,
    this.isRtl = true,
  });

  @override
  Widget build(BuildContext context) {
    final stats = profile.computeStatistics();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.person_outline, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  isRtl ? 'الملف المعرفي' : 'Cognitive Profile',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusChip(stats: stats, scheme: scheme, isRtl: isRtl),
              ],
            ),
            const SizedBox(height: 14),
            // Overall confidence bar
            _LabeledBar(
              label: isRtl ? 'الثقة العامة' : 'Overall Confidence',
              value: stats.overallConfidence,
              color: scheme.primary,
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 8),
            _LabeledBar(
              label: isRtl ? 'التغطية' : 'Coverage',
              value: stats.coverageRatio,
              color: scheme.tertiary,
              textTheme: textTheme,
              scheme: scheme,
            ),
            if (stats.strongestDimensions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                isRtl ? 'أبرز نقاط القوة:' : 'Top Strengths:',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _DimensionList(
                dims: stats.strongestDimensions,
                color: Colors.green.shade700,
                scheme: scheme,
                textTheme: textTheme,
              ),
            ],
            if (stats.weakestDimensions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                isRtl ? 'مجالات التطوير:' : 'Areas for Growth:',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _DimensionList(
                dims: stats.weakestDimensions,
                color: scheme.error,
                scheme: scheme,
                textTheme: textTheme,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              isRtl
                  ? 'الأدلة: ${stats.totalEvidenceCount} · الأسئلة: ${stats.totalQuestionsAnswered}'
                  : 'Evidence: ${stats.totalEvidenceCount} · Questions: ${stats.totalQuestionsAnswered}',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ProfileStatistics stats;
  final ColorScheme scheme;
  final bool isRtl;

  const _StatusChip({
    required this.stats,
    required this.scheme,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final ready = stats.overallConfidence >= 0.35 &&
        stats.totalEvidenceCount >= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ready
            ? Colors.green.shade50
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ready
              ? Colors.green.shade300
              : scheme.outlineVariant,
        ),
      ),
      child: Text(
        ready
            ? (isRtl ? 'جاهز' : 'Ready')
            : (isRtl ? 'قيد التقييم' : 'Assessing'),
        style: TextStyle(
          color: ready ? Colors.green.shade700 : scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LabeledBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final TextTheme textTheme;
  final ColorScheme scheme;

  const _LabeledBar({
    required this.label,
    required this.value,
    required this.color,
    required this.textTheme,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              '${(value * 100).round()}%',
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DimensionList extends StatelessWidget {
  final List<DimensionStat> dims;
  final Color color;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _DimensionList({
    required this.dims,
    required this.color,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: dims.take(4).map((d) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            d.label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        );
      }).toList(),
    );
  }
}
