/// SAIE — ConversationPhase
///
/// Tracks the high-level phase of the entire conversation session.
/// Distinct from [AssessmentPhase], which tracks depth of assessment.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationStage
// ─────────────────────────────────────────────────────────────────────────────

enum ConversationStage {
  /// Initial greeting — system introduces itself.
  introduction,

  /// Student profile is being established (assessment running).
  assessment,

  /// Assessment is paused due to discussion or interruption.
  paused,

  /// Recommendation is ready and being discussed.
  recommendation,

  /// Student is asking follow-up academic questions post-recommendation.
  postRecommendation,

  /// Student indicated goodbye.
  closing,
}

extension ConversationStageX on ConversationStage {
  bool get isActive =>
      this == ConversationStage.assessment ||
      this == ConversationStage.recommendation ||
      this == ConversationStage.postRecommendation;

  bool get canReceiveAnswer =>
      this == ConversationStage.assessment;
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentNeed
// ─────────────────────────────────────────────────────────────────────────────

/// An open student need that must be resolved before the assessment can advance.
///
/// Stored in [ConversationPhase.pendingNeed]. The controller clears this
/// once the student's sub-question has been answered and they are ready to
/// return to the assessment question.
sealed class StudentNeed {
  const StudentNeed();

  /// Human-readable Arabic description (for logging/debugging only).
  String describeAr();
}

/// Student asked whether a specific real-life example counts as an answer.
/// Example: "هل التنمر يُعتبر قيادة؟"
final class ExampleValidationNeed extends StudentNeed {
  /// The example the student proposed.
  final String studentExample;

  const ExampleValidationNeed(this.studentExample);

  @override
  String describeAr() =>
      'الطالب يسأل إن كان "$studentExample" مقبولاً كإجابة للسؤال.';
}

/// Student sent a follow-up question after receiving an explanation.
/// Example: "لكن ماذا لو كنت أحب الاثنين؟" after examples were given.
final class FollowUpClarificationNeed extends StudentNeed {
  /// The follow-up question text.
  final String followUpQuestion;

  const FollowUpClarificationNeed(this.followUpQuestion);

  @override
  String describeAr() =>
      'الطالب لديه سؤال متابعة بعد الشرح: "$followUpQuestion"';
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationPhase
// ─────────────────────────────────────────────────────────────────────────────

/// Full phase snapshot of the conversation at a single point in time.
final class ConversationPhase extends Equatable {
  final ConversationStage stage;
  final AssessmentPhase assessmentPhase;
  final int interruptionCount;
  final int clarificationCount;
  final int discussionDepth;
  final bool assessmentPaused;
  final DateTime lastTransitionAt;

  /// An open student need that must be satisfied before assessment resumes.
  ///
  /// Null = no open need, assessment may continue freely.
  /// Non-null = the system must address this need first on the next turn.
  final StudentNeed? pendingNeed;

  const ConversationPhase({
    required this.stage,
    required this.assessmentPhase,
    required this.interruptionCount,
    required this.clarificationCount,
    required this.discussionDepth,
    required this.assessmentPaused,
    required this.lastTransitionAt,
    this.pendingNeed,
  });

  factory ConversationPhase.initial() => ConversationPhase(
    stage: ConversationStage.introduction,
    assessmentPhase: AssessmentPhase.onboarding,
    interruptionCount: 0,
    clarificationCount: 0,
    discussionDepth: 0,
    assessmentPaused: false,
    lastTransitionAt: DateTime.now().toUtc(),
  );

  ConversationPhase transitionTo(ConversationStage newStage) =>
      copyWith(stage: newStage, lastTransitionAt: DateTime.now().toUtc());

  ConversationPhase advanceAssessmentPhase(AssessmentPhase phase) =>
      copyWith(assessmentPhase: phase);

  ConversationPhase interrupt() =>
      copyWith(interruptionCount: interruptionCount + 1, assessmentPaused: true);

  ConversationPhase resumeFromInterruption() =>
      copyWith(assessmentPaused: false, discussionDepth: 0);

  ConversationPhase addClarification() =>
      copyWith(clarificationCount: clarificationCount + 1);

  ConversationPhase incrementDiscussionDepth() =>
      copyWith(discussionDepth: discussionDepth + 1);

  /// Store an open student need — assessment will not advance until cleared.
  ConversationPhase withPendingNeed(StudentNeed need) =>
      copyWith(pendingNeed: need);

  /// Clear the pending need — assessment may now resume normally.
  ConversationPhase withNeedResolved() =>
      copyWith(clearPendingNeed: true);

  /// True when there is an open student need that must be addressed first.
  bool get hasUnresolvedNeed => pendingNeed != null;

  factory ConversationPhase.fromJson(Map<String, dynamic> json) =>
      ConversationPhase(
        stage: ConversationStage.values.byName(json['stage'] as String),
        assessmentPhase:
            AssessmentPhase.values.byName(json['assessment_phase'] as String),
        interruptionCount: json['interruption_count'] as int,
        clarificationCount: json['clarification_count'] as int,
        discussionDepth: json['discussion_depth'] as int,
        assessmentPaused: json['assessment_paused'] as bool,
        lastTransitionAt:
            DateTime.parse(json['last_transition_at'] as String),
        // pendingNeed is intentionally not persisted — it is ephemeral
        // within a single session. On restore, the student will naturally
        // re-ask if they still need help.
      );

  Map<String, dynamic> toJson() => {
    'stage': stage.name,
    'assessment_phase': assessmentPhase.name,
    'interruption_count': interruptionCount,
    'clarification_count': clarificationCount,
    'discussion_depth': discussionDepth,
    'assessment_paused': assessmentPaused,
    'last_transition_at': lastTransitionAt.toIso8601String(),
  };

  ConversationPhase copyWith({
    ConversationStage? stage,
    AssessmentPhase? assessmentPhase,
    int? interruptionCount,
    int? clarificationCount,
    int? discussionDepth,
    bool? assessmentPaused,
    DateTime? lastTransitionAt,
    StudentNeed? pendingNeed,
    bool clearPendingNeed = false,
  }) => ConversationPhase(
    stage: stage ?? this.stage,
    assessmentPhase: assessmentPhase ?? this.assessmentPhase,
    interruptionCount: interruptionCount ?? this.interruptionCount,
    clarificationCount: clarificationCount ?? this.clarificationCount,
    discussionDepth: discussionDepth ?? this.discussionDepth,
    assessmentPaused: assessmentPaused ?? this.assessmentPaused,
    lastTransitionAt: lastTransitionAt ?? this.lastTransitionAt,
    pendingNeed: clearPendingNeed ? null : (pendingNeed ?? this.pendingNeed),
  );

  @override
  List<Object?> get props =>
      [stage, assessmentPhase, interruptionCount, pendingNeed];
}
