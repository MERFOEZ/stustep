/// SAIE — ContinuationDetector
///
/// Detects student intent to start or continue the assessment.
///
/// This detector is the core fix for the chatbot mis-classification bug.
/// Short, imperative, context-free messages ("هيا بنا", "ابدأ", "التالي",
/// "وين الأسئلة") must be resolved by conversation STATE — not by their words.
///
/// Rules (context-driven, not keyword-driven):
///
/// [startAssessment]
///   - Activated primarily by [ConversationContext.isWaitingToStart].
///   - Any non-question, non-greeting, non-academic short message in
///     introduction stage = high prior for startAssessment.
///   - Greeting-like messages that follow a "ready?" system prompt also qualify.
///
/// [continueAssessment]
///   - Activated by [ConversationContext.isBetweenQuestions].
///   - Message is not a question, not a skip/restart/greeting.
///   - Message is short and non-academic.
library;

import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ContinuationDetector
// ─────────────────────────────────────────────────────────────────────────────

/// Context-aware detector for [SupportedIntent.startAssessment] and
/// [SupportedIntent.continueAssessment].
///
/// Uses the [ConversationContext.conversationStage] as the primary signal
/// — never keyword-only matching. The current context resolves ambiguity.
final class ContinuationDetector {
  const ContinuationDetector();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Scores [SupportedIntent.startAssessment].
  ///
  /// High score when:
  ///   - Stage is introduction (student has not yet started).
  ///   - Message is not a question, not clearly an academic question,
  ///     not a skip/restart/recommendation request.
  ///   - Message is short/imperative (≤ 6 words) OR looks like readiness.
  IntentScore scoreStart(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    // Primary gate: must be in introduction / pre-assessment state.
    if (!context.isWaitingToStart) {
      return IntentScore(
        intent: SupportedIntent.startAssessment,
        score: 0.0,
        signals: const {'not_waiting_to_start': 0.0},
      );
    }

    final signals = <String, double>{};
    double total = 0.0;

    // ── Signal 1: Stage = introduction gives strong base prior. ──────────────
    signals['introduction_stage'] = 0.55;
    total += 0.55;

    // ── Signal 2: Message is not a question or concept inquiry. ──────────────
    if (!analysis.looksLikeConceptQuestion &&
        !analysis.requestsQuestionClarification) {
      signals['not_a_question'] = 0.20;
      total += 0.20;
    }

    // ── Signal 3: No disqualifying signals. ──────────────────────────────────
    if (!analysis.containsSkipSignal &&
        !analysis.containsRestartSignal &&
        !analysis.containsRecommendationSignal) {
      signals['no_disqualifying_signals'] = 0.10;
      total += 0.10;
    }

    // ── Signal 4: Short imperative — classic "let's go" structure. ───────────
    final wc = analysis.tokens.wordCount;
    if (wc <= 5) {
      signals['short_message'] = 0.10;
      total += 0.10;
    }

    // ── Signal 5: Last engine message contained a readiness question. ─────────
    // e.g. "هل أنت مستعد لنبدأ؟"
    final last = context.lastEngineMessage ?? '';
    if ((last.contains('مستعد') ||
            last.contains('هل أنت') ||
            last.contains('نبدأ') ||
            last.contains('ابدأ') ||
            last.contains('لنبدأ')) &&
        (last.contains('؟') || last.contains('?'))) {
      signals['engine_asked_readiness'] = 0.15;
      total += 0.15;
    }

    // ── Signal 6: Greeting structure counts when stage is introduction. ───────
    // "مرحبا، ابدأ" is still a start request.
    if (analysis.looksLikeGreeting && wc <= 3) {
      // Short greeting in intro stage = could be readiness, slight bump.
      signals['greeting_in_intro'] = 0.05;
      total += 0.05;
    }

    // Subtract if the message looks strongly academic.
    if (analysis.looksLikeConceptQuestion) {
      signals['academic_penalty'] = -0.30;
      total -= 0.30;
    }

    return IntentScore(
      intent: SupportedIntent.startAssessment,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Scores [SupportedIntent.continueAssessment].
  ///
  /// High score when:
  ///   - Stage is assessment AND no pending question (between questions).
  ///   - Message is short, non-question, non-academic.
  IntentScore scoreContinue(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    // Primary gate: must be in assessment, between questions.
    if (!context.isBetweenQuestions) {
      return IntentScore(
        intent: SupportedIntent.continueAssessment,
        score: 0.0,
        signals: const {'not_between_questions': 0.0},
      );
    }

    final signals = <String, double>{};
    double total = 0.0;

    // ── Signal 1: Stage = assessment, no active question. ────────────────────
    signals['between_questions'] = 0.55;
    total += 0.55;

    // ── Signal 2: Not a question, not academic. ───────────────────────────────
    if (!analysis.looksLikeConceptQuestion &&
        !analysis.requestsQuestionClarification) {
      signals['not_a_question'] = 0.20;
      total += 0.20;
    }

    // ── Signal 3: No special signals. ────────────────────────────────────────
    if (!analysis.containsSkipSignal &&
        !analysis.containsRestartSignal &&
        !analysis.containsRecommendationSignal) {
      signals['no_disqualifying_signals'] = 0.10;
      total += 0.10;
    }

    // ── Signal 4: Short message = proceed command. ────────────────────────────
    if (analysis.tokens.wordCount <= 5) {
      signals['short_message'] = 0.10;
      total += 0.10;
    }

    // Subtract if academic.
    if (analysis.looksLikeConceptQuestion) {
      signals['academic_penalty'] = -0.25;
      total -= 0.25;
    }

    return IntentScore(
      intent: SupportedIntent.continueAssessment,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  // ─── Stage helpers ─────────────────────────────────────────────────────────

  /// Returns the macro assessment state label for logging.
  static String describeStage(ConversationContext ctx) {
    if (ctx.isWaitingToStart) return 'WaitingToStart';
    if (ctx.isBetweenQuestions) return 'BetweenQuestions';
    if (ctx.hasPendingQuestion) return 'WaitingForAnswer';
    if (ctx.isInRecommendationPhase) return 'RecommendationPhase';
    return ctx.conversationStage.name;
  }
}
