/// SAIE — ConversationState (Decision Layer)
///
/// The mutable runtime state of an ongoing assessment conversation as tracked
/// by the [CognitiveDecisionEngine]. Separate from the domain ConversationState
/// in models/ — this version is decision-layer specific and focuses on the
/// engine's operational counters and flow tracking.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';
import 'package:stustep/features/saie/models/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClarificationRecord
// ─────────────────────────────────────────────────────────────────────────────

/// A record of a clarification that was requested during the session.
final class ClarificationRecord extends Equatable {
  /// The message that triggered the clarification.
  final String triggeringMessage;

  /// The classified intent that was below threshold.
  final SupportedIntent classifiedIntent;

  /// The confidence at which the intent was classified.
  final double confidence;

  /// Whether the clarification was resolved.
  final bool resolved;

  /// UTC timestamp when the clarification was issued.
  final DateTime issuedAt;

  const ClarificationRecord({
    required this.triggeringMessage,
    required this.classifiedIntent,
    required this.confidence,
    required this.issuedAt,
    this.resolved = false,
  });

  factory ClarificationRecord.fromJson(Map<String, dynamic> json) =>
      ClarificationRecord(
        triggeringMessage: json['triggering_message'] as String,
        classifiedIntent:
            SupportedIntent.values.byName(json['classified_intent'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        resolved: json['resolved'] as bool? ?? false,
        issuedAt: DateTime.parse(json['issued_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'triggering_message': triggeringMessage,
    'classified_intent': classifiedIntent.name,
    'confidence': confidence,
    'resolved': resolved,
    'issued_at': issuedAt.toIso8601String(),
  };

  ClarificationRecord copyWith({
    String? triggeringMessage,
    SupportedIntent? classifiedIntent,
    double? confidence,
    bool? resolved,
    DateTime? issuedAt,
  }) => ClarificationRecord(
    triggeringMessage: triggeringMessage ?? this.triggeringMessage,
    classifiedIntent: classifiedIntent ?? this.classifiedIntent,
    confidence: confidence ?? this.confidence,
    resolved: resolved ?? this.resolved,
    issuedAt: issuedAt ?? this.issuedAt,
  );

  @override
  List<Object?> get props => [triggeringMessage, classifiedIntent, issuedAt];
}

// ─────────────────────────────────────────────────────────────────────────────
// DecisionConversationState
// ─────────────────────────────────────────────────────────────────────────────

/// The decision engine's operational view of the conversation.
///
/// Updated after every [DecisionResult] is produced. Never modified directly —
/// always replaced via [copyWith].
final class DecisionConversationState extends Equatable {
  /// The current assessment phase.
  final AssessmentPhase currentPhase;

  /// The currently active question (if any).
  final Question? currentQuestion;

  /// IDs of all questions answered so far.
  final List<String> answeredQuestionIds;

  /// IDs of all questions explicitly skipped.
  final List<String> skippedQuestionIds;

  /// All clarification records issued this session.
  final List<ClarificationRecord> clarifications;

  /// Total number of general discussion turns.
  final int discussionCount;

  /// Consecutive off-topic or ambiguous messages.
  final int consecutiveOffTopicCount;

  /// Current active conversation language.
  final Language activeLanguage;

  /// The last intent the engine classified.
  final SupportedIntent? lastIntent;

  /// Whether the engine is waiting for a clarification response.
  final bool awaitingClarification;

  /// Whether the assessment is paused (e.g., for a discussion turn).
  final bool assessmentPaused;

  /// UTC timestamp of the last state update.
  final DateTime lastUpdatedAt;

  const DecisionConversationState({
    required this.currentPhase,
    required this.answeredQuestionIds,
    required this.skippedQuestionIds,
    required this.clarifications,
    required this.discussionCount,
    required this.consecutiveOffTopicCount,
    required this.activeLanguage,
    required this.lastUpdatedAt,
    this.currentQuestion,
    this.lastIntent,
    this.awaitingClarification = false,
    this.assessmentPaused = false,
  });

  factory DecisionConversationState.initial({
    Language startLanguage = Language.arabic,
  }) => DecisionConversationState(
    currentPhase: AssessmentPhase.onboarding,
    currentQuestion: null,
    answeredQuestionIds: const [],
    skippedQuestionIds: const [],
    clarifications: const [],
    discussionCount: 0,
    consecutiveOffTopicCount: 0,
    activeLanguage: startLanguage,
    lastIntent: null,
    awaitingClarification: false,
    assessmentPaused: false,
    lastUpdatedAt: DateTime.now().toUtc(),
  );

  factory DecisionConversationState.fromJson(Map<String, dynamic> json) =>
      DecisionConversationState(
        currentPhase:
            AssessmentPhase.values.byName(json['current_phase'] as String),
        currentQuestion: json['current_question'] != null
            ? Question.fromJson(
                json['current_question'] as Map<String, dynamic>,
              )
            : null,
        answeredQuestionIds:
            (json['answered_question_ids'] as List<dynamic>).cast<String>(),
        skippedQuestionIds:
            (json['skipped_question_ids'] as List<dynamic>).cast<String>(),
        clarifications: (json['clarifications'] as List<dynamic>)
            .map(
              (e) => ClarificationRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        discussionCount: json['discussion_count'] as int,
        consecutiveOffTopicCount:
            json['consecutive_off_topic_count'] as int,
        activeLanguage:
            Language.values.byName(json['active_language'] as String),
        lastIntent: json['last_intent'] != null
            ? SupportedIntent.values.byName(json['last_intent'] as String)
            : null,
        awaitingClarification:
            json['awaiting_clarification'] as bool? ?? false,
        assessmentPaused: json['assessment_paused'] as bool? ?? false,
        lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'current_phase': currentPhase.name,
    if (currentQuestion != null)
      'current_question': currentQuestion!.toJson(),
    'answered_question_ids': answeredQuestionIds,
    'skipped_question_ids': skippedQuestionIds,
    'clarifications': clarifications.map((c) => c.toJson()).toList(),
    'discussion_count': discussionCount,
    'consecutive_off_topic_count': consecutiveOffTopicCount,
    'active_language': activeLanguage.name,
    if (lastIntent != null) 'last_intent': lastIntent!.name,
    'awaiting_clarification': awaitingClarification,
    'assessment_paused': assessmentPaused,
    'last_updated_at': lastUpdatedAt.toIso8601String(),
  };

  DecisionConversationState copyWith({
    AssessmentPhase? currentPhase,
    Question? currentQuestion,
    bool clearCurrentQuestion = false,
    List<String>? answeredQuestionIds,
    List<String>? skippedQuestionIds,
    List<ClarificationRecord>? clarifications,
    int? discussionCount,
    int? consecutiveOffTopicCount,
    Language? activeLanguage,
    SupportedIntent? lastIntent,
    bool? awaitingClarification,
    bool? assessmentPaused,
    DateTime? lastUpdatedAt,
  }) => DecisionConversationState(
    currentPhase: currentPhase ?? this.currentPhase,
    currentQuestion: clearCurrentQuestion
        ? null
        : currentQuestion ?? this.currentQuestion,
    answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
    skippedQuestionIds: skippedQuestionIds ?? this.skippedQuestionIds,
    clarifications: clarifications ?? this.clarifications,
    discussionCount: discussionCount ?? this.discussionCount,
    consecutiveOffTopicCount:
        consecutiveOffTopicCount ?? this.consecutiveOffTopicCount,
    activeLanguage: activeLanguage ?? this.activeLanguage,
    lastIntent: lastIntent ?? this.lastIntent,
    awaitingClarification:
        awaitingClarification ?? this.awaitingClarification,
    assessmentPaused: assessmentPaused ?? this.assessmentPaused,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );

  int get totalClarifications => clarifications.length;
  int get unresolvedClarifications =>
      clarifications.where((c) => !c.resolved).length;

  @override
  List<Object?> get props => [
    currentPhase,
    currentQuestion?.id,
    answeredQuestionIds.length,
    awaitingClarification,
    lastUpdatedAt,
  ];

  @override
  String toString() =>
      'DecisionConversationState(phase: ${currentPhase.name}, '
      'answered: ${answeredQuestionIds.length}, '
      'awaiting: $awaitingClarification)';
}
