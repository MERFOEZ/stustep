/// SAIE — RecommendationStatistics
///
/// Aggregate statistics for a completed recommendation report.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationStatistics
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregate metrics produced from a [RecommendationReport].
final class RecommendationStatistics extends Equatable {
  final int totalMajorsConsidered;
  final int totalMajorsFiltered;
  final int totalRecommendationsGenerated;
  final double topPickSimilarityScore;
  final double topPickConfidenceScore;
  final double averageSimilarityScore;
  final double averageConfidenceScore;
  final Map<String, int> categoryDistribution;
  final int totalReasonsGenerated;
  final int positiveReasonsCount;
  final int negativeReasonsCount;
  final DateTime computedAt;

  const RecommendationStatistics({
    required this.totalMajorsConsidered,
    required this.totalMajorsFiltered,
    required this.totalRecommendationsGenerated,
    required this.topPickSimilarityScore,
    required this.topPickConfidenceScore,
    required this.averageSimilarityScore,
    required this.averageConfidenceScore,
    required this.categoryDistribution,
    required this.totalReasonsGenerated,
    required this.positiveReasonsCount,
    required this.negativeReasonsCount,
    required this.computedAt,
  });

  factory RecommendationStatistics.fromReport(RecommendationReport report) {
    final recs = report.recommendations;
    if (recs.isEmpty) {
      return RecommendationStatistics(
        totalMajorsConsidered:
            report.sourceRanking.statistics.majorsEvaluated,
        totalMajorsFiltered: report.sourceRanking.statistics.majorsFiltered,
        totalRecommendationsGenerated: 0,
        topPickSimilarityScore: 0,
        topPickConfidenceScore: 0,
        averageSimilarityScore: 0,
        averageConfidenceScore: 0,
        categoryDistribution: const {},
        totalReasonsGenerated: 0,
        positiveReasonsCount: 0,
        negativeReasonsCount: 0,
        computedAt: DateTime.now().toUtc(),
      );
    }

    final topPick = recs.first;
    final avgSim =
        recs.map((r) => r.similarityScore).reduce((a, b) => a + b) /
            recs.length;
    final avgConf =
        recs.map((r) => r.confidence.score).reduce((a, b) => a + b) /
            recs.length;

    final catDist = <String, int>{};
    for (final r in recs) {
      final key = r.category.name;
      catDist[key] = (catDist[key] ?? 0) + 1;
    }

    final totalReasons = recs.fold(0, (s, r) => s + r.reasons.length);
    final posReasons = recs.fold(
        0, (s, r) => s + r.reasons.where((re) => re.positive).length);
    final negReasons = totalReasons - posReasons;

    return RecommendationStatistics(
      totalMajorsConsidered: report.sourceRanking.statistics.majorsEvaluated,
      totalMajorsFiltered: report.sourceRanking.statistics.majorsFiltered,
      totalRecommendationsGenerated: recs.length,
      topPickSimilarityScore: topPick.similarityScore.toDouble(),
      topPickConfidenceScore: topPick.confidence.score,
      averageSimilarityScore: avgSim.toDouble(),
      averageConfidenceScore: avgConf,
      categoryDistribution: catDist,
      totalReasonsGenerated: totalReasons,
      positiveReasonsCount: posReasons,
      negativeReasonsCount: negReasons,
      computedAt: DateTime.now().toUtc(),
    );
  }

  factory RecommendationStatistics.fromJson(Map<String, dynamic> json) =>
      RecommendationStatistics(
        totalMajorsConsidered: json['total_majors_considered'] as int,
        totalMajorsFiltered: json['total_majors_filtered'] as int,
        totalRecommendationsGenerated:
            json['total_recommendations_generated'] as int,
        topPickSimilarityScore:
            (json['top_pick_similarity_score'] as num).toDouble(),
        topPickConfidenceScore:
            (json['top_pick_confidence_score'] as num).toDouble(),
        averageSimilarityScore:
            (json['average_similarity_score'] as num).toDouble(),
        averageConfidenceScore:
            (json['average_confidence_score'] as num).toDouble(),
        categoryDistribution:
            (json['category_distribution'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        ),
        totalReasonsGenerated: json['total_reasons_generated'] as int,
        positiveReasonsCount: json['positive_reasons_count'] as int,
        negativeReasonsCount: json['negative_reasons_count'] as int,
        computedAt: DateTime.parse(json['computed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'total_majors_considered': totalMajorsConsidered,
    'total_majors_filtered': totalMajorsFiltered,
    'total_recommendations_generated': totalRecommendationsGenerated,
    'top_pick_similarity_score': topPickSimilarityScore,
    'top_pick_confidence_score': topPickConfidenceScore,
    'average_similarity_score': averageSimilarityScore,
    'average_confidence_score': averageConfidenceScore,
    'category_distribution': categoryDistribution,
    'total_reasons_generated': totalReasonsGenerated,
    'positive_reasons_count': positiveReasonsCount,
    'negative_reasons_count': negativeReasonsCount,
    'computed_at': computedAt.toIso8601String(),
  };

  RecommendationStatistics copyWith({
    int? totalMajorsConsidered,
    int? totalMajorsFiltered,
    int? totalRecommendationsGenerated,
    double? topPickSimilarityScore,
    double? topPickConfidenceScore,
    double? averageSimilarityScore,
    double? averageConfidenceScore,
    Map<String, int>? categoryDistribution,
    int? totalReasonsGenerated,
    int? positiveReasonsCount,
    int? negativeReasonsCount,
    DateTime? computedAt,
  }) => RecommendationStatistics(
    totalMajorsConsidered:
        totalMajorsConsidered ?? this.totalMajorsConsidered,
    totalMajorsFiltered: totalMajorsFiltered ?? this.totalMajorsFiltered,
    totalRecommendationsGenerated:
        totalRecommendationsGenerated ?? this.totalRecommendationsGenerated,
    topPickSimilarityScore:
        topPickSimilarityScore ?? this.topPickSimilarityScore,
    topPickConfidenceScore:
        topPickConfidenceScore ?? this.topPickConfidenceScore,
    averageSimilarityScore:
        averageSimilarityScore ?? this.averageSimilarityScore,
    averageConfidenceScore:
        averageConfidenceScore ?? this.averageConfidenceScore,
    categoryDistribution: categoryDistribution ?? this.categoryDistribution,
    totalReasonsGenerated:
        totalReasonsGenerated ?? this.totalReasonsGenerated,
    positiveReasonsCount: positiveReasonsCount ?? this.positiveReasonsCount,
    negativeReasonsCount: negativeReasonsCount ?? this.negativeReasonsCount,
    computedAt: computedAt ?? this.computedAt,
  );

  @override
  List<Object?> get props => [
    totalRecommendationsGenerated,
    averageSimilarityScore,
    computedAt,
  ];
}
