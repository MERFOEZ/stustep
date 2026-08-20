/// SAIE — SemanticMessageClassifier (Message Understanding Layer)
///
/// The authoritative semantic-level understanding of a student message.
/// This is executed BEFORE any routing decision and produces a
/// [SemanticMessageType] that the [ConversationRouter] must honour.
///
/// === DESIGN PRINCIPLE ===
/// The old system tried to classify intent from weak signals and allowed
/// answers to "win" simply because an active question existed.
///
/// This layer inverts the logic:
///   - A message is an ANSWER only when it positively looks like one.
///   - Any non-answer signal (request, question, confusion, location probe)
///     VETOES the answer classification UNCONDITIONALLY.
///
/// === GUARANTEE ===
/// If [SemanticMessageType] is NOT [SemanticMessageType.answer], the
/// [ConversationRouter] MUST NOT route to [ConversationRoute.continueAssessment].
///
/// This guarantee is enforced at the router level, not here.
/// This layer only classifies. It does NOT advance assessment state.
/// It does NOT generate responses. It does NOT update the profile.
library;

import 'package:stustep/features/saie/decision/contextual_answer_interpreter.dart';
import 'package:stustep/features/saie/decision/semantic_message_type.dart';

export 'package:stustep/features/saie/decision/semantic_message_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MessageAnalysis (partial interface for classification)
// ─────────────────────────────────────────────────────────────────────────────

/// The subset of [MessageAnalysis] fields needed by [SemanticMessageClassifier].
/// Using an abstract interface breaks the circular dependency:
///   message_analyzer → semantic_message_type  (one-way)
///   semantic_message_classifier → semantic_message_type (one-way)
abstract interface class ClassifiableMessage {
  bool get looksLikeGreeting;
  bool get looksLikeConceptQuestion;
  bool get looksLikeAnswer;
  /// True when the message contains BOTH answer content AND a trailing
  /// meta-question (e.g. "I play games, can I mention them?").
  bool get looksLikeCompoundMessage;
  bool get containsSkipSignal;
  bool get containsRestartSignal;
  bool get containsRecommendationSignal;
  bool get requestsQuestionClarification;
  bool get requestsWordMeaning;
  bool get expressesUncertainty;
  bool get requestsWhyThisQuestion;
  bool get requestsAlternativeQuestion;
  bool get requestsExamples;
  bool get requestsOptions;
  bool get requestsSimplification;
  // Token info needed for farewell check
  String get rawMessage;
  /// The contextual interpretation produced by [ContextualAnswerInterpreter].
  /// Null when no active question is present.
  AnswerInterpretation? get answerInterpretation;
}

// ─────────────────────────────────────────────────────────────────────────────
// SemanticMessageClassifier
// ─────────────────────────────────────────────────────────────────────────────

/// Classifies the semantic type of a student message.
///
/// This is the Message Understanding Layer. It runs after [MessageAnalyzerService]
/// and before [ConversationRouter].
///
/// === NON-ANSWER PRIORITY RULE ===
/// Any non-answer signal causes immediate return of the appropriate non-answer
/// type. An answer type is only returned when ALL non-answer checks pass.
///
/// This means: if in doubt, we do NOT advance the assessment.
final class SemanticMessageClassifier {
  const SemanticMessageClassifier();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Classify [message] and return the authoritative [SemanticMessageType].
  ///
  /// [hasPendingQuestion] — whether there is an active assessment question.
  ///
  /// Priority order (checked top-down, first match wins):
  ///  1. Greeting / farewell
  ///  2. Skip / restart
  ///  3. Recommendation request
  ///  4. QUL non-answer types (options, definition, examples, why, simplify, uncertainty, clarification)
  ///  5. Academic question (no pending question OR explicitly about a domain)
  ///  6. Answer (only after all non-answer types have been eliminated)
  ///  7. Unknown
  SemanticMessageType classify(
    ClassifiableMessage message, {
    required bool hasPendingQuestion,
  }) {
    // ── 1. Greeting / farewell (highest priority — always handle) ─────────────
    if (message.looksLikeGreeting) return SemanticMessageType.greeting;
    if (_isFarewell(message.rawMessage)) return SemanticMessageType.farewell;

    // ── 2. Assessment control signals ─────────────────────────────────────────
    if (message.containsSkipSignal) return SemanticMessageType.skipRequest;
    if (message.containsRestartSignal) return SemanticMessageType.restartRequest;
    if (message.containsRecommendationSignal) {
      return SemanticMessageType.recommendationRequest;
    }

    // ── 3. QUL non-answer types (only relevant when question is active) ────────
    if (hasPendingQuestion) {
      // Options/location request: "وين الخيارات", "وين الأنشطة", "وين المجالات"
      if (message.requestsOptions) {
        return SemanticMessageType.optionsRequest;
      }

      // Word meaning / definition
      if (message.requestsWordMeaning) {
        return SemanticMessageType.definitionRequest;
      }

      // Why is this question asked
      if (message.requestsWhyThisQuestion) {
        return SemanticMessageType.whyRequest;
      }

      // Explicit examples request
      if (message.requestsExamples) {
        return SemanticMessageType.exampleRequest;
      }

      // Simplification request
      if (message.requestsSimplification) {
        return SemanticMessageType.simplificationRequest;
      }

      // Uncertainty / don't know
      if (message.expressesUncertainty) {
        return SemanticMessageType.uncertaintyExpression;
      }

      // Clarification / confusion about the question
      if (message.requestsQuestionClarification) {
        return SemanticMessageType.clarificationRequest;
      }
    }

    // ── 4. Compound message: answer content + trailing meta-question ───────────
    // A compound message must NOT advance the assessment — the student is
    // partially answering but also asking a verification/permission question.
    // Route as clarificationRequest so the controller can:
    //   1. Acknowledge the content they mentioned.
    //   2. Answer the meta-question (yes, you can mention it).
    //   3. Invite them to give their full answer.
    if (hasPendingQuestion && message.looksLikeCompoundMessage) {
      return SemanticMessageType.clarificationRequest;
    }

    // ── 5. Academic question (may occur with or without pending question) ─────
    if (message.looksLikeConceptQuestion && !hasPendingQuestion) {
      return SemanticMessageType.academicQuestion;
    }
    // Even with a pending question, explicit academic structure → academic
    // BUT: only when not a compound message (compound is handled above)
    if (message.looksLikeConceptQuestion &&
        !message.requestsQuestionClarification &&
        !message.expressesUncertainty &&
        !message.looksLikeCompoundMessage) {
      return SemanticMessageType.academicQuestion;
    }

    // ── 6. Answer — context-aware via ContextualAnswerInterpreter ─────────────
    //
    // When an interpretation is available (active question exists), it
    // supersedes [looksLikeAnswer] completely:
    //
    //   compatible       → answer: the message satisfies the question's format.
    //
    //   structuralMismatch → clarificationRequest: the message expresses intent
    //       (e.g. "all of them" for a ranking question) but does NOT provide the
    //       required structure. The controller MUST preserve the assessment
    //       objective and explain what format is needed. Do NOT skip or simplify.
    //
    //   partialAnswer    → clarificationRequest: the message contains answer
    //       content but is incomplete. Acknowledge and invite elaboration.
    //
    // Falls back to the keyword-based [looksLikeAnswer] only when no
    // interpretation is available (activeQuestion was null at analysis time).
    if (hasPendingQuestion) {
      final interp = message.answerInterpretation;
      if (interp != null) {
        return switch (interp) {
          AnswerInterpretation.compatible    => SemanticMessageType.answer,
          AnswerInterpretation.structuralMismatch => SemanticMessageType.clarificationRequest,
          AnswerInterpretation.partialAnswer => SemanticMessageType.clarificationRequest,
          AnswerInterpretation.noActiveQuestion => SemanticMessageType.unknown,
        };
      }
      // Fallback: no active question context was available during analysis.
      if (message.looksLikeAnswer) return SemanticMessageType.answer;
    }

    // ── 7. Unknown ────────────────────────────────────────────────────────────
    return SemanticMessageType.unknown;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static bool _isFarewell(String rawMessage) {
    final text = rawMessage.toLowerCase();
    const farewellSignals = [
      'وداعا', 'مع السلامه', 'الى اللقاء', 'في امان الله', 'باي', 'خلاص',
      'goodbye', 'bye', 'farewell', 'see you', 'take care', 'later',
      'cya', 'good night', 'good bye',
    ];
    return farewellSignals.any((s) => text.contains(s));
  }
}
