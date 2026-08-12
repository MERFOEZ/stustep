/// نموذج عنصر متنافس في لوحة المتصدرين.
class LeaderboardEntryModel {
  final String userId;
  final String name;
  final String? photoUrl;
  final int weeklyPoints;
  final int totalPoints;
  final int currentStreak;
  final String tierLevel;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntryModel({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.weeklyPoints,
    required this.totalPoints,
    required this.currentStreak,
    required this.tierLevel,
    required this.rank,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final uid = map['userId'] as String? ?? '';
    return LeaderboardEntryModel(
      userId: uid,
      name: map['name'] as String? ?? 'Student',
      photoUrl: map['photoUrl'] as String?,
      weeklyPoints: (map['weeklyPoints'] as num?)?.toInt() ?? 0,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      tierLevel: map['tierLevel'] as String? ?? 'bronze',
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      isCurrentUser: currentUserId != null && uid == currentUserId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'weeklyPoints': weeklyPoints,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'tierLevel': tierLevel,
      'rank': rank,
    };
  }
}
