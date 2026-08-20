/// SAIE — AssessmentController
///
/// Manages lifecycle operations: start, pause, resume, restart, abandon.
/// Produces [AssessmentState] transitions — purely functional, no side effects.
library;

import 'package:stustep/features/saie/analysis/answer_history.dart';
import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';
import 'package:stustep/features/saie/assessment/assessment_state.dart';
import 'package:stustep/features/saie/assessment/question_history.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentController
// ─────────────────────────────────────────────────────────────────────────────

/// Handles lifecycle state transitions for an assessment session.
final class AssessmentController {
  static const _uuid = Uuid();

  const AssessmentController();

  // ── Start ──────────────────────────────────────────────────────────────

  /// Creates a brand-new [AssessmentState] for [studentId].
  AssessmentState start({
    required String studentId,
    required StudentCognitiveProfile profile,
    AssessmentConfiguration config = const AssessmentConfiguration(),
  }) {
    final now = DateTime.now().toUtc();
    return AssessmentState(
      sessionId: _uuid.v4(),
      studentId: studentId,
      status: AssessmentStatus.inProgress,
      phase: AssessmentPhase.onboarding,
      profile: profile,
      answerHistory: AnswerHistory.empty(studentId: studentId),
      progress: AssessmentProgress.initial(),
      askedQuestionIds: const [],
      skippedQuestionIds: const [],
      consecutiveSameDomainCount: 0,
      startedAt: now,
      lastUpdatedAt: now,
    );
  }

  // ── Pause ─────────────────────────────────────────────────────────────

  /// Pauses a running assessment. Restorable via [resume].
  AssessmentState pause(AssessmentState state) {
    if (!state.isInProgress) return state;
    final now = DateTime.now().toUtc();
    return state.copyWith(
      status: AssessmentStatus.paused,
      pausedAt: now,
      lastUpdatedAt: now,
    );
  }

  // ── Resume ────────────────────────────────────────────────────────────

  /// Resumes a previously paused assessment.
  AssessmentState resume(AssessmentState state) {
    if (!state.isPaused) return state;
    final now = DateTime.now().toUtc();
    return state.copyWith(
      status: AssessmentStatus.inProgress,
      lastUpdatedAt: now,
    );
  }

  // ── Restart ───────────────────────────────────────────────────────────

  /// Restarts the assessment, preserving the student profile but clearing
  /// all history, progress, and session data.
  AssessmentState restart({
    required AssessmentState state,
    required StudentCognitiveProfile freshProfile,
  }) {
    final now = DateTime.now().toUtc();
    return AssessmentState(
      sessionId: _uuid.v4(),
      studentId: state.studentId,
      status: AssessmentStatus.inProgress,
      phase: AssessmentPhase.onboarding,
      profile: freshProfile,
      answerHistory: AnswerHistory.empty(studentId: state.studentId),
      progress: AssessmentProgress.initial(),
      askedQuestionIds: const [],
      skippedQuestionIds: const [],
      consecutiveSameDomainCount: 0,
      startedAt: now,
      lastUpdatedAt: now,
    );
  }

  // ── Abandon ───────────────────────────────────────────────────────────

  /// Marks the assessment as abandoned.
  AssessmentState abandon(AssessmentState state) {
    final now = DateTime.now().toUtc();
    return state.copyWith(
      status: AssessmentStatus.abandoned,
      lastUpdatedAt: now,
    );
  }

  // ── Complete ──────────────────────────────────────────────────────────

  /// Marks the assessment as completed.
  AssessmentState complete(AssessmentState state) {
    final now = DateTime.now().toUtc();
    return state.copyWith(
      status: AssessmentStatus.completed,
      phase: AssessmentPhase.completed,
      completedAt: now,
      lastUpdatedAt: now,
      clearActiveQuestion: true,
    );
  }

  // ── Save / Restore ────────────────────────────────────────────────────

  /// Serialises [state] to a JSON-compatible map (for persistence).
  Map<String, dynamic> save(AssessmentState state) => state.toJson();

  /// Restores an [AssessmentState] from a saved JSON map.
  AssessmentState restore(Map<String, dynamic> json) =>
      AssessmentState.fromJson(json);

  // ── Internal helpers ──────────────────────────────────────────────────

  /// Updates the phase based on coverage ratio, using config thresholds.
  AssessmentPhase resolvePhase({
    required double coverageRatio,
    required AssessmentConfiguration config,
  }) {
    final thresholds = config.phaseProgressionThresholds;

    AssessmentPhase resolved = AssessmentPhase.onboarding;
    for (final entry in thresholds.entries) {
      if (coverageRatio >= entry.value) {
        resolved = entry.key;
      }
    }
    return resolved;
  }

  /// Builds updated [QuestionHistory] after a question was answered/skipped.
  QuestionHistory recordQuestion({
    required QuestionHistory history,
    required String questionId,
    required List<String> domainKeys,
    required QuestionOutcome outcome,
    String? rawAnswer,
  }) => history.append(QuestionRecord(
    questionId: questionId,
    outcome: outcome,
    askedAt: DateTime.now().toUtc(),
    domainKeys: domainKeys,
    rawAnswer: rawAnswer,
  ));
}
