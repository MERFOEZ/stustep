// SAIE — RecommendationCard Widget
//
// Displays a single MajorRecommendation.
// Data comes entirely from RecommendationReport. No AI logic.

import 'package:flutter/material.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

class RecommendationCard extends StatelessWidget {
  final MajorRecommendation rec;
  final bool isRtl;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.rec,
    this.isRtl = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = isRtl && rec.majorNameAr != null ? rec.majorNameAr! : rec.majorName;
    final pct = rec.similarityScore;

    return Card(
      elevation: 2,
      shadowColor: scheme.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RankBadge(rank: rec.rank, scheme: scheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRtl ? 'توافق $pct%' : '$pct% match',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
              const SizedBox(height: 12),
              // Match bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
              if (rec.topStrengths.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TagRow(
                  label: isRtl ? 'نقاط القوة:' : 'Strengths:',
                  tags: rec.topStrengths,
                  color: Colors.green.shade700,
                  scheme: scheme,
                ),
              ],
              if (rec.careerPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                _TagRow(
                  label: isRtl ? 'المسارات:' : 'Career Paths:',
                  tags: rec.careerPaths.take(3).toList(),
                  color: scheme.tertiary,
                  scheme: scheme,
                ),
              ],
              if (rec.explanation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  rec.explanation,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final ColorScheme scheme;

  const _RankBadge({required this.rank, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isTop ? Colors.amber.shade100 : scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: isTop ? Colors.amber.shade800 : scheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Color color;
  final ColorScheme scheme;

  const _TagRow({
    required this.label,
    required this.tags,
    required this.color,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        ...tags.take(3).map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                t,
                style: TextStyle(color: color, fontSize: 11),
              ),
            )),
      ],
    );
  }
}
