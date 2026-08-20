/// SAIE — MajorMatcher
///
/// Applies [MajorSimilarityCalculator] to every eligible major and returns
/// all [MajorScore] results above the minimum threshold.
library;

import 'package:stustep/features/saie/matching/major_score.dart';
import 'package:stustep/features/saie/matching/major_similarity_calculator.dart';
import 'package:stustep/features/saie/matching/matching_configuration.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MajorMatcher
// ─────────────────────────────────────────────────────────────────────────────

/// Scores every filtered major and returns results above the minimum threshold.
final class MajorMatcher {
  final MajorSimilarityCalculator _calculator;

  const MajorMatcher({
    MajorSimilarityCalculator calculator = const MajorSimilarityCalculator(),
  }) : _calculator = calculator;

  /// Evaluates all [eligibleMajors] against [profile].
  ///
  /// Only majors with [MajorScore.similarityScore] >=
  /// [config.minimumSimilarityScore] are returned.
  List<MajorScore> match({
    required List<Major> eligibleMajors,
    required StudentCognitiveProfile profile,
    required MatchingConfiguration config,
  }) {
    final results = <MajorScore>[];

    for (final major in eligibleMajors) {
      final score = _calculator.calculate(
        major: major,
        profile: profile,
        config: config,
      );

      if (score.similarityScore >= config.minimumSimilarityScore) {
        results.add(score);
      }
    }

    return results;
  }
}
