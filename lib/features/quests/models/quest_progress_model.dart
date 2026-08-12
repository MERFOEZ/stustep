import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج تقدم المستخدم في مهمة معينة (يومية أو أسبوعية).
class QuestProgressModel {
  final String id;
  final String userId;
  final String questId;
  final String dateOrWeekKey;
  final int currentCount;
  final int targetCount;
  final String status; // 'pending' | 'completed'
  final int pointsAwarded;
  final int repeatCount;
  final DateTime? updatedAt;

  const QuestProgressModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.dateOrWeekKey,
    this.currentCount = 0,
    this.targetCount = 1,
    this.status = 'pending',
    this.pointsAwarded = 0,
    this.repeatCount = 0,
    this.updatedAt,
  });

  bool get isCompleted => status == 'completed';
  double get progressRatio => targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  factory QuestProgressModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return QuestProgressModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      questId: map['questId'] as String? ?? '',
      dateOrWeekKey: (map['date'] ?? map['weekStartDate'] ?? '') as String,
      currentCount: (map['currentCount'] ?? map['currentProgress'] as num?)?.toInt() ?? 0,
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? 'pending',
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ?? 0,
      repeatCount: (map['repeatCount'] as num?)?.toInt() ?? 0,
      updatedAt: parseDate(map['updatedAt']),
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
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
