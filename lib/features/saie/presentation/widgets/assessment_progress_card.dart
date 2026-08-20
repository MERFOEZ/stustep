// SAIE — AssessmentProgressCard Widget
//
// Displays AssessmentProgress data from EngineResult.
// No AI logic — purely presentational.

import 'package:flutter/material.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';

class AssessmentProgressCard extends StatelessWidget {
  final AssessmentProgress progress;
  final bool isRtl;

  const AssessmentProgressCard({
    super.key,
    required this.progress,
    this.isRtl = true,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(Icons.psychology_outlined, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  isRtl ? 'تقدم التقييم' : 'Assessment Progress',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.coverageRatio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            _buildGrid(context, scheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        _statCell(
          context,
          isRtl ? 'الأسئلة' : 'Questions',
          '${progress.questionsAnswered}/${progress.questionsAsked}',
          scheme,
          textTheme,
        ),
        _statCell(
          context,
          isRtl ? 'الثقة' : 'Confidence',
          '${(progress.overallConfidence * 100).round()}%',
          scheme,
          textTheme,
        ),
        _statCell(
          context,
          isRtl ? 'متبقٍ' : 'Remaining',
          '~${progress.estimatedRemainingQuestions}',
          scheme,
          textTheme,
        ),
      ],
    );
  }

  Widget _statCell(
    BuildContext context,
    String label,
    String value,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
