/// SAIE — RecommendationReason
///
/// A single human-readable reason explaining one aspect of a recommendation.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReasonType
// ─────────────────────────────────────────────────────────────────────────────

enum ReasonType {
  /// A dimension where the student scored well and the major demands it.
  dimensionStrength,

  /// A dimension where the student scored low relative to major expectations.
  dimensionWeakness,

  /// Personality traits aligned with the major's personality profile.
  personalityAlignment,

  /// Learning style matched the major's delivery format.
  learningStyleMatch,

  /// Student interests overlap with the major's domain.
  interestAlignment,

  /// Evidence that supported this recommendation.
  supportingEvidence,

  /// Evidence that conflicted or reduced the score.
  conflictingEvidence,

  /// Market demand signal.
  marketDemand,

  /// Missing prerequisite skill or subject.
  missingSkill,

  /// Career path opportunity associated with this major.
  careerOpportunity,
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationReason
// ─────────────────────────────────────────────────────────────────────────────

/// One explainable reason for a recommendation score.
final class RecommendationReason extends Equatable {
  final ReasonType type;
  final String title;
  final String explanation;

  /// Influence strength [0.0, 1.0] — how much this reason affected the score.
  final double influence;

  /// Whether this reason increased (+) or decreased (−) the score.
  final bool positive;

  const RecommendationReason({
    required this.type,
    required this.title,
    required this.explanation,
    required this.influence,
    required this.positive,
  });

  factory RecommendationReason.fromJson(Map<String, dynamic> json) =>
      RecommendationReason(
        type: ReasonType.values.byName(json['type'] as String),
        title: json['title'] as String,
        explanation: json['explanation'] as String,
        influence: (json['influence'] as num).toDouble(),
        positive: json['positive'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'title': title,
    'explanation': explanation,
    'influence': influence,
    'positive': positive,
  };

  RecommendationReason copyWith({
    ReasonType? type,
    String? title,
    String? explanation,
    double? influence,
    bool? positive,
  }) => RecommendationReason(
    type: type ?? this.type,
    title: title ?? this.title,
    explanation: explanation ?? this.explanation,
    influence: influence ?? this.influence,
    positive: positive ?? this.positive,
  );

  @override
  List<Object?> get props => [type, title, influence, positive];
}
