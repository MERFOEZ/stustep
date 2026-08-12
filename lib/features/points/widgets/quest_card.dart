import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/quest_model.dart';
import '../models/user_quest_progress_model.dart';

class QuestCard extends StatelessWidget {
  final QuestModel quest;
  final UserQuestProgressModel? progress;
  final VoidCallback? onTap;

  const QuestCard({
    super.key,
    required this.quest,
    this.progress,
    this.onTap,
  });

  IconData _getIconForSection(String section) {
    switch (section) {
      case 'courses':
        return Icons.school_rounded;
      case 'ai_chat':
        return Icons.psychology_rounded;
      case 'academic_tools':
        return Icons.quiz_rounded;
      case 'groups':
        return Icons.forum_rounded;
      case 'home':
      default:
        return Icons.bolt_rounded;
    }
  }

  Color _getColorForSection(String section) {
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
        return const Color(0xFFFF4081);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = progress?.isCompleted ?? false;
    final currentCount = progress?.currentCount ?? 0;
    final targetCount = quest.targetCount;
    final progressRatio = progress?.progressRatio ?? (isCompleted ? 1.0 : 0.0);
    final isRepeated = (progress?.repeatCount ?? 0) > 0;

    final sectionColor = _getColorForSection(quest.section);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF00E676).withValues(alpha: 0.5)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? const Color(0xFF00E676).withValues(alpha: 0.08)
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sectionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getIconForSection(quest.section),
                    color: sectionColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.titleKey.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? (isDark ? Colors.white70 : Colors.black87)
                              : null,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
                        size: 14,
                        color: isCompleted ? const Color(0xFF00C853) : const Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${quest.pointsValue}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isCompleted ? const Color(0xFF00C853) : const Color(0xFFFFB300),
                        ),
                      ),
                    ],
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? const Color(0xFF00E676) : sectionColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isCompleted
                      ? 'quests.completed'.tr()
                      : '$currentCount / $targetCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF00C853) : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
            if (isRepeated) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'quests.diminishing_notice'.tr(),
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
