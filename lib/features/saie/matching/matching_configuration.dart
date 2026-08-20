/// SAIE — MatchingConfiguration
///
/// Controls every tunable parameter of the Major Matching Engine.
/// Injected at construction time — no global state.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchingConfiguration
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable configuration for the [MajorMatchingEngine].
final class MatchingConfiguration extends Equatable {
  /// Minimum overall profile confidence required to produce recommendations.
  /// Below this threshold the engine returns "Need More Evidence".
  final double minimumProfileConfidence;

  /// Minimum similarity score (0–100) for a major to appear in results.
  final int minimumSimilarityScore;

  /// Maximum number of top majors to return.
  final int topN;

  /// Dimension weights — how much each cognitive dimension contributes to
  /// the similarity score. Keys match [DimensionKeys] constants.
  /// Values must sum to ≤ 1.0; the engine normalises automatically.
  final Map<String, double> dimensionWeights;

  /// Whether to include majors marked as hidden in the knowledge base.
  final bool includeHidden;

  /// Whether to boost scores for majors with high market demand.
  final bool applyMarketDemandBoost;

  /// Maximum market-demand boost added to the raw score (in score points).
  final double marketDemandBoostMax;

  /// Minimum number of evidence records required before matching is run.
  final int minimumEvidenceCount;

  const MatchingConfiguration({
    this.minimumProfileConfidence = 0.30,
    this.minimumSimilarityScore = 20,
    this.topN = 10,
    this.dimensionWeights = _defaultWeights,
    this.includeHidden = false,
    this.applyMarketDemandBoost = true,
    this.marketDemandBoostMax = 5.0,
    this.minimumEvidenceCount = 5,
  });

  /// Default weight distribution across the 24 cognitive dimensions.
  ///
  /// Calibration rationale:
  /// - mathematics (0.10): strongest STEM-vs-humanities discriminator
  /// - logic (0.09): key CS/AI differentiator; low in medicine/law/business
  /// - technology (0.09): separates tech majors from all non-tech
  /// - empathy (0.08): separates medicine/psychology from STEM
  /// - critical_thinking (0.07): broad but required; differentiates research depth
  /// - problem_solving (0.08): spans engineering/CS; filters non-analytical
  /// - communication (0.07): key for business/law/media cluster
  /// - science (0.06): separates engineering/medicine from business/law
  /// - research (0.06): separates AI/data science from applied SWE
  /// - creativity (0.05): separates architecture/media/art from analytical fields
  /// - leadership (0.05): business/law tier signal
  /// - business (0.05): narrow but high-precision for business major
  /// - practical_vs_theoretical (0.05): key AI(high=theoretical) vs SWE(low) discriminator
  /// - technology_affinity (0.04): secondary tech signal
  /// - teamwork (0.03): SWE-specific but broad; lower weight
  /// - language (0.03): law/media specific
  /// - medicine (0.03): very specific — high value for medicine, 0 elsewhere
  /// - self_learning (0.03): broad, less discriminating
  /// - decision_style (0.03): business/law secondary
  /// - stress_preference (0.02): medicine secondary
  /// - art (0.02): architecture/media specific
  /// - law (0.02): very specific to law major
  /// - academic_performance (0.02): supporting signal
  /// - ambiguity_tolerance (0.02): design/research secondary
  static const Map<String, double> _defaultWeights = {
    'mathematics': 0.10,
    'logic': 0.09,
    'technology': 0.09,
    'empathy': 0.08,
    'problem_solving': 0.08,
    'critical_thinking': 0.07,
    'communication': 0.07,
    'science': 0.06,
    'research': 0.06,
    'creativity': 0.05,
    'leadership': 0.05,
    'business': 0.05,
    'practical_vs_theoretical': 0.05,
    'technology_affinity': 0.04,
    'teamwork': 0.03,
    'language': 0.03,
    'medicine': 0.03,
    'self_learning': 0.03,
    'decision_style': 0.03,
    'stress_preference': 0.02,
    'art': 0.02,
    'law': 0.02,
    'academic_performance': 0.02,
    'ambiguity_tolerance': 0.02,
  };


  factory MatchingConfiguration.fromJson(Map<String, dynamic> json) =>
      MatchingConfiguration(
        minimumProfileConfidence:
            (json['minimum_profile_confidence'] as num?)?.toDouble() ?? 0.30,
        minimumSimilarityScore:
            json['minimum_similarity_score'] as int? ?? 20,
        topN: json['top_n'] as int? ?? 10,
        dimensionWeights:
            (json['dimension_weights'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            _defaultWeights,
        includeHidden: json['include_hidden'] as bool? ?? false,
        applyMarketDemandBoost:
            json['apply_market_demand_boost'] as bool? ?? true,
        marketDemandBoostMax:
            (json['market_demand_boost_max'] as num?)?.toDouble() ?? 5.0,
        minimumEvidenceCount: json['minimum_evidence_count'] as int? ?? 3,
      );

  Map<String, dynamic> toJson() => {
    'minimum_profile_confidence': minimumProfileConfidence,
    'minimum_similarity_score': minimumSimilarityScore,
    'top_n': topN,
    'dimension_weights': dimensionWeights,
    'include_hidden': includeHidden,
    'apply_market_demand_boost': applyMarketDemandBoost,
    'market_demand_boost_max': marketDemandBoostMax,
    'minimum_evidence_count': minimumEvidenceCount,
  };

  MatchingConfiguration copyWith({
    double? minimumProfileConfidence,
    int? minimumSimilarityScore,
    int? topN,
    Map<String, double>? dimensionWeights,
    bool? includeHidden,
    bool? applyMarketDemandBoost,
    double? marketDemandBoostMax,
    int? minimumEvidenceCount,
  }) => MatchingConfiguration(
    minimumProfileConfidence:
        minimumProfileConfidence ?? this.minimumProfileConfidence,
    minimumSimilarityScore:
        minimumSimilarityScore ?? this.minimumSimilarityScore,
    topN: topN ?? this.topN,
    dimensionWeights: dimensionWeights ?? this.dimensionWeights,
    includeHidden: includeHidden ?? this.includeHidden,
    applyMarketDemandBoost:
        applyMarketDemandBoost ?? this.applyMarketDemandBoost,
    marketDemandBoostMax: marketDemandBoostMax ?? this.marketDemandBoostMax,
    minimumEvidenceCount: minimumEvidenceCount ?? this.minimumEvidenceCount,
  );

  @override
  List<Object?> get props => [
    minimumProfileConfidence,
    minimumSimilarityScore,
    topN,
    includeHidden,
  ];
}
