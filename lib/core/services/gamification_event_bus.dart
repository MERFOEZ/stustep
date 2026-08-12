import 'package:flutter/material.dart';
import '../../features/points/services/points_service.dart';
import '../../features/quests/services/quests_service.dart';
import '../../features/points/widgets/points_reward_dialog.dart';

enum GamificationAction {
  completeLesson('complete_lesson'),
  aiChatSession('ai_chat_session'),
  passQuiz('pass_quiz'),
  communityInteraction('community_interaction'),
  dailyLogin('daily_login'),
  completeCourse('complete_course'),
  useSection('use_section'),
  receiveLike('receive_like');

  final String key;
  const GamificationAction(this.key);
}

class GamificationEventBus {
  static final PointsService _pointsService = PointsService();
  static final QuestsService _questsService = QuestsService();

  /// Records an action, awards points via Cloud Function (with local dev fallback), and optionally shows celebratory popup.
  static Future<void> record(
    GamificationAction action, {
    BuildContext? context,
    String? referenceId,
    Map<String, dynamic>? metadata,
    bool showCelebration = false,
    String? celebrationTitle,
  }) async {
    try {
      // 1. Record activity in QuestsService
      final questResult = await _questsService.recordActivity(
        actionType: action.key,
        referenceId: referenceId,
        metadata: metadata,
      );

      // 2. Record activity in PointsService
      final pointsResult = await _pointsService.recordActivity(
        actionType: action.key,
        referenceId: referenceId,
        metadata: metadata,
      );

      final awardedPoints = (questResult['awardedPoints'] as num?)?.toInt() ??
          (pointsResult['awardedPoints'] as num?)?.toInt() ??
          0;

      if (showCelebration && context != null && context.mounted && awardedPoints > 0) {
        PointsRewardDialog.show(
          context,
          pointsEarned: awardedPoints,
          title: celebrationTitle ?? 'نشاط تعليمي جديد!',
        );
      }
    } catch (e) {
      debugPrint('GamificationEventBus Error: $e');
    }
  }
}
