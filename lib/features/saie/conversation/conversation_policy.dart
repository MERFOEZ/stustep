/// SAIE — ConversationPolicy
///
/// Immutable set of rules governing conversation behaviour.
/// Controls maximum depths, timeouts, and retention strategies.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationPolicy
// ─────────────────────────────────────────────────────────────────────────────

final class ConversationPolicy extends Equatable {
  // ── Discussion limits ────────────────────────────────────────────────────

  /// Max number of times the student may interrupt the assessment with
  /// off-topic or academic-discussion messages before the engine forces
  /// a gentle return to the assessment.
  final int maxInterruptionCount;

  /// Max depth (turns) of a single academic discussion sub-thread before
  /// the engine proactively returns to the assessment.
  final int maxDiscussionDepth;

  /// Max number of clarification requests per session.
  final int maxClarificationCount;

  // ── Context retention ────────────────────────────────────────────────────

  /// Number of recent turns kept in the active context window.
  final int contextWindowSize;

  /// Number of full turns before a periodic summary is generated.
  final int summaryEveryNTurns;

  // ── Timeout ───────────────────────────────────────────────────────────────

  /// Inactivity duration after which the session is considered timed out.
  final Duration sessionTimeout;

  // ── Assessment behaviour ─────────────────────────────────────────────────

  /// Whether to automatically return to assessment after an academic discussion.
  final bool autoReturnAfterDiscussion;

  /// Whether to repeat the active question after a clarification response.
  final bool repeatQuestionAfterClarification;

  /// Whether to repeat the active question after an explanation.
  final bool repeatQuestionAfterExplanation;

  /// Whether a recommendation discussion resets the assessment.
  final bool resetAssessmentOnRecommendationDiscussion;

  const ConversationPolicy({
    this.maxInterruptionCount = 5,
    this.maxDiscussionDepth = 4,
    this.maxClarificationCount = 8,
    this.contextWindowSize = 12,
    this.summaryEveryNTurns = 20,
    this.sessionTimeout = const Duration(minutes: 30),
    this.autoReturnAfterDiscussion = true,
    this.repeatQuestionAfterClarification = true,
    this.repeatQuestionAfterExplanation = true,
    this.resetAssessmentOnRecommendationDiscussion = false,
  });

  factory ConversationPolicy.fromJson(Map<String, dynamic> json) =>
      ConversationPolicy(
        maxInterruptionCount: json['max_interruption_count'] as int,
        maxDiscussionDepth: json['max_discussion_depth'] as int,
        maxClarificationCount: json['max_clarification_count'] as int,
        contextWindowSize: json['context_window_size'] as int,
        summaryEveryNTurns: json['summary_every_n_turns'] as int,
        sessionTimeout:
            Duration(seconds: json['session_timeout_seconds'] as int),
        autoReturnAfterDiscussion:
            json['auto_return_after_discussion'] as bool,
        repeatQuestionAfterClarification:
            json['repeat_question_after_clarification'] as bool,
        repeatQuestionAfterExplanation:
            json['repeat_question_after_explanation'] as bool,
        resetAssessmentOnRecommendationDiscussion:
            json['reset_assessment_on_recommendation_discussion'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'max_interruption_count': maxInterruptionCount,
    'max_discussion_depth': maxDiscussionDepth,
    'max_clarification_count': maxClarificationCount,
    'context_window_size': contextWindowSize,
    'summary_every_n_turns': summaryEveryNTurns,
    'session_timeout_seconds': sessionTimeout.inSeconds,
    'auto_return_after_discussion': autoReturnAfterDiscussion,
    'repeat_question_after_clarification': repeatQuestionAfterClarification,
    'repeat_question_after_explanation': repeatQuestionAfterExplanation,
    'reset_assessment_on_recommendation_discussion':
        resetAssessmentOnRecommendationDiscussion,
  };

  ConversationPolicy copyWith({
    int? maxInterruptionCount,
    int? maxDiscussionDepth,
    int? maxClarificationCount,
    int? contextWindowSize,
    int? summaryEveryNTurns,
    Duration? sessionTimeout,
    bool? autoReturnAfterDiscussion,
    bool? repeatQuestionAfterClarification,
    bool? repeatQuestionAfterExplanation,
    bool? resetAssessmentOnRecommendationDiscussion,
  }) => ConversationPolicy(
    maxInterruptionCount:
        maxInterruptionCount ?? this.maxInterruptionCount,
    maxDiscussionDepth: maxDiscussionDepth ?? this.maxDiscussionDepth,
    maxClarificationCount:
        maxClarificationCount ?? this.maxClarificationCount,
    contextWindowSize: contextWindowSize ?? this.contextWindowSize,
    summaryEveryNTurns: summaryEveryNTurns ?? this.summaryEveryNTurns,
    sessionTimeout: sessionTimeout ?? this.sessionTimeout,
    autoReturnAfterDiscussion:
        autoReturnAfterDiscussion ?? this.autoReturnAfterDiscussion,
    repeatQuestionAfterClarification: repeatQuestionAfterClarification ??
        this.repeatQuestionAfterClarification,
    repeatQuestionAfterExplanation: repeatQuestionAfterExplanation ??
        this.repeatQuestionAfterExplanation,
    resetAssessmentOnRecommendationDiscussion:
        resetAssessmentOnRecommendationDiscussion ??
            this.resetAssessmentOnRecommendationDiscussion,
  );

  @override
  List<Object?> get props => [
    maxInterruptionCount,
    maxDiscussionDepth,
    contextWindowSize,
    sessionTimeout,
  ];
}
