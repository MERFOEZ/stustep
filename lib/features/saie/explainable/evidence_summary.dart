/// SAIE — EvidenceSummary
///
/// Summarises all evidence collected during the assessment into
/// accepted, rejected, conflicting, and most-influential buckets.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EvidenceRecord
// ─────────────────────────────────────────────────────────────────────────────

/// A summarised view of a single [StudentEvidence] item.
final class EvidenceRecord extends Equatable {
  final String evidenceId;
  final String rawValue;
  final double weight;
  final double confidence;
  final Map<String, double> affectedDimensions;
  final String reason;
  final DateTime timestamp;
  final bool isInfluential;

  const EvidenceRecord({
    required this.evidenceId,
    required this.rawValue,
    required this.weight,
    required this.confidence,
    required this.affectedDimensions,
    required this.reason,
    required this.timestamp,
    required this.isInfluential,
  });

  factory EvidenceRecord.fromEvidence(
    StudentEvidence e, {
    bool isInfluential = false,
  }) => EvidenceRecord(
    evidenceId: e.id,
    rawValue: e.rawValue,
    weight: e.weight,
    confidence: e.confidence,
    affectedDimensions: e.affectedDimensions,
    reason: e.reason,
    timestamp: e.timestamp,
    isInfluential: isInfluential,
  );

  factory EvidenceRecord.fromJson(Map<String, dynamic> json) => EvidenceRecord(
    evidenceId: json['evidence_id'] as String,
    rawValue: json['raw_value'] as String,
    weight: (json['weight'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    affectedDimensions:
        (json['affected_dimensions'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
    reason: json['reason'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isInfluential: json['is_influential'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'evidence_id': evidenceId,
    'raw_value': rawValue,
    'weight': weight,
    'confidence': confidence,
    'affected_dimensions': affectedDimensions,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
    'is_influential': isInfluential,
  };

  EvidenceRecord copyWith({
    String? evidenceId,
    String? rawValue,
    double? weight,
    double? confidence,
    Map<String, double>? affectedDimensions,
    String? reason,
    DateTime? timestamp,
    bool? isInfluential,
  }) => EvidenceRecord(
    evidenceId: evidenceId ?? this.evidenceId,
    rawValue: rawValue ?? this.rawValue,
    weight: weight ?? this.weight,
    confidence: confidence ?? this.confidence,
    affectedDimensions: affectedDimensions ?? this.affectedDimensions,
    reason: reason ?? this.reason,
    timestamp: timestamp ?? this.timestamp,
    isInfluential: isInfluential ?? this.isInfluential,
  );

  @override
  List<Object?> get props => [evidenceId, weight, isInfluential];
}

// ─────────────────────────────────────────────────────────────────────────────
// EvidenceSummary
// ─────────────────────────────────────────────────────────────────────────────

/// Complete classification of all evidence records from an assessment.
final class EvidenceSummary extends Equatable {
  /// Evidence records accepted and used to update the profile.
  final List<EvidenceRecord> accepted;

  /// Evidence records rejected (low weight / invalid answers).
  final List<EvidenceRecord> rejected;

  /// Evidence records that contradict each other for the same dimension.
  final List<EvidenceRecord> conflicting;

  /// The top N most influential accepted evidence records.
  final List<EvidenceRecord> mostInfluential;

  final int totalCount;
  final double averageWeight;
  final double averageConfidence;
  final DateTime computedAt;

  const EvidenceSummary({
    required this.accepted,
    required this.rejected,
    required this.conflicting,
    required this.mostInfluential,
    required this.totalCount,
    required this.averageWeight,
    required this.averageConfidence,
    required this.computedAt,
  });

  factory EvidenceSummary.fromProfile(
    StudentCognitiveProfile profile, {
    int topN = 5,
    double rejectionWeightThreshold = 0.10,
  }) {
    final all = profile.evidence;
    if (all.isEmpty) {
      return EvidenceSummary(
        accepted: const [],
        rejected: const [],
        conflicting: const [],
        mostInfluential: const [],
        totalCount: 0,
        averageWeight: 0.0,
        averageConfidence: 0.0,
        computedAt: DateTime.now().toUtc(),
      );
    }

    final accepted = <EvidenceRecord>[];
    final rejected = <EvidenceRecord>[];

    for (final e in all) {
      if (e.weight >= rejectionWeightThreshold) {
        accepted.add(EvidenceRecord.fromEvidence(e));
      } else {
        rejected.add(EvidenceRecord.fromEvidence(e));
      }
    }

    // Detect conflicting: multiple evidence for same dimension with
    // very different weight values.
    final conflicting = _detectConflicting(accepted);

    // Most influential = top N accepted by weight.
    final sortedByWeight = List<EvidenceRecord>.from(accepted)
      ..sort((a, b) => b.weight.compareTo(a.weight));
    final mostInfluential = sortedByWeight
        .take(topN)
        .map((e) => e.copyWith(isInfluential: true))
        .toList();

    final avgWeight = all.isEmpty
        ? 0.0
        : all.map((e) => e.weight).reduce((a, b) => a + b) / all.length;
    final avgConf = all.isEmpty
        ? 0.0
        : all.map((e) => e.confidence).reduce((a, b) => a + b) / all.length;

    return EvidenceSummary(
      accepted: accepted,
      rejected: rejected,
      conflicting: conflicting,
      mostInfluential: mostInfluential,
      totalCount: all.length,
      averageWeight: avgWeight,
      averageConfidence: avgConf,
      computedAt: DateTime.now().toUtc(),
    );
  }

  static List<EvidenceRecord> _detectConflicting(
    List<EvidenceRecord> accepted,
  ) {
    final dimensionGroups = <String, List<EvidenceRecord>>{};
    for (final record in accepted) {
      for (final key in record.affectedDimensions.keys) {
        dimensionGroups.putIfAbsent(key, () => []).add(record);
      }
    }

    final conflicting = <EvidenceRecord>{};
    for (final records in dimensionGroups.values) {
      if (records.length < 2) continue;
      final weights =
          records.map((r) => r.affectedDimensions.values.first).toList();
      final mean = weights.reduce((a, b) => a + b) / weights.length;
      final variance = weights
              .map((w) => (w - mean) * (w - mean))
              .reduce((a, b) => a + b) /
          weights.length;
      if (variance > 0.15) {
        conflicting.addAll(records);
      }
    }
    return conflicting.toList();
  }

  factory EvidenceSummary.fromJson(Map<String, dynamic> json) => EvidenceSummary(
    accepted: (json['accepted'] as List<dynamic>)
        .map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    rejected: (json['rejected'] as List<dynamic>)
        .map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    conflicting: (json['conflicting'] as List<dynamic>)
        .map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    mostInfluential: (json['most_influential'] as List<dynamic>)
        .map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalCount: json['total_count'] as int,
    averageWeight: (json['average_weight'] as num).toDouble(),
    averageConfidence: (json['average_confidence'] as num).toDouble(),
    computedAt: DateTime.parse(json['computed_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'accepted': accepted.map((e) => e.toJson()).toList(),
    'rejected': rejected.map((e) => e.toJson()).toList(),
    'conflicting': conflicting.map((e) => e.toJson()).toList(),
    'most_influential': mostInfluential.map((e) => e.toJson()).toList(),
    'total_count': totalCount,
    'average_weight': averageWeight,
    'average_confidence': averageConfidence,
    'computed_at': computedAt.toIso8601String(),
  };

  EvidenceSummary copyWith({
    List<EvidenceRecord>? accepted,
    List<EvidenceRecord>? rejected,
    List<EvidenceRecord>? conflicting,
    List<EvidenceRecord>? mostInfluential,
    int? totalCount,
    double? averageWeight,
    double? averageConfidence,
    DateTime? computedAt,
  }) => EvidenceSummary(
    accepted: accepted ?? this.accepted,
    rejected: rejected ?? this.rejected,
    conflicting: conflicting ?? this.conflicting,
    mostInfluential: mostInfluential ?? this.mostInfluential,
    totalCount: totalCount ?? this.totalCount,
    averageWeight: averageWeight ?? this.averageWeight,
    averageConfidence: averageConfidence ?? this.averageConfidence,
    computedAt: computedAt ?? this.computedAt,
  );

  @override
  List<Object?> get props => [totalCount, accepted.length, conflicting.length];
}
