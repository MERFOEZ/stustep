/// SAIE — AssessmentConfiguration
///
/// All tunable parameters for the Adaptive Assessment Engine.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentConfiguration
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable configuration injected into the [AdaptiveAssessmentEngine].
final class AssessmentConfiguration extends Equatable {
  /// Minimum number of questions to ask before considering completion.
  final int minimumQuestions;

  /// Absolute maximum questions per session (safety ceiling).
  final int maximumQuestions;

  /// Coverage ratio [0.0, 1.0] required before the engine may stop.
  final double minimumCoverageRatio;

  /// Overall profile confidence required for completion.
  final double minimumCompletionConfidence;

  /// Confidence required from the Matching Engine to accept a recommendation.
  final double minimumRecommendationConfidence;

  /// How many consecutive questions from the same domain to allow.
  final int maxConsecutiveSameDomain;

  /// Weight applied to information gain during question valuation.
  final double infoGainWeight;

  /// Weight applied to confidence gain during question valuation.
  final double confidenceGainWeight;

  /// Weight applied to evidence gain during question valuation.
  final double evidenceGainWeight;

  /// Penalty applied for question redundancy during valuation.
  final double redundancyPenalty;

  /// Minimum evidence count per dimension before it is considered "covered".
  final int evidenceCountForCoverage;

  /// Phase progression thresholds — coverage ratios that trigger phase change.
  final Map<AssessmentPhase, double> phaseProgressionThresholds;

  const AssessmentConfiguration({
    this.minimumQuestions = 8,
    this.maximumQuestions = 40,
    this.minimumCoverageRatio = 0.70,
    this.minimumCompletionConfidence = 0.55,
    this.minimumRecommendationConfidence = 0.50,
    this.maxConsecutiveSameDomain = 2,
    this.infoGainWeight = 0.40,
    this.confidenceGainWeight = 0.30,
    this.evidenceGainWeight = 0.20,
    this.redundancyPenalty = 0.10,
    this.evidenceCountForCoverage = 2,
    this.phaseProgressionThresholds = const {
      AssessmentPhase.onboarding: 0.0,
      AssessmentPhase.exploration: 0.20,
      AssessmentPhase.deepening: 0.45,
      AssessmentPhase.calibration: 0.65,
      AssessmentPhase.synthesis: 0.80,
      AssessmentPhase.completed: 1.0,
    },
  });

  factory AssessmentConfiguration.fromJson(Map<String, dynamic> json) =>
      AssessmentConfiguration(
        minimumQuestions: json['minimum_questions'] as int? ?? 8,
        maximumQuestions: json['maximum_questions'] as int? ?? 40,
        minimumCoverageRatio:
            (json['minimum_coverage_ratio'] as num?)?.toDouble() ?? 0.70,
        minimumCompletionConfidence:
            (json['minimum_completion_confidence'] as num?)?.toDouble() ?? 0.55,
        minimumRecommendationConfidence:
            (json['minimum_recommendation_confidence'] as num?)?.toDouble() ??
                0.50,
        maxConsecutiveSameDomain:
            json['max_consecutive_same_domain'] as int? ?? 2,
        infoGainWeight:
            (json['info_gain_weight'] as num?)?.toDouble() ?? 0.40,
        confidenceGainWeight:
            (json['confidence_gain_weight'] as num?)?.toDouble() ?? 0.30,
        evidenceGainWeight:
            (json['evidence_gain_weight'] as num?)?.toDouble() ?? 0.20,
        redundancyPenalty:
            (json['redundancy_penalty'] as num?)?.toDouble() ?? 0.10,
        evidenceCountForCoverage:
            json['evidence_count_for_coverage'] as int? ?? 2,
        phaseProgressionThresholds:
            (json['phase_progression_thresholds'] as Map<String, dynamic>?)
                    ?.map(
                      (k, v) => MapEntry(
                        AssessmentPhase.values.byName(k),
                        (v as num).toDouble(),
                      ),
                    ) ??
                const {},
      );

  Map<String, dynamic> toJson() => {
    'minimum_questions': minimumQuestions,
    'maximum_questions': maximumQuestions,
    'minimum_coverage_ratio': minimumCoverageRatio,
    'minimum_completion_confidence': minimumCompletionConfidence,
    'minimum_recommendation_confidence': minimumRecommendationConfidence,
    'max_consecutive_same_domain': maxConsecutiveSameDomain,
    'info_gain_weight': infoGainWeight,
    'confidence_gain_weight': confidenceGainWeight,
    'evidence_gain_weight': evidenceGainWeight,
    'redundancy_penalty': redundancyPenalty,
    'evidence_count_for_coverage': evidenceCountForCoverage,
    'phase_progression_thresholds': phaseProgressionThresholds.map(
      (k, v) => MapEntry(k.name, v),
    ),
  };

  AssessmentConfiguration copyWith({
    int? minimumQuestions,
    int? maximumQuestions,
    double? minimumCoverageRatio,
    double? minimumCompletionConfidence,
    double? minimumRecommendationConfidence,
    int? maxConsecutiveSameDomain,
    double? infoGainWeight,
    double? confidenceGainWeight,
    double? evidenceGainWeight,
    double? redundancyPenalty,
    int? evidenceCountForCoverage,
    Map<AssessmentPhase, double>? phaseProgressionThresholds,
  }) => AssessmentConfiguration(
    minimumQuestions: minimumQuestions ?? this.minimumQuestions,
    maximumQuestions: maximumQuestions ?? this.maximumQuestions,
    minimumCoverageRatio: minimumCoverageRatio ?? this.minimumCoverageRatio,
    minimumCompletionConfidence:
        minimumCompletionConfidence ?? this.minimumCompletionConfidence,
    minimumRecommendationConfidence:
        minimumRecommendationConfidence ?? this.minimumRecommendationConfidence,
    maxConsecutiveSameDomain:
        maxConsecutiveSameDomain ?? this.maxConsecutiveSameDomain,
    infoGainWeight: infoGainWeight ?? this.infoGainWeight,
    confidenceGainWeight: confidenceGainWeight ?? this.confidenceGainWeight,
    evidenceGainWeight: evidenceGainWeight ?? this.evidenceGainWeight,
    redundancyPenalty: redundancyPenalty ?? this.redundancyPenalty,
    evidenceCountForCoverage:
        evidenceCountForCoverage ?? this.evidenceCountForCoverage,
    phaseProgressionThresholds:
        phaseProgressionThresholds ?? this.phaseProgressionThresholds,
  );

  @override
  List<Object?> get props => [
    minimumQuestions,
    maximumQuestions,
    minimumCoverageRatio,
    minimumCompletionConfidence,
  ];
}
