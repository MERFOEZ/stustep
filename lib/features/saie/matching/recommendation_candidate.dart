/// SAIE — RecommendationCandidate
///
/// A major that has passed the minimum score and confidence thresholds and is
/// eligible to be returned as a recommendation. Wraps [MajorScore] with
/// rank metadata.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/matching/major_score.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationCandidate
// ─────────────────────────────────────────────────────────────────────────────

/// A ranked recommendation candidate.
final class RecommendationCandidate extends Equatable {
  /// 1-based rank in the final ranking (1 = best match).
  final int rank;

  /// The full score details for this candidate.
  final MajorScore score;

  /// Whether this candidate is the top pick.
  bool get isTopPick => rank == 1;

  /// Whether this candidate is in the top 3.
  bool get isTopThree => rank <= 3;

  const RecommendationCandidate({
    required this.rank,
    required this.score,
  });

  factory RecommendationCandidate.fromJson(Map<String, dynamic> json) =>
      RecommendationCandidate(
        rank: json['rank'] as int,
        score: MajorScore.fromJson(json['score'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'score': score.toJson(),
  };

  RecommendationCandidate copyWith({
    int? rank,
    MajorScore? score,
  }) => RecommendationCandidate(
    rank: rank ?? this.rank,
    score: score ?? this.score,
  );

  @override
  List<Object?> get props => [rank, score.majorId];

  @override
  String toString() =>
      'RecommendationCandidate(rank: $rank, major: ${score.majorId}, '
      'score: ${score.similarityScore})';
}
