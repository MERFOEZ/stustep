/// SAIE — Supported Intent Types
///
/// Every student message is classified into exactly one of these intent types
/// by the [IntentClassifier]. The highest-confidence intent governs all
/// subsequent engine decisions.
library;

// ─────────────────────────────────────────────────────────────────────────────
// SupportedIntent
// ─────────────────────────────────────────────────────────────────────────────

/// The complete set of intent categories the SAIE engine recognises.
enum SupportedIntent {
  /// The student is directly answering the currently active question.
  answerCurrentQuestion,

  /// The student wants to begin the assessment (pre-assessment state).
  /// Examples: "هيا بنا", "ابدأ", "أنا جاهز", "وين الأسئلة"
  startAssessment,

  /// The student wants to continue/resume assessment (mid-assessment, no pending q).
  /// Examples: "التالي", "كمل", "واصل"
  continueAssessment,

  /// The student is asking an academic or domain-related question.
  askAcademicQuestion,

  /// The student is asking for clarification or explanation of a term.
  requestExplanation,

  /// The student is greeting the system.
  greeting,

  /// The student is engaging in general off-topic discussion.
  generalDiscussion,

  /// The student explicitly wants to skip the current question.
  skipQuestion,

  /// The student wants to restart the assessment from the beginning.
  restartAssessment,

  /// The student is asking for a recommendation or result.
  requestRecommendation,

  /// The message is completely off-topic and cannot be processed meaningfully.
  offTopic,

  /// Student is asking what a specific word/concept in the question means.
  askWordMeaning,

  /// Student expresses uncertainty — does not know how to answer.
  expressUncertainty,

  /// Student asks why this specific question is being asked.
  askWhyThisQuestion,

  /// Student explicitly requests a different question (same domain if possible).
  requestAlternativeQuestion,

  /// Student requests examples relevant to the current question.
  requestExamples,

  /// Intent cannot be determined from available context.
  unknown,
}

extension SupportedIntentX on SupportedIntent {
  /// Human-readable display name.
  String get label => switch (this) {
    SupportedIntent.answerCurrentQuestion => 'Answer Current Question',
    SupportedIntent.startAssessment => 'Start Assessment',
    SupportedIntent.continueAssessment => 'Continue Assessment',
    SupportedIntent.askAcademicQuestion => 'Ask Academic Question',
    SupportedIntent.requestExplanation => 'Request Explanation',
    SupportedIntent.greeting => 'Greeting',
    SupportedIntent.generalDiscussion => 'General Discussion',
    SupportedIntent.skipQuestion => 'Skip Question',
    SupportedIntent.restartAssessment => 'Restart Assessment',
    SupportedIntent.requestRecommendation => 'Request Recommendation',
    SupportedIntent.offTopic => 'Off-Topic',
    SupportedIntent.askWordMeaning => 'Ask Word Meaning',
    SupportedIntent.expressUncertainty => 'Express Uncertainty',
    SupportedIntent.askWhyThisQuestion => 'Ask Why This Question',
    SupportedIntent.requestAlternativeQuestion => 'Request Alternative Question',
    SupportedIntent.requestExamples => 'Request Examples',
    SupportedIntent.unknown => 'Unknown',
  };

  /// Returns `true` if this intent should update the student's cognitive profile.
  bool get mayCauseProfileUpdate => switch (this) {
    SupportedIntent.answerCurrentQuestion => true,
    SupportedIntent.generalDiscussion => true,
    SupportedIntent.startAssessment => false,
    SupportedIntent.continueAssessment => false,
    SupportedIntent.askAcademicQuestion => false,
    SupportedIntent.requestExplanation => false,
    SupportedIntent.greeting => false,
    SupportedIntent.skipQuestion => false,
    SupportedIntent.restartAssessment => false,
    SupportedIntent.requestRecommendation => false,
    SupportedIntent.offTopic => false,
    SupportedIntent.askWordMeaning => false,
    SupportedIntent.expressUncertainty => false,
    SupportedIntent.askWhyThisQuestion => false,
    SupportedIntent.requestAlternativeQuestion => false,
    SupportedIntent.requestExamples => false,
    SupportedIntent.unknown => false,
  };

  /// Returns `true` if this intent should pause the assessment flow.
  bool get pausesAssessment => switch (this) {
    SupportedIntent.askAcademicQuestion => true,
    SupportedIntent.requestExplanation => true,
    SupportedIntent.generalDiscussion => true,
    SupportedIntent.greeting => false,
    SupportedIntent.answerCurrentQuestion => false,
    SupportedIntent.startAssessment => false,
    SupportedIntent.continueAssessment => false,
    SupportedIntent.skipQuestion => false,
    SupportedIntent.restartAssessment => true,
    SupportedIntent.requestRecommendation => true,
    SupportedIntent.offTopic => true,
    // Question Understanding Layer — never pauses assessment.
    SupportedIntent.askWordMeaning => false,
    SupportedIntent.expressUncertainty => false,
    SupportedIntent.askWhyThisQuestion => false,
    SupportedIntent.requestAlternativeQuestion => false,
    SupportedIntent.requestExamples => false,
    SupportedIntent.unknown => true,
  };

  /// Returns `true` if this intent requires the knowledge base.
  bool get requiresKnowledgeBase => switch (this) {
    SupportedIntent.askAcademicQuestion => true,
    SupportedIntent.requestRecommendation => true,
    SupportedIntent.requestExplanation => true,
    _ => false,
  };
}
