/// SAIE — SemanticMessageType
///
/// The semantic classification of a student message.
/// Produced by the Message Understanding Layer (SemanticMessageClassifier)
/// and carried on [MessageAnalysis] for downstream consumers.
library;

// ─────────────────────────────────────────────────────────────────────────────
// SemanticMessageType
// ─────────────────────────────────────────────────────────────────────────────

/// The semantic type of an incoming student message.
///
/// This is the output of the [SemanticMessageClassifier].
/// The [ConversationRouter] uses this type — not raw intent scores — to
/// decide whether to advance the assessment.
enum SemanticMessageType {
  /// Student has provided an actual answer to the active question.
  /// Routing: → continueAssessment
  answer,

  /// Student is asking for clarification of the question text.
  /// Routing: → clarification / QUL
  clarificationRequest,

  /// Student is asking what a word or term in the question means.
  /// Routing: → wordMeaning / QUL
  definitionRequest,

  /// Student wants to see example answers for the question.
  /// Routing: → questionExamples / QUL
  exampleRequest,

  /// Student is asking "where are the options/list/fields/activities".
  /// i.e., the question refers to something they cannot see.
  /// Routing: → questionExamples / QUL (show options)
  optionsRequest,

  /// Student wants a simpler restatement of the question.
  /// Routing: → clarification / QUL
  simplificationRequest,

  /// Student is asking why this question is being asked.
  /// Routing: → whyThisQuestion / QUL
  whyRequest,

  /// Student is expressing uncertainty / don't know.
  /// Routing: → uncertainty / QUL
  uncertaintyExpression,

  /// Student is asking an academic/domain question unrelated to active Q.
  /// Routing: → academicDiscussion
  academicQuestion,

  /// Student sent a greeting.
  /// Routing: → greeting
  greeting,

  /// Student wants to skip the current question.
  /// Routing: → skipQuestion
  skipRequest,

  /// Student wants to restart the assessment.
  /// Routing: → restartAssessment
  restartRequest,

  /// Student is asking about or discussing the recommendation.
  /// Routing: → recommendationDiscussion
  recommendationRequest,

  /// Student said goodbye.
  /// Routing: → goodbye
  farewell,

  /// Cannot be determined — requires clarification.
  /// Routing: → unknown
  unknown,
}

extension SemanticMessageTypeX on SemanticMessageType {
  /// Returns true if this type must NEVER advance the assessment.
  bool get blocksAssessmentAdvancement => this != SemanticMessageType.answer;

  /// Returns true if this type is a QUL (Question Understanding Layer) type.
  bool get isQulType => switch (this) {
    SemanticMessageType.clarificationRequest ||
    SemanticMessageType.definitionRequest ||
    SemanticMessageType.exampleRequest ||
    SemanticMessageType.optionsRequest ||
    SemanticMessageType.simplificationRequest ||
    SemanticMessageType.whyRequest ||
    SemanticMessageType.uncertaintyExpression => true,
    _ => false,
  };
}
