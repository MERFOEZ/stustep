/// SAIE — AnswerCompletionEvaluation
///
/// Output model for [AnswerCompletionEvaluator].
///
/// Separates two orthogonal concerns:
///   [CompletionState] — what the system must do next (structural decision).
///   [CompletionReason] — why the system is doing it (content decision).
///
/// The controller branches on [state] (stable, 3 cases).
/// The response builder branches on [reason] (extensible, N cases).
library;

// ─────────────────────────────────────────────────────────────────────────────
// CompletionState
// ─────────────────────────────────────────────────────────────────────────────

/// Determines the controller's structural next action for this turn.
///
/// Intentionally small — exactly three values.
/// New failure modes add a new [CompletionReason], not a new state.
enum CompletionState {
  /// The question has been answered sufficiently.
  /// [AdaptiveAssessmentEngine.advance] MAY be called.
  complete,

  /// The question has not been answered sufficiently.
  /// The assessment MUST NOT advance.
  /// Consult [CompletionEvaluation.reason] to determine what response to build.
  continueConversation,

  /// The evaluator encountered an unrecoverable internal error.
  /// The controller falls back to [continueConversation] behavior
  /// and logs a diagnostic.
  blocked,
}

extension CompletionStateX on CompletionState {
  /// True when assessment advancement is permitted for this turn.
  bool get allowsAdvancement => this == CompletionState.complete;

  /// True when the controller must produce a non-advancing response.
  bool get requiresConversation => this != CompletionState.complete;
}

// ─────────────────────────────────────────────────────────────────────────────
// CompletionReason
// ─────────────────────────────────────────────────────────────────────────────

/// Describes why the [CompletionState] decision was made.
///
/// Used by the controller's response builder to determine what to say.
/// Adding a new reason extends the response-building switch without touching
/// the outer state-switch in the controller.
///
/// Rule: only add a reason if it produces a *different* student-facing response.
/// If two scenarios produce the same response, they share a reason.
enum CompletionReason {
  /// The question was answered sufficiently.
  /// Only appears with [CompletionState.complete].
  /// Explicit value makes [CompletionEvaluation] fully self-describing.
  accepted,

  /// The answer is present but too thin for the question type.
  /// Example: "نعم" to an open-ended question.
  /// Action: probe once with "Can you tell me a little more about that?".
  partialAnswer,

  /// The answer does not contain enough content to evaluate.
  /// Example: single random word, or a one-character response.
  /// Action: ask the student to provide more information
  ///         (e.g. "Please enter a number from 1 to 5" for Likert).
  insufficientContent,

  /// The student's message is a question, not an answer.
  /// Example: "هل التنمر يُعتبر قيادة؟", "What does this mean?"
  /// Action: re-route to the QUL handler; do not probe.
  clarificationRequest,

  /// The student is asking about the assessment structure, not the question.
  /// Example: "لماذا تسألني هذا؟", "Can I skip this?"
  /// Action: re-route to the meta handler; do not probe.
  metaQuestion,

  /// The evaluator cannot determine completion with sufficient confidence.
  /// Honest "I don't know" — not a failure.
  /// Action: treat identically to [partialAnswer] — probe once.
  lowEvaluatorConfidence,
}

extension CompletionReasonX on CompletionReason {
  /// True when this reason requires routing to a QUL or meta handler
  /// rather than building a probe response inline.
  bool get requiresRerouting =>
      this == CompletionReason.clarificationRequest ||
      this == CompletionReason.metaQuestion;

  /// True when the system should probe exactly once and then accept
  /// the next student message regardless of its content.
  /// Prevents infinite loops without sacrificing one follow-up opportunity.
  bool get isProbeOnce =>
      this == CompletionReason.partialAnswer ||
      this == CompletionReason.lowEvaluatorConfidence;
}

// ─────────────────────────────────────────────────────────────────────────────
// CompletionEvaluation
// ─────────────────────────────────────────────────────────────────────────────

/// The complete output of [AnswerCompletionEvaluator.evaluate].
///
/// [state]    — drives the controller's structural decision (advance or not).
/// [reason]   — drives the response builder's content decision (what to say).
/// [gap]      — a student-facing description of what is missing or needed.
/// [confidence] — for escalation policies and diagnostics; never shown.
/// [rationale]  — internal debug string; never shown to the student.
final class CompletionEvaluation {
  final CompletionState state;
  final CompletionReason reason;

  /// A targeted, student-facing description of what is missing or required.
  ///
  /// Null when [state] is [CompletionState.complete].
  /// Used by the controller to build a specific, non-generic probe response.
  ///
  /// Examples:
  ///   - "يرجى إدخال رقم من 1 إلى 5"
  ///   - "هل يمكنك إخباري أكثر عن تجربتك في هذا المجال؟"
  final String? gap;

  /// Evaluator confidence in [0.0, 1.0].
  ///
  /// Used for escalation policies (e.g., force-advance after N low-confidence
  /// turns). Not used for response content.
  final double confidence;

  /// Internal rationale for this decision.
  ///
  /// Used for logging, debugging, and test assertions.
  /// NEVER shown to the student.
  final String rationale;

  const CompletionEvaluation({
    required this.state,
    required this.reason,
    required this.confidence,
    required this.rationale,
    this.gap,
  });

  // ── Named constructors for common outcomes ─────────────────────────────────
  // The evaluator's internal logic uses these — results are declarative and
  // readable without needing to construct raw field values.

  factory CompletionEvaluation.complete({
    double confidence = 0.95,
    String rationale = 'Answer satisfies the question objective.',
  }) => CompletionEvaluation(
    state: CompletionState.complete,
    reason: CompletionReason.accepted,
    confidence: confidence,
    rationale: rationale,
  );

  factory CompletionEvaluation.partial({
    required String gap,
    double confidence = 0.75,
    String rationale = 'Answer is present but insufficient in depth.',
  }) => CompletionEvaluation(
    state: CompletionState.continueConversation,
    reason: CompletionReason.partialAnswer,
    confidence: confidence,
    gap: gap,
    rationale: rationale,
  );

  factory CompletionEvaluation.insufficient({
    required String gap,
    double confidence = 0.85,
    String rationale = 'Answer does not contain enough content to evaluate.',
  }) => CompletionEvaluation(
    state: CompletionState.continueConversation,
    reason: CompletionReason.insufficientContent,
    confidence: confidence,
    gap: gap,
    rationale: rationale,
  );

  factory CompletionEvaluation.clarificationRequest({
    double confidence = 0.90,
    String rationale = 'Message is a clarification request, not an answer.',
  }) => CompletionEvaluation(
    state: CompletionState.continueConversation,
    reason: CompletionReason.clarificationRequest,
    confidence: confidence,
    rationale: rationale,
  );

  factory CompletionEvaluation.metaQuestion({
    double confidence = 0.85,
    String rationale = 'Message is about the assessment structure.',
  }) => CompletionEvaluation(
    state: CompletionState.continueConversation,
    reason: CompletionReason.metaQuestion,
    confidence: confidence,
    rationale: rationale,
  );

  factory CompletionEvaluation.lowConfidence({
    required String gap,
    double confidence = 0.30,
    String rationale = 'Evaluator confidence below decision threshold.',
  }) => CompletionEvaluation(
    state: CompletionState.continueConversation,
    reason: CompletionReason.lowEvaluatorConfidence,
    confidence: confidence,
    gap: gap,
    rationale: rationale,
  );

  factory CompletionEvaluation.blocked({
    String rationale = 'Internal evaluation error.',
  }) => CompletionEvaluation(
    state: CompletionState.blocked,
    reason: CompletionReason.lowEvaluatorConfidence,
    confidence: 0.0,
    rationale: rationale,
  );

  // ── Convenience predicates ─────────────────────────────────────────────────

  bool get allowsAdvancement  => state.allowsAdvancement;
  bool get requiresRerouting  => reason.requiresRerouting;
  bool get isProbeOnce        => reason.isProbeOnce;
}
