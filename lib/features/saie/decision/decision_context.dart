/// SAIE — DecisionContext
///
/// The fully assembled input package passed to the [CognitiveDecisionEngine]
/// for every incoming message. Bundles the raw message, its structural
/// analysis, and the full conversation context into a single immutable unit.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DecisionContext
// ─────────────────────────────────────────────────────────────────────────────

/// The complete, immutable input to the [CognitiveDecisionEngine].
///
/// Created once per student message. The engine never modifies this object;
/// it only reads from it to produce a [DecisionResult].
final class DecisionContext extends Equatable {
  /// The raw message text from the student.
  final String rawMessage;

  /// The structural analysis of the raw message.
  final MessageAnalysis analysis;

  /// The full conversation context at the time of this message.
  final ConversationContext conversationContext;

  /// A unique request ID for tracing this decision.
  final String requestId;

  /// UTC timestamp when this context was assembled.
  final DateTime createdAt;

  const DecisionContext({
    required this.rawMessage,
    required this.analysis,
    required this.conversationContext,
    required this.requestId,
    required this.createdAt,
  });

  DecisionContext copyWith({
    String? rawMessage,
    MessageAnalysis? analysis,
    ConversationContext? conversationContext,
    String? requestId,
    DateTime? createdAt,
  }) => DecisionContext(
    rawMessage: rawMessage ?? this.rawMessage,
    analysis: analysis ?? this.analysis,
    conversationContext: conversationContext ?? this.conversationContext,
    requestId: requestId ?? this.requestId,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [requestId, createdAt];

  @override
  String toString() =>
      'DecisionContext(requestId: $requestId, '
      'msg: "${rawMessage.length > 40 ? "${rawMessage.substring(0, 40)}..." : rawMessage}")';
}
