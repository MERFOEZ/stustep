/// StuStep — Conversation model
library;

import 'package:stustep/features/saie_core/models/chat_message_model.dart';
import 'package:stustep/features/saie_core/models/user_role.dart';

/// A persistent conversation tied to one user and one assessment.
///
/// Key invariants:
///   - conversationId is globally unique (UUID v4)
///   - userId + assessmentId together identify the exact context
///   - messages are append-only (never mutated in place)
///
/// Multiple conversations per user are supported — each has its own
/// conversationId. The UI shows the latest one by default.
class Conversation {
  const Conversation({
    required this.conversationId,
    required this.userId,
    required this.assessmentId,
    required this.role,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
  });

  final String conversationId;
  final String userId;
  final String assessmentId;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessageModel> messages;

  bool get isEmpty => messages.isEmpty;
  int get messageCount => messages.length;

  Conversation addMessage(ChatMessageModel msg) => Conversation(
        conversationId: conversationId,
        userId: userId,
        assessmentId: assessmentId,
        role: role,
        createdAt: createdAt,
        lastMessageAt: msg.timestamp,
        messages: [...messages, msg],
      );

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        conversationId: json['conversation_id'] as String,
        userId: json['user_id'] as String,
        assessmentId: json['assessment_id'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.storageKey == json['role'],
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        messages: (json['messages'] as List<dynamic>)
            .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'user_id': userId,
        'assessment_id': assessmentId,
        'role': role.storageKey,
        'created_at': createdAt.toIso8601String(),
        'last_message_at': lastMessageAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}
