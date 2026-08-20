/// SAIE — RecommendationValidator
///
/// Gate that decides whether the engine has enough data to produce
/// a valid recommendation. Never guesses.
library;

import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_confidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ValidationResult
// ─────────────────────────────────────────────────────────────────────────────

enum ValidationOutcome { valid, needMoreAssessment, noConfidentMatch }

final class RecommendationValidationResult {
  final ValidationOutcome outcome;
  final String message;
  final double profileConfidence;
  final double coverageRatio;
  final int evidenceCount;
  final ConfidenceTier confidenceTier;

  const RecommendationValidationResult({
    required this.outcome,
    required this.message,
    required this.profileConfidence,
    required this.coverageRatio,
    required this.evidenceCount,
    required this.confidenceTier,
  });

  bool get isValid => outcome == ValidationOutcome.valid;
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationValidator
// ─────────────────────────────────────────────────────────────────────────────

/// Validates that the system has enough data to produce a recommendation.
final class RecommendationValidator {
  static const double _minProfileConfidence = 0.35;
  static const double _minCoverage = 0.55;
  static const int _minEvidenceCount = 5;
  static const int _minMatchScore = 30;

  const RecommendationValidator();

  RecommendationValidationResult validate({
    required StudentCognitiveProfile profile,
    required MajorRanking ranking,
    required AssessmentStatistics stats,
  }) {
    final profileStats = profile.computeStatistics();
    final coverage = profileStats.coverageRatio;
    final confidence = profileStats.overallConfidence;
    final evidenceCount = profile.evidenceCount;

    // Gate 1: Not enough profile evidence.
    if (evidenceCount < _minEvidenceCount ||
        coverage < _minCoverage ||
        confidence < _minProfileConfidence) {
      return RecommendationValidationResult(
        outcome: ValidationOutcome.needMoreAssessment,
        message:
            'More assessment data is needed. '
            'Current coverage: ${(coverage * 100).toStringAsFixed(0)}% '
            '(required: ${(_minCoverage * 100).toStringAsFixed(0)}%), '
            'confidence: ${(confidence * 100).toStringAsFixed(0)}% '
            '(required: ${(_minProfileConfidence * 100).toStringAsFixed(0)}%), '
            'evidence: $evidenceCount records (required: $_minEvidenceCount).',
        profileConfidence: confidence,
        coverageRatio: coverage,
        evidenceCount: evidenceCount,
        confidenceTier: ConfidenceTier.insufficient,
      );
    }

    // Gate 2: Matching engine didn't produce any candidates above threshold.
    if (ranking.candidates.isEmpty ||
        ranking.candidates.first.score.similarityScore < _minMatchScore) {
      return RecommendationValidationResult(
        outcome: ValidationOutcome.noConfidentMatch,
        message:
            'No university major matched with sufficient confidence. '
            'Consider broadening interests or providing more detailed answers.',
        profileConfidence: confidence,
        coverageRatio: coverage,
        evidenceCount: evidenceCount,
        confidenceTier: ConfidenceTier.low,
      );
    }

    final tier = _computeTier(confidence, coverage, evidenceCount);

    return RecommendationValidationResult(
      outcome: ValidationOutcome.valid,
      message: 'Recommendation data is sufficient.',
      profileConfidence: confidence,
      coverageRatio: coverage,
      evidenceCount: evidenceCount,
      confidenceTier: tier,
    );
  }

  ConfidenceTier _computeTier(
    double confidence,
    double coverage,
    int evidenceCount,
  ) {
    final composite = confidence * 0.5 +
        coverage * 0.3 +
        (evidenceCount.clamp(0, 20) / 20.0) * 0.2;
    if (composite < 0.30) return ConfidenceTier.insufficient;
    if (composite < 0.50) return ConfidenceTier.low;
    if (composite < 0.70) return ConfidenceTier.moderate;
    if (composite < 0.85) return ConfidenceTier.high;
    return ConfidenceTier.veryHigh;
  }
}
