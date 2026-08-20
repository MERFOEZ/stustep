/// SAIE — AdaptiveAssessmentEngine
///
/// The master orchestrator for Task 7.
///
/// Responsibility: Decide WHAT HAPPENS NEXT.
/// It does NOT recommend majors — that is the [MajorMatchingEngine]'s job.
///
/// Pipeline per turn:
/// 1. Receive current [AssessmentState] + [AnswerProcessingResult].
/// 2. Update profile, history, and progress.
/// 3. Compute [CoverageReport] + [GapReport].
/// 4. Evaluate adaptive completion.
/// 5. If not complete: select next question.
/// 6. Advance phase if coverage crossed a threshold.
/// 7. Return updated [AssessmentState].
///
/// For start: call [begin].
/// For each student turn: call [advance].
/// For lifecycle ops: call [controller] methods directly.
library;

import 'package:stustep/features/saie/analysis/answer_history.dart';
import 'package:stustep/features/saie/analysis/answer_intelligence_engine.dart';
import 'package:stustep/features/saie/assessment/assessment_completion.dart';
import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/assessment/assessment_controller.dart';
import 'package:stustep/features/saie/assessment/assessment_state.dart';
import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/assessment/coverage_engine.dart';
import 'package:stustep/features/saie/assessment/knowledge_gap_engine.dart';
import 'package:stustep/features/saie/assessment/question_history.dart';
import 'package:stustep/features/saie/assessment/question_selector.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentTurnResult
// ─────────────────────────────────────────────────────────────────────────────

/// The complete output of a single assessment turn.
final class AssessmentTurnResult {
  /// The updated assessment state after this turn.
  final AssessmentState updatedState;

  /// The next question to ask (null if the assessment is complete).
  final Question? nextQuestion;

  /// Whether the assessment completed in this turn.
  final bool assessmentCompleted;

  /// The completion decision that was evaluated.
  final CompletionDecision completionDecision;

  /// Statistics snapshot for this turn.
  final AssessmentStatistics statistics;

  const AssessmentTurnResult({
    required this.updatedState,
    required this.assessmentCompleted,
    required this.completionDecision,
    required this.statistics,
    this.nextQuestion,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveAssessmentEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the full adaptive assessment lifecycle.
final class AdaptiveAssessmentEngine {
  final AssessmentController _controller;
  final CoverageEngine _coverageEngine;
  final KnowledgeGapEngine _gapEngine;
  final QuestionSelector _questionSelector;
  final AssessmentCompletion _completion;
  final AssessmentStatisticsGenerator _statsGenerator;
  final AssessmentConfiguration _config;

  const AdaptiveAssessmentEngine({
    AssessmentController controller = const AssessmentController(),
    CoverageEngine coverageEngine = const CoverageEngine(),
    KnowledgeGapEngine gapEngine = const KnowledgeGapEngine(),
    QuestionSelector questionSelector = const QuestionSelector(),
    AssessmentCompletion completion = const AssessmentCompletion(),
    AssessmentStatisticsGenerator statsGenerator =
        const AssessmentStatisticsGenerator(),
    AssessmentConfiguration config = const AssessmentConfiguration(),
  })  : _controller = controller,
        _coverageEngine = coverageEngine,
        _gapEngine = gapEngine,
        _questionSelector = questionSelector,
        _completion = completion,
        _statsGenerator = statsGenerator,
        _config = config;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Starts a new assessment session for [studentId].
  AssessmentState begin({
    required String studentId,
    required StudentCognitiveProfile profile,
    required List<Question> allQuestions,
  }) {
    var state = _controller.start(
      studentId: studentId,
      profile: profile,
      config: _config,
    );

    // Select the first question immediately.
    final coverageReport = _coverageEngine.compute(
      profile: profile,
      config: _config,
    );
    final gapReport = _gapEngine.analyse(profile);
    final history = QuestionHistory.empty();

    final firstQuestion = _questionSelector.selectNext(
      allQuestions: allQuestions,
      profile: profile,
      history: history,
      coverageReport: coverageReport,
      gapReport: gapReport,
      config: _config,
      currentPhase: state.phase,
    );

    return state.copyWith(activeQuestion: firstQuestion);
  }

  /// Advances the assessment after a student answer.
  ///
  /// [processingResult] is the output of [AnswerIntelligenceEngine.process].
  /// [questionHistory] carries the running session-level question log.
  /// [allQuestions] is the live pool from the knowledge base.
  AssessmentTurnResult advance({
    required AssessmentState currentState,
    required AnswerProcessingResult processingResult,
    required QuestionHistory questionHistory,
    required List<Question> allQuestions,
    required ConversationContext context,
  }) {
    final now = DateTime.now().toUtc();
    final answeredQuestion = currentState.activeQuestion;
    if (answeredQuestion == null) {
      return _noOpResult(currentState, questionHistory, allQuestions);
    }

    // ── Step 1: Update profile from processing result ─────────────────────
    final updatedProfile = processingResult.updatedProfile ??
        currentState.profile;

    // ── Step 2: Update AnswerHistory ──────────────────────────────────────
    final updatedAnswerHistory = processingResult.updatedHistory;

    // ── Step 3: Record question outcome in QuestionHistory ────────────────
    final wasSkipped = processingResult.historyEntry.decision ==
        AnswerDecision.rejectedInvalid;
    final outcome =
        wasSkipped ? QuestionOutcome.skipped : QuestionOutcome.answered;

    final updatedQuestionHistory = _controller.recordQuestion(
      history: questionHistory,
      questionId: answeredQuestion.id,
      domainKeys: answeredQuestion.targetDomainIds,
      outcome: outcome,
      rawAnswer: processingResult.validation.normalisedText,
    );

    // ── Step 4: Coverage + Gap analysis ───────────────────────────────────
    final coverageReport = _coverageEngine.compute(
      profile: updatedProfile,
      config: _config,
    );
    final gapReport = _gapEngine.analyse(updatedProfile);

    // ── Step 5: Update progress ───────────────────────────────────────────
    final profileStats = updatedProfile.computeStatistics();
    final prevProgress = currentState.progress;

    final updatedProgress = prevProgress.copyWith(
      questionsAsked: prevProgress.questionsAsked + 1,
      questionsAnswered: wasSkipped
          ? prevProgress.questionsAnswered
          : prevProgress.questionsAnswered + 1,
      questionsSkipped: wasSkipped
          ? prevProgress.questionsSkipped + 1
          : prevProgress.questionsSkipped,
      coverageRatio: coverageReport.overallCoverageRatio,
      overallConfidence: profileStats.overallConfidence,
      updatedAt: now,
    );

    // ── Step 6: Resolve phase ─────────────────────────────────────────────
    final newPhase = _controller.resolvePhase(
      coverageRatio: coverageReport.overallCoverageRatio,
      config: _config,
    );

    // ── Step 7: Completion check ──────────────────────────────────────────
    final availableQuestions = allQuestions
        .where((q) =>
            !updatedQuestionHistory.allAskedIds.contains(q.id) || q.repeatable)
        .length;

    final completionDecision = _completion.evaluate(
      profile: updatedProfile,
      coverageReport: coverageReport,
      gapReport: gapReport,
      questionsAsked: updatedProgress.questionsAsked,
      availableQuestions: availableQuestions,
      config: _config,
    );

    // ── Step 8: Build updated asked/skipped lists ─────────────────────────
    final askedIds = [...currentState.askedQuestionIds, answeredQuestion.id];
    final skippedIds = wasSkipped
        ? [...currentState.skippedQuestionIds, answeredQuestion.id]
        : currentState.skippedQuestionIds;

    // ── Step 9: Select next question (if continuing) ──────────────────────
    Question? nextQuestion;
    if (!completionDecision.shouldComplete) {
      nextQuestion = _questionSelector.selectNext(
        allQuestions: allQuestions,
        profile: updatedProfile,
        history: updatedQuestionHistory,
        coverageReport: coverageReport,
        gapReport: gapReport,
        config: _config,
        currentPhase: newPhase,
      );
    }

    // ── Step 10: Compute statistics ───────────────────────────────────────
    final stats = _statsGenerator.generate(
      progress: updatedProgress,
      answerHistory: updatedAnswerHistory,
      totalEvidenceCollected: updatedProfile.evidenceCount,
    );

    // ── Step 11: Assemble updated state ───────────────────────────────────
    var updatedState = currentState.copyWith(
      profile: updatedProfile,
      answerHistory: updatedAnswerHistory,
      progress: updatedProgress,
      phase: newPhase,
      activeQuestion: nextQuestion,
      clearActiveQuestion: nextQuestion == null,
      askedQuestionIds: askedIds,
      skippedQuestionIds: skippedIds,
      lastUpdatedAt: now,
    );

    if (completionDecision.shouldComplete) {
      updatedState = _controller.complete(updatedState);
    }

    return AssessmentTurnResult(
      updatedState: updatedState,
      nextQuestion: nextQuestion,
      assessmentCompleted: completionDecision.shouldComplete,
      completionDecision: completionDecision,
      statistics: stats,
    );
  }

  // ── Lifecycle Delegation ─────────────────────────────────────────────────

  AssessmentState pause(AssessmentState state) => _controller.pause(state);
  AssessmentState resume(AssessmentState state) => _controller.resume(state);
  AssessmentState abandon(AssessmentState state) => _controller.abandon(state);

  AssessmentState restart({
    required AssessmentState state,
    required StudentCognitiveProfile freshProfile,
    required List<Question> allQuestions,
  }) {
    final restarted = _controller.restart(
      state: state,
      freshProfile: freshProfile,
    );
    return begin(
      studentId: state.studentId,
      profile: freshProfile,
      allQuestions: allQuestions,
    ).copyWith(sessionId: restarted.sessionId);
  }

  Map<String, dynamic> save(AssessmentState state) =>
      _controller.save(state);

  AssessmentState restore(Map<String, dynamic> json) =>
      _controller.restore(json);

  // ── Skip ──────────────────────────────────────────────────────────────────

  /// Skips the currently active question and selects the next one.
  ///
  /// This is the ONLY authorised path for skipping a question.
  /// No caller may directly write [AssessmentState.activeQuestion] or
  /// [AssessmentState.skippedQuestionIds] — all skip logic must go here.
  ///
  /// Returns an [AssessmentTurnResult] identical in shape to [advance()],
  /// so callers can handle both paths uniformly.
  AssessmentTurnResult skip({
    required AssessmentState currentState,
    required List<Question> allQuestions,
    /// Optional domain preference — the engine first tries to select a
    /// question from these domains before falling back to the full pool.
    /// Only [AdaptiveAssessmentEngine] may act on this preference.
    List<String> preferredDomainIds = const [],
  }) {
    final now = DateTime.now().toUtc();
    final skippedQuestion = currentState.activeQuestion;

    // Guard: nothing to skip.
    if (skippedQuestion == null) {
      return _noOpResult(currentState, QuestionHistory.empty(), allQuestions);
    }

    // ── Step 1: Record in ids ─────────────────────────────────────────────
    final askedIds = [...currentState.askedQuestionIds, skippedQuestion.id];
    final skippedIds = [...currentState.skippedQuestionIds, skippedQuestion.id];

    // ── Step 2: Update progress ────────────────────────────────────────────
    final now2 = now;
    final updatedProgress = currentState.progress.copyWith(
      questionsAsked: currentState.progress.questionsAsked + 1,
      questionsSkipped: currentState.progress.questionsSkipped + 1,
      updatedAt: now2,
    );

    // ── Step 3: Coverage + Gap (unchanged profile) ─────────────────────────
    final coverageReport = _coverageEngine.compute(
      profile: currentState.profile,
      config: _config,
    );
    final gapReport = _gapEngine.analyse(currentState.profile);

    // ── Step 4: Build history for QuestionSelector ─────────────────────────
    // Reconstruct from all asked ids so QuestionSelector excludes every
    // previously asked question, not just the one being skipped now.
    final records = askedIds.map((id) {
      final isSkipped = skippedIds.contains(id);
      final q = allQuestions.where((q) => q.id == id).firstOrNull;
      return QuestionRecord(
        questionId: id,
        outcome: isSkipped ? QuestionOutcome.skipped : QuestionOutcome.answered,
        askedAt: now,
        domainKeys: q?.targetDomainIds ?? const [],
      );
    }).toList();
    final updatedHistory = QuestionHistory(records: records);

    // ── Step 5: Select next question ───────────────────────────────────────
    final newPhase = _controller.resolvePhase(
      coverageRatio: coverageReport.overallCoverageRatio,
      config: _config,
    );

    // Try domain-preferred pool first (for "alternative question" UX).
    // If the preferred-domain pool has no candidates, fall back to full pool.
    final domainFilteredPool = preferredDomainIds.isEmpty
        ? allQuestions
        : allQuestions
            .where((q) =>
                q.targetDomainIds.any(preferredDomainIds.contains))
            .toList();

    Question? nextQuestion = _questionSelector.selectNext(
      allQuestions: domainFilteredPool.isNotEmpty ? domainFilteredPool : allQuestions,
      profile: currentState.profile,
      history: updatedHistory,
      coverageReport: coverageReport,
      gapReport: gapReport,
      config: _config,
      currentPhase: newPhase,
    );

    // If domain-filtered pool was empty or produced no result, try full pool.
    if (nextQuestion == null && domainFilteredPool != allQuestions) {
      nextQuestion = _questionSelector.selectNext(
        allQuestions: allQuestions,
        profile: currentState.profile,
        history: updatedHistory,
        coverageReport: coverageReport,
        gapReport: gapReport,
        config: _config,
        currentPhase: newPhase,
      );
    }

    // ── Step 6: Completion check ──────────────────────────────────────────
    final availableQuestions = allQuestions
        .where((q) =>
            !updatedHistory.allAskedIds.contains(q.id) || q.repeatable)
        .length;

    final completionDecision = _completion.evaluate(
      profile: currentState.profile,
      coverageReport: coverageReport,
      gapReport: gapReport,
      questionsAsked: updatedProgress.questionsAsked,
      availableQuestions: availableQuestions,
      config: _config,
    );

    // ── Step 7: Stats ──────────────────────────────────────────────────────
    final stats = _statsGenerator.generate(
      progress: updatedProgress,
      answerHistory: currentState.answerHistory,
      totalEvidenceCollected: currentState.profile.evidenceCount,
    );

    // ── Step 8: Assemble updated state ─────────────────────────────────────
    var updatedState = currentState.copyWith(
      progress: updatedProgress,
      phase: newPhase,
      activeQuestion: nextQuestion,
      clearActiveQuestion: nextQuestion == null,
      askedQuestionIds: askedIds,
      skippedQuestionIds: skippedIds,
      lastUpdatedAt: now,
    );

    if (completionDecision.shouldComplete) {
      updatedState = _controller.complete(updatedState);
    }

    return AssessmentTurnResult(
      updatedState: updatedState,
      nextQuestion: nextQuestion,
      assessmentCompleted: completionDecision.shouldComplete,
      completionDecision: completionDecision,
      statistics: stats,
    );
  }


  // ── Private ───────────────────────────────────────────────────────────────

  AssessmentTurnResult _noOpResult(
    AssessmentState state,
    QuestionHistory questionHistory,
    List<Question> allQuestions,
  ) {
    final coverage = _coverageEngine.compute(profile: state.profile, config: _config);
    final gaps = _gapEngine.analyse(state.profile);
    final stats = _statsGenerator.generate(
      progress: state.progress,
      answerHistory: state.answerHistory,
      totalEvidenceCollected: state.profile.evidenceCount,
    );
    final decision = _completion.evaluate(
      profile: state.profile,
      coverageReport: coverage,
      gapReport: gaps,
      questionsAsked: state.progress.questionsAsked,
      availableQuestions: allQuestions.length,
      config: _config,
    );
    return AssessmentTurnResult(
      updatedState: state,
      nextQuestion: state.activeQuestion,
      assessmentCompleted: false,
      completionDecision: decision,
      statistics: stats,
    );
  }
}
