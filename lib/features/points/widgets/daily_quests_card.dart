import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/points_provider.dart';
import '../screens/points_hub_screen.dart';

class DailyQuestsCard extends StatelessWidget {
  const DailyQuestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final pointsProvider = context.watch<PointsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dailyQuests = pointsProvider.dailyQuests;
    final totalQuests = dailyQuests.length;
    final completedQuestsCount = pointsProvider.dailyProgress.values
        .where((p) => p.isCompleted)
        .length;

    final progressRatio = totalQuests > 0 ? (completedQuestsCount / totalQuests).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6200EE).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF6200EE),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'quests.daily_title'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PointsHubScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'quests.view_all'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF6200EE),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF6200EE),
                        size: 11,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6200EE)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completedQuestsCount / $totalQuests',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
