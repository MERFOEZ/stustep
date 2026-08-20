/// SAIE — ConversationContext
///
/// A complete, immutable snapshot of the conversation state at a single point
/// in time. Passed to all route handlers.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/conversation/conversation_language.dart';
import 'package:stustep/features/saie/conversation/conversation_memory.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/conversation/conversation_policy.dart';
import 'package:stustep/features/saie/decision/decision_result.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationContext
// ─────────────────────────────────────────────────────────────────────────────

/// Full conversation context passed to the router and all handlers.
final class ConversationContext extends Equatable {
  final String sessionId;
  final String studentId;

  /// The student's current incoming message (raw text).
  final String studentMessage;

  /// The DecisionEngine result for this turn.
  final DecisionResult decision;

  /// Active student cognitive profile.
  final StudentCognitiveProfile profile;

  /// Working memory (history, facts, summaries).
  final ConversationMemory memory;

  /// Current conversation phase.
  final ConversationPhase phase;

  /// Active language state.
  final ConversationLanguage language;

  /// Conversation policies.
  final ConversationPolicy policy;

  /// Currently active assessment question (null if not in assessment).
  final Question? activeQuestion;

  /// UTC timestamp for this turn.
  final DateTime turnAt;

  const ConversationContext({
    required this.sessionId,
    required this.studentId,
    required this.studentMessage,
    required this.decision,
    required this.profile,
    required this.memory,
    required this.phase,
    required this.language,
    required this.policy,
    required this.turnAt,
    this.activeQuestion,
  });

  bool get hasActiveQuestion => activeQuestion != null;
  bool get hasRecommendation => memory.recommendationReport != null;
  bool get isArabic => language.isArabic;
  bool get isEnglish => language.isEnglish;

  ConversationContext copyWith({
    String? sessionId,
    String? studentId,
    String? studentMessage,
    DecisionResult? decision,
    StudentCognitiveProfile? profile,
    ConversationMemory? memory,
    ConversationPhase? phase,
    ConversationLanguage? language,
    ConversationPolicy? policy,
    Question? activeQuestion,
    DateTime? turnAt,
  }) => ConversationContext(
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    studentMessage: studentMessage ?? this.studentMessage,
    decision: decision ?? this.decision,
    profile: profile ?? this.profile,
    memory: memory ?? this.memory,
    phase: phase ?? this.phase,
    language: language ?? this.language,
    policy: policy ?? this.policy,
    activeQuestion: activeQuestion ?? this.activeQuestion,
    turnAt: turnAt ?? this.turnAt,
  );

  @override
  List<Object?> get props => [sessionId, studentId, turnAt];
}
