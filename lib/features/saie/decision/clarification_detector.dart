/// SAIE — ClarificationDetector
///
/// Determines whether a [DecisionResult] should trigger a clarification
/// request to the student. Generates the structured [ClarificationRequest]
/// text in the appropriate language.
library;

import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/decision_result.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClarificationTrigger
// ─────────────────────────────────────────────────────────────────────────────

/// The reason a clarification was triggered.
enum ClarificationTrigger {
  /// Winner score is below the minimum threshold.
  lowConfidence,

  /// Top two candidates are too close to distinguish.
  highAmbiguity,

  /// The message is a confirmed explanation request for the active question.
  explanationRequest,

  /// Maximum consecutive clarifications reached — force a default.
  exhausted,
}

// ─────────────────────────────────────────────────────────────────────────────
// ClarificationDetector
// ─────────────────────────────────────────────────────────────────────────────

/// Evaluates whether a clarification is needed and builds the request.
final class ClarificationDetector {
  /// Minimum confidence threshold for direct execution (no clarification).
  static const double _threshold = 0.65;

  /// Max consecutive clarifications before the engine forces a skip.
  static const int _maxClarifications = 3;

  const ClarificationDetector();

  /// Returns a [ClarificationRequest] if clarification is needed, else null.
  ///
  /// Also returns the [ClarificationTrigger] for tracing purposes.
  ({ClarificationRequest? request, ClarificationTrigger? trigger}) evaluate(
    DecisionConfidence confidence,
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    // If we have too many clarifications already, give up and skip forward.
    if (context.clarificationCount >= _maxClarifications) {
      return (
        request: ClarificationRequest(
          clarificationMessage: _exhaustedMessage(context.activeLanguage),
          reason: 'Maximum clarification attempts reached — skipping forward.',
          repeatQuestionAfter: false,
        ),
        trigger: ClarificationTrigger.exhausted,
      );
    }

    // Explicit explanation request → structured explanation clarification.
    if (confidence.winner.intent == SupportedIntent.requestExplanation &&
        confidence.winner.score >= _threshold &&
        context.hasPendingQuestion) {
      return (
        request: ClarificationRequest(
          clarificationMessage: _explanationRequestMessage(
            context.activeQuestion!.text,
            context.activeLanguage,
          ),
          reason: 'Student requested explanation of the current question.',
          repeatQuestionAfter: true,
        ),
        trigger: ClarificationTrigger.explanationRequest,
      );
    }

    // Low confidence — engine cannot commit to an intent.
    if (!confidence.isDecisive) {
      return (
        request: ClarificationRequest(
          clarificationMessage: _lowConfidenceMessage(
            analysis.tokens.normalised,
            context.activeLanguage,
          ),
          reason:
              'Winner confidence ${confidence.winner.score.toStringAsFixed(3)} '
              'is below threshold $_threshold.',
          repeatQuestionAfter: context.hasPendingQuestion,
        ),
        trigger: ClarificationTrigger.lowConfidence,
      );
    }

    // High ambiguity — two candidates are too close.
    if (confidence.isAmbiguous) {
      return (
        request: ClarificationRequest(
          clarificationMessage: _ambiguousMessage(context.activeLanguage),
          reason:
              'Ambiguity score ${confidence.ambiguityScore.toStringAsFixed(3)} '
              'is below 0.15 — candidates too close.',
          repeatQuestionAfter: context.hasPendingQuestion,
        ),
        trigger: ClarificationTrigger.highAmbiguity,
      );
    }

    // No clarification needed.
    return (request: null, trigger: null);
  }

  // ─── Message builders (bilingual) ─────────────────────────────────────────

  String _lowConfidenceMessage(String originalMessage, Language lang) =>
      lang == Language.arabic
          ? 'لم أفهم ردّك تمامًا. هل يمكنك توضيح ما تقصده؟'
          : 'I didn\'t quite understand your response. Could you please clarify what you mean?';

  String _ambiguousMessage(Language lang) =>
      lang == Language.arabic
          ? 'هل يمكنك إعادة الصياغة؟ ردّك يمكن تفسيره بأكثر من طريقة.'
          : 'Could you rephrase that? Your message could be interpreted in multiple ways.';

  String _explanationRequestMessage(String questionText, Language lang) =>
      lang == Language.arabic
          ? 'بالطبع! دعني أوضّح السؤال لك.\n\n'
            'السؤال الأصلي كان: "$questionText"\n\n'
            'سأشرح المصطلح أو المفهوم المقصود ثم نعود إلى السؤال.'
          : 'Of course! Let me clarify the question for you.\n\n'
            'The original question was: "$questionText"\n\n'
            'I\'ll explain the term or concept and then we\'ll return to the question.';

  String _exhaustedMessage(Language lang) =>
      lang == Language.arabic
          ? 'يبدو أن هذا السؤال صعب قليلًا. سننتقل إلى السؤال التالي.'
          : 'This question seems a bit unclear. Let\'s move on to the next one.';
}
