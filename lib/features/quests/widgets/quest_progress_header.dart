import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class QuestProgressHeader extends StatelessWidget {
  final bool isDaily;
  final int completedCount;
  final int totalCount;

  const QuestProgressHeader({
    super.key,
    required this.isDaily,
    required this.completedCount,
    required this.totalCount,
  });

  String _getTimeUntilReset() {
    final now = DateTime.now().toUtc();
    if (isDaily) {
      // Midnight UTC
      final midnight = DateTime.utc(now.year, now.month, now.day + 1);
      final diff = midnight.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } else {
      // Next Monday 00:00 UTC
      final daysUntilMonday = ((8 - now.weekday) % 7);
      final targetDays = daysUntilMonday == 0 ? 7 : daysUntilMonday;
      final nextMonday = DateTime.utc(now.year, now.month, now.day + targetDays);
      final diff = nextMonday.difference(now);
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return '${days}d ${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1035), const Color(0xFF2A1650), const Color(0xFF3B1E6D)]
              : [const Color(0xFF6200EE), const Color(0xFF7C4DFF), const Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EE).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDaily ? 'quests.daily'.tr() : 'quests.weekly'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isDaily ? 'quests.daily_reset_in'.tr() : 'quests.weekly_reset_in'.tr()} ${_getTimeUntilReset()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount / $totalCount ${'quests.completed'.tr()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (completedCount == totalCount && totalCount > 0)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'quests.all_done'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
