/// SAIE — CoverageEngine
///
/// Measures what percentage of the cognitive space has been sufficiently
/// evidenced. Used by the assessment engine to determine:
/// - Which dimensions still need questions.
/// - Whether the overall coverage threshold has been met.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimensionCoverage
// ─────────────────────────────────────────────────────────────────────────────

/// Coverage status of a single cognitive dimension.
final class DimensionCoverage extends Equatable {
  final String key;
  final String label;
  final int evidenceCount;
  final double confidence;
  final bool isCovered;

  const DimensionCoverage({
    required this.key,
    required this.label,
    required this.evidenceCount,
    required this.confidence,
    required this.isCovered,
  });

  factory DimensionCoverage.fromJson(Map<String, dynamic> json) =>
      DimensionCoverage(
        key: json['key'] as String,
        label: json['label'] as String,
        evidenceCount: json['evidence_count'] as int,
        confidence: (json['confidence'] as num).toDouble(),
        isCovered: json['is_covered'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'evidence_count': evidenceCount,
    'confidence': confidence,
    'is_covered': isCovered,
  };

  DimensionCoverage copyWith({
    String? key,
    String? label,
    int? evidenceCount,
    double? confidence,
    bool? isCovered,
  }) => DimensionCoverage(
    key: key ?? this.key,
    label: label ?? this.label,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    confidence: confidence ?? this.confidence,
    isCovered: isCovered ?? this.isCovered,
  );

  @override
  List<Object?> get props => [key, evidenceCount, isCovered];
}

// ─────────────────────────────────────────────────────────────────────────────
// CoverageReport
// ─────────────────────────────────────────────────────────────────────────────

/// Full coverage snapshot for all cognitive dimensions.
final class CoverageReport extends Equatable {
  final List<DimensionCoverage> dimensions;
  final double overallCoverageRatio;
  final int coveredCount;
  final int totalCount;
  final DateTime computedAt;

  const CoverageReport({
    required this.dimensions,
    required this.overallCoverageRatio,
    required this.coveredCount,
    required this.totalCount,
    required this.computedAt,
  });

  List<DimensionCoverage> get uncoveredDimensions =>
      dimensions.where((d) => !d.isCovered).toList();

  List<DimensionCoverage> get coveredDimensions =>
      dimensions.where((d) => d.isCovered).toList();

  List<String> get uncoveredKeys =>
      uncoveredDimensions.map((d) => d.key).toList();

  bool get isSufficient => overallCoverageRatio >= 0.70;

  factory CoverageReport.fromJson(Map<String, dynamic> json) => CoverageReport(
    dimensions: (json['dimensions'] as List<dynamic>)
        .map((e) => DimensionCoverage.fromJson(e as Map<String, dynamic>))
        .toList(),
    overallCoverageRatio: (json['overall_coverage_ratio'] as num).toDouble(),
    coveredCount: json['covered_count'] as int,
    totalCount: json['total_count'] as int,
    computedAt: DateTime.parse(json['computed_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'dimensions': dimensions.map((d) => d.toJson()).toList(),
    'overall_coverage_ratio': overallCoverageRatio,
    'covered_count': coveredCount,
    'total_count': totalCount,
    'computed_at': computedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [coveredCount, overallCoverageRatio];
}

// ─────────────────────────────────────────────────────────────────────────────
// CoverageEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless service that computes [CoverageReport] from a profile.
final class CoverageEngine {
  const CoverageEngine();

  /// Computes a [CoverageReport] for [profile] using [config] thresholds.
  CoverageReport compute({
    required StudentCognitiveProfile profile,
    required AssessmentConfiguration config,
  }) {
    final now = DateTime.now().toUtc();
    final all = DimensionKeys.all;
    final coverageList = <DimensionCoverage>[];
    int coveredCount = 0;

    for (final key in all) {
      final dim = profile.dimension(key);
      final evidenceCount = dim.evidenceCount;
      final confidence = dim.confidence;
      final covered = evidenceCount >= config.evidenceCountForCoverage;

      if (covered) coveredCount++;

      coverageList.add(DimensionCoverage(
        key: key,
        label: DimensionKeys.labels[key] ?? key,
        evidenceCount: evidenceCount,
        confidence: confidence,
        isCovered: covered,
      ));
    }

    final ratio = all.isEmpty ? 0.0 : coveredCount / all.length;

    return CoverageReport(
      dimensions: coverageList,
      overallCoverageRatio: ratio,
      coveredCount: coveredCount,
      totalCount: all.length,
      computedAt: now,
    );
  }

  /// Returns dimension keys that are not yet covered, sorted by priority.
  /// Priority = low confidence + low evidence count.
  List<String> prioritisedUncoveredKeys({
    required StudentCognitiveProfile profile,
    required AssessmentConfiguration config,
  }) {
    final report = compute(profile: profile, config: config);
    final uncovered = report.uncoveredDimensions.toList()
      ..sort((a, b) {
        // sort: lowest confidence first, then lowest evidence count
        final confCmp = a.confidence.compareTo(b.confidence);
        if (confCmp != 0) return confCmp;
        return a.evidenceCount.compareTo(b.evidenceCount);
      });
    return uncovered.map((d) => d.key).toList();
  }
}
