/// نموذج تقدّم المستخدم في مهمة معينة.
class UserQuestProgressModel {
  final String id;
  final String userId;
  final String questId;
  final String dateOrWeekKey;
  final int currentCount;
  final int targetCount;
  final String status; // 'pending' | 'in_progress' | 'completed'
  final int pointsAwarded;
  final int repeatCount;

  const UserQuestProgressModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.dateOrWeekKey,
    this.currentCount = 0,
    required this.targetCount,
    this.status = 'pending',
    this.pointsAwarded = 0,
    this.repeatCount = 0,
  });

  bool get isCompleted => status == 'completed' || currentCount >= targetCount;
  double get progressRatio => targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  factory UserQuestProgressModel.fromMap(String id, Map<String, dynamic> map) {
    return UserQuestProgressModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      questId: map['questId'] as String? ?? '',
      dateOrWeekKey: map['date'] as String? ?? map['weekStartDate'] as String? ?? '',
      currentCount: (map['currentCount'] as num?)?.toInt() ?? 0,
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? 'pending',
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ?? 0,
      repeatCount: (map['repeatCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'questId': questId,
      'date': dateOrWeekKey,
      'currentCount': currentCount,
      'targetCount': targetCount,
      'status': status,
      'pointsAwarded': pointsAwarded,
      'repeatCount': repeatCount,
    };
  }
}
