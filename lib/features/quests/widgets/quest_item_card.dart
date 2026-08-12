import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/quest_model.dart';
import '../models/quest_progress_model.dart';

class QuestItemCard extends StatelessWidget {
  final QuestModel quest;
  final QuestProgressModel? progress;

  const QuestItemCard({
    super.key,
    required this.quest,
    this.progress,
  });

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'courses':
        return Icons.school_rounded;
      case 'ai_chat':
        return Icons.smart_toy_rounded;
      case 'academic_tools':
        return Icons.quiz_rounded;
      case 'groups':
        return Icons.people_rounded;
      case 'home':
      default:
        return Icons.stars_rounded;
    }
  }

  Color _getSectionColor(String section) {
    switch (section) {
      case 'courses':
        return const Color(0xFF6200EE);
      case 'ai_chat':
        return const Color(0xFF00B0FF);
      case 'academic_tools':
        return const Color(0xFFFF9100);
      case 'groups':
        return const Color(0xFF00E676);
      case 'home':
      default:
        return const Color(0xFFE91E63);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = progress?.isCompleted ?? false;
    final currentCount = progress?.currentCount ?? 0;
    final targetCount = quest.targetCount;
    final ratio = targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;
    final repeatCount = progress?.repeatCount ?? 0;

    final sectionColor = _getSectionColor(quest.section);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00C853).withValues(alpha: 0.4)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          width: isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? const Color(0xFF00C853).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getSectionIcon(quest.section),
                  color: sectionColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.titleKey.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest.descriptionKey.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Points Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [const Color(0xFF00C853), const Color(0xFF00E676)]
                        : [const Color(0xFFFF9100), const Color(0xFFFFAB00)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${quest.pointsValue}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress Bar & Ratio
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? const Color(0xFF00C853) : sectionColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentCount / $targetCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? const Color(0xFF00C853) : null,
                ),
              ),
              const SizedBox(width: 8),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isCompleted ? const Color(0xFF00C853) : const Color(0xFFFF9100)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'quests.completed'.tr() : 'quests.in_progress'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF00C853) : const Color(0xFFFF9100),
                  ),
                ),
              ),
            ],
          ),
          // Diminishing returns note on repeat
          if (repeatCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9100).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFF9100),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'quests.diminishing_notice'.tr(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFF9100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
