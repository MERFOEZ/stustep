import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardEntryTile extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final bool isPromotion;
  final bool isDemotion;

  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.isPromotion = false,
    this.isDemotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrent = entry.isCurrentUser;

    Color? zoneColor;
    if (isPromotion) {
      zoneColor = const Color(0xFF00E676);
    } else if (isDemotion) {
      zoneColor = const Color(0xFFFF5252);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? Theme.of(context).primaryColor
              : (zoneColor?.withValues(alpha: 0.35) ??
                  (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: zoneColor ?? (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
            backgroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                ? NetworkImage(entry.photoUrl!)
                : null,
            child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name and Streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                          color: isCurrent ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.currentStreak > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF5722),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.currentStreak} ${'points.days'.tr()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF5722),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Weekly Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.weeklyPoints}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'leaderboard.points_short'.tr(),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
