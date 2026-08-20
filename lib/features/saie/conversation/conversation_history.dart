/// SAIE — ConversationHistory
///
/// Append-only, immutable log of all turns in a session.
/// Provides windowed access for the context engine.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationTurnRecord
// ─────────────────────────────────────────────────────────────────────────────

/// An extended record of a single conversation turn with metadata.
final class ConversationTurnRecord extends Equatable {
  final String turnId;
  final MessageRole role;
  final String content;
  final String? intentName;
  final bool wasAssessmentTurn;
  final bool wasInterruption;
  final bool wasClarification;
  final DateTime timestamp;

  const ConversationTurnRecord({
    required this.turnId,
    required this.role,
    required this.content,
    required this.wasAssessmentTurn,
    required this.wasInterruption,
    required this.wasClarification,
    required this.timestamp,
    this.intentName,
  });

  bool get isStudent => role == MessageRole.student;
  bool get isEngine => role == MessageRole.engine;

  factory ConversationTurnRecord.fromJson(Map<String, dynamic> json) =>
      ConversationTurnRecord(
        turnId: json['turn_id'] as String,
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        intentName: json['intent_name'] as String?,
        wasAssessmentTurn: json['was_assessment_turn'] as bool,
        wasInterruption: json['was_interruption'] as bool,
        wasClarification: json['was_clarification'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
    'turn_id': turnId,
    'role': role.name,
    'content': content,
    if (intentName != null) 'intent_name': intentName,
    'was_assessment_turn': wasAssessmentTurn,
    'was_interruption': wasInterruption,
    'was_clarification': wasClarification,
    'timestamp': timestamp.toIso8601String(),
  };

  ConversationTurnRecord copyWith({
    String? turnId,
    MessageRole? role,
    String? content,
    String? intentName,
    bool? wasAssessmentTurn,
    bool? wasInterruption,
    bool? wasClarification,
    DateTime? timestamp,
  }) => ConversationTurnRecord(
    turnId: turnId ?? this.turnId,
    role: role ?? this.role,
    content: content ?? this.content,
    intentName: intentName ?? this.intentName,
    wasAssessmentTurn: wasAssessmentTurn ?? this.wasAssessmentTurn,
    wasInterruption: wasInterruption ?? this.wasInterruption,
    wasClarification: wasClarification ?? this.wasClarification,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  List<Object?> get props => [turnId, role, timestamp];
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Append-only, immutable conversation log.
final class ConversationHistory extends Equatable {
  final String sessionId;
  final List<ConversationTurnRecord> turns;
  final DateTime startedAt;

  const ConversationHistory({
    required this.sessionId,
    required this.turns,
    required this.startedAt,
  });

  factory ConversationHistory.empty(String sessionId) => ConversationHistory(
    sessionId: sessionId,
    turns: const [],
    startedAt: DateTime.now().toUtc(),
  );

  /// Total turn count.
  int get length => turns.length;
  bool get isEmpty => turns.isEmpty;

  /// Appends a new turn.
  ConversationHistory append(ConversationTurnRecord turn) =>
      ConversationHistory(
        sessionId: sessionId,
        turns: [...turns, turn],
        startedAt: startedAt,
      );

  /// Returns the last [n] turns (context window).
  List<ConversationTurnRecord> window(int n) =>
      turns.length <= n ? turns : turns.sublist(turns.length - n);

  /// Returns all student turns only.
  List<ConversationTurnRecord> get studentTurns =>
      turns.where((t) => t.isStudent).toList();

  /// Returns all interruption turns.
  List<ConversationTurnRecord> get interruptions =>
      turns.where((t) => t.wasInterruption).toList();

  /// Returns the most recent student message content.
  String? get lastStudentMessage =>
      turns.reversed.where((t) => t.isStudent).cast<ConversationTurnRecord?>().firstOrNull?.content;

  /// Returns the most recent engine message content.
  String? get lastEngineMessage =>
      turns.reversed.where((t) => t.isEngine).cast<ConversationTurnRecord?>().firstOrNull?.content;

  factory ConversationHistory.fromJson(Map<String, dynamic> json) =>
      ConversationHistory(
        sessionId: json['session_id'] as String,
        turns: (json['turns'] as List<dynamic>)
            .map((e) =>
                ConversationTurnRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt: DateTime.parse(json['started_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'turns': turns.map((t) => t.toJson()).toList(),
    'started_at': startedAt.toIso8601String(),
  };

  ConversationHistory copyWith({
    String? sessionId,
    List<ConversationTurnRecord>? turns,
    DateTime? startedAt,
  }) => ConversationHistory(
    sessionId: sessionId ?? this.sessionId,
    turns: turns ?? this.turns,
    startedAt: startedAt ?? this.startedAt,
  );

  @override
  List<Object?> get props => [sessionId, turns.length];
}
