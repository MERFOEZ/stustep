/// SAIE — CognitiveDecisionEngine
///
/// The central brain of the SAIE system.
///
/// Every student message MUST pass through this engine before any downstream
/// processing. No profile update, question advance, response generation, or
/// any other action may occur without a [DecisionResult] from this engine.
///
/// Pipeline per message:
/// 1. Analyse message → [MessageAnalysis]
/// 2. Detect language → update language policy if switched
/// 3. Detect contradiction → block profile update and issue clarification
/// 4. Classify intent → [DecisionConfidence]
/// 5. Evaluate clarification → [ClarificationRequest?]
/// 6. Assemble → [DecisionResult]
library;

import 'package:uuid/uuid.dart';
import 'package:stustep/features/saie/decision/clarification_detector.dart';
import 'package:stustep/features/saie/decision/contradiction_detector.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_result.dart';
import 'package:stustep/features/saie/decision/intent_classifier.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/message_analyzer_service.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CognitiveDecisionEngine
// ─────────────────────────────────────────────────────────────────────────────

/// The central message processing engine.
///
/// Stateless — all state is provided via [ConversationContext].
/// Every call to [process] is deterministic given the same inputs.
final class CognitiveDecisionEngine {
  static const _uuid = Uuid();

  final MessageAnalyzerService _analyzerService;
  final IntentClassifier _classifier;
  final ClarificationDetector _clarificationDetector;
  final ContradictionDetector _contradictionDetector;

  const CognitiveDecisionEngine({
    MessageAnalyzerService analyzerService = const MessageAnalyzerService(),
    IntentClassifier classifier = const IntentClassifier(),
    ClarificationDetector clarificationDetector =
        const ClarificationDetector(),
    ContradictionDetector contradictionDetector =
        const ContradictionDetector(),
  })  : _analyzerService = analyzerService,
        _classifier = classifier,
        _clarificationDetector = clarificationDetector,
        _contradictionDetector = contradictionDetector;

  // ─── Core Entry Point ─────────────────────────────────────────────────────

  /// Processes a raw student [message] within the given [context].
  ///
  /// Returns a [DecisionResult] that authorises or blocks every downstream action.
  DecisionResult process({
    required String message,
    required ConversationContext context,
  }) {
    final requestId = _uuid.v4();
    final now = DateTime.now().toUtc();

    // ── Step 1: Structural message analysis ──
    final analysis = _analyzerService.analyse(message, context);

    // ── Step 2: Language detection + switch detection ──
    final detectedLang = analysis.detectedLanguage;
    final previousLang = context.activeLanguage;
    final languageSwitched =
        detectedLang.language != Language.unknown &&
        detectedLang.language != Language.mixed &&
        detectedLang.language != previousLang &&
        detectedLang.confidence >= 0.70;

    // ── Step 3: Contradiction detection ──
    final contradictionResult =
        _contradictionDetector.detect(analysis, context);
    final contradictionDetected =
        contradictionResult != null && contradictionResult.signal != null;
    final contradictionMsg =
        contradictionDetected ? contradictionResult.clarificationMessage : null;

    // ── Step 4: Intent classification ──
    final confidence = _classifier.classify(analysis, context);
    final winner = confidence.winner;

    // ── Step 5: Clarification evaluation ──
    final clarificationEval = _clarificationDetector.evaluate(
      confidence,
      analysis,
      context,
    );

    final shouldClarify = clarificationEval.request != null ||
        contradictionDetected;

    // Contradiction always blocks profile update and forces clarification.
    ClarificationRequest? clarificationRequest = clarificationEval.request;
    if (contradictionDetected && contradictionMsg != null) {
      clarificationRequest = ClarificationRequest(
        clarificationMessage: contradictionMsg,
        reason: 'Contradiction detected against prior student statement.',
        repeatQuestionAfter: context.hasPendingQuestion,
      );
    }

    // Profile update is blocked by contradictions and clarification turns.
    // For answerCurrentQuestion, the decisive-confidence gate is intentionally
    // bypassed — the AnswerQualityEvaluator's ScoreBand.invalid (multiplier=0)
    // already rejects low-quality answers at the evidence layer, so requiring
    // intent-level decisiveness here would silently discard valid answers whose
    // phrasing was unusual but whose content was real.
    final shouldUpdateProfile = !shouldClarify &&
        !contradictionDetected &&
        winner.intent.mayCauseProfileUpdate &&
        (confidence.isDecisive ||
            winner.intent == SupportedIntent.answerCurrentQuestion);

    final shouldRepeatQuestion = clarificationEval.request?.repeatQuestionAfter ??
        (winner.intent == SupportedIntent.requestExplanation &&
            context.hasPendingQuestion);

    // Assessment advances when the student answers OR when they explicitly
    // want to start/continue — both map to the assessment pipeline.
    final shouldAdvanceAssessment = !shouldClarify &&
        !contradictionDetected &&
        (winner.intent == SupportedIntent.answerCurrentQuestion ||
            winner.intent == SupportedIntent.startAssessment ||
            winner.intent == SupportedIntent.continueAssessment) &&
        confidence.isDecisive;

    // ── Step 7: Downstream requirements ──
    final requiresLLM = winner.intent == SupportedIntent.askAcademicQuestion ||
        winner.intent == SupportedIntent.generalDiscussion ||
        winner.intent == SupportedIntent.requestExplanation ||
        !confidence.isDecisive;

    final requiresKnowledgeBase = winner.intent.requiresKnowledgeBase;

    final requiresReasoning =
        winner.intent == SupportedIntent.answerCurrentQuestion ||
        winner.intent == SupportedIntent.requestRecommendation ||
        contradictionDetected;

    // ── Step 8: Build reasoning trace ──
    final trace = _buildTrace(
      winner: winner.intent,
      winnerScore: winner.score,
      decisive: confidence.isDecisive,
      langSwitched: languageSwitched,
      contradiction: contradictionDetected,
      clarify: shouldClarify,
      trigger: clarificationEval.trigger,
    );

    return DecisionResult(
      requestId: requestId,
      detectedIntent: winner.intent,
      confidence: confidence,
      detectedLanguage: detectedLang,
      languageSwitched: languageSwitched,
      shouldUpdateProfile: shouldUpdateProfile,
      shouldAskClarification: shouldClarify,
      clarificationRequest: clarificationRequest,
      shouldRepeatQuestion: shouldRepeatQuestion,
      shouldAdvanceAssessment: shouldAdvanceAssessment,
      requiresLLM: requiresLLM,
      requiresKnowledgeBase: requiresKnowledgeBase,
      requiresReasoning: requiresReasoning,
      contradictionDetected: contradictionDetected,
      contradictionSignal: contradictionResult?.signal,
      reasoningTrace: trace,
      producedAt: now,
      messageAnalysis: analysis,  // ← carries SemanticMessageType for router
    );
  }

  // ─── Reasoning Trace ──────────────────────────────────────────────────────

  String _buildTrace({
    required SupportedIntent winner,
    required double winnerScore,
    required bool decisive,
    required bool langSwitched,
    required bool contradiction,
    required bool clarify,
    required ClarificationTrigger? trigger,
  }) {
    final buf = StringBuffer();
    buf.write('[CognitiveDecisionEngine] ');
    buf.write('Winner: ${winner.name} @ ${winnerScore.toStringAsFixed(3)}. ');
    buf.write('Decisive: $decisive. ');
    if (langSwitched) buf.write('Language switched. ');
    if (contradiction) buf.write('Contradiction detected. ');
    if (clarify) {
      buf.write('Clarification triggered');
      if (trigger != null) buf.write(' (${trigger.name})');
      buf.write('. ');
    }
    buf.write('ProfileUpdate: ${!clarify && !contradiction}. ');
    buf.write('AdvanceAssessment: ${winner == SupportedIntent.answerCurrentQuestion && decisive && !clarify}.');
    return buf.toString();
  }
}
