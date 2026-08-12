import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ReferralStatsCard extends StatelessWidget {
  final int totalInvited;
  final int activeReferrals;
  final int totalPointsEarned;

  const ReferralStatsCard({
    super.key,
    required this.totalInvited,
    required this.activeReferrals,
    required this.totalPointsEarned,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            context,
            title: 'referral.total_invited'.tr(),
            value: '$totalInvited',
            icon: Icons.people_outline_rounded,
            color: const Color(0xFF6200EE),
          ),
          Container(
            height: 40,
            width: 1,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
          _buildStatColumn(
            context,
            title: 'referral.active_friends'.tr(),
            value: '$activeReferrals',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF00C853),
          ),
          Container(
            height: 40,
            width: 1,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
          _buildStatColumn(
            context,
            title: 'referral.points_earned'.tr(),
            value: '+$totalPointsEarned',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFFFAB00),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
