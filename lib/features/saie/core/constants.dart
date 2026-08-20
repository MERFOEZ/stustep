/// SAIE — Core Constants
///
/// System-wide configuration constants for the SAIE reasoning engine.
/// All values are compile-time constants — no runtime mutation.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Engine Thresholds
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum number of evidence signals required before synthesis can begin.
const int kMinimumEvidenceForSynthesis = 5;

/// Maximum questions per assessment session (safety cap).
const int kMaxQuestionsPerSession = 30;

/// Minimum questions before phase transition is allowed.
const int kMinQuestionsPerPhase = 3;

/// Confidence score threshold to classify a recommendation as "high" quality.
const double kHighConfidenceThreshold = 0.75;

/// Confidence score threshold to classify a recommendation as "very high".
const double kVeryHighConfidenceThreshold = 0.90;

/// Minimum confidence score required to emit a recommendation.
const double kMinRecommendationConfidence = 0.40;

/// Maximum number of top recommendations returned to the presentation layer.
const int kMaxRecommendations = 5;

// ─────────────────────────────────────────────────────────────────────────────
// Scoring Weights
// ─────────────────────────────────────────────────────────────────────────────

/// Weight applied to explicit interest signals in scoring.
const double kInterestSignalWeight = 0.35;

/// Weight applied to academic performance signals in scoring.
const double kAcademicPerformanceWeight = 0.30;

/// Weight applied to personality dimension alignment in scoring.
const double kPersonalityAlignmentWeight = 0.20;

/// Weight applied to skill-match signals in scoring.
const double kSkillMatchWeight = 0.15;

// ─────────────────────────────────────────────────────────────────────────────
// Knowledge Base Paths
// ─────────────────────────────────────────────────────────────────────────────

/// Asset path root for all knowledge base JSON files.
const String kKnowledgeBasePath = 'assets/knowledge';

/// Subdirectory containing major definitions.
const String kMajorsPath = '$kKnowledgeBasePath/majors';

/// Subdirectory containing career definitions.
const String kCareersPath = '$kKnowledgeBasePath/careers';

/// Subdirectory containing assessment question banks.
const String kQuestionsPath = '$kKnowledgeBasePath/questions';

/// Subdirectory containing skill taxonomy definitions.
const String kSkillsPath = '$kKnowledgeBasePath/skills';

/// Filename for the majors index manifest.
const String kMajorsIndexFile = '$kMajorsPath/index.json';

/// Filename for the careers index manifest.
const String kCareersIndexFile = '$kCareersPath/index.json';

/// Filename for the skills taxonomy index.
const String kSkillsIndexFile = '$kSkillsPath/index.json';

// ─────────────────────────────────────────────────────────────────────────────
// Storage Keys
// ─────────────────────────────────────────────────────────────────────────────

/// SharedPreferences key prefix for stored session data.
const String kSessionStoragePrefix = 'saie_session_';

/// SharedPreferences key for the current active session ID.
const String kActiveSessionKey = 'saie_active_session_id';

/// SharedPreferences key for persisted student profile.
const String kStudentProfileKey = 'saie_student_profile';

// ─────────────────────────────────────────────────────────────────────────────
// Session & UI
// ─────────────────────────────────────────────────────────────────────────────

/// Default session timeout in minutes. Sessions idle beyond this are paused.
const int kSessionTimeoutMinutes = 60;

/// Minimum answer length (characters) for open-ended responses.
const int kMinOpenEndedAnswerLength = 10;

/// Maximum stored conversation messages per session.
const int kMaxConversationHistory = 200;
