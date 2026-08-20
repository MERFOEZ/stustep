/// SAIE — Confidence Model
///
/// Represents the engine's computed confidence in a specific domain inference.
/// Confidence is always derived — never user-provided.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/core/extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Confidence
// ─────────────────────────────────────────────────────────────────────────────

/// The engine's probabilistic confidence in a particular academic inference.
///
/// [score] is the raw continuous value in [0.0, 1.0].
/// [level] is the discretized classification derived from [score].
/// [evidenceCount] is the number of supporting signals used in computation.
final class Confidence extends Equatable {
  /// Raw confidence score in [0.0, 1.0].
  final double score;

  /// Number of evidence signals that contributed to this confidence value.
  final int evidenceCount;

  /// Optional explanation of how confidence was calculated.
  final String? rationale;

  const Confidence({
    required this.score,
    required this.evidenceCount,
    this.rationale,
  }) : assert(score >= 0.0 && score <= 1.0, 'Score must be in [0.0, 1.0]');

  /// Returns the discretized [ConfidenceLevel] for this score.
  ConfidenceLevel get level => ConfidenceLevelX.fromScore(score);

  /// Returns `true` if this confidence meets the threshold for recommendation.
  bool get isActionable => score >= 0.40;

  /// Returns `true` if this confidence is high enough for a firm recommendation.
  bool get isHighConfidence => score >= 0.75;

  /// A zero-value [Confidence] used as an initial state.
  static const Confidence zero = Confidence(score: 0.0, evidenceCount: 0);

  /// Creates a [Confidence] from a decoded JSON map.
  factory Confidence.fromJson(Map<String, dynamic> json) => Confidence(
    score: (json['score'] as num).toDouble(),
    evidenceCount: json['evidence_count'] as int,
    rationale: json['rationale'] as String?,
  );

  /// Serializes this [Confidence] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'score': score,
    'evidence_count': evidenceCount,
    'level': level.name,
    if (rationale != null) 'rationale': rationale,
  };

  /// Returns a copy of this [Confidence] with specified fields replaced.
  Confidence copyWith({
    double? score,
    int? evidenceCount,
    String? rationale,
  }) => Confidence(
    score: score ?? this.score,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    rationale: rationale ?? this.rationale,
  );

  @override
  List<Object?> get props => [score, evidenceCount];

  @override
  String toString() =>
      'Confidence(score: ${score.toStringAsFixed(2)}, '
      'level: ${level.name}, evidenceCount: $evidenceCount)';
}
