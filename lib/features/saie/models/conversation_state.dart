/// SAIE — ConversationState Model
///
/// Represents the complete, current state of a single assessment session.
/// This is the primary mutable aggregate managed by the SAIE engine.
/// It is reconstructed from persisted JSON and updated immutably after
/// each reasoning cycle.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/assessment_goal.dart';
import 'package:stustep/features/saie/models/confidence.dart';
import 'package:stustep/features/saie/models/conversation_message.dart';
import 'package:stustep/features/saie/models/evidence.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/models/recommendation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationState
// ─────────────────────────────────────────────────────────────────────────────

/// The complete, immutable snapshot of an active assessment session.
///
/// [ConversationState] is the single state atom the engine reads from and
/// writes to. Every engine operation returns a new [ConversationState] —
/// the previous state is never mutated.
final class ConversationState extends Equatable {
  /// Unique session identifier (UUID v4).
  final String sessionId;

  /// The student's unique profile ID (links back to [StudentProfile]).
  final String studentId;

  /// The goal this session is working toward.
  final AssessmentGoal goal;

  /// Current phase of the adaptive assessment.
  final AssessmentPhase phase;

  /// Current session lifecycle status.
  final SessionStatus status;

  /// Chronological log of all conversation turns.
  final List<ConversationMessage> messages;

  /// All evidence signals collected so far.
  final List<Evidence> collectedEvidence;

  /// IDs of questions already asked in this session.
  final List<String> askedQuestionIds;

  /// The current question waiting for a student response (if any).
  final Question? pendingQuestion;

  /// Engine's current confidence map per domain.
  /// Key: domain ID, Value: current [Confidence] for that domain.
  final Map<String, Confidence> domainConfidences;

  /// Recommendations produced at synthesis phase (empty until completed).
  final List<Recommendation> recommendations;

  /// UTC timestamp when this session was created.
  final DateTime createdAt;

  /// UTC timestamp of the last update to this state.
  final DateTime updatedAt;

  /// UTC timestamp when this session was completed (if applicable).
  final DateTime? completedAt;

  const ConversationState({
    required this.sessionId,
    required this.studentId,
    required this.goal,
    required this.phase,
    required this.status,
    required this.messages,
    required this.collectedEvidence,
    required this.askedQuestionIds,
    required this.domainConfidences,
    required this.recommendations,
    required this.createdAt,
    required this.updatedAt,
    this.pendingQuestion,
    this.completedAt,
  });

  /// Creates an [ConversationState] from a decoded JSON map.
  factory ConversationState.fromJson(Map<String, dynamic> json) =>
      ConversationState(
        sessionId: json['session_id'] as String,
        studentId: json['student_id'] as String,
        goal: AssessmentGoal.fromJson(
          json['goal'] as Map<String, dynamic>,
        ),
        phase: AssessmentPhase.values.byName(json['phase'] as String),
        status: SessionStatus.values.byName(json['status'] as String),
        messages: (json['messages'] as List<dynamic>)
            .map((m) =>
                ConversationMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        collectedEvidence: (json['collected_evidence'] as List<dynamic>)
            .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        askedQuestionIds:
            (json['asked_question_ids'] as List<dynamic>).cast<String>(),
        pendingQuestion: json['pending_question'] != null
            ? Question.fromJson(
                json['pending_question'] as Map<String, dynamic>,
              )
            : null,
        domainConfidences:
            (json['domain_confidences'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            Confidence.fromJson(v as Map<String, dynamic>),
          ),
        ),
        recommendations: (json['recommendations'] as List<dynamic>)
            .map((r) =>
                Recommendation.fromJson(r as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  /// Serializes this [ConversationState] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'student_id': studentId,
    'goal': goal.toJson(),
    'phase': phase.name,
    'status': status.name,
    'messages': messages.map((m) => m.toJson()).toList(),
    'collected_evidence': collectedEvidence.map((e) => e.toJson()).toList(),
    'asked_question_ids': askedQuestionIds,
    if (pendingQuestion != null) 'pending_question': pendingQuestion!.toJson(),
    'domain_confidences': domainConfidences.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
  };

  /// Returns a copy of this [ConversationState] with specified fields replaced.
  ConversationState copyWith({
    String? sessionId,
    String? studentId,
    AssessmentGoal? goal,
    AssessmentPhase? phase,
    SessionStatus? status,
    List<ConversationMessage>? messages,
    List<Evidence>? collectedEvidence,
    List<String>? askedQuestionIds,
    Question? pendingQuestion,
    bool clearPendingQuestion = false,
    Map<String, Confidence>? domainConfidences,
    List<Recommendation>? recommendations,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) => ConversationState(
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    goal: goal ?? this.goal,
    phase: phase ?? this.phase,
    status: status ?? this.status,
    messages: messages ?? this.messages,
    collectedEvidence: collectedEvidence ?? this.collectedEvidence,
    askedQuestionIds: askedQuestionIds ?? this.askedQuestionIds,
    pendingQuestion: clearPendingQuestion
        ? null
        : pendingQuestion ?? this.pendingQuestion,
    domainConfidences: domainConfidences ?? this.domainConfidences,
    recommendations: recommendations ?? this.recommendations,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt ?? this.completedAt,
  );

  // ─── Derived helpers ──────────────────────────────────────────────────────

  /// Total number of questions asked so far.
  int get questionCount => askedQuestionIds.length;

  /// Returns `true` if the session has produced recommendations.
  bool get hasRecommendations => recommendations.isNotEmpty;

  /// Returns the top recommendation, or `null` if none yet.
  Recommendation? get primaryRecommendation =>
      recommendations.isEmpty
          ? null
          : recommendations.reduce((a, b) => a.rank < b.rank ? a : b);

  /// Returns all evidence for a specific domain ID.
  List<Evidence> evidenceForDomain(String domainId) =>
      collectedEvidence.where((e) => e.domainId == domainId).toList();

  /// Returns `true` if this session is still accepting input.
  bool get isActive => status == SessionStatus.active;

  @override
  List<Object?> get props => [sessionId, phase, status, updatedAt];

  @override
  String toString() =>
      'ConversationState(session: $sessionId, phase: ${phase.name}, '
      'status: ${status.name}, questions: $questionCount)';
}
