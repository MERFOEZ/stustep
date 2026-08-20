/// SAIE — CognitiveDimension
///
/// A single measurable axis of the student's cognitive and personality space.
/// Every dimension tracks its current score, confidence, evidence history,
/// and trend over time. Nothing is static — every update is immutable and
/// appended to the history.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimensionTrend
// ─────────────────────────────────────────────────────────────────────────────

/// The direction in which a dimension's score is moving.
enum DimensionTrend {
  /// Score is consistently increasing across recent updates.
  rising,

  /// Score is consistently decreasing across recent updates.
  falling,

  /// Score is oscillating without a clear direction.
  volatile,

  /// Score has been stable for the last N updates.
  stable,

  /// Not enough evidence to determine a trend.
  unknown,
}

// ─────────────────────────────────────────────────────────────────────────────
// DimensionUpdate
// ─────────────────────────────────────────────────────────────────────────────

/// A single historical update record for a [CognitiveDimension].
final class DimensionUpdate extends Equatable {
  /// ID of the evidence that triggered this update.
  final String evidenceId;

  /// Score value before this update.
  final double previousScore;

  /// Score value after this update.
  final double newScore;

  /// Confidence level after this update, in [0.0, 1.0].
  final double newConfidence;

  /// UTC timestamp of this update.
  final DateTime timestamp;

  /// Optional reason describing why this update occurred.
  final String? reason;

  const DimensionUpdate({
    required this.evidenceId,
    required this.previousScore,
    required this.newScore,
    required this.newConfidence,
    required this.timestamp,
    this.reason,
  });

  factory DimensionUpdate.fromJson(Map<String, dynamic> json) =>
      DimensionUpdate(
        evidenceId: json['evidence_id'] as String,
        previousScore: (json['previous_score'] as num).toDouble(),
        newScore: (json['new_score'] as num).toDouble(),
        newConfidence: (json['new_confidence'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        reason: json['reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'evidence_id': evidenceId,
    'previous_score': previousScore,
    'new_score': newScore,
    'new_confidence': newConfidence,
    'timestamp': timestamp.toIso8601String(),
    if (reason != null) 'reason': reason,
  };

  DimensionUpdate copyWith({
    String? evidenceId,
    double? previousScore,
    double? newScore,
    double? newConfidence,
    DateTime? timestamp,
    String? reason,
  }) => DimensionUpdate(
    evidenceId: evidenceId ?? this.evidenceId,
    previousScore: previousScore ?? this.previousScore,
    newScore: newScore ?? this.newScore,
    newConfidence: newConfidence ?? this.newConfidence,
    timestamp: timestamp ?? this.timestamp,
    reason: reason ?? this.reason,
  );

  @override
  List<Object?> get props =>
      [evidenceId, previousScore, newScore, newConfidence, timestamp];
}

// ─────────────────────────────────────────────────────────────────────────────
// CognitiveDimension
// ─────────────────────────────────────────────────────────────────────────────

/// A fully tracked, evidence-backed cognitive or personality dimension.
///
/// Score is always in [0.0, 1.0].
/// Confidence is in [0.0, 1.0] and reflects how much evidence supports [score].
/// [history] stores every past update for rollback and timeline support.
/// [trend] is computed from the last N updates.
final class CognitiveDimension extends Equatable {
  /// Unique key identifying this dimension (e.g., `"logic"`, `"creativity"`).
  final String key;

  /// Human-readable display label.
  final String label;

  /// Current inferred score in [0.0, 1.0].
  final double score;

  /// Engine confidence in the current [score], in [0.0, 1.0].
  final double confidence;

  /// Total number of evidence signals that have affected this dimension.
  final int evidenceCount;

  /// The detected trend direction across recent updates.
  final DimensionTrend trend;

  /// Chronological list of all score updates.
  final List<DimensionUpdate> history;

  /// UTC timestamp of the last update.
  final DateTime lastUpdated;

  const CognitiveDimension({
    required this.key,
    required this.label,
    required this.score,
    required this.confidence,
    required this.evidenceCount,
    required this.trend,
    required this.history,
    required this.lastUpdated,
  })  : assert(score >= 0.0 && score <= 1.0, 'score must be in [0.0, 1.0]'),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'confidence must be in [0.0, 1.0]',
        );

  /// Creates a zeroed [CognitiveDimension] for initial profile construction.
  factory CognitiveDimension.initial({
    required String key,
    required String label,
  }) => CognitiveDimension(
    key: key,
    label: label,
    score: 0.0,
    confidence: 0.0,
    evidenceCount: 0,
    trend: DimensionTrend.unknown,
    history: const [],
    lastUpdated: DateTime.now().toUtc(),
  );

  factory CognitiveDimension.fromJson(Map<String, dynamic> json) =>
      CognitiveDimension(
        key: json['key'] as String,
        label: json['label'] as String,
        score: (json['score'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        evidenceCount: json['evidence_count'] as int,
        trend: DimensionTrend.values.byName(json['trend'] as String),
        history: (json['history'] as List<dynamic>)
            .map((e) => DimensionUpdate.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'score': score,
    'confidence': confidence,
    'evidence_count': evidenceCount,
    'trend': trend.name,
    'history': history.map((u) => u.toJson()).toList(),
    'last_updated': lastUpdated.toIso8601String(),
  };

  /// Returns a new [CognitiveDimension] after applying a new evidence update.
  ///
  /// [newScore] is the updated score value.
  /// [newConfidence] is the updated confidence value.
  /// [update] is the [DimensionUpdate] record to append to history.
  CognitiveDimension withUpdate({
    required double newScore,
    required double newConfidence,
    required DimensionUpdate update,
  }) {
    final updatedHistory = [...history, update];
    return CognitiveDimension(
      key: key,
      label: label,
      score: newScore.clamp(0.0, 1.0),
      confidence: newConfidence.clamp(0.0, 1.0),
      evidenceCount: evidenceCount + 1,
      trend: _computeTrend(updatedHistory),
      history: updatedHistory,
      lastUpdated: update.timestamp,
    );
  }

  CognitiveDimension copyWith({
    String? key,
    String? label,
    double? score,
    double? confidence,
    int? evidenceCount,
    DimensionTrend? trend,
    List<DimensionUpdate>? history,
    DateTime? lastUpdated,
  }) => CognitiveDimension(
    key: key ?? this.key,
    label: label ?? this.label,
    score: score ?? this.score,
    confidence: confidence ?? this.confidence,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    trend: trend ?? this.trend,
    history: history ?? this.history,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  /// Whether this dimension has enough evidence to be considered reliable.
  bool get isReliable => evidenceCount >= 3 && confidence >= 0.4;

  /// Whether this dimension is completely uncharted.
  bool get isUnknown => evidenceCount == 0;

  /// Computes a [DimensionTrend] from the last 5 updates.
  static DimensionTrend _computeTrend(List<DimensionUpdate> history) {
    if (history.length < 2) return DimensionTrend.unknown;
    final window = history.length > 5
        ? history.sublist(history.length - 5)
        : history;
    int rising = 0;
    int falling = 0;
    for (int i = 1; i < window.length; i++) {
      final delta = window[i].newScore - window[i - 1].newScore;
      if (delta > 0.02) {
        rising++;
      } else if (delta < -0.02) {
        falling++;
      }
    }
    final total = window.length - 1;
    if (rising == total) return DimensionTrend.rising;
    if (falling == total) return DimensionTrend.falling;
    if (rising == 0 && falling == 0) return DimensionTrend.stable;
    return DimensionTrend.volatile;
  }

  @override
  List<Object?> get props =>
      [key, score, confidence, evidenceCount, trend, lastUpdated];

  @override
  String toString() =>
      'CognitiveDimension(key: $key, score: ${score.toStringAsFixed(2)}, '
      'confidence: ${confidence.toStringAsFixed(2)}, trend: ${trend.name})';
}
