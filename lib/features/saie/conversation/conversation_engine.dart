/// SAIE — ConversationEngine
///
/// Single entry point for every student message in a conversation session.
///
/// Pipeline per turn:
/// 1. Detect & apply language (Arabic default, auto-switch).
/// 2. Run [CognitiveDecisionEngine.process] — authorises all downstream actions.
/// 3. Build [ConversationContext] snapshot.
/// 4. Route via [ConversationRouter].
/// 5. Dispatch to [ConversationController].
/// 6. Append student + engine turns to [ConversationMemory].
/// 7. Return [ConversationTurnOutput].
///
/// Pure Dart. No Flutter. No network. No OpenAI.
library;

import 'package:stustep/features/saie/analysis/answer_intelligence_engine.dart';
import 'package:stustep/features/saie/assessment/adaptive_assessment_engine.dart';
import 'package:stustep/features/saie/assessment/assessment_controller.dart';
import 'package:stustep/features/saie/conversation/conversation_context.dart' as conv;
import 'package:stustep/features/saie/conversation/conversation_controller.dart';
import 'package:stustep/features/saie/conversation/conversation_event.dart';
import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/conversation/conversation_language.dart';
import 'package:stustep/features/saie/conversation/conversation_memory.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/conversation/conversation_policy.dart';
import 'package:stustep/features/saie/conversation/conversation_router.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/decision/cognitive_decision_engine.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart' as dec;
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/explainable/explainable_ai_engine.dart';
import 'package:stustep/features/saie/llm/llm_explanation_service.dart';
import 'package:stustep/features/saie/llm/llm_service.dart';
import 'package:stustep/features/saie/llm/local_explanation_fallback.dart';
import 'package:stustep/features/saie/matching/major_matching_engine.dart';
import 'package:stustep/features/saie/models/assessment_goal.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_engine.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationTurnOutput
// ─────────────────────────────────────────────────────────────────────────────

/// The full output produced by [ConversationEngine.process] for one turn.
final class ConversationTurnOutput {
  /// The engine's response text to present to the student.
  final String response;

  /// Updated conversation memory (append-only).
  final ConversationMemory updatedMemory;

  /// Updated conversation phase.
  final ConversationPhase updatedPhase;

  /// Updated language state.
  final ConversationLanguage updatedLanguage;

  /// Updated student cognitive profile.
  final StudentCognitiveProfile updatedProfile;

  /// The route chosen for this turn.
  final ConversationRoute route;

  /// The event produced this turn.
  final ConversationEvent event;

  /// Whether the assessment advanced.
  final bool assessmentAdvanced;

  /// Whether a recommendation was generated this turn.
  final bool recommendationGenerated;

  const ConversationTurnOutput({
    required this.response,
    required this.updatedMemory,
    required this.updatedPhase,
    required this.updatedLanguage,
    required this.updatedProfile,
    required this.route,
    required this.event,
    required this.assessmentAdvanced,
    required this.recommendationGenerated,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationEngine
// ─────────────────────────────────────────────────────────────────────────────

/// The single entry point for all incoming student messages.
///
/// Usage:
/// ```dart
/// final engine = ConversationEngine(
///   decisionEngine: ...,
///   controller: ...,
///   router: const ConversationRouter(),
///   policy: const ConversationPolicy(),
///   allMajors: loadedMajors,
///   allQuestions: loadedQuestions,
/// );
///
/// var memory = ConversationMemory.empty(sessionId);
/// var phase  = ConversationPhase.initial();
/// var profile = StudentCognitiveProfile.initial(studentId: id);
/// var language = ConversationLanguage.initial();
///
/// final output = engine.process(
///   studentMessage: message,
///   memory: memory,
///   phase: phase,
///   profile: profile,
///   language: language,
/// );
/// ```
final class ConversationEngine {
  final CognitiveDecisionEngine _decisionEngine;
  final ConversationController _controller;
  final ConversationRouter _router;
  final ConversationPolicy _policy;

  static const _uuid = Uuid();

  const ConversationEngine({
    required CognitiveDecisionEngine decisionEngine,
    required ConversationController controller,
    ConversationRouter router = const ConversationRouter(),
    ConversationPolicy policy = const ConversationPolicy(),
    required List<Major> allMajors,
    required List<Question> allQuestions,
  })  : _decisionEngine = decisionEngine,
        _controller = controller,
        _router = router,
        _policy = policy;

  // ── Primary API ────────────────────────────────────────────────────────────

  /// Processes one student message and returns a [ConversationTurnOutput].
  Future<ConversationTurnOutput> process({
    required String studentMessage,
    required String studentId,
    required ConversationMemory memory,
    required ConversationPhase phase,
    required StudentCognitiveProfile profile,
    required ConversationLanguage language,
  }) async {
    final sessionId = memory.sessionId;
    final now = DateTime.now().toUtc();

    // ── Step 1: Append student turn ─────────────────────────────────────────
    final studentTurn = _buildTurn(
      message: studentMessage,
      isEngine: false,
      phase: phase,
      eventType: ConversationEventType.studentMessage,
    );
    var mem = memory.appendTurn(studentTurn);

    // ── Step 2: Detect language (pre-decision) ──────────────────────────────
    // The decision engine will confirm; we use a provisional detection here.
    final provisionalLang =
        _detectLanguage(studentMessage, language);

    // ── Step 3: Run Decision Engine ─────────────────────────────────────────
    final assessmentState = mem.assessmentState;
    final decCtx = _buildDecisionContext(
      studentId: studentId,
      message: studentMessage,
      profile: profile,
      memory: mem,
      phase: phase,
      assessmentState: assessmentState,
    );

    final decision = _decisionEngine.process(
      message: studentMessage,
      context: decCtx,
    );

    // ── Step 4: Apply confirmed language ────────────────────────────────────
    final updatedLanguage =
        provisionalLang.applyDetection(decision.detectedLanguage);

    // ── Step 5: Build ConversationContext snapshot ──────────────────────────
    final ctx = conv.ConversationContext(
      sessionId: sessionId,
      studentId: studentId,
      studentMessage: studentMessage,
      decision: decision,
      profile: profile,
      memory: mem,
      phase: phase,
      language: updatedLanguage,
      policy: _policy,
      activeQuestion: assessmentState?.activeQuestion,
      turnAt: now,
    );

    // ── Step 6: Route ────────────────────────────────────────────────────────
    final routeDecision = _router.route(ctx);

    // ── Step 7: Dispatch to controller ──────────────────────────────────────
    final result = await _controller.handle(
      context: ctx,
      routeDecision: routeDecision,
    );

    // ── Step 8: Append engine turn ───────────────────────────────────────────
    final engineTurn = _buildTurn(
      message: result.response,
      isEngine: true,
      phase: result.updatedPhase,
      eventType: result.event.type,
      intentName: decision.detectedIntent.name,
      wasInterruption:
          routeDecision.route == ConversationRoute.academicDiscussion,
    );
    final finalMemory = result.updatedMemory.appendTurn(engineTurn);

    // ── Step 9: Return output ────────────────────────────────────────────────
    return ConversationTurnOutput(
      response: result.response,
      updatedMemory: finalMemory,
      updatedPhase: result.updatedPhase,
      updatedLanguage: result.updatedLanguage.nextTurn(),
      updatedProfile: result.updatedProfile,
      route: routeDecision.route,
      event: result.event,
      assessmentAdvanced: result.assessmentAdvanced,
      recommendationGenerated: result.recommendationGenerated,
    );
  }

  // ─── Factory constructor ───────────────────────────────────────────────────

  /// Convenience factory that wires all engines from their parts.
  factory ConversationEngine.create({
    required CognitiveDecisionEngine decisionEngine,
    required AnswerIntelligenceEngine answerEngine,
    required AdaptiveAssessmentEngine assessmentEngine,
    required AssessmentController assessmentController,
    required MajorMatchingEngine matchingEngine,
    required RecommendationEngine recommendationEngine,
    required ExplainableAIEngine explainableEngine,
    required LlmService llmService,
    required List<Major> allMajors,
    required List<Question> allQuestions,
    ConversationPolicy policy = const ConversationPolicy(),
  }) => ConversationEngine(
    decisionEngine: decisionEngine,
    controller: ConversationController(
      answerEngine: answerEngine,
      assessmentEngine: assessmentEngine,
      assessmentController: assessmentController,
      matchingEngine: matchingEngine,
      recommendationEngine: recommendationEngine,
      explainableEngine: explainableEngine,
      explanationService: LLMExplanationService(
        llmService: llmService,
        fallback: const LocalExplanationFallback(),
      ),
      allMajors: allMajors,
      allQuestions: allQuestions,
    ),
    router: const ConversationRouter(),
    policy: policy,
    allMajors: allMajors,
    allQuestions: allQuestions,
  );

  // ─── Private helpers ───────────────────────────────────────────────────────

  ConversationLanguage _detectLanguage(
    String message,
    ConversationLanguage current,
  ) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);
    final hasLatin = RegExp(r'[a-zA-Z]{3,}').hasMatch(message);

    final lang = hasArabic
        ? Language.arabic
        : hasLatin
            ? Language.english
            : current.active;

    // Build a DetectedLanguage value for applyDetection().
    final detectedLang = DetectedLanguage(
      language: lang,
      confidence: 0.9,
      arabicRatio: hasArabic ? 0.9 : 0.0,
      latinRatio: hasLatin ? 0.9 : 0.0,
    );
    return current.applyDetection(detectedLang);
  }

  ConversationTurnRecord _buildTurn({
    required String message,
    required bool isEngine,
    required ConversationPhase phase,
    required ConversationEventType eventType,
    String? intentName,
    bool wasInterruption = false,
  }) => ConversationTurnRecord(
    turnId: _uuid.v4(),
    role: isEngine ? MessageRole.engine : MessageRole.student,
    content: message,
    intentName: intentName,
    wasAssessmentTurn: phase.stage.canReceiveAnswer,
    wasInterruption: wasInterruption,
    wasClarification: eventType == ConversationEventType.questionExplained,
    timestamp: DateTime.now().toUtc(),
  );

  dec.ConversationContext _buildDecisionContext({
    required String studentId,
    required String message,
    required StudentCognitiveProfile profile,
    required ConversationMemory memory,
    required ConversationPhase phase,
    required dynamic assessmentState,
  }) {
    final state = assessmentState;
    return dec.ConversationContext(
      studentId: studentId,
      currentPhase: state?.phase ?? phase.assessmentPhase,
      currentGoal: AssessmentGoal(
        id: 'default',
        type: AssessmentGoalType.majorSelection,
        focusDomainIds: const [],
        createdAt: DateTime.now().toUtc(),
      ),
      activeQuestion: state?.activeQuestion,
      cognitiveProfile: profile,
      recentHistory: memory
          .contextWindow(_policy)
          .map((t) => dec.ConversationTurn(
                role: t.role,
                content: t.content,
                timestamp: t.timestamp,
              ))
          .toList(),
      lastEngineMessage: memory.history.lastEngineMessage,
      lastStudentMessage: memory.history.lastStudentMessage,
      answeredQuestionIds: state?.askedQuestionIds ?? const [],
      skippedQuestionIds: state?.skippedQuestionIds ?? const [],
      unevidencedDimensionKeys: const [],
      consecutiveOffTopicCount: phase.interruptionCount,
      discussionCount: phase.discussionDepth,
      clarificationCount: phase.clarificationCount,
      // ── Critical fix: pass conversation stage so the ContinuationDetector
      // can resolve context-dependent messages (e.g. "هيا بنا" in introduction
      // stage = startAssessment, NOT an academic question).
      conversationStage: phase.stage,
      activeLanguage: Language.arabic,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
