import * as admin from 'firebase-admin';
import { PointsService } from './pointsService';

export interface ReferralRecord {
  id: string;
  referrerId: string;
  referredId: string;
  status: 'pending' | 'activated' | 'rewarded' | 'suspicious' | 'expired';
  createdAt: admin.firestore.Timestamp;
  activatedAt: admin.firestore.Timestamp | null;
  rewardedAt: admin.firestore.Timestamp | null;
  referrerDeviceId?: string | null;
  referredDeviceId?: string | null;
  referredEmail?: string | null;
  fraudReason?: string | null;
}

export interface ReferralStats {
  referralCode: string;
  referralLink: string;
  totalInvited: number;
  activeReferrals: number;
  totalPointsEarned: number;
  referrals: Array<{
    id: string;
    referredId: string;
    status: string;
    createdAt: string;
    activatedAt?: string | null;
    rewardedAt?: string | null;
  }>;
}

const DISPOSABLE_EMAIL_DOMAINS = new Set([
  'mailinator.com',
  'tempmail.com',
  '10minutemail.com',
  'guerrillamail.com',
  'throwawaymail.com',
  'yopmail.com',
  'yopmail.fr',
  'yopmail.net',
  'trashmail.com',
  'fakeinbox.com',
  'dispostable.com',
  'sharklasers.com',
  'getairmail.com',
  'mohmal.com',
  'crazymailing.com',
  'temp-mail.org',
  'emailondeck.com',
  'fakemailgenerator.com',
]);

export class ReferralService {
  private db: admin.firestore.Firestore;
  private pointsService: PointsService;

  constructor(db: admin.firestore.Firestore, pointsService: PointsService) {
    this.db = db;
    this.pointsService = pointsService;
  }

  /**
   * Generates a unique 6-8 character alphanumeric referral code.
   */
  public async generateUniqueReferralCode(): Promise<string> {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous 0/O, 1/I
    let isUnique = false;
    let code = '';

    while (!isUnique) {
      code = 'STU';
      for (let i = 0; i < 4; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }

      const existing = await this.db.collection('users').where('referralCode', '==', code).limit(1).get();
      if (existing.empty) {
        isUnique = true;
      }
    }

    return code;
  }

  /**
   * Ensures a user document has a referralCode assigned.
   */
  public async ensureUserReferralCode(userId: string): Promise<string> {
    const userRef = this.db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (userDoc.exists && userDoc.data()?.referralCode) {
      return userDoc.data()!.referralCode;
    }

    const referralCode = await this.generateUniqueReferralCode();
    await userRef.set({ referralCode }, { merge: true });
    return referralCode;
  }

  /**
   * Applies a referral code when a new user registers:
   * 1. Validates code and resolves referrer.
   * 2. Fraud prevention (Self-referral, Disposable email, Device/IP match, Monthly cap).
   * 3. Creates pending referral record.
   * 4. Awards 10 Welcome points to the new user.
   */
  public async applyReferralCode(params: {
    referredUserId: string;
    referralCode: string;
    deviceId?: string;
    ipAddress?: string;
    userEmail?: string;
  }): Promise<{ success: boolean; message: string; status: string }> {
    const { referredUserId, referralCode, deviceId, ipAddress, userEmail } = params;

    const cleanCode = referralCode.trim().toUpperCase();

    // 1. Resolve Referrer
    const referrerSnap = await this.db
      .collection('users')
      .where('referralCode', '==', cleanCode)
      .limit(1)
      .get();

    if (referrerSnap.empty) {
      return { success: false, message: 'كود الدعوة غير صالح', status: 'invalid_code' };
    }

    const referrerDoc = referrerSnap.docs[0];
    const referrerId = referrerDoc.id;
    const referrerData = referrerDoc.data() || {};

    // 2. Anti-Fraud Checks
    // Check 2.1: Self referral
    if (referrerId === referredUserId) {
      return { success: false, message: 'لا يمكنك استخدام كود الدعوة الخاص بك', status: 'self_referral' };
    }

    // Check 2.2: User already has a referrer
    const userRef = this.db.collection('users').doc(referredUserId);
    const userDoc = await userRef.get();
    if (userDoc.exists && userDoc.data()?.referredBy) {
      return { success: false, message: 'تم استخدام كود دعوة لهذا الحساب مسبقاً', status: 'already_referred' };
    }

    // Check 2.3: Disposable email
    if (userEmail) {
      const domain = userEmail.split('@')[1]?.toLowerCase();
      if (domain && DISPOSABLE_EMAIL_DOMAINS.has(domain)) {
        await this.logSuspiciousReferral(referrerId, referredUserId, 'disposable_email', { userEmail, domain });
        return { success: false, message: 'البريد الإلكتروني المستخدم غير مؤهل لنظام الدعوات', status: 'suspicious_email' };
      }
    }

    // Check 2.4: Device / IP fingerprint matching
    let isSuspicious = false;
    let fraudReason: string | null = null;

    if (deviceId && referrerData.lastDeviceId && deviceId === referrerData.lastDeviceId) {
      isSuspicious = true;
      fraudReason = 'device_match';
    } else if (ipAddress && referrerData.lastIpAddress && ipAddress === referrerData.lastIpAddress) {
      isSuspicious = true;
      fraudReason = 'ip_match';
    }

    if (isSuspicious) {
      await this.logSuspiciousReferral(referrerId, referredUserId, fraudReason || 'fingerprint_match', {
        deviceId,
        referrerDeviceId: referrerData.lastDeviceId,
        ipAddress,
      });

      const referralRef = this.db.collection('referrals').doc();
      await referralRef.set({
        id: referralRef.id,
        referrerId,
        referredId: referredUserId,
        status: 'suspicious',
        fraudReason,
        createdAt: admin.firestore.Timestamp.now(),
        activatedAt: null,
        rewardedAt: null,
        referrerDeviceId: referrerData.lastDeviceId || null,
        referredDeviceId: deviceId || null,
        referredEmail: userEmail || null,
      });

      await userRef.set({ referredBy: referrerId, lastDeviceId: deviceId, lastIpAddress: ipAddress }, { merge: true });

      return {
        success: true,
        message: 'تم ربط الحساب بنجاح',
        status: 'suspicious',
      };
    }

    // Check 2.5: Monthly cap check (Max 10 rewarded referrals per calendar month)
    const now = new Date();
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const monthlyCountSnap = await this.db
      .collection('referrals')
      .where('referrerId', '==', referrerId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(monthStart))
      .where('status', 'in', ['activated', 'rewarded'])
      .get();

    const monthlyCapExceeded = monthlyCountSnap.size >= 10;

    // 3. Create Referral Record
    const referralRef = this.db.collection('referrals').doc();
    const nowTimestamp = admin.firestore.Timestamp.now();

    await referralRef.set({
      id: referralRef.id,
      referrerId,
      referredId: referredUserId,
      status: monthlyCapExceeded ? 'cap_exceeded' : 'pending',
      createdAt: nowTimestamp,
      activatedAt: null,
      rewardedAt: null,
      referrerDeviceId: referrerData.lastDeviceId || null,
      referredDeviceId: deviceId || null,
      referredEmail: userEmail || null,
    });

    // Update referred user document
    await userRef.set(
      {
        referredBy: referrerId,
        referralId: referralRef.id,
        lastDeviceId: deviceId || null,
        lastIpAddress: ipAddress || null,
      },
      { merge: true }
    );

    // 4. Award Welcome Points (10 pts) to the newly registered student
    await this.pointsService.awardPoints(
      referredUserId,
      10,
      'referral_welcome',
      referralRef.id,
      { referrerId }
    );

    return {
      success: true,
      message: 'تم تفعيل كود الدعوة ومنح 10 نقاط ترحيبية بنجاح!',
      status: 'pending',
    };
  }

  /**
   * Evaluates Stage 1 (Activation):
   * When referred user completes first lesson + first AI chat within 7 days -> awards 30 points to referrer.
   */
  public async evaluateReferralActivation(referredUserId: string): Promise<void> {
    const referralSnap = await this.db
      .collection('referrals')
      .where('referredId', '==', referredUserId)
      .where('status', '==', 'pending')
      .limit(1)
      .get();

    if (referralSnap.empty) return;

    const referralDoc = referralSnap.docs[0];
    const referral = referralDoc.data() as ReferralRecord;

    // Check if within 7 days from creation
    const createdAt = referral.createdAt.toDate();
    const now = new Date();
    const diffDays = (now.getTime() - createdAt.getTime()) / (1000 * 3600 * 24);

    if (diffDays > 7) {
      await referralDoc.ref.update({ status: 'expired' });
      return;
    }

    // Check if user completed at least 1 lesson AND 1 AI chat
    const lessonSnap = await this.db
      .collection('pointsTransactions')
      .where('userId', '==', referredUserId)
      .where('source', '==', 'activity_complete_lesson')
      .limit(1)
      .get();

    const aiSnap = await this.db
      .collection('pointsTransactions')
      .where('userId', '==', referredUserId)
      .where('source', '==', 'activity_ai_chat_session')
      .limit(1)
      .get();

    if (!lessonSnap.empty && !aiSnap.empty) {
      const nowTimestamp = admin.firestore.Timestamp.now();
      await referralDoc.ref.update({
        status: 'activated',
        activatedAt: nowTimestamp,
      });

      // Award 30 points to the referrer
      await this.pointsService.awardPoints(
        referral.referrerId,
        30,
        'referral_activation',
        referral.id,
        { referredUserId }
      );
    }
  }

  /**
   * Evaluates Stage 2 (Retention):
   * When referred user maintains a 7-day streak -> awards 50 points to referrer.
   */
  public async evaluateReferralRetention(referredUserId: string, currentStreak: number): Promise<void> {
    if (currentStreak < 7) return;

    const referralSnap = await this.db
      .collection('referrals')
      .where('referredId', '==', referredUserId)
      .where('status', '==', 'activated')
      .limit(1)
      .get();

    if (referralSnap.empty) return;

    const referralDoc = referralSnap.docs[0];
    const referral = referralDoc.data() as ReferralRecord;

    const nowTimestamp = admin.firestore.Timestamp.now();
    await referralDoc.ref.update({
      status: 'rewarded',
      rewardedAt: nowTimestamp,
    });

    // Award 50 points to the referrer
    await this.pointsService.awardPoints(
      referral.referrerId,
      50,
      'referral_retention',
      referral.id,
      { referredUserId, currentStreak }
    );
  }

  /**
   * Fetches referral stats for a given user.
   */
  public async getReferralStats(userId: string): Promise<ReferralStats> {
    const referralCode = await this.ensureUserReferralCode(userId);
    const referralLink = `https://stustep.app/signup?ref=${referralCode}`;

    const referralsSnap = await this.db
      .collection('referrals')
      .where('referrerId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    let activeCount = 0;
    const referralsList: ReferralStats['referrals'] = [];

    referralsSnap.docs.forEach((d) => {
      const data = d.data();
      const status = data.status || 'pending';
      if (status === 'activated' || status === 'rewarded') {
        activeCount++;
      }

      referralsList.push({
        id: d.id,
        referredId: data.referredId || '',
        status,
        createdAt: data.createdAt?.toDate().toISOString() || new Date().toISOString(),
        activatedAt: data.activatedAt?.toDate().toISOString() || null,
        rewardedAt: data.rewardedAt?.toDate().toISOString() || null,
      });
    });

    // Calculate total points earned from referrals
    const txSnap = await this.db
      .collection('pointsTransactions')
      .where('userId', '==', userId)
      .where('source', 'in', ['referral_activation', 'referral_retention'])
      .get();

    let totalPoints = 0;
    txSnap.docs.forEach((t) => {
      totalPoints += (t.data().amount || 0);
    });

    return {
      referralCode,
      referralLink,
      totalInvited: referralsSnap.size,
      activeReferrals: activeCount,
      totalPointsEarned: totalPoints,
      referrals: referralsList,
    };
  }

  /**
   * Logs suspicious referral attempts for audit.
   */
  private async logSuspiciousReferral(
    referrerId: string,
    referredId: string,
    reason: string,
    details: Record<string, any>
  ): Promise<void> {
    await this.db.collection('suspiciousReferrals').add({
      referrerId,
      referredId,
      reason,
      details,
      timestamp: admin.firestore.Timestamp.now(),
    });
  }
}
