import * as admin from 'firebase-admin';
import { LEADERBOARD_CONFIG, LEADERBOARD_TIERS, LeaderboardTier } from '../config/constants';
import { PointsService } from './pointsService';

export interface LeaderboardMember {
  userId: string;
  name: string;
  photoUrl?: string;
  weeklyPoints: number;
  totalPoints: number;
  currentStreak: number;
  tierLevel: LeaderboardTier;
  rank?: number;
}

export class LeaderboardService {
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
  }

  /**
   * Ensures the user belongs to a weekly group of 20-30 members for their tier.
   */
  public async ensureUserInGroup(userId: string): Promise<string> {
    const weekStartKey = PointsService.getWeekStartDateKey();
    const userDoc = await this.db.collection('users').doc(userId).get();
    const userData = userDoc.data() || {};
    const tier: LeaderboardTier = userData.tierLevel || 'bronze';

    if (userData.leaderboardGroupId && userData.leaderboardWeekStart === weekStartKey) {
      return userData.leaderboardGroupId;
    }

    // Find an open group in this tier with fewer than GROUP_MAX_SIZE members
    const openGroupsSnap = await this.db
      .collection('leaderboardGroups')
      .where('weekStartDate', '==', weekStartKey)
      .where('tierLevel', '==', tier)
      .where('memberCount', '<', LEADERBOARD_CONFIG.GROUP_MAX_SIZE)
      .limit(1)
      .get();

    let groupId: string;

    if (!openGroupsSnap.empty) {
      const groupDoc = openGroupsSnap.docs[0];
      groupId = groupDoc.id;

      await groupDoc.ref.update({
        memberIds: admin.firestore.FieldValue.arrayUnion(userId),
        memberCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.Timestamp.now(),
      });
    } else {
      // Create a new group
      const newGroupRef = this.db.collection('leaderboardGroups').doc();
      groupId = newGroupRef.id;

      await newGroupRef.set({
        id: groupId,
        tierLevel: tier,
        weekStartDate: weekStartKey,
        memberIds: [userId],
        memberCount: 1,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }

    // Update user's assigned group
    await this.db.collection('users').doc(userId).set(
      {
        leaderboardGroupId: groupId,
        leaderboardWeekStart: weekStartKey,
        tierLevel: tier,
      },
      { merge: true }
    );

    return groupId;
  }

  /**
   * Retrieves members of a leaderboard group sorted by weeklyPoints descending.
   */
  public async getGroupLeaderboard(
    groupId: string,
    limit: number = 30,
    startAfterPoints?: number
  ): Promise<{ members: LeaderboardMember[]; weekStartDate: string; tierLevel: string }> {
    const groupDoc = await this.db.collection('leaderboardGroups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw new Error('Leaderboard group not found');
    }

    const groupData = groupDoc.data() || {};
    const memberIds: string[] = groupData.memberIds || [];

    if (memberIds.length === 0) {
      return {
        members: [],
        weekStartDate: groupData.weekStartDate || PointsService.getWeekStartDateKey(),
        tierLevel: groupData.tierLevel || 'bronze',
      };
    }

    // Fetch user profiles for group members in chunks of 10 for Firestore 'in' limitation
    const members: LeaderboardMember[] = [];
    for (let i = 0; i < memberIds.length; i += 10) {
      const chunk = memberIds.slice(i, i + 10);
      const usersSnap = await this.db
        .collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
        .get();

      usersSnap.docs.forEach((doc) => {
        const u = doc.data();
        members.push({
          userId: doc.id,
          name: u.name || 'Student',
          photoUrl: u.photoUrl || u.profileImage || null,
          weeklyPoints: u.weeklyPoints || 0,
          totalPoints: u.totalPoints || 0,
          currentStreak: u.currentStreak || 0,
          tierLevel: u.tierLevel || groupData.tierLevel || 'bronze',
        });
      });
    }

    // Sort by weeklyPoints descending, then totalPoints descending
    members.sort((a, b) => b.weeklyPoints - a.weeklyPoints || b.totalPoints - a.totalPoints);

    // Assign rank 1-indexed
    members.forEach((m, idx) => {
      m.rank = idx + 1;
    });

    let result = members;
    if (startAfterPoints !== undefined) {
      const startIndex = result.findIndex((m) => m.weeklyPoints < startAfterPoints);
      if (startIndex !== -1) {
        result = result.slice(startIndex);
      }
    }

    return {
      members: result.slice(0, limit),
      weekStartDate: groupData.weekStartDate,
      tierLevel: groupData.tierLevel,
    };
  }

  /**
   * Weekly scheduled function to process all leaderboard groups:
   * - Top 7 promoted to next tier
   * - Bottom 5 demoted to previous tier
   * - Resets weekly points
   */
  public async processWeeklyReset(): Promise<void> {
    const previousWeekStart = PointsService.getWeekStartDateKey();
    const groupsSnap = await this.db
      .collection('leaderboardGroups')
      .where('weekStartDate', '==', previousWeekStart)
      .get();

    for (const groupDoc of groupsSnap.docs) {
      const groupData = groupDoc.data();
      const currentTierIndex = LEADERBOARD_TIERS.indexOf(groupData.tierLevel as LeaderboardTier);

      const { members } = await this.getGroupLeaderboard(groupDoc.id, 50);

      const batch = this.db.batch();

      members.forEach((member, index) => {
        let newTier: LeaderboardTier = member.tierLevel;

        if (index < LEADERBOARD_CONFIG.PROMOTION_COUNT) {
          // Promote if not already at highest tier (Diamond)
          if (currentTierIndex < LEADERBOARD_TIERS.length - 1) {
            newTier = LEADERBOARD_TIERS[currentTierIndex + 1];
          }
        } else if (index >= members.length - LEADERBOARD_CONFIG.DEMOTION_COUNT) {
          // Demote if not already at lowest tier (Bronze)
          if (currentTierIndex > 0) {
            newTier = LEADERBOARD_TIERS[currentTierIndex - 1];
          }
        }

        const userRef = this.db.collection('users').doc(member.userId);
        batch.set(
          userRef,
          {
            tierLevel: newTier,
            weeklyPoints: 0,
            leaderboardGroupId: null,
            leaderboardWeekStart: null,
            lastWeeklyRank: index + 1,
            lastWeeklyTier: member.tierLevel,
            updatedAt: admin.firestore.Timestamp.now(),
          },
          { merge: true }
        );
      });

      await batch.commit();
    }
  }
}
