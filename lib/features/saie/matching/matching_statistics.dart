/// SAIE — MatchingStatistics
///
/// Aggregate statistics for a complete matching run.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchingStatistics
// ─────────────────────────────────────────────────────────────────────────────

/// Statistics produced after evaluating all majors in a matching run.
final class MatchingStatistics extends Equatable {
  /// Total number of majors evaluated.
  final int majorsEvaluated;

  /// Number of majors that passed the minimum score threshold.
  final int majorsPassed;

  /// Number of majors filtered out before scoring.
  final int majorsFiltered;

  /// Highest similarity score achieved across all majors.
  final int highestScore;

  /// Lowest similarity score achieved across all majors.
  final int lowestScore;

  /// Average similarity score across all evaluated majors.
  final double averageScore;

  /// Overall profile confidence at the time of matching [0.0, 1.0].
  final double profileConfidence;

  /// Number of evidence records available at match time.
  final int evidenceCount;

  /// Number of cognitive dimensions with at least one evidence record.
  final int evidencedDimensions;

  /// Total number of cognitive dimensions tracked.
  final int totalDimensions;

  /// Duration of the matching run in milliseconds.
  final int durationMs;

  const MatchingStatistics({
    required this.majorsEvaluated,
    required this.majorsPassed,
    required this.majorsFiltered,
    required this.highestScore,
    required this.lowestScore,
    required this.averageScore,
    required this.profileConfidence,
    required this.evidenceCount,
    required this.evidencedDimensions,
    required this.totalDimensions,
    required this.durationMs,
  });

  factory MatchingStatistics.fromJson(Map<String, dynamic> json) =>
      MatchingStatistics(
        majorsEvaluated: json['majors_evaluated'] as int,
        majorsPassed: json['majors_passed'] as int,
        majorsFiltered: json['majors_filtered'] as int,
        highestScore: json['highest_score'] as int,
        lowestScore: json['lowest_score'] as int,
        averageScore: (json['average_score'] as num).toDouble(),
        profileConfidence: (json['profile_confidence'] as num).toDouble(),
        evidenceCount: json['evidence_count'] as int,
        evidencedDimensions: json['evidenced_dimensions'] as int,
        totalDimensions: json['total_dimensions'] as int,
        durationMs: json['duration_ms'] as int,
      );

  Map<String, dynamic> toJson() => {
    'majors_evaluated': majorsEvaluated,
    'majors_passed': majorsPassed,
    'majors_filtered': majorsFiltered,
    'highest_score': highestScore,
    'lowest_score': lowestScore,
    'average_score': averageScore,
    'profile_confidence': profileConfidence,
    'evidence_count': evidenceCount,
    'evidenced_dimensions': evidencedDimensions,
    'total_dimensions': totalDimensions,
    'duration_ms': durationMs,
  };

  MatchingStatistics copyWith({
    int? majorsEvaluated,
    int? majorsPassed,
    int? majorsFiltered,
    int? highestScore,
    int? lowestScore,
    double? averageScore,
    double? profileConfidence,
    int? evidenceCount,
    int? evidencedDimensions,
    int? totalDimensions,
    int? durationMs,
  }) => MatchingStatistics(
    majorsEvaluated: majorsEvaluated ?? this.majorsEvaluated,
    majorsPassed: majorsPassed ?? this.majorsPassed,
    majorsFiltered: majorsFiltered ?? this.majorsFiltered,
    highestScore: highestScore ?? this.highestScore,
    lowestScore: lowestScore ?? this.lowestScore,
    averageScore: averageScore ?? this.averageScore,
    profileConfidence: profileConfidence ?? this.profileConfidence,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    evidencedDimensions: evidencedDimensions ?? this.evidencedDimensions,
    totalDimensions: totalDimensions ?? this.totalDimensions,
    durationMs: durationMs ?? this.durationMs,
  );

  @override
  List<Object?> get props => [
    majorsEvaluated,
    majorsPassed,
    highestScore,
    profileConfidence,
  ];

  @override
  String toString() =>
      'MatchingStatistics(evaluated: $majorsEvaluated, '
      'passed: $majorsPassed, avg: ${averageScore.toStringAsFixed(1)}, '
      'durationMs: $durationMs)';
}
