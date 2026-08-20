/// SAIE — DimensionSummary
///
/// Produces a structured summary of all cognitive dimensions
/// for use in explanations and reports.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimensionStatus
// ─────────────────────────────────────────────────────────────────────────────

enum DimensionStatus {
  /// Excellent performance in this dimension.
  excellent,

  /// Good performance.
  good,

  /// Acceptable but with room for improvement.
  acceptable,

  /// Weak — needs development.
  weak,

  /// No evidence collected yet.
  undiscovered,
}

extension DimensionStatusX on DimensionStatus {
  String get label => switch (this) {
    DimensionStatus.excellent => 'Excellent',
    DimensionStatus.good => 'Good',
    DimensionStatus.acceptable => 'Acceptable',
    DimensionStatus.weak => 'Needs Improvement',
    DimensionStatus.undiscovered => 'Not Assessed',
  };

  bool get isStrength =>
      this == DimensionStatus.excellent || this == DimensionStatus.good;
  bool get isWeakness =>
      this == DimensionStatus.weak || this == DimensionStatus.undiscovered;
}

// ─────────────────────────────────────────────────────────────────────────────
// DimensionSnapshot
// ─────────────────────────────────────────────────────────────────────────────

/// A single cognitive dimension's full snapshot for an explanation.
final class DimensionSnapshot extends Equatable {
  final String key;
  final String label;
  final double score;
  final double confidence;
  final int evidenceCount;
  final DimensionStatus status;
  final String interpretation;

  const DimensionSnapshot({
    required this.key,
    required this.label,
    required this.score,
    required this.confidence,
    required this.evidenceCount,
    required this.status,
    required this.interpretation,
  });

  bool get isStrength => status.isStrength;
  bool get isWeakness => status.isWeakness;

  factory DimensionSnapshot.fromJson(Map<String, dynamic> json) =>
      DimensionSnapshot(
        key: json['key'] as String,
        label: json['label'] as String,
        score: (json['score'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        evidenceCount: json['evidence_count'] as int,
        status: DimensionStatus.values.byName(json['status'] as String),
        interpretation: json['interpretation'] as String,
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'score': score,
    'confidence': confidence,
    'evidence_count': evidenceCount,
    'status': status.name,
    'interpretation': interpretation,
  };

  DimensionSnapshot copyWith({
    String? key,
    String? label,
    double? score,
    double? confidence,
    int? evidenceCount,
    DimensionStatus? status,
    String? interpretation,
  }) => DimensionSnapshot(
    key: key ?? this.key,
    label: label ?? this.label,
    score: score ?? this.score,
    confidence: confidence ?? this.confidence,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    status: status ?? this.status,
    interpretation: interpretation ?? this.interpretation,
  );

  @override
  List<Object?> get props => [key, score, status];
}

// ─────────────────────────────────────────────────────────────────────────────
// DimensionSummary
// ─────────────────────────────────────────────────────────────────────────────

/// Full snapshot of all cognitive dimensions for one student.
final class DimensionSummary extends Equatable {
  final List<DimensionSnapshot> dimensions;
  final List<DimensionSnapshot> strengths;
  final List<DimensionSnapshot> weaknesses;
  final List<DimensionSnapshot> undiscovered;
  final DateTime computedAt;

  const DimensionSummary({
    required this.dimensions,
    required this.strengths,
    required this.weaknesses,
    required this.undiscovered,
    required this.computedAt,
  });

  factory DimensionSummary.fromProfile(StudentCognitiveProfile profile) {
    final now = DateTime.now().toUtc();
    final snapshots = <DimensionSnapshot>[];

    for (final key in DimensionKeys.all) {
      final dim = profile.dimension(key);
      final label = DimensionKeys.labels[key] ?? key;
      final score = dim.score;
      final conf = dim.confidence;
      final evCount = dim.evidenceCount;

      final status = evCount == 0
          ? DimensionStatus.undiscovered
          : score >= 0.80
              ? DimensionStatus.excellent
              : score >= 0.60
                  ? DimensionStatus.good
                  : score >= 0.40
                      ? DimensionStatus.acceptable
                      : DimensionStatus.weak;

      snapshots.add(DimensionSnapshot(
        key: key,
        label: label,
        score: score,
        confidence: conf,
        evidenceCount: evCount,
        status: status,
        interpretation: _interpretation(label, score, conf, evCount),
      ));
    }

    return DimensionSummary(
      dimensions: snapshots,
      strengths: snapshots.where((d) => d.isStrength).toList()
        ..sort((a, b) => b.score.compareTo(a.score)),
      weaknesses: snapshots.where((d) => d.isWeakness).toList()
        ..sort((a, b) => a.score.compareTo(b.score)),
      undiscovered:
          snapshots.where((d) => d.status == DimensionStatus.undiscovered).toList(),
      computedAt: now,
    );
  }

  static String _interpretation(
    String label,
    double score,
    double confidence,
    int evidenceCount,
  ) {
    if (evidenceCount == 0) {
      return '$label has not been assessed yet. More questions will cover this area.';
    }
    final pct = (score * 100).toStringAsFixed(0);
    final confPct = (confidence * 100).toStringAsFixed(0);
    if (score >= 0.80) {
      return 'Excellent $label aptitude ($pct%) with $confPct% confidence across $evidenceCount evidence records.';
    } else if (score >= 0.60) {
      return 'Good $label performance ($pct%) supported by $evidenceCount evidence records.';
    } else if (score >= 0.40) {
      return 'Acceptable $label performance ($pct%) but there is room for improvement.';
    }
    return 'Weak $label performance ($pct%). Development in this area is recommended.';
  }

  factory DimensionSummary.fromJson(Map<String, dynamic> json) =>
      DimensionSummary(
        dimensions: (json['dimensions'] as List<dynamic>)
            .map((e) =>
                DimensionSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        strengths: (json['strengths'] as List<dynamic>)
            .map((e) =>
                DimensionSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        weaknesses: (json['weaknesses'] as List<dynamic>)
            .map((e) =>
                DimensionSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        undiscovered: (json['undiscovered'] as List<dynamic>)
            .map((e) =>
                DimensionSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        computedAt: DateTime.parse(json['computed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'dimensions': dimensions.map((d) => d.toJson()).toList(),
    'strengths': strengths.map((d) => d.toJson()).toList(),
    'weaknesses': weaknesses.map((d) => d.toJson()).toList(),
    'undiscovered': undiscovered.map((d) => d.toJson()).toList(),
    'computed_at': computedAt.toIso8601String(),
  };

  DimensionSummary copyWith({
    List<DimensionSnapshot>? dimensions,
    List<DimensionSnapshot>? strengths,
    List<DimensionSnapshot>? weaknesses,
    List<DimensionSnapshot>? undiscovered,
    DateTime? computedAt,
  }) => DimensionSummary(
    dimensions: dimensions ?? this.dimensions,
    strengths: strengths ?? this.strengths,
    weaknesses: weaknesses ?? this.weaknesses,
    undiscovered: undiscovered ?? this.undiscovered,
    computedAt: computedAt ?? this.computedAt,
  );

  @override
  List<Object?> get props => [dimensions.length, strengths.length];
}
