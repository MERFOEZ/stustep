/// SAIE — Core Enumeration Definitions
///
/// All domain enumerations for the StuStep Academic Intelligence Engine.
/// Enums are the single source of truth for categorical values across the system.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Assessment & Reasoning
// ─────────────────────────────────────────────────────────────────────────────

/// Represents the current phase of an adaptive assessment session.
enum AssessmentPhase {
  /// Initial data gathering; no prior knowledge of the student yet.
  onboarding,

  /// The engine is exploring surface-level interests and strengths.
  exploration,

  /// The engine is deepening analysis in a specific academic area.
  deepening,

  /// Cross-domain verification and contradiction resolution.
  calibration,

  /// Sufficient evidence collected; generating final recommendation.
  synthesis,

  /// Assessment is complete; recommendations have been produced.
  completed,
}

/// Classifies the intent behind a student's conversational message.
enum IntentType {
  /// Student is answering a direct assessment question.
  answerQuestion,

  /// Student is freely expressing interests or thoughts.
  shareInterest,

  /// Student wants to know more about a specific major or career.
  requestInformation,

  /// Student is expressing concern, confusion, or uncertainty.
  expressDoubt,

  /// Student is asking for a recommendation or next step.
  requestRecommendation,

  /// Student wants to restart or change direction.
  resetSession,

  /// Intent cannot be determined from the input.
  unknown,
}

/// The quality of a student's response to an assessment question.
enum AnswerQuality {
  /// Demonstrates deep understanding and confidence.
  strong,

  /// Shows reasonable understanding with some gaps.
  moderate,

  /// Shows surface-level understanding or guessing.
  weak,

  /// Answer is irrelevant, incomplete, or off-topic.
  invalid,

  /// Student explicitly declined to answer.
  skipped,
}

// ─────────────────────────────────────────────────────────────────────────────
// Questions
// ─────────────────────────────────────────────────────────────────────────────

/// The format type of an assessment question.
enum QuestionType {
  /// Single correct answer from multiple options.
  multipleChoice,

  /// True or false answer.
  trueFalse,

  /// Free-text response from the student.
  openEnded,

  /// Student rates agreement on a scale.
  likertScale,

  /// Student orders a list of items by preference or priority.
  ranking,

  /// Student selects multiple valid answers.
  multiSelect,

  /// Scenario-based situational judgment question.
  situationalJudgment,
}

/// The difficulty level of an assessment question.
enum QuestionDifficulty {
  /// Foundational; suitable for initial screening.
  basic,

  /// Requires applied understanding.
  intermediate,

  /// Requires synthesis, analysis, or domain-specific reasoning.
  advanced,

  /// Adaptive difficulty determined by engine at runtime.
  adaptive,
}

// ─────────────────────────────────────────────────────────────────────────────
// Confidence & Evidence
// ─────────────────────────────────────────────────────────────────────────────

/// Confidence level that the engine assigns to an inference or recommendation.
enum ConfidenceLevel {
  /// Very low confidence; requires significantly more data.
  veryLow,

  /// Low confidence; possible direction but unconfirmed.
  low,

  /// Moderate confidence; likely direction with some uncertainty.
  moderate,

  /// High confidence; well-supported by multiple evidence signals.
  high,

  /// Very high confidence; strongly supported by convergent evidence.
  veryHigh,
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Profile
// ─────────────────────────────────────────────────────────────────────────────

/// The student's dominant learning modality.
enum LearningStyle {
  /// Learns best through visual representations and spatial reasoning.
  visual,

  /// Learns best through reading and writing.
  readWrite,

  /// Learns best through listening and verbal explanation.
  auditory,

  /// Learns best through hands-on doing and experimentation.
  kinesthetic,

  /// No strong single preference; adapts across modalities.
  multimodal,
}

/// Big Five / MBTI-adjacent personality dimensions used for academic fit.
enum PersonalityDimension {
  /// Openness to new ideas and creative thinking.
  openness,

  /// Tendency to be organized, goal-oriented, and disciplined.
  conscientiousness,

  /// Preference for social interaction and group work.
  extraversion,

  /// Tendency toward cooperation, trust, and empathy.
  agreeableness,

  /// Emotional stability and stress tolerance.
  emotionalStability,

  /// Preference for structure versus spontaneity.
  judgingVsPerceiving,

  /// Preference for logical versus values-driven decisions.
  thinkingVsFeeling,

  /// Preference for concrete detail versus abstract concepts.
  sensingVsIntuition,
}

// ─────────────────────────────────────────────────────────────────────────────
// Majors & Careers
// ─────────────────────────────────────────────────────────────────────────────

/// High-level academic discipline category.
enum MajorCategory {
  /// Sciences: mathematics, physics, chemistry, biology, etc.
  stem,

  /// Business, accounting, economics, management.
  business,

  /// Medicine, nursing, pharmacy, allied health.
  healthAndMedicine,

  /// Law, political science, public administration.
  lawAndGovernance,

  /// Computer science, software engineering, IT.
  computingAndTechnology,

  /// Art, design, music, architecture, film.
  artsAndDesign,

  /// Sociology, psychology, philosophy, anthropology.
  socialAndHumanities,

  /// Education, pedagogy, curriculum design.
  education,

  /// Agricultural science, veterinary, environmental science.
  agricultureAndEnvironment,

  /// Languages, translation, linguistics, communication.
  languagesAndCommunication,
}

/// The primary work environment type for a career.
enum CareerEnvironment {
  /// Office-based, corporate, or organizational settings.
  corporate,

  /// Clinical, hospital, or patient-facing settings.
  clinical,

  /// Field research, outdoor, or lab-based work.
  research,

  /// Educational institutions, teaching, training.
  educational,

  /// Freelance, creative studio, or self-employed.
  creative,

  /// Government agencies, public sector, policy.
  governmental,

  /// Entrepreneurial, startup, or venture-based.
  entrepreneurial,

  /// Remote / digital-first work environment.
  remote,
}

// ─────────────────────────────────────────────────────────────────────────────
// Session & Conversation
// ─────────────────────────────────────────────────────────────────────────────

/// Role of a message sender within a conversation turn.
enum MessageRole {
  /// The SAIE reasoning engine is speaking.
  engine,

  /// The student is speaking.
  student,

  /// Internal system-generated annotation (not shown to the student).
  system,
}

/// Tracks the status of an overall assessment session.
enum SessionStatus {
  /// Session created but not yet started.
  initialized,

  /// Session is actively collecting data.
  active,

  /// Session is temporarily paused; can be resumed.
  paused,

  /// Session has been completed successfully.
  completed,

  /// Session was abandoned before completion.
  abandoned,
}

/// The type of academic goal the assessment is targeting.
enum AssessmentGoalType {
  /// Recommend an undergraduate major.
  majorSelection,

  /// Recommend a graduate program or specialization.
  graduateSpecialization,

  /// Identify suitable career paths.
  careerExploration,

  /// Evaluate academic readiness for a specific program.
  readinessCheck,

  /// Diagnose learning gaps and suggest bridging content.
  learningGapAnalysis,
}
