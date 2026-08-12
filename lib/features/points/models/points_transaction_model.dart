import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج سجل معاملة النقاط الموثقة في Firestore.
class PointsTransactionModel {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'earn' | 'spend'
  final String source; // 'daily_quest' | 'weekly_quest' | 'activity_...' | 'referral'
  final String? referenceId;
  final bool verified;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PointsTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.source,
    this.referenceId,
    this.verified = true,
    required this.timestamp,
    this.metadata = const {},
  });

  factory PointsTransactionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime ts = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    }

    return PointsTransactionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? 'earn',
      source: map['source'] as String? ?? 'activity',
      referenceId: map['referenceId'] as String?,
      verified: map['verified'] as bool? ?? true,
      timestamp: ts,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'source': source,
      'referenceId': referenceId,
      'verified': verified,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
