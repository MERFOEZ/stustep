/// SAIE — RecommendationConfidence
///
/// Computes and encapsulates the confidence level for a single recommendation.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConfidenceTier
// ─────────────────────────────────────────────────────────────────────────────

/// Human-readable confidence band for a recommendation.
enum ConfidenceTier {
  /// Score [0.0, 0.30) — assessment data insufficient.
  insufficient,

  /// Score [0.30, 0.50) — low but may still be displayed.
  low,

  /// Score [0.50, 0.70) — moderate; show with caveats.
  moderate,

  /// Score [0.70, 0.85) — high confidence.
  high,

  /// Score [0.85, 1.0] — very high confidence.
  veryHigh,
}

extension ConfidenceTierX on ConfidenceTier {
  String get label => switch (this) {
    ConfidenceTier.insufficient => 'Insufficient Data',
    ConfidenceTier.low => 'Low Confidence',
    ConfidenceTier.moderate => 'Moderate Confidence',
    ConfidenceTier.high => 'High Confidence',
    ConfidenceTier.veryHigh => 'Very High Confidence',
  };

  bool get isActionable =>
      this == ConfidenceTier.moderate ||
      this == ConfidenceTier.high ||
      this == ConfidenceTier.veryHigh;
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationConfidence
// ─────────────────────────────────────────────────────────────────────────────

/// Confidence model for a single recommendation.
final class RecommendationConfidence extends Equatable {
  /// Composite confidence score [0.0, 1.0].
  final double score;

  /// Human-readable tier.
  final ConfidenceTier tier;

  /// Profile confidence at the time of recommendation.
  final double profileConfidence;

  /// Number of evidence records that informed this recommendation.
  final int evidenceCount;

  /// Coverage ratio of the cognitive profile [0.0, 1.0].
  final double coverageRatio;

  /// Similarity score from the matching engine [0, 100].
  final int matchSimilarityScore;

  /// Human-readable confidence explanation.
  final String explanation;

  const RecommendationConfidence({
    required this.score,
    required this.tier,
    required this.profileConfidence,
    required this.evidenceCount,
    required this.coverageRatio,
    required this.matchSimilarityScore,
    required this.explanation,
  });

  bool get isActionable => tier.isActionable;

  factory RecommendationConfidence.compute({
    required double profileConfidence,
    required int evidenceCount,
    required double coverageRatio,
    required int matchSimilarityScore,
  }) {
    // Weighted composite.
    final scoreNorm = matchSimilarityScore / 100.0;
    final composite = (profileConfidence * 0.35 +
            coverageRatio * 0.25 +
            scoreNorm * 0.30 +
            (evidenceCount.clamp(0, 20) / 20.0) * 0.10)
        .clamp(0.0, 1.0);

    final tier = composite < 0.30
        ? ConfidenceTier.insufficient
        : composite < 0.50
            ? ConfidenceTier.low
            : composite < 0.70
                ? ConfidenceTier.moderate
                : composite < 0.85
                    ? ConfidenceTier.high
                    : ConfidenceTier.veryHigh;

    return RecommendationConfidence(
      score: composite,
      tier: tier,
      profileConfidence: profileConfidence,
      evidenceCount: evidenceCount,
      coverageRatio: coverageRatio,
      matchSimilarityScore: matchSimilarityScore,
      explanation:
          '${tier.label}: profile=${(profileConfidence * 100).toStringAsFixed(0)}% '
          'coverage=${(coverageRatio * 100).toStringAsFixed(0)}% '
          'match=$matchSimilarityScore/100 '
          'evidence=$evidenceCount records',
    );
  }

  factory RecommendationConfidence.fromJson(Map<String, dynamic> json) =>
      RecommendationConfidence(
        score: (json['score'] as num).toDouble(),
        tier: ConfidenceTier.values.byName(json['tier'] as String),
        profileConfidence: (json['profile_confidence'] as num).toDouble(),
        evidenceCount: json['evidence_count'] as int,
        coverageRatio: (json['coverage_ratio'] as num).toDouble(),
        matchSimilarityScore: json['match_similarity_score'] as int,
        explanation: json['explanation'] as String,
      );

  Map<String, dynamic> toJson() => {
    'score': score,
    'tier': tier.name,
    'profile_confidence': profileConfidence,
    'evidence_count': evidenceCount,
    'coverage_ratio': coverageRatio,
    'match_similarity_score': matchSimilarityScore,
    'explanation': explanation,
  };

  RecommendationConfidence copyWith({
    double? score,
    ConfidenceTier? tier,
    double? profileConfidence,
    int? evidenceCount,
    double? coverageRatio,
    int? matchSimilarityScore,
    String? explanation,
  }) => RecommendationConfidence(
    score: score ?? this.score,
    tier: tier ?? this.tier,
    profileConfidence: profileConfidence ?? this.profileConfidence,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    coverageRatio: coverageRatio ?? this.coverageRatio,
    matchSimilarityScore: matchSimilarityScore ?? this.matchSimilarityScore,
    explanation: explanation ?? this.explanation,
  );

  @override
  List<Object?> get props => [score, tier, matchSimilarityScore];
}
