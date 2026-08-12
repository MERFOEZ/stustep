import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات نقاط المستخدم والـ Streak والـ Tier.
class PointsUserModel {
  final String userId;
  final int totalPoints;
  final int weeklyPoints;
  final int currentStreak;
  final String tierLevel;
  final String? leaderboardGroupId;
  final DateTime? lastActivityDate;

  const PointsUserModel({
    required this.userId,
    this.totalPoints = 0,
    this.weeklyPoints = 0,
    this.currentStreak = 0,
    this.tierLevel = 'bronze',
    this.leaderboardGroupId,
    this.lastActivityDate,
  });

  factory PointsUserModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? lastAct;
    if (map['lastActivityDate'] is Timestamp) {
      lastAct = (map['lastActivityDate'] as Timestamp).toDate();
    } else if (map['lastActivityDate'] is String) {
      lastAct = DateTime.tryParse(map['lastActivityDate']);
    }

    return PointsUserModel(
      userId: id,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      weeklyPoints: (map['weeklyPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      tierLevel: map['tierLevel'] as String? ?? 'bronze',
      leaderboardGroupId: map['leaderboardGroupId'] as String?,
      lastActivityDate: lastAct,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'weeklyPoints': weeklyPoints,
      'currentStreak': currentStreak,
      'tierLevel': tierLevel,
      'leaderboardGroupId': leaderboardGroupId,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
    };
  }

  PointsUserModel copyWith({
    int? totalPoints,
    int? weeklyPoints,
    int? currentStreak,
    String? tierLevel,
    String? leaderboardGroupId,
    DateTime? lastActivityDate,
  }) {
    return PointsUserModel(
      userId: userId,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      tierLevel: tierLevel ?? this.tierLevel,
      leaderboardGroupId: leaderboardGroupId ?? this.leaderboardGroupId,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}
