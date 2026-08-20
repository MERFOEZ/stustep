/// SAIE — MajorComparison
///
/// Side-by-side dimension-level comparison between two [MajorScore] results.
/// Used for "why is Major A ranked higher than Major B?" queries.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/matching/major_score.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimensionComparison
// ─────────────────────────────────────────────────────────────────────────────

/// Side-by-side comparison of one dimension across two majors.
final class DimensionComparison extends Equatable {
  final String dimensionKey;
  final String label;

  /// Score contribution for the first major.
  final double scoreA;

  /// Score contribution for the second major.
  final double scoreB;

  /// Which major is stronger in this dimension (1, 2, or 0 for tie).
  int get winner {
    if ((scoreA - scoreB).abs() < 0.001) return 0;
    return scoreA > scoreB ? 1 : 2;
  }

  const DimensionComparison({
    required this.dimensionKey,
    required this.label,
    required this.scoreA,
    required this.scoreB,
  });

  factory DimensionComparison.fromJson(Map<String, dynamic> json) =>
      DimensionComparison(
        dimensionKey: json['dimension_key'] as String,
        label: json['label'] as String,
        scoreA: (json['score_a'] as num).toDouble(),
        scoreB: (json['score_b'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'dimension_key': dimensionKey,
    'label': label,
    'score_a': scoreA,
    'score_b': scoreB,
    'winner': winner,
  };

  @override
  List<Object?> get props => [dimensionKey, scoreA, scoreB];
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorComparison
// ─────────────────────────────────────────────────────────────────────────────

/// A complete dimension-level comparison between two scored majors.
final class MajorComparison extends Equatable {
  final MajorScore majorA;
  final MajorScore majorB;

  /// Dimension-level side-by-side results.
  final List<DimensionComparison> dimensionComparisons;

  /// Dimensions where major A is stronger.
  final List<String> strongerInA;

  /// Dimensions where major B is stronger.
  final List<String> strongerInB;

  /// Score delta: majorA.similarityScore - majorB.similarityScore.
  int get scoreDelta => majorA.similarityScore - majorB.similarityScore;

  const MajorComparison({
    required this.majorA,
    required this.majorB,
    required this.dimensionComparisons,
    required this.strongerInA,
    required this.strongerInB,
  });

  /// Builds a [MajorComparison] from two scored results.
  factory MajorComparison.compare(MajorScore a, MajorScore b) {
    final mapA = {for (final c in a.contributions) c.dimensionKey: c};
    final mapB = {for (final c in b.contributions) c.dimensionKey: c};

    final allKeys = {...mapA.keys, ...mapB.keys};
    final comparisons = <DimensionComparison>[];
    final strongerA = <String>[];
    final strongerB = <String>[];

    for (final key in allKeys) {
      final cA = mapA[key];
      final cB = mapB[key];
      final sA = cA?.weightedContribution ?? 0.0;
      final sB = cB?.weightedContribution ?? 0.0;
      final label = cA?.label ?? cB?.label ?? key;

      final dc = DimensionComparison(
        dimensionKey: key,
        label: label,
        scoreA: sA,
        scoreB: sB,
      );
      comparisons.add(dc);

      if (dc.winner == 1) {
        strongerA.add(key);
      } else if (dc.winner == 2) {
        strongerB.add(key);
      }
    }

    comparisons.sort((x, y) =>
        (y.scoreA - y.scoreB).abs().compareTo((x.scoreA - x.scoreB).abs()));

    return MajorComparison(
      majorA: a,
      majorB: b,
      dimensionComparisons: comparisons,
      strongerInA: strongerA,
      strongerInB: strongerB,
    );
  }

  Map<String, dynamic> toJson() => {
    'major_a': majorA.toJson(),
    'major_b': majorB.toJson(),
    'dimension_comparisons': dimensionComparisons.map((d) => d.toJson()).toList(),
    'stronger_in_a': strongerInA,
    'stronger_in_b': strongerInB,
    'score_delta': scoreDelta,
  };

  @override
  List<Object?> get props => [majorA.majorId, majorB.majorId];
}
