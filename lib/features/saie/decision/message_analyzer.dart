/// SAIE — MessageAnalysis
///
/// The structural decomposition of a raw student message before classification.
/// The [MessageAnalyzer] produces one [MessageAnalysis] per incoming message.
/// Classification signals are derived from this analysis object.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/decision/contextual_answer_interpreter.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/semantic_message_classifier.dart';

export 'package:stustep/features/saie/decision/contextual_answer_interpreter.dart'
    show AnswerInterpretation;

// ─────────────────────────────────────────────────────────────────────────────
// MessageTokens
// ─────────────────────────────────────────────────────────────────────────────

/// Structural token analysis of the raw message.
final class MessageTokens extends Equatable {
  /// The raw message text.
  final String raw;

  /// Normalised (trimmed, whitespace-collapsed) text.
  final String normalised;

  /// Character count.
  final int charCount;

  /// Word count (split by whitespace).
  final int wordCount;

  /// Number of question marks detected.
  final int questionMarkCount;

  /// Whether the message ends with a question mark.
  final bool endsWithQuestion;

  /// Whether the message is a single word.
  final bool isSingleWord;

  /// Whether the message is very short (≤ 3 words).
  final bool isVeryShort;

  /// Whether the message contains a negation signal.
  final bool containsNegation;

  /// Whether the message contains an affirmation signal.
  final bool containsAffirmation;

  const MessageTokens({
    required this.raw,
    required this.normalised,
    required this.charCount,
    required this.wordCount,
    required this.questionMarkCount,
    required this.endsWithQuestion,
    required this.isSingleWord,
    required this.isVeryShort,
    required this.containsNegation,
    required this.containsAffirmation,
  });

  @override
  List<Object?> get props => [raw, wordCount, questionMarkCount];
}

// ─────────────────────────────────────────────────────────────────────────────
// MessageAnalysis
// ─────────────────────────────────────────────────────────────────────────────

/// The complete structural analysis of a student message.
///
/// Produced once per message by [MessageAnalyzer]. All classifiers read
/// from this object — none re-parse the raw text independently.
///
/// Implements [ClassifiableMessage] so it can be passed directly to
/// [SemanticMessageClassifier.classify].
final class MessageAnalysis extends Equatable implements ClassifiableMessage {
  /// The token-level structural analysis.
  final MessageTokens tokens;

  @override
  String get rawMessage => tokens.raw;

  /// Detected language of this message.
  final DetectedLanguage detectedLanguage;

  /// Whether the message appears to be a greeting.
  @override
  final bool looksLikeGreeting;

  /// Whether the message appears to be a question about a concept or term.
  @override
  final bool looksLikeConceptQuestion;

  /// Whether the message appears to be an answer to the active question.
  @override
  final bool looksLikeAnswer;

  /// Whether the message is a compound message: contains answer-like content
  /// AND a trailing meta-question (e.g. "I do X and Y — can I mention them?").
  ///
  /// A compound message must NOT advance the assessment. The controller should
  /// acknowledge the content, address the meta-question, and invite a full answer.
  @override
  final bool looksLikeCompoundMessage;

  /// Whether the message appears to reference the current active question topic.
  final bool referencesCurrentTopic;

  /// Whether the message references something said earlier in the conversation.
  final bool referencesHistory;

  /// Whether the message contains a skip signal.
  @override
  final bool containsSkipSignal;

  /// Whether the message contains a restart signal.
  @override
  final bool containsRestartSignal;

  /// Whether the message contains a recommendation request signal.
  @override
  final bool containsRecommendationSignal;

  /// Whether the message appears to be a contradiction of a prior statement.
  final bool looksLikeContradiction;

  /// Whether the message requests clarification of the current question.
  @override
  final bool requestsQuestionClarification;

  /// Whether the student is asking what a specific word/term means.
  @override
  final bool requestsWordMeaning;

  /// Whether the student expresses uncertainty ("I don't know").
  @override
  final bool expressesUncertainty;

  /// Whether the student is asking why this question is being asked.
  @override
  final bool requestsWhyThisQuestion;

  /// Whether the student explicitly wants a different question.
  @override
  final bool requestsAlternativeQuestion;

  /// Whether the student is asking for examples related to the question.
  @override
  final bool requestsExamples;

  /// Whether the student is asking "where are the options/activities/fields".
  /// Covers: "وين الخيارات", "وين الأنشطة", "وين المجالات", "show me the options".
  @override
  final bool requestsOptions;

  /// Whether the student is asking for a simpler restatement of the question.
  /// Covers: "بسّط", "simplify", "rephrase", "easier", "بعبارة أبسط".
  @override
  final bool requestsSimplification;

  /// The contextual interpretation of this message relative to the active
  /// assessment question, produced by [ContextualAnswerInterpreter].
  ///
  /// Null when no active question exists.
  /// When present, this supersedes [looksLikeAnswer] for answer routing.
  @override
  final AnswerInterpretation? answerInterpretation;

  /// The authoritative semantic type determined by [SemanticMessageClassifier].
  /// This is the primary input to the [ConversationRouter].
  final SemanticMessageType semanticType;

  /// UTC timestamp when this analysis was produced.
  final DateTime analysedAt;

  const MessageAnalysis({
    required this.tokens,
    required this.detectedLanguage,
    required this.looksLikeGreeting,
    required this.looksLikeConceptQuestion,
    required this.looksLikeAnswer,
    required this.looksLikeCompoundMessage,
    required this.referencesCurrentTopic,
    required this.referencesHistory,
    required this.containsSkipSignal,
    required this.containsRestartSignal,
    required this.containsRecommendationSignal,
    required this.looksLikeContradiction,
    required this.requestsQuestionClarification,
    required this.requestsWordMeaning,
    required this.expressesUncertainty,
    required this.requestsWhyThisQuestion,
    required this.requestsAlternativeQuestion,
    required this.requestsExamples,
    required this.requestsOptions,
    required this.requestsSimplification,
    required this.semanticType,
    required this.analysedAt,
    this.answerInterpretation,
  });


  MessageAnalysis copyWith({
    MessageTokens? tokens,
    DetectedLanguage? detectedLanguage,
    bool? looksLikeGreeting,
    bool? looksLikeConceptQuestion,
    bool? looksLikeAnswer,
    bool? looksLikeCompoundMessage,
    bool? referencesCurrentTopic,
    bool? referencesHistory,
    bool? containsSkipSignal,
    bool? containsRestartSignal,
    bool? containsRecommendationSignal,
    bool? looksLikeContradiction,
    bool? requestsQuestionClarification,
    bool? requestsWordMeaning,
    bool? expressesUncertainty,
    bool? requestsWhyThisQuestion,
    bool? requestsAlternativeQuestion,
    bool? requestsExamples,
    bool? requestsOptions,
    bool? requestsSimplification,
    SemanticMessageType? semanticType,
    DateTime? analysedAt,
    Object? answerInterpretation = _keepExisting,
  }) => MessageAnalysis(
    tokens: tokens ?? this.tokens,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    looksLikeGreeting: looksLikeGreeting ?? this.looksLikeGreeting,
    looksLikeConceptQuestion:
        looksLikeConceptQuestion ?? this.looksLikeConceptQuestion,
    looksLikeAnswer: looksLikeAnswer ?? this.looksLikeAnswer,
    looksLikeCompoundMessage: looksLikeCompoundMessage ?? this.looksLikeCompoundMessage,
    referencesCurrentTopic:
        referencesCurrentTopic ?? this.referencesCurrentTopic,
    referencesHistory: referencesHistory ?? this.referencesHistory,
    containsSkipSignal: containsSkipSignal ?? this.containsSkipSignal,
    containsRestartSignal:
        containsRestartSignal ?? this.containsRestartSignal,
    containsRecommendationSignal:
        containsRecommendationSignal ?? this.containsRecommendationSignal,
    looksLikeContradiction:
        looksLikeContradiction ?? this.looksLikeContradiction,
    requestsQuestionClarification:
        requestsQuestionClarification ?? this.requestsQuestionClarification,
    requestsWordMeaning: requestsWordMeaning ?? this.requestsWordMeaning,
    expressesUncertainty: expressesUncertainty ?? this.expressesUncertainty,
    requestsWhyThisQuestion:
        requestsWhyThisQuestion ?? this.requestsWhyThisQuestion,
    requestsAlternativeQuestion:
        requestsAlternativeQuestion ?? this.requestsAlternativeQuestion,
    requestsExamples: requestsExamples ?? this.requestsExamples,
    requestsOptions: requestsOptions ?? this.requestsOptions,
    requestsSimplification: requestsSimplification ?? this.requestsSimplification,
    semanticType: semanticType ?? this.semanticType,
    analysedAt: analysedAt ?? this.analysedAt,
    answerInterpretation: answerInterpretation == _keepExisting
        ? this.answerInterpretation
        : answerInterpretation as AnswerInterpretation?,
  );


  @override
  List<Object?> get props => [
    tokens.raw,
    detectedLanguage.language,
    looksLikeAnswer,
    looksLikeConceptQuestion,
    analysedAt,
  ];

  @override
  String toString() =>
      'MessageAnalysis(words: ${tokens.wordCount}, '
      'lang: ${detectedLanguage.language.name}, '
      'answer: $looksLikeAnswer, question: $looksLikeConceptQuestion, '
      'uncertainty: $expressesUncertainty, wordMeaning: $requestsWordMeaning, '
      'interpretation: $answerInterpretation)';
}

// Sentinel object for nullable copyWith fields.
// Allows distinguishing "explicitly set to null" from "not provided".
const _keepExisting = Object();

