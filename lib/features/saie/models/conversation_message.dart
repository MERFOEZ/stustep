/// SAIE — ConversationMessage Model
///
/// Represents a single message exchange in an assessment conversation.
/// Messages are the raw input/output log of the SAIE engine — not a chatbot.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationMessage
// ─────────────────────────────────────────────────────────────────────────────

/// A single turn in an assessment conversation.
///
/// Every message has a [role], [content], and [timestamp].
/// Engine messages may additionally carry a [linkedQuestionId] and
/// [inferredIntentType] derived from NLU processing of student messages.
final class ConversationMessage extends Equatable {
  /// Unique identifier for this message.
  final String id;

  /// The role of the sender.
  final MessageRole role;

  /// The text content of the message.
  final String content;

  /// UTC timestamp when this message was created.
  final DateTime timestamp;

  /// ID of the [Question] this message is a response to (if any).
  final String? linkedQuestionId;

  /// The intent inferred from this message (if role is [MessageRole.student]).
  final IntentType? inferredIntent;

  /// IDs of [Evidence] records derived from this message (if any).
  final List<String> derivedEvidenceIds;

  /// Whether this message has been processed by the reasoning engine.
  final bool isProcessed;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.linkedQuestionId,
    this.inferredIntent,
    this.derivedEvidenceIds = const [],
    this.isProcessed = false,
  });

  /// Creates a [ConversationMessage] from a decoded JSON map.
  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: json['id'] as String,
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        linkedQuestionId: json['linked_question_id'] as String?,
        inferredIntent: json['inferred_intent'] != null
            ? IntentType.values.byName(json['inferred_intent'] as String)
            : null,
        derivedEvidenceIds:
            (json['derived_evidence_ids'] as List<dynamic>?)?.cast<String>() ??
                const [],
        isProcessed: json['is_processed'] as bool? ?? false,
      );

  /// Serializes this [ConversationMessage] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    if (linkedQuestionId != null) 'linked_question_id': linkedQuestionId,
    if (inferredIntent != null) 'inferred_intent': inferredIntent!.name,
    if (derivedEvidenceIds.isNotEmpty)
      'derived_evidence_ids': derivedEvidenceIds,
    'is_processed': isProcessed,
  };

  /// Returns a copy of this [ConversationMessage] with specified fields replaced.
  ConversationMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    String? linkedQuestionId,
    IntentType? inferredIntent,
    List<String>? derivedEvidenceIds,
    bool? isProcessed,
  }) => ConversationMessage(
    id: id ?? this.id,
    role: role ?? this.role,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    linkedQuestionId: linkedQuestionId ?? this.linkedQuestionId,
    inferredIntent: inferredIntent ?? this.inferredIntent,
    derivedEvidenceIds: derivedEvidenceIds ?? this.derivedEvidenceIds,
    isProcessed: isProcessed ?? this.isProcessed,
  );

  /// Returns `true` if this message is from the student.
  bool get isStudent => role == MessageRole.student;

  /// Returns `true` if this message is from the engine.
  bool get isEngine => role == MessageRole.engine;

  @override
  List<Object?> get props => [id, role, content, timestamp];

  @override
  String toString() =>
      'ConversationMessage(id: $id, role: ${role.name}, '
      'processed: $isProcessed)';
}
