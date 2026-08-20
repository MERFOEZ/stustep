/// SAIE — AnswerDetector
///
/// Determines whether a student message is an answer to the currently active
/// question. Score is context-dependent — it considers the question type,
/// the conversation history, and structural message signals.
/// Never uses keyword-only matching.
library;

import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/semantic_message_classifier.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerDetector
// ─────────────────────────────────────────────────────────────────────────────

/// Computes the [IntentScore] for [SupportedIntent.answerCurrentQuestion].
///
/// A message is a strong candidate answer when:
/// - There IS an active question (prerequisite).
/// - The message is structurally non-question.
/// - The message does not contain skip/restart/recommendation signals.
/// - The message does not look like a concept question or greeting.
/// - The message length is proportional to the question type.
/// - The engine was last awaiting an answer (conversation history signal).
final class AnswerDetector {
  const AnswerDetector();

  /// Computes an [IntentScore] for [SupportedIntent.answerCurrentQuestion].
  IntentScore score(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    // Hard prerequisite: no active question → score zero.
    if (!context.hasPendingQuestion) {
      return IntentScore(
        intent: SupportedIntent.answerCurrentQuestion,
        score: 0.0,
        signals: const {'no_active_question': -1.0},
      );
    }

    // ── SEMANTIC TYPE VETO ────────────────────────────────────────────────────
    // If the Message Understanding Layer has already classified this message as
    // a non-answer type (clarification, definition, options request, etc.),
    // immediately return zero. This is the hard guard that prevents any
    // clarification request from scoring as an answer.
    final semanticType = analysis.semanticType;
    if (semanticType != SemanticMessageType.unknown &&
        semanticType != SemanticMessageType.answer) {
      return IntentScore(
        intent: SupportedIntent.answerCurrentQuestion,
        score: 0.0,
        signals: {'semantic_type_veto': -1.0, 'semantic_type': 0.0},
      );
    }

    final signals = <String, double>{};
    double total = 0.0;

    // Signal 1: Active question exists (+0.35 base).
    signals['active_question_present'] = 0.35;
    total += 0.35;

    // Signal 2: Message is not a question itself.
    if (!analysis.looksLikeConceptQuestion &&
        !analysis.requestsQuestionClarification) {
      signals['not_a_question'] = 0.20;
      total += 0.20;
    } else {
      // If it IS a question — this is likely RequestExplanation, not an answer.
      signals['is_a_question'] = -0.20;
      total -= 0.20;
    }

    // Signal 3: No disqualifying signals.
    if (!analysis.containsSkipSignal &&
        !analysis.containsRestartSignal &&
        !analysis.containsRecommendationSignal) {
      signals['no_disqualifying_signals'] = 0.15;
      total += 0.15;
    }

    // Signal 4: Message is not a greeting.
    if (!analysis.looksLikeGreeting) {
      signals['not_a_greeting'] = 0.05;
      total += 0.05;
    }

    // Signal 5: Last engine message looks like a question (was awaiting answer).
    if (context.lastEngineMessage != null) {
      final last = context.lastEngineMessage!;
      if (last.contains('?') || last.contains('؟')) {
        signals['engine_asked_question'] = 0.15;
        total += 0.15;
      }
    }

    // Signal 6: Question type–specific length check.
    final q = context.activeQuestion!;
    final wordCount = analysis.tokens.wordCount;

    switch (q.type) {
      case QuestionType.multipleChoice || QuestionType.multiSelect:
        // Multiple choice answers tend to be short (1-3 words) or option keys.
        if (wordCount <= 6) {
          signals['appropriate_length_mc'] = 0.10;
          total += 0.10;
        }
      case QuestionType.likertScale:
        // Likert answers are typically 1-4 words (numbers or sentiment words).
        if (wordCount <= 5) {
          signals['appropriate_length_likert'] = 0.10;
          total += 0.10;
        }
      case QuestionType.openEnded:
        // Open-ended answers tend to be longer.
        if (wordCount >= 5) {
          signals['appropriate_length_open'] = 0.08;
          total += 0.08;
        }
      case QuestionType.ranking:
        signals['ranking_type'] = 0.05;
        total += 0.05;
      default:
        break;
    }

    // Signal 7: Message references the active question topic.
    if (analysis.referencesCurrentTopic) {
      signals['references_current_topic'] = 0.10;
      total += 0.10;
    }

    // Signal 8: Contradiction signals reduce answer confidence.
    if (analysis.looksLikeContradiction) {
      signals['possible_contradiction'] = -0.05;
      total -= 0.05;
    }

    final finalScore = total.clamp(0.0, 1.0);
    return IntentScore(
      intent: SupportedIntent.answerCurrentQuestion,
      score: finalScore,
      signals: signals,
    );
  }
}
