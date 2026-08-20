/// SAIE — DecisionConfidence
///
/// Represents the confidence scores across all candidate intents for a single
/// message classification. The engine always computes ALL candidate confidences
/// before selecting a winner. If no candidate exceeds the minimum threshold,
/// a clarification is requested.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IntentScore
// ─────────────────────────────────────────────────────────────────────────────

/// A single candidate intent with its computed confidence score.
final class IntentScore extends Equatable {
  /// The candidate intent.
  final SupportedIntent intent;

  /// Confidence score in [0.0, 1.0].
  final double score;

  /// Breakdown of signals that contributed to this score.
  /// Key: signal name, Value: individual contribution weight.
  final Map<String, double> signals;

  const IntentScore({
    required this.intent,
    required this.score,
    this.signals = const {},
  });

  factory IntentScore.fromJson(Map<String, dynamic> json) => IntentScore(
    intent: SupportedIntent.values.byName(json['intent'] as String),
    score: (json['score'] as num).toDouble(),
    signals: (json['signals'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        const {},
  );

  Map<String, dynamic> toJson() => {
    'intent': intent.name,
    'score': score,
    if (signals.isNotEmpty) 'signals': signals,
  };

  IntentScore copyWith({
    SupportedIntent? intent,
    double? score,
    Map<String, double>? signals,
  }) => IntentScore(
    intent: intent ?? this.intent,
    score: score ?? this.score,
    signals: signals ?? this.signals,
  );

  @override
  List<Object?> get props => [intent, score];

  @override
  String toString() =>
      'IntentScore(${intent.name}: ${score.toStringAsFixed(3)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// DecisionConfidence
// ─────────────────────────────────────────────────────────────────────────────

/// The complete confidence distribution across all candidate intents.
///
/// The [winner] is the highest-scoring candidate.
/// If [winner.score] < [minimumThreshold], the engine must clarify rather
/// than execute any intent.
final class DecisionConfidence extends Equatable {
  /// All candidate scores, sorted descending by score.
  final List<IntentScore> candidates;

  /// The minimum confidence threshold for direct intent execution.
  final double minimumThreshold;

  const DecisionConfidence({
    required this.candidates,
    this.minimumThreshold = 0.65,
  });

  /// The highest-confidence candidate intent.
  IntentScore get winner =>
      candidates.isEmpty
          ? IntentScore(
              intent: SupportedIntent.unknown,
              score: 0.0,
            )
          : candidates.first;

  /// The runner-up candidate (second highest score).
  IntentScore? get runnerUp =>
      candidates.length > 1 ? candidates[1] : null;

  /// Returns `true` if the winning intent meets the minimum threshold.
  bool get isDecisive => winner.score >= minimumThreshold;

  /// Ambiguity = difference between winner and runner-up.
  /// Low delta → high ambiguity → clarification likely needed.
  double get ambiguityScore {
    if (runnerUp == null) return 1.0;
    return (winner.score - runnerUp!.score).clamp(0.0, 1.0);
  }

  /// Returns `true` if the top two candidates are too close to distinguish.
  bool get isAmbiguous => ambiguityScore < 0.15;

  factory DecisionConfidence.fromJson(Map<String, dynamic> json) =>
      DecisionConfidence(
        candidates: (json['candidates'] as List<dynamic>)
            .map((e) => IntentScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        minimumThreshold: (json['minimum_threshold'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'candidates': candidates.map((c) => c.toJson()).toList(),
    'minimum_threshold': minimumThreshold,
    'winner': winner.toJson(),
    'is_decisive': isDecisive,
    'ambiguity_score': ambiguityScore,
  };

  DecisionConfidence copyWith({
    List<IntentScore>? candidates,
    double? minimumThreshold,
  }) => DecisionConfidence(
    candidates: candidates ?? this.candidates,
    minimumThreshold: minimumThreshold ?? this.minimumThreshold,
  );

  @override
  List<Object?> get props => [candidates, minimumThreshold];

  @override
  String toString() =>
      'DecisionConfidence(winner: ${winner.intent.name}@'
      '${winner.score.toStringAsFixed(3)}, decisive: $isDecisive)';
}
