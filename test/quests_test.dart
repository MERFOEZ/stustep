import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/quests/models/quest_model.dart';
import 'package:stustep/features/quests/models/quest_progress_model.dart';

void main() {
  group('Isolated Quests Feature Test Suite', () {
    test('QuestModel serialization and type checks', () {
      const quest = QuestModel(
        id: 'daily_lesson',
        type: 'daily',
        titleKey: 'quests.daily_lesson_title',
        descriptionKey: 'quests.daily_lesson_desc',
        section: 'courses',
        pointsValue: 15,
        targetCount: 1,
        actionType: 'complete_lesson',
      );

      expect(quest.id, 'daily_lesson');
      expect(quest.isDaily, true);
      expect(quest.isWeekly, false);
      expect(quest.pointsValue, 15);

      final map = quest.toMap();
      expect(map['titleKey'], 'quests.daily_lesson_title');
      expect(map['pointsValue'], 15);

      final fromMap = QuestModel.fromMap('daily_lesson', map);
      expect(fromMap.id, 'daily_lesson');
      expect(fromMap.actionType, 'complete_lesson');
    });

    test('QuestProgressModel calculations and status flags', () {
      const progressPending = QuestProgressModel(
        id: 'u1_weekly_5_days_2026-08-10',
        userId: 'u1',
        questId: 'weekly_5_days',
        dateOrWeekKey: '2026-08-10',
        currentCount: 3,
        targetCount: 5,
        status: 'pending',
      );

      expect(progressPending.isCompleted, false);
      expect(progressPending.progressRatio, 0.6);

      const progressCompleted = QuestProgressModel(
        id: 'u1_weekly_5_days_2026-08-10',
        userId: 'u1',
        questId: 'weekly_5_days',
        dateOrWeekKey: '2026-08-10',
        currentCount: 5,
        targetCount: 5,
        status: 'completed',
        pointsAwarded: 50,
      );

      expect(progressCompleted.isCompleted, true);
      expect(progressCompleted.progressRatio, 1.0);
      expect(progressCompleted.pointsAwarded, 50);

      final map = progressCompleted.toMap();
      expect(map['status'], 'completed');
      expect(map['pointsAwarded'], 50);

      final fromMap = QuestProgressModel.fromMap('u1_weekly_5_days_2026-08-10', map);
      expect(fromMap.isCompleted, true);
      expect(fromMap.pointsAwarded, 50);
    });
  });
}
