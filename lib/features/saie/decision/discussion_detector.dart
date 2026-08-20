/// SAIE — DiscussionDetector
///
/// Detects whether a student message is general discussion, an off-topic
/// statement, a greeting, a skip signal, a restart signal, or a
/// recommendation request. Returns scored candidates for all these intents.
library;

import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DiscussionDetector
// ─────────────────────────────────────────────────────────────────────────────

/// Computes [IntentScore] values for all non-answer intents:
/// - [SupportedIntent.greeting]
/// - [SupportedIntent.generalDiscussion]
/// - [SupportedIntent.skipQuestion]
/// - [SupportedIntent.restartAssessment]
/// - [SupportedIntent.requestRecommendation]
/// - [SupportedIntent.offTopic]
final class DiscussionDetector {
  const DiscussionDetector();

  /// Computes score for [SupportedIntent.greeting].
  IntentScore scoreGreeting(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.looksLikeGreeting) {
      return IntentScore(
        intent: SupportedIntent.greeting,
        score: 0.0,
      );
    }
    final signals = <String, double>{};
    double total = 0.0;

    signals['greeting_structure'] = 0.60;
    total += 0.60;

    // Greetings tend to be very short.
    if (analysis.tokens.isSingleWord || analysis.tokens.isVeryShort) {
      signals['very_short'] = 0.20;
      total += 0.20;
    }

    // Start of session boosts greeting likelihood.
    if (context.answeredQuestionIds.isEmpty && context.discussionCount == 0) {
      signals['session_start'] = 0.20;
      total += 0.20;
    }

    return IntentScore(
      intent: SupportedIntent.greeting,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Computes score for [SupportedIntent.generalDiscussion].
  IntentScore scoreDiscussion(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    final signals = <String, double>{};
    double total = 0.0;

    // Not a question, not an answer structure, not a greeting, not special.
    final isNeutral = !analysis.looksLikeGreeting &&
        !analysis.containsSkipSignal &&
        !analysis.containsRestartSignal &&
        !analysis.containsRecommendationSignal;

    if (!isNeutral) {
      return IntentScore(intent: SupportedIntent.generalDiscussion, score: 0.0);
    }

    // General statement — moderate base score.
    signals['neutral_message'] = 0.30;
    total += 0.30;

    // Medium or long messages suggest discussion.
    if (analysis.tokens.wordCount >= 5) {
      signals['medium_length'] = 0.20;
      total += 0.20;
    }

    // Already in discussion mode boosts likelihood.
    if (context.discussionCount > 0) {
      signals['ongoing_discussion'] = 0.15;
      total += 0.15;
    }

    // Concept question + no active question → likely general discussion.
    if (analysis.looksLikeConceptQuestion && !context.hasPendingQuestion) {
      signals['concept_no_pending'] = 0.20;
      total += 0.20;
    }

    return IntentScore(
      intent: SupportedIntent.generalDiscussion,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Computes score for [SupportedIntent.skipQuestion].
  IntentScore scoreSkip(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.containsSkipSignal) {
      return IntentScore(intent: SupportedIntent.skipQuestion, score: 0.0);
    }
    final signals = <String, double>{'skip_signal': 0.70};
    double total = 0.70;

    if (context.hasPendingQuestion) {
      signals['active_question'] = 0.20;
      total += 0.20;
    }
    if (analysis.tokens.isVeryShort) {
      signals['short_command'] = 0.10;
      total += 0.10;
    }

    return IntentScore(
      intent: SupportedIntent.skipQuestion,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Computes score for [SupportedIntent.restartAssessment].
  IntentScore scoreRestart(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.containsRestartSignal) {
      return IntentScore(intent: SupportedIntent.restartAssessment, score: 0.0);
    }
    final signals = <String, double>{'restart_signal': 0.75};
    double total = 0.75;

    // Stronger if already answered some questions (restart is meaningful).
    if (context.answeredQuestionIds.isNotEmpty) {
      signals['has_history'] = 0.15;
      total += 0.15;
    }
    if (analysis.tokens.isVeryShort) {
      signals['short_command'] = 0.10;
      total += 0.10;
    }

    return IntentScore(
      intent: SupportedIntent.restartAssessment,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Computes score for [SupportedIntent.requestRecommendation].
  IntentScore scoreRecommendation(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.containsRecommendationSignal) {
      return IntentScore(
        intent: SupportedIntent.requestRecommendation,
        score: 0.0,
      );
    }
    final signals = <String, double>{'recommendation_signal': 0.65};
    double total = 0.65;

    // More meaningful when profile has evidence.
    if (context.cognitiveProfile.evidenceCount >= 3) {
      signals['profile_has_evidence'] = 0.20;
      total += 0.20;
    }
    if (analysis.tokens.endsWithQuestion) {
      signals['question_form'] = 0.10;
      total += 0.10;
    }

    return IntentScore(
      intent: SupportedIntent.requestRecommendation,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }

  /// Computes score for [SupportedIntent.offTopic].
  IntentScore scoreOffTopic(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    final signals = <String, double>{};
    double total = 0.0;

    // Very high consecutive off-topic count raises this score.
    if (context.consecutiveOffTopicCount > 2) {
      signals['repeated_off_topic'] = 0.40;
      total += 0.40;
    }

    // No topic reference, no question, no greeting, no special signal.
    final nothingDetected = !analysis.looksLikeGreeting &&
        !analysis.looksLikeAnswer &&
        !analysis.looksLikeConceptQuestion &&
        !analysis.referencesCurrentTopic &&
        !analysis.containsSkipSignal &&
        !analysis.containsRestartSignal &&
        !analysis.containsRecommendationSignal;

    if (nothingDetected) {
      signals['no_signals_detected'] = 0.30;
      total += 0.30;
    }

    return IntentScore(
      intent: SupportedIntent.offTopic,
      score: total.clamp(0.0, 1.0),
      signals: signals,
    );
  }
}
