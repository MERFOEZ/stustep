import * as admin from 'firebase-admin';

export interface AwardPointsResult {
  awardedAmount: number;
  totalPoints: number;
  weeklyPoints: number;
  currentStreak: number;
  streakIncremented: boolean;
  transactionId: string;
}

export class PointsService {
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
  }

  /**
   * Calculates diminishing returns for repeated activities.
   * 1st completion: 100%
   * 2nd completion: 20% (min 1)
   * 3rd+ completion: 1 point
   */
  public calculateDiminishingPoints(basePoints: number, previousAttemptsToday: number): number {
    if (previousAttemptsToday === 0) {
      return basePoints;
    } else if (previousAttemptsToday === 1) {
      return Math.max(1, Math.floor(basePoints * 0.20));
    } else {
      return 1;
    }
  }

  /**
   * Helper to format UTC Date as YYYY-MM-DD
   */
  public static getTodayDateKey(date: Date = new Date()): string {
    return date.toISOString().split('T')[0];
  }

  /**
   * Helper to get Monday UTC Date of the current week (YYYY-MM-DD)
   */
  public static getWeekStartDateKey(date: Date = new Date()): string {
    const d = new Date(date);
    const day = d.getUTCDay(); // 0 is Sunday, 1 is Monday
    const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
    d.setUTCDate(diff);
    return d.toISOString().split('T')[0];
  }

  /**
   * Atomically awards points, updates streak, and logs a verified audit transaction.
   */
  public async awardPoints(
    userId: string,
    amount: number,
    source: string,
    referenceId?: string,
    metadata?: Record<string, any>
  ): Promise<AwardPointsResult> {
    if (amount <= 0) {
      throw new Error('Points amount must be greater than zero');
    }

    const userRef = this.db.collection('users').doc(userId);
    const txRef = this.db.collection('pointsTransactions').doc();

    const now = admin.firestore.Timestamp.now();
    const todayKey = PointsService.getTodayDateKey();

    return await this.db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      let totalPoints = amount;
      let weeklyPoints = amount;
      let currentStreak = 1;
      let streakIncremented = false;
      let lastActivityDate: admin.firestore.Timestamp | null = null;
      let tierLevel = 'bronze';

      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        totalPoints = (userData.totalPoints || 0) + amount;
        weeklyPoints = (userData.weeklyPoints || 0) + amount;
        currentStreak = userData.currentStreak || 0;
        tierLevel = userData.tierLevel || 'bronze';

        if (userData.lastActivityDate) {
          lastActivityDate = userData.lastActivityDate;
          const lastDate = lastActivityDate!.toDate();
          const lastDateKey = PointsService.getTodayDateKey(lastDate);

          const yesterday = new Date();
          yesterday.setUTCDate(yesterday.getUTCDate() - 1);
          const yesterdayKey = PointsService.getTodayDateKey(yesterday);

          if (lastDateKey === todayKey) {
            // Already active today, maintain current streak
          } else if (lastDateKey === yesterdayKey) {
            // Active yesterday, increment streak
            currentStreak += 1;
            streakIncremented = true;
          } else {
            // Missed a day, reset streak to 1
            currentStreak = 1;
            streakIncremented = true;
          }
        } else {
          currentStreak = 1;
          streakIncremented = true;
        }
      }

      // Update user document
      transaction.set(
        userRef,
        {
          totalPoints,
          weeklyPoints,
          currentStreak,
          tierLevel,
          lastActivityDate: now,
          lastActiveDateKey: todayKey,
          updatedAt: now,
        },
        { merge: true }
      );

      // Create verified immutable transaction record
      transaction.set(txRef, {
        id: txRef.id,
        userId,
        amount,
        type: 'earn',
        source,
        referenceId: referenceId || null,
        verified: true,
        metadata: metadata || {},
        timestamp: now,
      });

      return {
        awardedAmount: amount,
        totalPoints,
        weeklyPoints,
        currentStreak,
        streakIncremented,
        transactionId: txRef.id,
      };
    });
  }
}
