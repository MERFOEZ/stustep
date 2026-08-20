/// SAIE — ConversationContext
///
/// The full contextual state the [CognitiveDecisionEngine] needs to make
/// accurate intent classification decisions. This is read-only input to the
/// engine — it never mutates context; it only reads it.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/models/assessment_goal.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationTurn
// ─────────────────────────────────────────────────────────────────────────────

/// A single turn in the conversation history (role + content).
final class ConversationTurn extends Equatable {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  const ConversationTurn({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ConversationTurn.fromJson(Map<String, dynamic> json) =>
      ConversationTurn(
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  ConversationTurn copyWith({
    MessageRole? role,
    String? content,
    DateTime? timestamp,
  }) => ConversationTurn(
    role: role ?? this.role,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
  );

  bool get isEngine => role == MessageRole.engine;
  bool get isStudent => role == MessageRole.student;

  @override
  List<Object?> get props => [role, content, timestamp];
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationContext
// ─────────────────────────────────────────────────────────────────────────────

/// All context the engine needs to make a fully-informed classification.
///
/// Every field here represents information that affects the meaning of a
/// student message. Context-free classification is forbidden.
final class ConversationContext extends Equatable {
  /// The student's unique ID.
  final String studentId;

  /// The current assessment phase.
  final AssessmentPhase currentPhase;

  /// The active assessment goal.
  final AssessmentGoal currentGoal;

  /// The question the student is currently expected to answer.
  /// Null if no question is pending.
  final Question? activeQuestion;

  /// The full cognitive profile of the student.
  final StudentCognitiveProfile cognitiveProfile;

  /// The last N turns of conversation history (engine + student).
  final List<ConversationTurn> recentHistory;

  /// The last message sent by the engine.
  final String? lastEngineMessage;

  /// The last message sent by the student (the one before the current input).
  final String? lastStudentMessage;

  /// IDs of questions already answered in this session.
  final List<String> answeredQuestionIds;

  /// IDs of questions the student explicitly skipped.
  final List<String> skippedQuestionIds;

  /// IDs of dimensions in the cognitive profile that still have zero evidence.
  final List<String> unevidencedDimensionKeys;

  /// Number of consecutive off-topic or ambiguous messages in the current run.
  final int consecutiveOffTopicCount;

  /// Number of general discussion turns this session.
  final int discussionCount;

  /// Number of clarification requests already issued this session.
  final int clarificationCount;

  /// The macro conversation stage (introduction / assessment / recommendation …).
  /// This is the primary signal used to disambiguate contextual messages.
  final ConversationStage conversationStage;

  /// The active conversation language policy.
  final Language activeLanguage;

  /// UTC timestamp of context creation.
  final DateTime createdAt;

  const ConversationContext({
    required this.studentId,
    required this.currentPhase,
    required this.currentGoal,
    required this.cognitiveProfile,
    required this.recentHistory,
    required this.answeredQuestionIds,
    required this.skippedQuestionIds,
    required this.unevidencedDimensionKeys,
    required this.consecutiveOffTopicCount,
    required this.discussionCount,
    required this.clarificationCount,
    required this.conversationStage,
    required this.activeLanguage,
    required this.createdAt,
    this.activeQuestion,
    this.lastEngineMessage,
    this.lastStudentMessage,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) =>
      ConversationContext(
        studentId: json['student_id'] as String,
        currentPhase:
            AssessmentPhase.values.byName(json['current_phase'] as String),
        currentGoal: AssessmentGoal.fromJson(
          json['current_goal'] as Map<String, dynamic>,
        ),
        activeQuestion: json['active_question'] != null
            ? Question.fromJson(
                json['active_question'] as Map<String, dynamic>,
              )
            : null,
        cognitiveProfile: StudentCognitiveProfile.fromJson(
          json['cognitive_profile'] as Map<String, dynamic>,
        ),
        recentHistory: (json['recent_history'] as List<dynamic>)
            .map((e) => ConversationTurn.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastEngineMessage: json['last_engine_message'] as String?,
        lastStudentMessage: json['last_student_message'] as String?,
        answeredQuestionIds:
            (json['answered_question_ids'] as List<dynamic>).cast<String>(),
        skippedQuestionIds:
            (json['skipped_question_ids'] as List<dynamic>).cast<String>(),
        unevidencedDimensionKeys:
            (json['unevidenced_dimension_keys'] as List<dynamic>).cast<String>(),
        consecutiveOffTopicCount:
            json['consecutive_off_topic_count'] as int,
        discussionCount: json['discussion_count'] as int,
        clarificationCount: json['clarification_count'] as int,
        conversationStage: json.containsKey('conversation_stage')
            ? ConversationStage.values.byName(
                json['conversation_stage'] as String)
            : ConversationStage.introduction,
        activeLanguage:
            Language.values.byName(json['active_language'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'current_phase': currentPhase.name,
    'current_goal': currentGoal.toJson(),
    if (activeQuestion != null) 'active_question': activeQuestion!.toJson(),
    'cognitive_profile': cognitiveProfile.toJson(),
    'recent_history': recentHistory.map((t) => t.toJson()).toList(),
    if (lastEngineMessage != null) 'last_engine_message': lastEngineMessage,
    if (lastStudentMessage != null) 'last_student_message': lastStudentMessage,
    'answered_question_ids': answeredQuestionIds,
    'skipped_question_ids': skippedQuestionIds,
    'unevidenced_dimension_keys': unevidencedDimensionKeys,
    'consecutive_off_topic_count': consecutiveOffTopicCount,
    'discussion_count': discussionCount,
    'clarification_count': clarificationCount,
    'conversation_stage': conversationStage.name,
    'active_language': activeLanguage.name,
    'created_at': createdAt.toIso8601String(),
  };

  ConversationContext copyWith({
    String? studentId,
    AssessmentPhase? currentPhase,
    AssessmentGoal? currentGoal,
    Question? activeQuestion,
    bool clearActiveQuestion = false,
    StudentCognitiveProfile? cognitiveProfile,
    List<ConversationTurn>? recentHistory,
    String? lastEngineMessage,
    String? lastStudentMessage,
    List<String>? answeredQuestionIds,
    List<String>? skippedQuestionIds,
    List<String>? unevidencedDimensionKeys,
    int? consecutiveOffTopicCount,
    int? discussionCount,
    int? clarificationCount,
    ConversationStage? conversationStage,
    Language? activeLanguage,
    DateTime? createdAt,
  }) => ConversationContext(
    studentId: studentId ?? this.studentId,
    currentPhase: currentPhase ?? this.currentPhase,
    currentGoal: currentGoal ?? this.currentGoal,
    activeQuestion: clearActiveQuestion
        ? null
        : activeQuestion ?? this.activeQuestion,
    cognitiveProfile: cognitiveProfile ?? this.cognitiveProfile,
    recentHistory: recentHistory ?? this.recentHistory,
    lastEngineMessage: lastEngineMessage ?? this.lastEngineMessage,
    lastStudentMessage: lastStudentMessage ?? this.lastStudentMessage,
    answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
    skippedQuestionIds: skippedQuestionIds ?? this.skippedQuestionIds,
    unevidencedDimensionKeys:
        unevidencedDimensionKeys ?? this.unevidencedDimensionKeys,
    consecutiveOffTopicCount:
        consecutiveOffTopicCount ?? this.consecutiveOffTopicCount,
    discussionCount: discussionCount ?? this.discussionCount,
    clarificationCount: clarificationCount ?? this.clarificationCount,
    conversationStage: conversationStage ?? this.conversationStage,
    activeLanguage: activeLanguage ?? this.activeLanguage,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns `true` if there is an active question waiting for an answer.
  bool get hasPendingQuestion => activeQuestion != null;

  /// Returns `true` when the conversation is in the pre-assessment introduction
  /// stage — the student has not yet started answering any questions.
  bool get isWaitingToStart =>
      conversationStage == ConversationStage.introduction &&
      answeredQuestionIds.isEmpty &&
      !hasPendingQuestion;

  /// Returns `true` when inside an active assessment but with no pending question
  /// (i.e., engine is between questions or just finished one).
  bool get isBetweenQuestions =>
      conversationStage == ConversationStage.assessment &&
      !hasPendingQuestion;

  /// Returns `true` when the recommendation is ready and being discussed.
  bool get isInRecommendationPhase =>
      conversationStage == ConversationStage.recommendation ||
      conversationStage == ConversationStage.postRecommendation;

  /// Returns the last [n] turns, newest first.
  List<ConversationTurn> lastNTurns(int n) =>
      recentHistory.length <= n
          ? recentHistory.reversed.toList()
          : recentHistory.sublist(recentHistory.length - n).reversed.toList();

  @override
  List<Object?> get props => [
    studentId,
    currentPhase,
    activeQuestion?.id,
    recentHistory.length,
    activeLanguage,
  ];

  @override
  String toString() =>
      'ConversationContext(student: $studentId, phase: ${currentPhase.name}, '
      'pendingQ: ${activeQuestion?.id ?? "none"}, lang: ${activeLanguage.name})';
}
