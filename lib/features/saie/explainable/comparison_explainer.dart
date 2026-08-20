/// SAIE — ComparisonExplainer
///
/// Explains WHY Major A ranked above Major B using their matching scores
/// and dimension contributions side by side.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/matching/major_comparison.dart';
import 'package:stustep/features/saie/matching/major_score.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ComparisonPoint
// ─────────────────────────────────────────────────────────────────────────────

/// A single dimension comparison point between two majors.
final class ComparisonPoint extends Equatable {
  final String dimensionKey;
  final String label;
  final double scoreA;
  final double scoreB;
  final double expectationA;
  final double expectationB;
  final bool aWins;
  final String explanation;

  const ComparisonPoint({
    required this.dimensionKey,
    required this.label,
    required this.scoreA,
    required this.scoreB,
    required this.expectationA,
    required this.expectationB,
    required this.aWins,
    required this.explanation,
  });

  factory ComparisonPoint.fromJson(Map<String, dynamic> json) =>
      ComparisonPoint(
        dimensionKey: json['dimension_key'] as String,
        label: json['label'] as String,
        scoreA: (json['score_a'] as num).toDouble(),
        scoreB: (json['score_b'] as num).toDouble(),
        expectationA: (json['expectation_a'] as num).toDouble(),
        expectationB: (json['expectation_b'] as num).toDouble(),
        aWins: json['a_wins'] as bool,
        explanation: json['explanation'] as String,
      );

  Map<String, dynamic> toJson() => {
    'dimension_key': dimensionKey,
    'label': label,
    'score_a': scoreA,
    'score_b': scoreB,
    'expectation_a': expectationA,
    'expectation_b': expectationB,
    'a_wins': aWins,
    'explanation': explanation,
  };

  ComparisonPoint copyWith({
    String? dimensionKey,
    String? label,
    double? scoreA,
    double? scoreB,
    double? expectationA,
    double? expectationB,
    bool? aWins,
    String? explanation,
  }) => ComparisonPoint(
    dimensionKey: dimensionKey ?? this.dimensionKey,
    label: label ?? this.label,
    scoreA: scoreA ?? this.scoreA,
    scoreB: scoreB ?? this.scoreB,
    expectationA: expectationA ?? this.expectationA,
    expectationB: expectationB ?? this.expectationB,
    aWins: aWins ?? this.aWins,
    explanation: explanation ?? this.explanation,
  );

  @override
  List<Object?> get props => [dimensionKey, aWins];
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorComparisonExplanation
// ─────────────────────────────────────────────────────────────────────────────

/// Full comparison between two ranked majors.
final class MajorComparisonExplanation extends Equatable {
  final MajorRecommendation majorA;
  final MajorRecommendation majorB;
  final String summary;
  final List<ComparisonPoint> dimensionComparisons;
  final List<String> reasonsAWins;
  final List<String> reasonsBWins;
  final int scoreDifference;
  final double confidenceDifference;

  const MajorComparisonExplanation({
    required this.majorA,
    required this.majorB,
    required this.summary,
    required this.dimensionComparisons,
    required this.reasonsAWins,
    required this.reasonsBWins,
    required this.scoreDifference,
    required this.confidenceDifference,
  });

  factory MajorComparisonExplanation.fromJson(Map<String, dynamic> json) =>
      MajorComparisonExplanation(
        majorA: MajorRecommendation.fromJson(
          json['major_a'] as Map<String, dynamic>,
        ),
        majorB: MajorRecommendation.fromJson(
          json['major_b'] as Map<String, dynamic>,
        ),
        summary: json['summary'] as String,
        dimensionComparisons: (json['dimension_comparisons'] as List<dynamic>)
            .map((e) => ComparisonPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        reasonsAWins:
            (json['reasons_a_wins'] as List<dynamic>).cast<String>(),
        reasonsBWins:
            (json['reasons_b_wins'] as List<dynamic>).cast<String>(),
        scoreDifference: json['score_difference'] as int,
        confidenceDifference:
            (json['confidence_difference'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'major_a': majorA.toJson(),
    'major_b': majorB.toJson(),
    'summary': summary,
    'dimension_comparisons':
        dimensionComparisons.map((c) => c.toJson()).toList(),
    'reasons_a_wins': reasonsAWins,
    'reasons_b_wins': reasonsBWins,
    'score_difference': scoreDifference,
    'confidence_difference': confidenceDifference,
  };

  MajorComparisonExplanation copyWith({
    MajorRecommendation? majorA,
    MajorRecommendation? majorB,
    String? summary,
    List<ComparisonPoint>? dimensionComparisons,
    List<String>? reasonsAWins,
    List<String>? reasonsBWins,
    int? scoreDifference,
    double? confidenceDifference,
  }) => MajorComparisonExplanation(
    majorA: majorA ?? this.majorA,
    majorB: majorB ?? this.majorB,
    summary: summary ?? this.summary,
    dimensionComparisons: dimensionComparisons ?? this.dimensionComparisons,
    reasonsAWins: reasonsAWins ?? this.reasonsAWins,
    reasonsBWins: reasonsBWins ?? this.reasonsBWins,
    scoreDifference: scoreDifference ?? this.scoreDifference,
    confidenceDifference: confidenceDifference ?? this.confidenceDifference,
  );

  @override
  List<Object?> get props => [
    majorA.majorId,
    majorB.majorId,
    scoreDifference,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// ComparisonExplainer
// ─────────────────────────────────────────────────────────────────────────────

/// Produces a [MajorComparisonExplanation] for any two [MajorRecommendation]s.
final class ComparisonExplainer {
  const ComparisonExplainer();

  /// Compares [a] (higher-ranked) with [b] (lower-ranked).
  MajorComparisonExplanation explain({
    required MajorRecommendation a,
    required MajorRecommendation b,
    required MajorScore scoreA,
    required MajorScore scoreB,
    required StudentCognitiveProfile profile,
    MajorComparison? preComputedComparison,
  }) {
    final scoreDiff = a.similarityScore - b.similarityScore;
    final confDiff = a.confidence.score - b.confidence.score;

    final dimComparisons = _buildDimensionComparisons(scoreA, scoreB, profile);
    final aWinReasons = _buildWinReasons(a, b, scoreA, scoreB, dimComparisons);
    final bWinReasons = _buildWinReasons(b, a, scoreB, scoreA, dimComparisons, inverse: true);

    final summary =
        '${a.majorName} ranked ${a.rank < b.rank ? "above" : "below"} '
        '${b.majorName} with a score difference of $scoreDiff points '
        '(${a.similarityScore} vs ${b.similarityScore}). '
        '${aWinReasons.isNotEmpty ? "Key advantage: ${aWinReasons.first}" : ""}';

    return MajorComparisonExplanation(
      majorA: a,
      majorB: b,
      summary: summary,
      dimensionComparisons: dimComparisons,
      reasonsAWins: aWinReasons,
      reasonsBWins: bWinReasons,
      scoreDifference: scoreDiff,
      confidenceDifference: confDiff,
    );
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  List<ComparisonPoint> _buildDimensionComparisons(
    MajorScore scoreA,
    MajorScore scoreB,
    StudentCognitiveProfile profile,
  ) {
    final points = <ComparisonPoint>[];
    final keysA = {for (final c in scoreA.contributions) c.dimensionKey: c};
    final keysB = {for (final c in scoreB.contributions) c.dimensionKey: c};
    final allKeys = {...keysA.keys, ...keysB.keys};

    for (final key in allKeys) {
      final ca = keysA[key];
      final cb = keysB[key];
      final label = DimensionKeys.labels[key] ?? key;
      final student = profile.scoreFor(key);

      final expA = ca?.majorExpectation ?? 0.0;
      final expB = cb?.majorExpectation ?? 0.0;

      // A wins on a dimension if the student's gap to A's expectation is smaller.
      final gapA = (student - expA).abs();
      final gapB = (student - expB).abs();
      final aWins = gapA <= gapB;

      points.add(ComparisonPoint(
        dimensionKey: key,
        label: label,
        scoreA: ca?.weightedContribution ?? 0.0,
        scoreB: cb?.weightedContribution ?? 0.0,
        expectationA: expA,
        expectationB: expB,
        aWins: aWins,
        explanation:
            'Student score ${(student * 100).toStringAsFixed(0)}% — '
            '${scoreA.majorName} expects ${(expA * 100).toStringAsFixed(0)}% '
            'vs ${scoreB.majorName} expects ${(expB * 100).toStringAsFixed(0)}%.',
      ));
    }

    return points;
  }

  List<String> _buildWinReasons(
    MajorRecommendation winner,
    MajorRecommendation loser,
    MajorScore winnerScore,
    MajorScore loserScore,
    List<ComparisonPoint> dimComparisons, {
    bool inverse = false,
  }) {
    final reasons = <String>[];

    final scoreDiff =
        winner.similarityScore - loser.similarityScore;
    if (!inverse && scoreDiff > 0) {
      reasons.add(
        'Higher similarity score by $scoreDiff points '
        '(${winner.similarityScore}/100 vs ${loser.similarityScore}/100).',
      );
    }

    final winningDimensions = dimComparisons.where((d) => d.aWins == !inverse).toList();
    if (winningDimensions.isNotEmpty) {
      final topDim = winningDimensions.first;
      reasons.add(
        'Student fit is better in "${topDim.label}" '
        '(expectation gap is smaller for ${winner.majorName}).',
      );
    }

    if (!inverse && winnerScore.marketDemandBoosted &&
        !loserScore.marketDemandBoosted) {
      reasons.add(
        '${winner.majorName} received a market demand boost; '
        '${loser.majorName} did not.',
      );
    }

    if (!inverse &&
        winner.missingSkills.length < loser.missingSkills.length) {
      reasons.add(
        '${winner.majorName} has fewer missing prerequisite skills '
        '(${winner.missingSkills.length} vs ${loser.missingSkills.length}).',
      );
    }

    return reasons;
  }
}
