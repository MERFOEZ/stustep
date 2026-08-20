/// SAIE — QuestionDetector
///
/// Determines whether a student message is asking an academic or domain
/// question (i.e., about a subject, field, or concept), rather than
/// answering the active assessment question.
library;

import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionDetector
// ─────────────────────────────────────────────────────────────────────────────

/// Computes [IntentScore] values for:
/// - [SupportedIntent.askAcademicQuestion]
/// - [SupportedIntent.requestExplanation]
///
/// The distinction is:
/// - [askAcademicQuestion]: the student is asking about an academic domain
///   (e.g., "What is Software Engineering?", "ما هو علم البيانات؟").
/// - [requestExplanation]: the student is asking to clarify something in the
///   *current question* (e.g., "ماذا تعني رياضية؟").
final class QuestionDetector {
  const QuestionDetector();

  /// Returns a score for [SupportedIntent.askAcademicQuestion].
  IntentScore scoreAcademic(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    final signals = <String, double>{};
    double total = 0.0;

    // Must be a question.
    if (!analysis.looksLikeConceptQuestion &&
        !analysis.tokens.endsWithQuestion) {
      return IntentScore(
        intent: SupportedIntent.askAcademicQuestion,
        score: 0.0,
        signals: const {'not_a_question': -1.0},
      );
    }

    // Signal 1: Ends with question mark.
    if (analysis.tokens.endsWithQuestion) {
      signals['ends_with_question'] = 0.30;
      total += 0.30;
    }

    // Signal 2: Message looks like a concept question.
    if (analysis.looksLikeConceptQuestion) {
      signals['concept_question_structure'] = 0.30;
      total += 0.30;
    }

    // Signal 3: Does NOT reference the current question topic
    // (suggesting it's about something else, not clarification).
    if (!analysis.requestsQuestionClarification) {
      signals['not_clarification'] = 0.20;
      total += 0.20;
    } else {
      // References the current question → more likely RequestExplanation.
      signals['references_question_topic'] = -0.25;
      total -= 0.25;
    }

    // Signal 4: Medium-to-long message (questions tend to have a subject).
    if (analysis.tokens.wordCount >= 3) {
      signals['sufficient_length'] = 0.10;
      total += 0.10;
    }

    // Signal 5: No active question makes academic question more likely.
    if (!context.hasPendingQuestion) {
      signals['no_pending_question'] = 0.10;
      total += 0.10;
    }

    return IntentScore(
      intent: SupportedIntent.askAcademicQuestion,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Returns a score for [SupportedIntent.requestExplanation].
  IntentScore scoreExplanation(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    final signals = <String, double>{};
    double total = 0.0;

    // Must be a question or end with question mark.
    if (!analysis.looksLikeConceptQuestion &&
        !analysis.tokens.endsWithQuestion &&
        !analysis.requestsQuestionClarification) {
      return IntentScore(
        intent: SupportedIntent.requestExplanation,
        score: 0.0,
        signals: const {'not_explanation_shaped': -1.0},
      );
    }

    // Signal 1: Specifically requests clarification of active question.
    if (analysis.requestsQuestionClarification) {
      signals['clarification_of_question'] = 0.45;
      total += 0.45;
    }

    // Signal 2: Active question exists (explanation makes sense).
    if (context.hasPendingQuestion) {
      signals['active_question_present'] = 0.25;
      total += 0.25;
    }

    // Signal 3: Short message — explanatory requests tend to be brief.
    if (analysis.tokens.isVeryShort || analysis.tokens.wordCount <= 7) {
      signals['short_message'] = 0.15;
      total += 0.15;
    }

    // Signal 4: References current topic.
    if (analysis.referencesCurrentTopic) {
      signals['references_current_topic'] = 0.15;
      total += 0.15;
    }

    return IntentScore(
      intent: SupportedIntent.requestExplanation,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  // ── Question Understanding Layer detectors ────────────────────────────────

  /// Returns a score for [SupportedIntent.askWordMeaning].
  /// Fires when the student asks what a word/concept means.
  IntentScore scoreWordMeaning(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.requestsWordMeaning || !context.hasPendingQuestion) {
      return IntentScore(
        intent: SupportedIntent.askWordMeaning,
        score: 0.0,
        signals: const {'no_word_meaning_signal': 0.0},
      );
    }
    double total = 0.70;
    final signals = <String, double>{'word_meaning_signal': 0.70};
    if (context.hasPendingQuestion) {
      signals['active_question'] = 0.15;
      total += 0.15;
    }
    return IntentScore(
      intent: SupportedIntent.askWordMeaning,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Returns a score for [SupportedIntent.expressUncertainty].
  /// Fires when the student expresses that they don't know or aren't sure.
  IntentScore scoreUncertainty(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.expressesUncertainty || !context.hasPendingQuestion) {
      return IntentScore(
        intent: SupportedIntent.expressUncertainty,
        score: 0.0,
        signals: const {'no_uncertainty_signal': 0.0},
      );
    }
    double total = 0.70;
    final signals = <String, double>{'uncertainty_signal': 0.70};
    if (context.hasPendingQuestion) {
      signals['active_question'] = 0.15;
      total += 0.15;
    }
    return IntentScore(
      intent: SupportedIntent.expressUncertainty,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Returns a score for [SupportedIntent.askWhyThisQuestion].
  /// Fires when the student asks why this specific question is being asked.
  IntentScore scoreWhyThisQuestion(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.requestsWhyThisQuestion || !context.hasPendingQuestion) {
      return IntentScore(
        intent: SupportedIntent.askWhyThisQuestion,
        score: 0.0,
        signals: const {'no_why_signal': 0.0},
      );
    }
    double total = 0.75;
    final signals = <String, double>{'why_question_signal': 0.75};
    if (context.hasPendingQuestion) {
      signals['active_question'] = 0.10;
      total += 0.10;
    }
    return IntentScore(
      intent: SupportedIntent.askWhyThisQuestion,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Returns a score for [SupportedIntent.requestAlternativeQuestion].
  /// Fires when the student explicitly requests a different question.
  IntentScore scoreAlternativeQuestion(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.requestsAlternativeQuestion || !context.hasPendingQuestion) {
      return IntentScore(
        intent: SupportedIntent.requestAlternativeQuestion,
        score: 0.0,
        signals: const {'no_alternative_signal': 0.0},
      );
    }
    double total = 0.70;
    final signals = <String, double>{'alternative_question_signal': 0.70};
    if (context.hasPendingQuestion) {
      signals['active_question'] = 0.15;
      total += 0.15;
    }
    return IntentScore(
      intent: SupportedIntent.requestAlternativeQuestion,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Returns a score for [SupportedIntent.requestExamples].
  /// Fires when the student requests examples relevant to the current question.
  IntentScore scoreExamples(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.requestsExamples || !context.hasPendingQuestion) {
      return IntentScore(
        intent: SupportedIntent.requestExamples,
        score: 0.0,
        signals: const {'no_examples_signal': 0.0},
      );
    }
    double total = 0.70;
    final signals = <String, double>{'examples_signal': 0.70};
    if (context.hasPendingQuestion) {
      signals['active_question'] = 0.15;
      total += 0.15;
    }
    return IntentScore(
      intent: SupportedIntent.requestExamples,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }
}
