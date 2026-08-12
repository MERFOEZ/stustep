/// نموذج مجموعة المنافسة الأسبوعية (20-30 طالباً).
class LeaderboardGroupModel {
  final String id;
  final String tierLevel;
  final String weekStartDate;
  final List<String> memberIds;
  final int memberCount;

  const LeaderboardGroupModel({
    required this.id,
    required this.tierLevel,
    required this.weekStartDate,
    required this.memberIds,
    required this.memberCount,
  });

  factory LeaderboardGroupModel.fromMap(String id, Map<String, dynamic> map) {
    final members = (map['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return LeaderboardGroupModel(
      id: id,
      tierLevel: map['tierLevel'] as String? ?? 'bronze',
      weekStartDate: map['weekStartDate'] as String? ?? '',
      memberIds: members,
      memberCount: (map['memberCount'] as num?)?.toInt() ?? members.length,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tierLevel': tierLevel,
      'weekStartDate': weekStartDate,
      'memberIds': memberIds,
      'memberCount': memberCount,
    };
  }
}
