/// SAIE — MajorRanking
///
/// The final output of the [MajorMatchingEngine].
/// Contains either a ranked list of candidates or a "Need More Evidence" signal.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/matching/matching_statistics.dart';
import 'package:stustep/features/saie/matching/recommendation_candidate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RankingStatus
// ─────────────────────────────────────────────────────────────────────────────

/// The overall status of a [MajorRanking] result.
enum RankingStatus {
  /// Ranking produced — candidates are available.
  success,

  /// Profile does not have enough evidence to produce reliable recommendations.
  needMoreEvidence,

  /// No majors in the knowledge base passed the minimum score threshold.
  noMatchesFound,

  /// The knowledge base contains no majors to compare against.
  emptyKnowledgeBase,
}

extension RankingStatusX on RankingStatus {
  bool get isSuccess => this == RankingStatus.success;
  String get message => switch (this) {
    RankingStatus.success => 'Recommendations are ready.',
    RankingStatus.needMoreEvidence =>
      'The profile needs more evidence before recommendations can be made. '
      'Please continue the assessment.',
    RankingStatus.noMatchesFound =>
      'No majors matched the student profile above the minimum threshold.',
    RankingStatus.emptyKnowledgeBase =>
      'The knowledge base contains no majors.',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorRanking
// ─────────────────────────────────────────────────────────────────────────────

/// The complete output of a matching run.
final class MajorRanking extends Equatable {
  /// Whether recommendations are available.
  final RankingStatus status;

  /// Ranked candidates (empty when [status] != [RankingStatus.success]).
  final List<RecommendationCandidate> candidates;

  /// Statistical summary of the matching run.
  final MatchingStatistics statistics;

  /// Human-readable message explaining the result.
  final String message;

  /// UTC timestamp when this ranking was computed.
  final DateTime computedAt;

  const MajorRanking({
    required this.status,
    required this.candidates,
    required this.statistics,
    required this.message,
    required this.computedAt,
  });

  bool get hasRecommendations =>
      status.isSuccess && candidates.isNotEmpty;

  RecommendationCandidate? get topPick =>
      candidates.isEmpty ? null : candidates.first;

  List<RecommendationCandidate> get topThree =>
      candidates.take(3).toList();

  factory MajorRanking.fromJson(Map<String, dynamic> json) => MajorRanking(
    status: RankingStatus.values.byName(json['status'] as String),
    candidates: (json['candidates'] as List<dynamic>)
        .map((e) => RecommendationCandidate.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList(),
    statistics: MatchingStatistics.fromJson(
      json['statistics'] as Map<String, dynamic>,
    ),
    message: json['message'] as String,
    computedAt: DateTime.parse(json['computed_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'candidates': candidates.map((c) => c.toJson()).toList(),
    'statistics': statistics.toJson(),
    'message': message,
    'computed_at': computedAt.toIso8601String(),
  };

  MajorRanking copyWith({
    RankingStatus? status,
    List<RecommendationCandidate>? candidates,
    MatchingStatistics? statistics,
    String? message,
    DateTime? computedAt,
  }) => MajorRanking(
    status: status ?? this.status,
    candidates: candidates ?? this.candidates,
    statistics: statistics ?? this.statistics,
    message: message ?? this.message,
    computedAt: computedAt ?? this.computedAt,
  );

  @override
  List<Object?> get props => [status, candidates.length, computedAt];

  @override
  String toString() =>
      'MajorRanking(status: ${status.name}, '
      'candidates: ${candidates.length})';
}
