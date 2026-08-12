/// نموذج تعريف المهمة (يومية أو أسبوعية) المخزنة في Firestore.
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
    this.targetCount = 1,
    required this.actionType,
    this.isActive = true,
  });

  bool get isDaily => type == 'daily';
  bool get isWeekly => type == 'weekly';

  factory QuestModel.fromMap(String id, Map<String, dynamic> map) {
    return QuestModel(
      id: id,
      type: map['type'] as String? ?? 'daily',
      titleKey: map['titleKey'] as String? ?? '',
      descriptionKey: map['descriptionKey'] as String? ?? '',
      section: map['section'] as String? ?? 'home',
      pointsValue: (map['pointsValue'] as num?)?.toInt() ?? 0,
      targetCount: (map['targetCount'] as num?)?.toInt() ?? (map['targetValue'] as num?)?.toInt() ?? 1,
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
