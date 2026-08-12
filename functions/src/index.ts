import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { PointsService } from './services/pointsService';
import { QuestService } from './services/questService';
import { LeaderboardService } from './services/leaderboardService';
import { ReferralService } from './services/referralService';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const pointsService = new PointsService(db);
const referralService = new ReferralService(db, pointsService);
const questService = new QuestService(db, pointsService, referralService);
const leaderboardService = new LeaderboardService(db);

/**
 * 1. Callable Cloud Function: recordActivity
 * Main entry point for recording client activities securely.
 */
export const recordActivity = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { actionType, referenceId, metadata } = data || {};

  if (!actionType || typeof actionType !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'actionType is required');
  }

  try {
    // Ensure user has a referralCode assigned
    await referralService.ensureUserReferralCode(userId);

    // Ensure user is assigned to a leaderboard group
    await leaderboardService.ensureUserInGroup(userId);

    // Process activity & award points
    const result = await questService.processActivity(userId, actionType, referenceId, metadata);
    return result;
  } catch (error: any) {
    functions.logger.error('Error recording activity:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to record activity');
  }
});

/**
 * 2. Callable Cloud Function: getLeaderboard
 * Fetches user's current leaderboard group standings.
 */
export const getLeaderboard = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { limit = 30, startAfterPoints } = data || {};

  try {
    const groupId = await leaderboardService.ensureUserInGroup(userId);
    const result = await leaderboardService.getGroupLeaderboard(groupId, limit, startAfterPoints);
    return {
      groupId,
      ...result,
    };
  } catch (error: any) {
    functions.logger.error('Error fetching leaderboard:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to fetch leaderboard');
  }
});

/**
 * 3. Callable Cloud Function: applyReferralCode
 * Applies an invitation code during or after registration with anti-fraud safeguards.
 */
export const applyReferralCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const referredUserId = context.auth.uid;
  const { referralCode, deviceId } = data || {};
  const userEmail = context.auth.token.email;
  const ipAddress = context.rawRequest?.ip;

  if (!referralCode || typeof referralCode !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'referralCode is required');
  }

  try {
    const result = await referralService.applyReferralCode({
      referredUserId,
      referralCode,
      deviceId,
      ipAddress,
      userEmail,
    });
    return result;
  } catch (error: any) {
    functions.logger.error('Error applying referral code:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to apply referral code');
  }
});

/**
 * 4. Callable Cloud Function: getReferralStats
 * Fetches referral code, link, invited friends list, and total earnings.
 */
export const getReferralStats = functions.https.onCall(async (_, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;

  try {
    const stats = await referralService.getReferralStats(userId);
    return stats;
  } catch (error: any) {
    functions.logger.error('Error getting referral stats:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to get referral stats');
  }
});

/**
 * 5. Callable Cloud Function: seedDefaultQuests
 * Populates Firestore with default daily and weekly quests.
 */
export const seedDefaultQuests = functions.https.onCall(async (_, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    await questService.seedDefaultQuests();
    return { success: true, message: 'Default quests successfully seeded in Firestore' };
  } catch (error: any) {
    functions.logger.error('Error seeding quests:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to seed quests');
  }
});

/**
 * 6. Firestore Trigger: onUserCreated
 * Automatically generates and assigns unique referralCode when a new user document is created.
 */
export const onUserCreated = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const data = snap.data();

    if (!data.referralCode) {
      try {
        await referralService.ensureUserReferralCode(userId);
        functions.logger.info(`Assigned referralCode to new user: ${userId}`);
      } catch (error) {
        functions.logger.error(`Failed to assign referralCode to user ${userId}:`, error);
      }
    }
  });

/**
 * 7. Scheduled Cloud Function: dailyMidnightReset
 * Runs daily at midnight UTC: resets daily quests and expires referrals older than 7 days without activation.
 */
export const dailyMidnightReset = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    functions.logger.info('Running dailyMidnightReset...');
    try {
      await questService.seedDefaultQuests();

      // Check and expire unactivated referrals older than 7 days
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 7);

      const expiredSnap = await db
        .collection('referrals')
        .where('status', '==', 'pending')
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
        .get();

      const batch = db.batch();
      expiredSnap.docs.forEach((doc) => {
        batch.update(doc.ref, { status: 'expired' });
      });
      await batch.commit();

      functions.logger.info(`Daily midnight reset completed. Expired ${expiredSnap.size} pending referrals.`);
    } catch (error) {
      functions.logger.error('Error in dailyMidnightReset:', error);
    }
  });

/**
 * 8. Scheduled Cloud Function: weeklyMondayLeaderboardReset
 * Runs every Monday at 00:00 UTC to evaluate tiers and reset weekly points.
 */
export const weeklyMondayLeaderboardReset = functions.pubsub
  .schedule('0 0 * * 1')
  .timeZone('UTC')
  .onRun(async () => {
    functions.logger.info('Running weeklyMondayLeaderboardReset...');
    try {
      await leaderboardService.processWeeklyReset();
      functions.logger.info('Weekly leaderboard reset and promotions completed successfully');
    } catch (error) {
      functions.logger.error('Error in weeklyMondayLeaderboardReset:', error);
    }
  });
