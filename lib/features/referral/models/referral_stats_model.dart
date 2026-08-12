import 'referral_model.dart';

/// نموذج إحصائيات نظام الدعوة للمستخدم الحالي.
class ReferralStatsModel {
  final String referralCode;
  final String referralLink;
  final int totalInvited;
  final int activeReferrals;
  final int totalPointsEarned;
  final List<ReferralModel> referrals;

  const ReferralStatsModel({
    required this.referralCode,
    required this.referralLink,
    this.totalInvited = 0,
    this.activeReferrals = 0,
    this.totalPointsEarned = 0,
    this.referrals = const [],
  });

  factory ReferralStatsModel.fromMap(Map<String, dynamic> map) {
    final rawList = (map['referrals'] as List<dynamic>?) ?? [];
    final referrals = rawList
        .map((item) => ReferralModel.fromMap(
              (item as Map)['id']?.toString() ?? '',
              Map<String, dynamic>.from(item),
            ))
        .toList();

    return ReferralStatsModel(
      referralCode: map['referralCode'] as String? ?? '',
      referralLink: map['referralLink'] as String? ?? '',
      totalInvited: (map['totalInvited'] as num?)?.toInt() ?? referrals.length,
      activeReferrals: (map['activeReferrals'] as num?)?.toInt() ?? 0,
      totalPointsEarned: (map['totalPointsEarned'] as num?)?.toInt() ?? 0,
      referrals: referrals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referralCode': referralCode,
      'referralLink': referralLink,
      'totalInvited': totalInvited,
      'activeReferrals': activeReferrals,
      'totalPointsEarned': totalPointsEarned,
      'referrals': referrals.map((r) => r.toMap()).toList(),
    };
  }
}
