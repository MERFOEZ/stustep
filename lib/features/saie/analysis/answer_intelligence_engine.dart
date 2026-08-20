/// SAIE — AnswerIntelligenceEngine
///
/// The central orchestrator for Task 5.
///
/// Pipeline per student answer:
/// 1. Validate → reject invalid answers immediately.
/// 2. Duplicate detection → block if semantically identical to prior answer.
/// 3. Extract features → [AnswerFeatures].
/// 4. Score quality → [AnswerScore] (0–100, 9 dimensions).
/// 5. Extract evidence → [List<StudentEvidence>].
/// 6. Update profile dimensions → [DimensionUpdateResult].
/// 7. Update confidence → per-dimension confidence policy.
/// 8. Record history → [AnswerHistoryEntry] appended to [AnswerHistory].
/// 9. Return [AnswerProcessingResult].
///
/// Nothing updates the profile unless this engine approves it via
/// [DecisionResult.shouldUpdateProfile].
library;

import 'package:uuid/uuid.dart';
import 'package:stustep/features/saie/analysis/answer_feature_extractor.dart';
import 'package:stustep/features/saie/analysis/answer_features.dart';
import 'package:stustep/features/saie/analysis/answer_history.dart';
import 'package:stustep/features/saie/analysis/answer_quality_evaluator.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/analysis/answer_validation.dart';
import 'package:stustep/features/saie/analysis/confidence_updater.dart';
import 'package:stustep/features/saie/analysis/dimension_updater.dart';
import 'package:stustep/features/saie/analysis/evidence_extractor.dart';
import 'package:stustep/features/saie/analysis/semantic_similarity.dart';
import 'package:stustep/features/saie/analysis/structured_answer_resolver.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_result.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerProcessingResult
// ─────────────────────────────────────────────────────────────────────────────

/// The complete output of the [AnswerIntelligenceEngine] for a single answer.
final class AnswerProcessingResult {
  /// Unique ID for this processing cycle.
  final String processingId;

  /// The validation result for the raw answer.
  final ValidationResult validation;

  /// The extracted features (null if validation failed).
  final AnswerFeatures? features;

  /// The computed quality score (null if rejected before scoring).
  final AnswerScore? score;

  /// The history entry created for this answer.
  final AnswerHistoryEntry historyEntry;

  /// The updated cognitive profile (null if no profile update occurred).
  final StudentCognitiveProfile? updatedProfile;

  /// Keys of dimensions that were updated (empty if none).
  final List<String> updatedDimensionKeys;

  /// The updated answer history after appending this entry.
  final AnswerHistory updatedHistory;

  /// Whether the profile was modified by this answer.
  final bool profileUpdated;

  /// UTC timestamp of processing.
  final DateTime processedAt;

  const AnswerProcessingResult({
    required this.processingId,
    required this.validation,
    required this.historyEntry,
    required this.updatedHistory,
    required this.updatedDimensionKeys,
    required this.profileUpdated,
    required this.processedAt,
    this.features,
    this.score,
    this.updatedProfile,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerIntelligenceEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the full answer processing pipeline.
///
/// Stateless — all state is passed in via parameters.
final class AnswerIntelligenceEngine {
  static const _uuid = Uuid();

  final AnswerValidator _validator;
  final AnswerFeatureExtractor _featureExtractor;
  final AnswerQualityEvaluator _evaluator;
  final SemanticSimilarityService _similarityService;
  final EvidenceExtractor _evidenceExtractor;
  final StructuredAnswerResolver _resolver;
  final DimensionUpdater _dimensionUpdater;
  final ConfidenceUpdater _confidenceUpdater;

  const AnswerIntelligenceEngine({
    AnswerValidator validator = const AnswerValidator(),
    AnswerFeatureExtractor featureExtractor = const AnswerFeatureExtractor(),
    AnswerQualityEvaluator evaluator = const AnswerQualityEvaluator(),
    SemanticSimilarityService similarityService =
        const SemanticSimilarityService(),
    EvidenceExtractor evidenceExtractor = const EvidenceExtractor(),
    StructuredAnswerResolver resolver = const StructuredAnswerResolver(),
    DimensionUpdater dimensionUpdater = const DimensionUpdater(),
    ConfidenceUpdater confidenceUpdater = const ConfidenceUpdater(),
  })  : _validator = validator,
        _featureExtractor = featureExtractor,
        _evaluator = evaluator,
        _similarityService = similarityService,
        _evidenceExtractor = evidenceExtractor,
        _resolver = resolver,
        _dimensionUpdater = dimensionUpdater,
        _confidenceUpdater = confidenceUpdater;

  // ─── Core Entry Point ─────────────────────────────────────────────────────

  /// Processes a student answer through the full 9-step pipeline.
  ///
  /// [decisionResult] must have [DecisionResult.shouldUpdateProfile] == true
  /// for any profile modifications to occur.
  AnswerProcessingResult process({
    required String rawAnswer,
    required Question activeQuestion,
    required StudentCognitiveProfile profile,
    required ConversationContext context,
    required DecisionResult decisionResult,
    required AnswerHistory history,
    int consecutiveWeakCount = 0,
  }) {
    final processingId = _uuid.v4();
    final now = DateTime.now().toUtc();

    // ── Step 1: Validation ──
    final recentAnswerTexts = history.acceptedAnswerTexts;
    final validation = _validator.validate(
      rawAnswer: rawAnswer,
      recentAnswers: recentAnswerTexts.take(5).toList(),
    );

    if (!validation.isValid) {
      return _rejectedResult(
        processingId: processingId,
        rawAnswer: rawAnswer,
        questionId: activeQuestion.id,
        validation: validation,
        decision: AnswerDecision.rejectedInvalid,
        history: history,
        now: now,
      );
    }

    // ── Step 2: Semantic duplicate detection ──
    final duplicate = _similarityService.findDuplicate(
      validation.normalisedText,
      history.answersForQuestion(activeQuestion.id),
    );

    if (duplicate != null && duplicate.isDuplicate) {
      // Still score it, but mark as rejected duplicate.
      final features = _featureExtractor.extract(
        rawAnswer: validation.normalisedText,
        context: context,
        recentAnswerTexts: recentAnswerTexts,
      );
      final score = _evaluator.evaluate(
        rawAnswer: rawAnswer,
        features: features.copyWith(isRepetition: true),
        question: activeQuestion,
        profile: profile,
        recentAnswerTexts: recentAnswerTexts,
        contradictionDetected: decisionResult.contradictionDetected,
      );
      return _rejectedResult(
        processingId: processingId,
        rawAnswer: rawAnswer,
        questionId: activeQuestion.id,
        validation: validation,
        decision: AnswerDecision.rejectedDuplicate,
        history: history,
        now: now,
        score: score,
        features: features,
      );
    }

    // ── Step 3: Feature extraction ──
    final features = _featureExtractor.extract(
      rawAnswer: validation.normalisedText,
      context: context,
      recentAnswerTexts: recentAnswerTexts,
    );

    // ── Step 4: Quality scoring ──
    final score = _evaluator.evaluate(
      rawAnswer: rawAnswer,
      features: features,
      question: activeQuestion,
      profile: profile,
      recentAnswerTexts: recentAnswerTexts,
      contradictionDetected: decisionResult.contradictionDetected,
    );

    // Gate: profile update requires engine approval AND valid score.
    final canUpdateProfile = decisionResult.shouldUpdateProfile &&
        score.allowsProfileUpdate;

    // ── Step 4b: Structured answer resolution ──
    // Resolve the raw answer into a typed StructuredAnswerResult so the
    // EvidenceExtractor knows what kind of answer was given (option, Likert,
    // ranked, multi-select, or open-ended). This MUST happen before extraction.
    final structuredAnswer = _resolver.resolve(
      rawAnswer: rawAnswer,
      question: activeQuestion,
    );

    // ── Step 5: Evidence extraction ──
    final List<StudentEvidence> evidenceList = canUpdateProfile
        ? _evidenceExtractor.extract(
            question: activeQuestion,
            rawAnswer: rawAnswer,
            score: score,
            features: features,
            structuredAnswer: structuredAnswer,
          )
        : const <StudentEvidence>[];

    // ── Step 6 & 7: Dimension + confidence update ──
    StudentCognitiveProfile? updatedProfile;
    List<String> updatedKeys = const [];

    if (canUpdateProfile && evidenceList.isNotEmpty) {
      // Apply evidence to dimensions.
      final dimResult = _dimensionUpdater.apply(
        profile: profile,
        evidenceList: evidenceList,
        sessionId: processingId,
      );

      // Apply confidence policy.
      final confUpdated = _confidenceUpdater.update(
        profile: dimResult.updatedProfile,
        dimensionKeys: dimResult.updatedDimensionKeys,
        score: score,
        contradictionDetected: decisionResult.contradictionDetected,
        consecutiveWeakCount: consecutiveWeakCount,
      );

      updatedProfile = confUpdated;
      updatedKeys = dimResult.updatedDimensionKeys;
    }

    // ── Step 8: Determine final decision ──
    final decision = _resolveDecision(
      score: score,
      contradictionDetected: decisionResult.contradictionDetected,
      profileUpdated: updatedProfile != null,
    );

    // ── Step 9: Record history ──
    final entry = AnswerHistoryEntry(
      entryId: _uuid.v4(),
      questionId: activeQuestion.id,
      rawAnswer: rawAnswer,
      score: score,
      extractedEvidence: List.from(evidenceList),
      updatedDimensionKeys: updatedKeys,
      decision: decision,
      recordedAt: now,
    );

    final updatedHistory = history.append(entry);

    return AnswerProcessingResult(
      processingId: processingId,
      validation: validation,
      features: features,
      score: score,
      historyEntry: entry,
      updatedProfile: updatedProfile,
      updatedDimensionKeys: updatedKeys,
      updatedHistory: updatedHistory,
      profileUpdated: updatedProfile != null,
      processedAt: now,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  AnswerDecision _resolveDecision({
    required AnswerScore score,
    required bool contradictionDetected,
    required bool profileUpdated,
  }) {
    if (contradictionDetected) return AnswerDecision.acceptedContradiction;
    if (!score.allowsProfileUpdate) return AnswerDecision.rejectedInvalid;
    if (score.band == ScoreBand.weak) return AnswerDecision.acceptedWeak;
    return AnswerDecision.accepted;
  }

  AnswerProcessingResult _rejectedResult({
    required String processingId,
    required String rawAnswer,
    required String questionId,
    required ValidationResult validation,
    required AnswerDecision decision,
    required AnswerHistory history,
    required DateTime now,
    AnswerScore? score,
    AnswerFeatures? features,
  }) {
    final rejectedScore = score ??
        AnswerScore(
          questionId: questionId,
          answerText: rawAnswer,
          relevance: 0,
          completeness: 0,
          specificity: 0,
          consistency: 0,
          confidence: 0,
          evidenceStrength: 0,
          reasoningDepth: 0,
          informationDensity: 0,
          contextAwareness: 0,
          total: 0,
          band: ScoreBand.invalid,
          scoringReason: validation.reason,
          scoredAt: now,
        );

    final entry = AnswerHistoryEntry(
      entryId: _uuid.v4(),
      questionId: questionId,
      rawAnswer: rawAnswer,
      score: rejectedScore,
      extractedEvidence: const <StudentEvidence>[],
      updatedDimensionKeys: const [],
      decision: decision,
      recordedAt: now,
    );

    return AnswerProcessingResult(
      processingId: processingId,
      validation: validation,
      features: features,
      score: rejectedScore,
      historyEntry: entry,
      updatedProfile: null,
      updatedDimensionKeys: const [],
      updatedHistory: history.append(entry),
      profileUpdated: false,
      processedAt: now,
    );
  }
}
