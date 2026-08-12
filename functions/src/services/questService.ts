import * as admin from 'firebase-admin';
import { DEFAULT_DAILY_QUESTS, DEFAULT_WEEKLY_QUESTS, QuestDefinition } from '../config/constants';
import { PointsService } from './pointsService';
import { ReferralService } from './referralService';

export interface ProcessActivityResult {
  success: boolean;
  awardedPoints: number;
  completedQuests: string[];
  totalPoints: number;
  weeklyPoints: number;
  currentStreak: number;
  streakIncremented: boolean;
  message: string;
}

export class QuestService {
  private db: admin.firestore.Firestore;
  private pointsService: PointsService;
  private referralService?: ReferralService;

  constructor(db: admin.firestore.Firestore, pointsService: PointsService, referralService?: ReferralService) {
    this.db = db;
    this.pointsService = pointsService;
    this.referralService = referralService;
  }

  /**
   * Seeds default daily and weekly quests if not present.
   */
  public async seedDefaultQuests(): Promise<void> {
    const batch = this.db.batch();

    for (const quest of DEFAULT_DAILY_QUESTS) {
      const ref = this.db.collection('dailyQuests').doc(quest.id);
      batch.set(ref, quest, { merge: true });
    }

    for (const quest of DEFAULT_WEEKLY_QUESTS) {
      const ref = this.db.collection('weeklyQuests').doc(quest.id);
      batch.set(ref, quest, { merge: true });
    }

    await batch.commit();
  }

  /**
   * Fetches active daily quests from Firestore (or fallback to defaults).
   */
  public async getActiveDailyQuests(): Promise<QuestDefinition[]> {
    const snap = await this.db.collection('dailyQuests').where('isActive', '==', true).get();
    if (snap.empty) {
      return DEFAULT_DAILY_QUESTS;
    }
    return snap.docs.map((d) => d.data() as QuestDefinition);
  }

  /**
   * Fetches active weekly quests from Firestore (or fallback to defaults).
   */
  public async getActiveWeeklyQuests(): Promise<QuestDefinition[]> {
    const snap = await this.db.collection('weeklyQuests').where('isActive', '==', true).get();
    if (snap.empty) {
      return DEFAULT_WEEKLY_QUESTS;
    }
    return snap.docs.map((d) => d.data() as QuestDefinition);
  }

  /**
   * Processes a client-reported activity securely:
   * 1. Matches active daily quests with actionType.
   * 2. Evaluates daily progress & diminishing returns.
   * 3. Matches active weekly quests.
   * 4. Awards points and updates user streaks atomically.
   */
  public async processActivity(
    userId: string,
    actionType: string,
    referenceId?: string,
    metadata?: Record<string, any>
  ): Promise<ProcessActivityResult> {
    const todayKey = PointsService.getTodayDateKey();
    const weekStartKey = PointsService.getWeekStartDateKey();

    const dailyQuests = await this.getActiveDailyQuests();
    const weeklyQuests = await this.getActiveWeeklyQuests();

    const matchingDaily = dailyQuests.filter((q) => q.actionType === actionType);
    const matchingWeekly = weeklyQuests.filter((q) => q.actionType === actionType);

    let totalPointsToAward = 0;
    const completedQuests: string[] = [];

    // 1. Process Daily Quests
    for (const quest of matchingDaily) {
      const progressId = `${userId}_${quest.id}_${todayKey}`;
      const progressRef = this.db.collection('userDailyQuestProgress').doc(progressId);
      const progressDoc = await progressRef.get();

      if (!progressDoc.exists) {
        // First completion today: full points
        const points = quest.pointsValue;
        totalPointsToAward += points;
        completedQuests.push(quest.id);

        await progressRef.set({
          id: progressId,
          userId,
          questId: quest.id,
          date: todayKey,
          currentCount: 1,
          targetCount: quest.targetCount,
          status: 'completed',
          pointsAwarded: points,
          repeatCount: 0,
          updatedAt: admin.firestore.Timestamp.now(),
        });
      } else {
        // Repeated completion today: apply diminishing returns
        const data = progressDoc.data() || {};
        const repeatCount = (data.repeatCount || 0) + 1;
        const diminishingPoints = this.pointsService.calculateDiminishingPoints(
          quest.pointsValue,
          repeatCount
        );

        totalPointsToAward += diminishingPoints;

        await progressRef.update({
          currentCount: admin.firestore.FieldValue.increment(1),
          repeatCount: repeatCount,
          pointsAwarded: admin.firestore.FieldValue.increment(diminishingPoints),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      }
    }

    // 2. Process Weekly Quests
    for (const quest of matchingWeekly) {
      const progressId = `${userId}_${quest.id}_${weekStartKey}`;
      const progressRef = this.db.collection('userWeeklyQuestProgress').doc(progressId);
      const progressDoc = await progressRef.get();

      if (!progressDoc.exists) {
        const isComplete = 1 >= quest.targetCount;
        const points = isComplete ? quest.pointsValue : 0;
        if (isComplete) {
          totalPointsToAward += points;
          completedQuests.push(quest.id);
        }

        await progressRef.set({
          id: progressId,
          userId,
          questId: quest.id,
          weekStartDate: weekStartKey,
          currentCount: 1,
          targetCount: quest.targetCount,
          status: isComplete ? 'completed' : 'in_progress',
          pointsAwarded: points,
          updatedAt: admin.firestore.Timestamp.now(),
        });
      } else {
        const data = progressDoc.data() || {};
        if (data.status !== 'completed') {
          const newCount = (data.currentCount || 0) + 1;
          const isNowComplete = newCount >= quest.targetCount;
          const points = isNowComplete ? quest.pointsValue : 0;

          if (isNowComplete) {
            totalPointsToAward += points;
            completedQuests.push(quest.id);
          }

          await progressRef.update({
            currentCount: newCount,
            status: isNowComplete ? 'completed' : 'in_progress',
            pointsAwarded: admin.firestore.FieldValue.increment(points),
            updatedAt: admin.firestore.Timestamp.now(),
          });
        }
      }
    }

    // Fallback: If activity doesn't match any quest directly, give base participation points (e.g. 5)
    if (totalPointsToAward === 0 && matchingDaily.length === 0 && matchingWeekly.length === 0) {
      totalPointsToAward = 5;
    }

    // 3. Atomically award total points and update user profile & streak
    const awardResult = await this.pointsService.awardPoints(
      userId,
      Math.max(1, totalPointsToAward),
      `activity_${actionType}`,
      referenceId,
      { actionType, ...metadata, completedQuests }
    );

    // 4. Check Referral Milestones (Activation & Retention)
    if (this.referralService) {
      try {
        await this.referralService.evaluateReferralActivation(userId);
        await this.referralService.evaluateReferralRetention(userId, awardResult.currentStreak);
      } catch (e) {
        admin.firestore().collection('systemLogs').add({
          type: 'referral_eval_error',
          userId,
          error: String(e),
          timestamp: admin.firestore.Timestamp.now(),
        });
      }
    }

    return {
      success: true,
      awardedPoints: awardResult.awardedAmount,
      completedQuests,
      totalPoints: awardResult.totalPoints,
      weeklyPoints: awardResult.weeklyPoints,
      currentStreak: awardResult.currentStreak,
      streakIncremented: awardResult.streakIncremented,
      message: 'Activity recorded and points awarded successfully',
    };
  }
}
