/// نموذج تعريف المهمة اليومية أو الأسبوعية.
class QuestModel {
  final String id;
  final String type; // 'daily' | 'weekly'
  final String titleKey;
  final String descriptionKey;
  final String section;
  final int pointsValue;
  final int targetCount;
  final String actionType;
  final bool isActive;

  const QuestModel({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.descriptionKey,
    required this.section,
    required this.pointsValue,
    required this.targetCount,
    required this.actionType,
    this.isActive = true,
  });

  factory QuestModel.fromMap(String id, Map<String, dynamic> map) {
    return QuestModel(
      id: id,
      type: map['type'] as String? ?? 'daily',
      titleKey: map['titleKey'] as String? ?? '',
      descriptionKey: map['descriptionKey'] as String? ?? '',
      section: map['section'] as String? ?? 'general',
      pointsValue: (map['pointsValue'] as num?)?.toInt() ?? 10,
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      actionType: map['actionType'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'section': section,
      'pointsValue': pointsValue,
      'targetCount': targetCount,
      'actionType': actionType,
      'isActive': isActive,
    };
  }
}
