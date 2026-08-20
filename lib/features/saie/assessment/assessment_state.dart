/// SAIE — AssessmentState
///
/// Immutable snapshot of the entire assessment at a given moment.
/// This is what gets saved, restored, paused, and resumed.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/analysis/answer_history.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentStatus
// ─────────────────────────────────────────────────────────────────────────────

/// The current lifecycle status of an assessment session.
enum AssessmentStatus {
  /// Assessment has not started yet.
  notStarted,

  /// Assessment is actively in progress.
  inProgress,

  /// Assessment has been paused (can be resumed).
  paused,

  /// Assessment completed successfully; ready for recommendation.
  completed,

  /// Assessment was explicitly abandoned by the student.
  abandoned,
}

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentState
// ─────────────────────────────────────────────────────────────────────────────

/// Complete, immutable state of the assessment engine at a point in time.
///
/// Saving this object is sufficient to fully restore an assessment.
final class AssessmentState extends Equatable {
  /// Unique identifier for this assessment session.
  final String sessionId;

  /// ID of the student this assessment belongs to.
  final String studentId;

  /// Lifecycle status.
  final AssessmentStatus status;

  /// Current assessment phase.
  final AssessmentPhase phase;

  /// The question currently being asked (null if awaiting processing).
  final Question? activeQuestion;

  /// The cognitive profile snapshot at this moment.
  final StudentCognitiveProfile profile;

  /// Cumulative answer history for this session.
  final AnswerHistory answerHistory;

  /// Progress tracking.
  final AssessmentProgress progress;

  /// IDs of questions already asked in this session.
  final List<String> askedQuestionIds;

  /// IDs of questions explicitly skipped by the student.
  final List<String> skippedQuestionIds;

  /// The last domain key addressed (for diversity control).
  final String? lastDomainKey;

  /// Count of consecutive questions from the same domain.
  final int consecutiveSameDomainCount;

  /// UTC timestamp when this assessment was created.
  final DateTime startedAt;

  /// UTC timestamp of the last state update.
  final DateTime lastUpdatedAt;

  /// UTC timestamp when the assessment was paused (null if not paused).
  final DateTime? pausedAt;

  /// UTC timestamp when the assessment was completed (null if not done).
  final DateTime? completedAt;

  const AssessmentState({
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.phase,
    required this.profile,
    required this.answerHistory,
    required this.progress,
    required this.askedQuestionIds,
    required this.skippedQuestionIds,
    required this.consecutiveSameDomainCount,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.activeQuestion,
    this.lastDomainKey,
    this.pausedAt,
    this.completedAt,
  });

  bool get isInProgress => status == AssessmentStatus.inProgress;
  bool get isPaused => status == AssessmentStatus.paused;
  bool get isCompleted => status == AssessmentStatus.completed;
  bool get isNotStarted => status == AssessmentStatus.notStarted;
  bool get hasActiveQuestion => activeQuestion != null;

  factory AssessmentState.fromJson(Map<String, dynamic> json) =>
      AssessmentState(
        sessionId: json['session_id'] as String,
        studentId: json['student_id'] as String,
        status: AssessmentStatus.values.byName(json['status'] as String),
        phase: AssessmentPhase.values.byName(json['phase'] as String),
        activeQuestion: json['active_question'] != null
            ? Question.fromJson(
                json['active_question'] as Map<String, dynamic>,
              )
            : null,
        profile: StudentCognitiveProfile.fromJson(
          json['profile'] as Map<String, dynamic>,
        ),
        answerHistory: AnswerHistory.fromJson(
          json['answer_history'] as Map<String, dynamic>,
        ),
        progress: AssessmentProgress.fromJson(
          json['progress'] as Map<String, dynamic>,
        ),
        askedQuestionIds:
            (json['asked_question_ids'] as List<dynamic>).cast<String>(),
        skippedQuestionIds:
            (json['skipped_question_ids'] as List<dynamic>).cast<String>(),
        lastDomainKey: json['last_domain_key'] as String?,
        consecutiveSameDomainCount:
            json['consecutive_same_domain_count'] as int,
        startedAt: DateTime.parse(json['started_at'] as String),
        lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
        pausedAt: json['paused_at'] != null
            ? DateTime.parse(json['paused_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'student_id': studentId,
    'status': status.name,
    'phase': phase.name,
    if (activeQuestion != null) 'active_question': activeQuestion!.toJson(),
    'profile': profile.toJson(),
    'answer_history': answerHistory.toJson(),
    'progress': progress.toJson(),
    'asked_question_ids': askedQuestionIds,
    'skipped_question_ids': skippedQuestionIds,
    if (lastDomainKey != null) 'last_domain_key': lastDomainKey,
    'consecutive_same_domain_count': consecutiveSameDomainCount,
    'started_at': startedAt.toIso8601String(),
    'last_updated_at': lastUpdatedAt.toIso8601String(),
    if (pausedAt != null) 'paused_at': pausedAt!.toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
  };

  AssessmentState copyWith({
    String? sessionId,
    String? studentId,
    AssessmentStatus? status,
    AssessmentPhase? phase,
    Question? activeQuestion,
    bool clearActiveQuestion = false,
    StudentCognitiveProfile? profile,
    AnswerHistory? answerHistory,
    AssessmentProgress? progress,
    List<String>? askedQuestionIds,
    List<String>? skippedQuestionIds,
    String? lastDomainKey,
    int? consecutiveSameDomainCount,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
  }) => AssessmentState(
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    status: status ?? this.status,
    phase: phase ?? this.phase,
    activeQuestion:
        clearActiveQuestion ? null : (activeQuestion ?? this.activeQuestion),
    profile: profile ?? this.profile,
    answerHistory: answerHistory ?? this.answerHistory,
    progress: progress ?? this.progress,
    askedQuestionIds: askedQuestionIds ?? this.askedQuestionIds,
    skippedQuestionIds: skippedQuestionIds ?? this.skippedQuestionIds,
    lastDomainKey: lastDomainKey ?? this.lastDomainKey,
    consecutiveSameDomainCount:
        consecutiveSameDomainCount ?? this.consecutiveSameDomainCount,
    startedAt: startedAt ?? this.startedAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    pausedAt: pausedAt ?? this.pausedAt,
    completedAt: completedAt ?? this.completedAt,
  );

  @override
  List<Object?> get props => [sessionId, status, phase, lastUpdatedAt];

  @override
  String toString() =>
      'AssessmentState(session: $sessionId, status: ${status.name}, '
      'phase: ${phase.name}, asked: ${askedQuestionIds.length})';
}
