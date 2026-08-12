import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/referral/models/referral_model.dart';
import 'package:stustep/features/referral/models/referral_stats_model.dart';
import 'package:stustep/core/services/referral_link_service.dart';

void main() {
  group('Referral System Test Suite', () {
    test('ReferralModel serialization and deserialization', () {
      final now = DateTime.now();
      final referral = ReferralModel(
        id: 'ref_123',
        referrerId: 'user_A',
        referredId: 'user_B',
        status: 'activated',
        createdAt: now,
        activatedAt: now,
      );

      expect(referral.id, 'ref_123');
      expect(referral.referrerId, 'user_A');
      expect(referral.referredId, 'user_B');
      expect(referral.status, 'activated');
      expect(referral.isActivated, true);
      expect(referral.isPending, false);
      expect(referral.isRewarded, false);

      final map = referral.toMap();
      expect(map['referrerId'], 'user_A');
      expect(map['status'], 'activated');

      final fromMap = ReferralModel.fromMap('ref_123', map);
      expect(fromMap.referrerId, 'user_A');
      expect(fromMap.referredId, 'user_B');
      expect(fromMap.status, 'activated');
    });

    test('ReferralStatsModel calculates metrics and list correctly', () {
      final now = DateTime.now();
      final r1 = ReferralModel(
        id: 'r1',
        referrerId: 'u1',
        referredId: 'u2',
        status: 'pending',
        createdAt: now,
      );
      final r2 = ReferralModel(
        id: 'r2',
        referrerId: 'u1',
        referredId: 'u3',
        status: 'activated',
        createdAt: now,
        activatedAt: now,
      );
      final r3 = ReferralModel(
        id: 'r3',
        referrerId: 'u1',
        referredId: 'u4',
        status: 'rewarded',
        createdAt: now,
        activatedAt: now,
        rewardedAt: now,
      );

      final stats = ReferralStatsModel(
        referralCode: 'STUP9A',
        referralLink: 'https://stustep.app/signup?ref=STUP9A',
        totalInvited: 3,
        activeReferrals: 2,
        totalPointsEarned: 80,
        referrals: [r1, r2, r3],
      );

      expect(stats.referralCode, 'STUP9A');
      expect(stats.totalInvited, 3);
      expect(stats.activeReferrals, 2);
      expect(stats.totalPointsEarned, 80);
      expect(stats.referrals.length, 3);

      final map = stats.toMap();
      expect(map['referralCode'], 'STUP9A');
      expect(map['totalPointsEarned'], 80);

      final fromMap = ReferralStatsModel.fromMap(map);
      expect(fromMap.referralCode, 'STUP9A');
      expect(fromMap.totalPointsEarned, 80);
      expect(fromMap.referrals.length, 3);
    });

    test('ReferralLinkService extracts ref code from URLs accurately', () {
      const url1 = 'https://stustep.app/signup?ref=STEP77X';
      final code1 = ReferralLinkService.extractReferralCodeFromUrl(url1);
      expect(code1, 'STEP77X');

      const url2 = 'stustep://signup?ref=ABC890';
      final code2 = ReferralLinkService.extractReferralCodeFromUrl(url2);
      expect(code2, 'ABC890');

      const url3 = 'https://stustep.app/home';
      final code3 = ReferralLinkService.extractReferralCodeFromUrl(url3);
      expect(code3, null);
    });
  });
}
