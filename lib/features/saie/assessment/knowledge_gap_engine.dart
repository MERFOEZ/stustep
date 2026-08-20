/// SAIE — KnowledgeGapEngine
///
/// Determines what the system still doesn't know about the student.
/// Identifies weak, conflicting, and unconfirmed dimensions.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GapType
// ─────────────────────────────────────────────────────────────────────────────

/// The category of a knowledge gap.
enum GapType {
  /// No evidence at all for this dimension.
  missing,

  /// Evidence exists but confidence is too low.
  weakEvidence,

  /// Evidence records contradict each other.
  conflicting,

  /// Dimension has evidence but needs confirmation from a different angle.
  requiresConfirmation,
}

// ─────────────────────────────────────────────────────────────────────────────
// KnowledgeGap
// ─────────────────────────────────────────────────────────────────────────────

/// A single identified gap in the student's cognitive profile.
final class KnowledgeGap extends Equatable {
  final String dimensionKey;
  final String label;
  final GapType type;

  /// Urgency score [0.0, 1.0] — higher = more important to fill.
  final double urgency;

  /// Human-readable reason this gap was identified.
  final String reason;

  const KnowledgeGap({
    required this.dimensionKey,
    required this.label,
    required this.type,
    required this.urgency,
    required this.reason,
  });

  factory KnowledgeGap.fromJson(Map<String, dynamic> json) => KnowledgeGap(
    dimensionKey: json['dimension_key'] as String,
    label: json['label'] as String,
    type: GapType.values.byName(json['type'] as String),
    urgency: (json['urgency'] as num).toDouble(),
    reason: json['reason'] as String,
  );

  Map<String, dynamic> toJson() => {
    'dimension_key': dimensionKey,
    'label': label,
    'type': type.name,
    'urgency': urgency,
    'reason': reason,
  };

  KnowledgeGap copyWith({
    String? dimensionKey,
    String? label,
    GapType? type,
    double? urgency,
    String? reason,
  }) => KnowledgeGap(
    dimensionKey: dimensionKey ?? this.dimensionKey,
    label: label ?? this.label,
    type: type ?? this.type,
    urgency: urgency ?? this.urgency,
    reason: reason ?? this.reason,
  );

  @override
  List<Object?> get props => [dimensionKey, type, urgency];
}

// ─────────────────────────────────────────────────────────────────────────────
// GapReport
// ─────────────────────────────────────────────────────────────────────────────

/// Complete gap analysis for the current profile state.
final class GapReport extends Equatable {
  final List<KnowledgeGap> gaps;
  final bool hasSignificantGaps;
  final DateTime computedAt;

  const GapReport({
    required this.gaps,
    required this.hasSignificantGaps,
    required this.computedAt,
  });

  List<KnowledgeGap> get missing =>
      gaps.where((g) => g.type == GapType.missing).toList();

  List<KnowledgeGap> get weakEvidence =>
      gaps.where((g) => g.type == GapType.weakEvidence).toList();

  List<KnowledgeGap> get conflicting =>
      gaps.where((g) => g.type == GapType.conflicting).toList();

  List<KnowledgeGap> get requiresConfirmation =>
      gaps.where((g) => g.type == GapType.requiresConfirmation).toList();

  List<String> get highUrgencyKeys =>
      gaps.where((g) => g.urgency >= 0.7).map((g) => g.dimensionKey).toList();

  List<String> get allGapKeys =>
      gaps.map((g) => g.dimensionKey).toList();

  factory GapReport.fromJson(Map<String, dynamic> json) => GapReport(
    gaps: (json['gaps'] as List<dynamic>)
        .map((e) => KnowledgeGap.fromJson(e as Map<String, dynamic>))
        .toList(),
    hasSignificantGaps: json['has_significant_gaps'] as bool,
    computedAt: DateTime.parse(json['computed_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'gaps': gaps.map((g) => g.toJson()).toList(),
    'has_significant_gaps': hasSignificantGaps,
    'computed_at': computedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [gaps.length, hasSignificantGaps];
}

// ─────────────────────────────────────────────────────────────────────────────
// KnowledgeGapEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies all [KnowledgeGap]s in the current student profile.
final class KnowledgeGapEngine {
  /// Confidence below this is considered "weak evidence".
  static const double _weakConfidenceThreshold = 0.35;

  /// Confidence below this is considered "requires confirmation".
  static const double _confirmationThreshold = 0.55;

  /// If standard deviation of evidence scores exceeds this, flag conflicting.
  static const double _conflictThreshold = 0.30;

  const KnowledgeGapEngine();

  /// Analyses [profile] and returns a [GapReport].
  GapReport analyse(StudentCognitiveProfile profile) {
    final now = DateTime.now().toUtc();
    final gaps = <KnowledgeGap>[];

    for (final key in DimensionKeys.all) {
      final dim = profile.dimension(key);
      final label = DimensionKeys.labels[key] ?? key;
      final evidenceCount = dim.evidenceCount;
      final confidence = dim.confidence;

      if (evidenceCount == 0) {
        gaps.add(KnowledgeGap(
          dimensionKey: key,
          label: label,
          type: GapType.missing,
          urgency: 1.0,
          reason: 'No evidence collected for this dimension.',
        ));
        continue;
      }

      // Check for conflicting evidence (score variance across evidence records).
      final hasConflict = _hasConflictingEvidence(profile, key);
      if (hasConflict) {
        gaps.add(KnowledgeGap(
          dimensionKey: key,
          label: label,
          type: GapType.conflicting,
          urgency: 0.85,
          reason: 'Evidence records for this dimension are contradictory.',
        ));
        continue;
      }

      if (confidence < _weakConfidenceThreshold) {
        gaps.add(KnowledgeGap(
          dimensionKey: key,
          label: label,
          type: GapType.weakEvidence,
          urgency: 0.75,
          reason: 'Evidence exists but confidence is too low '
              '(${(confidence * 100).toStringAsFixed(0)}%).',
        ));
        continue;
      }

      if (confidence < _confirmationThreshold) {
        gaps.add(KnowledgeGap(
          dimensionKey: key,
          label: label,
          type: GapType.requiresConfirmation,
          urgency: 0.50,
          reason: 'Dimension needs additional confirmation '
              '(confidence ${(confidence * 100).toStringAsFixed(0)}%).',
        ));
      }
    }

    // Sort by urgency descending.
    gaps.sort((a, b) => b.urgency.compareTo(a.urgency));

    final hasSignificant = gaps.any((g) =>
        g.type == GapType.missing ||
        g.type == GapType.conflicting ||
        (g.type == GapType.weakEvidence && g.urgency >= 0.70));

    return GapReport(
      gaps: gaps,
      hasSignificantGaps: hasSignificant,
      computedAt: now,
    );
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  bool _hasConflictingEvidence(StudentCognitiveProfile profile, String key) {
    // Collect evidence records that affect this dimension.
    final evidenceForDim = profile.evidence
        .where((e) => e.affectedDimensions.containsKey(key))
        .toList();

    if (evidenceForDim.length < 2) return false;

    // Use each evidence record's dimension weight for this key as the "score".
    final scores = evidenceForDim
        .map((e) => (e.affectedDimensions[key] ?? 0.0).abs())
        .toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores
            .map((s) => (s - mean) * (s - mean))
            .reduce((a, b) => a + b) /
        scores.length;

    return variance > _conflictThreshold;
  }
}
