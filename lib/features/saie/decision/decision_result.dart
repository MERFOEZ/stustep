/// SAIE — DecisionResult
///
/// The complete, authoritative output of the [CognitiveDecisionEngine] for
/// a single student message. Every downstream system (profile updater,
/// question selector, response generator) reads exclusively from this result.
/// Nothing in the profile changes without a [DecisionResult] approving it.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ContradictionSignal
// ─────────────────────────────────────────────────────────────────────────────

/// Describes a detected contradiction between a current statement and history.
final class ContradictionSignal extends Equatable {
  /// The dimension key that is affected.
  final String dimensionKey;

  /// A summary of what was said earlier.
  final String priorStatement;

  /// A summary of what was just said that conflicts.
  final String currentStatement;

  /// Confidence that this is a genuine contradiction, in [0.0, 1.0].
  final double confidence;

  const ContradictionSignal({
    required this.dimensionKey,
    required this.priorStatement,
    required this.currentStatement,
    required this.confidence,
  });

  factory ContradictionSignal.fromJson(Map<String, dynamic> json) =>
      ContradictionSignal(
        dimensionKey: json['dimension_key'] as String,
        priorStatement: json['prior_statement'] as String,
        currentStatement: json['current_statement'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'dimension_key': dimensionKey,
    'prior_statement': priorStatement,
    'current_statement': currentStatement,
    'confidence': confidence,
  };

  ContradictionSignal copyWith({
    String? dimensionKey,
    String? priorStatement,
    String? currentStatement,
    double? confidence,
  }) => ContradictionSignal(
    dimensionKey: dimensionKey ?? this.dimensionKey,
    priorStatement: priorStatement ?? this.priorStatement,
    currentStatement: currentStatement ?? this.currentStatement,
    confidence: confidence ?? this.confidence,
  );

  @override
  List<Object?> get props => [dimensionKey, confidence];
}

// ─────────────────────────────────────────────────────────────────────────────
// ClarificationRequest
// ─────────────────────────────────────────────────────────────────────────────

/// A structured clarification request produced when confidence is too low.
final class ClarificationRequest extends Equatable {
  /// The message to send to the student asking for clarification.
  final String clarificationMessage;

  /// The reason the clarification was triggered.
  final String reason;

  /// Whether the original question should be repeated after the clarification.
  final bool repeatQuestionAfter;

  const ClarificationRequest({
    required this.clarificationMessage,
    required this.reason,
    this.repeatQuestionAfter = true,
  });

  factory ClarificationRequest.fromJson(Map<String, dynamic> json) =>
      ClarificationRequest(
        clarificationMessage: json['clarification_message'] as String,
        reason: json['reason'] as String,
        repeatQuestionAfter: json['repeat_question_after'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'clarification_message': clarificationMessage,
    'reason': reason,
    'repeat_question_after': repeatQuestionAfter,
  };

  ClarificationRequest copyWith({
    String? clarificationMessage,
    String? reason,
    bool? repeatQuestionAfter,
  }) => ClarificationRequest(
    clarificationMessage: clarificationMessage ?? this.clarificationMessage,
    reason: reason ?? this.reason,
    repeatQuestionAfter: repeatQuestionAfter ?? this.repeatQuestionAfter,
  );

  @override
  List<Object?> get props => [clarificationMessage, reason];
}

// ─────────────────────────────────────────────────────────────────────────────
// DecisionResult
// ─────────────────────────────────────────────────────────────────────────────

/// The authoritative output of the [CognitiveDecisionEngine].
///
/// Every downstream system reads from this object.
/// No profile update, question advance, or response may occur without it.
final class DecisionResult extends Equatable {
  /// The unique request ID this result responds to.
  final String requestId;

  /// The winning classified intent.
  final SupportedIntent detectedIntent;

  /// The full confidence distribution across all candidate intents.
  final DecisionConfidence confidence;

  /// The detected language of the student's message.
  final DetectedLanguage detectedLanguage;

  /// Whether the language has switched from the prior active language.
  final bool languageSwitched;

  // ─── Profile Gate ─────────────────────────────────────────────────────────

  /// Whether the profile may be updated based on this message.
  /// This is the gate — false means no profile change is allowed.
  final bool shouldUpdateProfile;

  // ─── Conversation Flow ────────────────────────────────────────────────────

  /// Whether the engine should ask for clarification before proceeding.
  final bool shouldAskClarification;

  /// The structured clarification request to send (if [shouldAskClarification]).
  final ClarificationRequest? clarificationRequest;

  /// Whether the active question should be repeated after handling this message.
  final bool shouldRepeatQuestion;

  /// Whether the assessment should advance to the next question/phase.
  final bool shouldAdvanceAssessment;

  // ─── Downstream Requirements ──────────────────────────────────────────────

  /// Whether this result requires an LLM call to generate a response.
  /// True for open-ended discussion, academic questions, and explanations.
  final bool requiresLLM;

  /// Whether this result requires a knowledge base lookup.
  final bool requiresKnowledgeBase;

  /// Whether this result requires deeper profile reasoning before acting.
  final bool requiresReasoning;

  // ─── Contradiction ────────────────────────────────────────────────────────

  /// Whether a contradiction was detected against the student's history.
  final bool contradictionDetected;

  /// Details of the detected contradiction (if any).
  final ContradictionSignal? contradictionSignal;

  // ─── Reasoning Trace ──────────────────────────────────────────────────────

  /// Human-readable explanation of why this classification was made.
  final String reasoningTrace;

  /// UTC timestamp when this result was produced.
  final DateTime producedAt;

  /// The full structural message analysis from which this result was derived.
  /// Carries the authoritative [SemanticMessageType] for the router.
  final MessageAnalysis? messageAnalysis;

  const DecisionResult({
    required this.requestId,
    required this.detectedIntent,
    required this.confidence,
    required this.detectedLanguage,
    required this.languageSwitched,
    required this.shouldUpdateProfile,
    required this.shouldAskClarification,
    required this.shouldRepeatQuestion,
    required this.shouldAdvanceAssessment,
    required this.requiresLLM,
    required this.requiresKnowledgeBase,
    required this.requiresReasoning,
    required this.contradictionDetected,
    required this.reasoningTrace,
    required this.producedAt,
    this.clarificationRequest,
    this.contradictionSignal,
    this.messageAnalysis,
  });

  factory DecisionResult.fromJson(Map<String, dynamic> json) => DecisionResult(
    requestId: json['request_id'] as String,
    detectedIntent:
        SupportedIntent.values.byName(json['detected_intent'] as String),
    confidence: DecisionConfidence.fromJson(
      json['confidence'] as Map<String, dynamic>,
    ),
    detectedLanguage: DetectedLanguage.fromJson(
      json['detected_language'] as Map<String, dynamic>,
    ),
    languageSwitched: json['language_switched'] as bool,
    shouldUpdateProfile: json['should_update_profile'] as bool,
    shouldAskClarification: json['should_ask_clarification'] as bool,
    clarificationRequest: json['clarification_request'] != null
        ? ClarificationRequest.fromJson(
            json['clarification_request'] as Map<String, dynamic>,
          )
        : null,
    shouldRepeatQuestion: json['should_repeat_question'] as bool,
    shouldAdvanceAssessment: json['should_advance_assessment'] as bool,
    requiresLLM: json['requires_llm'] as bool,
    requiresKnowledgeBase: json['requires_knowledge_base'] as bool,
    requiresReasoning: json['requires_reasoning'] as bool,
    contradictionDetected: json['contradiction_detected'] as bool,
    contradictionSignal: json['contradiction_signal'] != null
        ? ContradictionSignal.fromJson(
            json['contradiction_signal'] as Map<String, dynamic>,
          )
        : null,
    reasoningTrace: json['reasoning_trace'] as String,
    producedAt: DateTime.parse(json['produced_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'detected_intent': detectedIntent.name,
    'confidence': confidence.toJson(),
    'detected_language': detectedLanguage.toJson(),
    'language_switched': languageSwitched,
    'should_update_profile': shouldUpdateProfile,
    'should_ask_clarification': shouldAskClarification,
    if (clarificationRequest != null)
      'clarification_request': clarificationRequest!.toJson(),
    'should_repeat_question': shouldRepeatQuestion,
    'should_advance_assessment': shouldAdvanceAssessment,
    'requires_llm': requiresLLM,
    'requires_knowledge_base': requiresKnowledgeBase,
    'requires_reasoning': requiresReasoning,
    'contradiction_detected': contradictionDetected,
    if (contradictionSignal != null)
      'contradiction_signal': contradictionSignal!.toJson(),
    'reasoning_trace': reasoningTrace,
    'produced_at': producedAt.toIso8601String(),
  };

  DecisionResult copyWith({
    String? requestId,
    SupportedIntent? detectedIntent,
    DecisionConfidence? confidence,
    DetectedLanguage? detectedLanguage,
    bool? languageSwitched,
    bool? shouldUpdateProfile,
    bool? shouldAskClarification,
    ClarificationRequest? clarificationRequest,
    bool? shouldRepeatQuestion,
    bool? shouldAdvanceAssessment,
    bool? requiresLLM,
    bool? requiresKnowledgeBase,
    bool? requiresReasoning,
    bool? contradictionDetected,
    ContradictionSignal? contradictionSignal,
    String? reasoningTrace,
    DateTime? producedAt,
    MessageAnalysis? messageAnalysis,
  }) => DecisionResult(
    requestId: requestId ?? this.requestId,
    detectedIntent: detectedIntent ?? this.detectedIntent,
    confidence: confidence ?? this.confidence,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    languageSwitched: languageSwitched ?? this.languageSwitched,
    shouldUpdateProfile: shouldUpdateProfile ?? this.shouldUpdateProfile,
    shouldAskClarification:
        shouldAskClarification ?? this.shouldAskClarification,
    clarificationRequest: clarificationRequest ?? this.clarificationRequest,
    shouldRepeatQuestion: shouldRepeatQuestion ?? this.shouldRepeatQuestion,
    shouldAdvanceAssessment:
        shouldAdvanceAssessment ?? this.shouldAdvanceAssessment,
    requiresLLM: requiresLLM ?? this.requiresLLM,
    requiresKnowledgeBase: requiresKnowledgeBase ?? this.requiresKnowledgeBase,
    requiresReasoning: requiresReasoning ?? this.requiresReasoning,
    contradictionDetected:
        contradictionDetected ?? this.contradictionDetected,
    contradictionSignal: contradictionSignal ?? this.contradictionSignal,
    reasoningTrace: reasoningTrace ?? this.reasoningTrace,
    producedAt: producedAt ?? this.producedAt,
    messageAnalysis: messageAnalysis ?? this.messageAnalysis,
  );

  /// Winning intent confidence score.
  double get intentScore => confidence.winner.score;

  /// Returns `true` if the result is decisive (above threshold).
  bool get isDecisive => confidence.isDecisive;

  @override
  List<Object?> get props => [requestId, detectedIntent, producedAt];

  @override
  String toString() =>
      'DecisionResult(intent: ${detectedIntent.name}@'
      '${intentScore.toStringAsFixed(3)}, '
      'updateProfile: $shouldUpdateProfile, '
      'clarify: $shouldAskClarification)';
}
