import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/points/models/points_user_model.dart';
import 'package:stustep/features/points/models/quest_model.dart';
import 'package:stustep/features/points/models/user_quest_progress_model.dart';
import 'package:stustep/features/points/models/points_transaction_model.dart';
import 'package:stustep/features/leaderboard/models/leaderboard_entry_model.dart';

void main() {
  group('Gamification Models Test Suite', () {
    test('PointsUserModel creation and JSON map mapping', () {
      final now = DateTime.now();
      final model = PointsUserModel(
        userId: 'user_123',
        totalPoints: 250,
        weeklyPoints: 75,
        currentStreak: 5,
        tierLevel: 'gold',
        leaderboardGroupId: 'group_abc',
        lastActivityDate: now,
      );

      expect(model.userId, 'user_123');
      expect(model.totalPoints, 250);
      expect(model.weeklyPoints, 75);
      expect(model.currentStreak, 5);
      expect(model.tierLevel, 'gold');
      expect(model.leaderboardGroupId, 'group_abc');

      final map = model.toMap();
      expect(map['totalPoints'], 250);
      expect(map['tierLevel'], 'gold');

      final fromMap = PointsUserModel.fromMap('user_123', map);
      expect(fromMap.totalPoints, 250);
      expect(fromMap.currentStreak, 5);
      expect(fromMap.tierLevel, 'gold');
    });

    test('QuestModel & UserQuestProgressModel progress ratios and completion', () {
      const quest = QuestModel(
        id: 'daily_lesson_1',
        type: 'daily',
        titleKey: 'quests.complete_lesson_title',
        descriptionKey: 'quests.complete_lesson_desc',
        section: 'courses',
        pointsValue: 15,
        targetCount: 2,
        actionType: 'complete_lesson',
      );

      expect(quest.pointsValue, 15);
      expect(quest.targetCount, 2);

      const progressHalf = UserQuestProgressModel(
        id: 'prog_1',
        userId: 'u1',
        questId: 'daily_lesson_1',
        dateOrWeekKey: '2026-08-12',
        currentCount: 1,
        targetCount: 2,
      );

      expect(progressHalf.isCompleted, false);
      expect(progressHalf.progressRatio, 0.5);

      const progressComplete = UserQuestProgressModel(
        id: 'prog_2',
        userId: 'u1',
        questId: 'daily_lesson_1',
        dateOrWeekKey: '2026-08-12',
        currentCount: 2,
        targetCount: 2,
        status: 'completed',
        pointsAwarded: 15,
      );

      expect(progressComplete.isCompleted, true);
      expect(progressComplete.progressRatio, 1.0);
    });

    test('LeaderboardEntryModel ranks and current user indicator', () {
      const entry1 = LeaderboardEntryModel(
        userId: 'u1',
        name: 'Ahmed',
        weeklyPoints: 200,
        totalPoints: 1000,
        currentStreak: 12,
        tierLevel: 'gold',
        rank: 1,
      );

      const entry2 = LeaderboardEntryModel(
        userId: 'u2',
        name: 'Sara',
        weeklyPoints: 150,
        totalPoints: 800,
        currentStreak: 3,
        tierLevel: 'gold',
        rank: 2,
        isCurrentUser: true,
      );

      expect(entry1.rank, 1);
      expect(entry2.isCurrentUser, true);

      final list = [entry2, entry1];
      list.sort((a, b) => b.weeklyPoints.compareTo(a.weeklyPoints));

      expect(list.first.name, 'Ahmed');
      expect(list.last.name, 'Sara');
    });

    test('PointsTransactionModel verified audit logging', () {
      final tx = PointsTransactionModel(
        id: 'tx_999',
        userId: 'u1',
        amount: 25,
        type: 'earn',
        source: 'daily_quest',
        referenceId: 'daily_lesson_1',
        verified: true,
        timestamp: DateTime.now(),
      );

      expect(tx.verified, true);
      expect(tx.amount, 25);
      expect(tx.type, 'earn');
      expect(tx.source, 'daily_quest');
    });
  });
}
