import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج سجل الدعوة في تطبيق Flutter.
class ReferralModel {
  final String id;
  final String referrerId;
  final String referredId;
  final String status; // 'pending' | 'activated' | 'rewarded' | 'suspicious' | 'expired'
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? rewardedAt;
  final String? fraudReason;

  const ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.status,
    required this.createdAt,
    this.activatedAt,
    this.rewardedAt,
    this.fraudReason,
  });

  bool get isPending => status == 'pending';
  bool get isActivated => status == 'activated';
  bool get isRewarded => status == 'rewarded';
  bool get isSuspicious => status == 'suspicious';
  bool get isExpired => status == 'expired';

  factory ReferralModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReferralModel(
      id: id,
      referrerId: map['referrerId'] as String? ?? '',
      referredId: map['referredId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: parseDate(map['createdAt']),
      activatedAt: map['activatedAt'] != null ? parseDate(map['activatedAt']) : null,
      rewardedAt: map['rewardedAt'] != null ? parseDate(map['rewardedAt']) : null,
      fraudReason: map['fraudReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrerId': referrerId,
      'referredId': referredId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'activatedAt': activatedAt?.toIso8601String(),
      'rewardedAt': rewardedAt?.toIso8601String(),
      'fraudReason': fraudReason,
    };
  }
}
