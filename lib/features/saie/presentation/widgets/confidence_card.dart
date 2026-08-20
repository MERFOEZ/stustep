// SAIE — ConfidenceCard Widget
//
// Displays a circular confidence gauge from EngineResult.
// No AI logic.

import 'package:flutter/material.dart';

class ConfidenceCard extends StatelessWidget {
  final double confidence; // 0.0 – 1.0
  final bool isRtl;

  const ConfidenceCard({
    super.key,
    required this.confidence,
    this.isRtl = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pct = (confidence * 100).round();
    final color = _confidenceColor(confidence, scheme);

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: confidence.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor:
                        scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Text(
                    '$pct',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'مستوى الثقة' : 'Confidence',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _label(pct, isRtl),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

  Color _confidenceColor(double v, ColorScheme s) {
    if (v >= 0.75) return Colors.green.shade600;
    if (v >= 0.45) return Colors.orange.shade600;
    return s.error;
  }

  String _label(int pct, bool rtl) {
    if (pct >= 75) return rtl ? 'ثقة عالية' : 'High confidence';
    if (pct >= 45) return rtl ? 'ثقة متوسطة' : 'Moderate confidence';
    return rtl ? 'نحتاج مزيداً من المعلومات' : 'Need more data';
  }
}
