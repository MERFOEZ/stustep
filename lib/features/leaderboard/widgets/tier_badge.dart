import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TierBadge extends StatelessWidget {
  final String tierLevel;
  final double size;
  final bool showLabel;

  const TierBadge({
    super.key,
    required this.tierLevel,
    this.size = 28,
    this.showLabel = true,
  });

  static Color getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFF00E5FF);
      case 'diamond':
        return const Color(0xFF7C4DFF);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  static String getTierLabelKey(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return 'leaderboard.tier_silver';
      case 'gold':
        return 'leaderboard.tier_gold';
      case 'platinum':
        return 'leaderboard.tier_platinum';
      case 'diamond':
        return 'leaderboard.tier_diamond';
      case 'bronze':
      default:
        return 'leaderboard.tier_bronze';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getTierColor(tierLevel);
    final labelKey = getTierLabelKey(tierLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_rounded,
            color: color,
            size: size * 0.65,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              labelKey.tr(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
