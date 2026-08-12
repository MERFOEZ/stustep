import 'package:flutter/material.dart';

/// شريط تقدم مخصص للمهام مع دعم ألوان المستويات والحالات.
class QuestProgressBar extends StatelessWidget {
  final double progressRatio; // 0.0 to 1.0
  final Color? progressColor;
  final Color? backgroundColor;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const QuestProgressBar({
    super.key,
    required this.progressRatio,
    this.progressColor,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedRatio = progressRatio.clamp(0.0, 1.0);
    final activeColor = progressColor ?? Theme.of(context).primaryColor;
    final bg = backgroundColor ?? (isDark ? Colors.white10 : Colors.grey.shade200);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: radius,
      child: LinearProgressIndicator(
        value: clampedRatio,
        minHeight: height,
        backgroundColor: bg,
        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
      ),
    );
  }
}
