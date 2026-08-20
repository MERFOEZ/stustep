/// SAIE — DecisionExplainer
///
/// Produces a complete natural-language explanation for why the engine
/// made a specific recommendation decision, covering:
/// - Why assessment was deemed sufficient (or insufficient).
/// - Why the top major was selected.
/// - Why lower-ranked majors were ranked lower.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/explainable/dimension_summary.dart';
import 'package:stustep/features/saie/explainable/evidence_summary.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_confidence.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DecisionExplanation
// ─────────────────────────────────────────────────────────────────────────────

/// A structured, complete explanation of the engine's recommendation decision.
final class DecisionExplanation extends Equatable {
  /// Why the assessment was deemed sufficient (or not).
  final String assessmentReadinessExplanation;

  /// Why the top recommendation was selected.
  final String topPickRationale;

  /// Summary of how evidence was used.
  final String evidenceUsageSummary;

  /// Summary of dimension coverage.
  final String dimensionCoverageSummary;

  /// Summary of confidence and its drivers.
  final String confidenceExplanation;

  /// Why certain majors were excluded or ranked lower.
  final List<String> rankingJustifications;

  /// Full narrative paragraph for UI display.
  final String narrative;

  /// UTC timestamp.
  final DateTime generatedAt;

  const DecisionExplanation({
    required this.assessmentReadinessExplanation,
    required this.topPickRationale,
    required this.evidenceUsageSummary,
    required this.dimensionCoverageSummary,
    required this.confidenceExplanation,
    required this.rankingJustifications,
    required this.narrative,
    required this.generatedAt,
  });

  factory DecisionExplanation.fromJson(Map<String, dynamic> json) =>
      DecisionExplanation(
        assessmentReadinessExplanation:
            json['assessment_readiness_explanation'] as String,
        topPickRationale: json['top_pick_rationale'] as String,
        evidenceUsageSummary: json['evidence_usage_summary'] as String,
        dimensionCoverageSummary: json['dimension_coverage_summary'] as String,
        confidenceExplanation: json['confidence_explanation'] as String,
        rankingJustifications:
            (json['ranking_justifications'] as List<dynamic>).cast<String>(),
        narrative: json['narrative'] as String,
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'assessment_readiness_explanation': assessmentReadinessExplanation,
    'top_pick_rationale': topPickRationale,
    'evidence_usage_summary': evidenceUsageSummary,
    'dimension_coverage_summary': dimensionCoverageSummary,
    'confidence_explanation': confidenceExplanation,
    'ranking_justifications': rankingJustifications,
    'narrative': narrative,
    'generated_at': generatedAt.toIso8601String(),
  };

  DecisionExplanation copyWith({
    String? assessmentReadinessExplanation,
    String? topPickRationale,
    String? evidenceUsageSummary,
    String? dimensionCoverageSummary,
    String? confidenceExplanation,
    List<String>? rankingJustifications,
    String? narrative,
    DateTime? generatedAt,
  }) => DecisionExplanation(
    assessmentReadinessExplanation:
        assessmentReadinessExplanation ?? this.assessmentReadinessExplanation,
    topPickRationale: topPickRationale ?? this.topPickRationale,
    evidenceUsageSummary: evidenceUsageSummary ?? this.evidenceUsageSummary,
    dimensionCoverageSummary:
        dimensionCoverageSummary ?? this.dimensionCoverageSummary,
    confidenceExplanation:
        confidenceExplanation ?? this.confidenceExplanation,
    rankingJustifications:
        rankingJustifications ?? this.rankingJustifications,
    narrative: narrative ?? this.narrative,
    generatedAt: generatedAt ?? this.generatedAt,
  );

  @override
  List<Object?> get props => [generatedAt, narrative.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// DecisionExplainer
// ─────────────────────────────────────────────────────────────────────────────

/// Produces a [DecisionExplanation] from a [RecommendationReport].
final class DecisionExplainer {
  const DecisionExplainer();

  DecisionExplanation explain({
    required RecommendationReport report,
    required StudentCognitiveProfile profile,
    required EvidenceSummary evidenceSummary,
    required DimensionSummary dimensionSummary,
  }) {
    final now = DateTime.now().toUtc();
    final stats = report.assessmentStats;
    final conf = report.overallConfidence;

    // ── Assessment readiness ─────────────────────────────────────────────
    final readiness = _assessmentReadiness(stats, conf, profile);

    // ── Top pick rationale ───────────────────────────────────────────────
    final topPick = report.topPick;
    final topPickRationale = topPick == null
        ? 'No major recommendation was produced because the profile did '
            'not meet the confidence threshold.'
        : _topPickRationale(topPick, dimensionSummary);

    // ── Evidence usage ───────────────────────────────────────────────────
    final evidenceUsage = _evidenceUsage(evidenceSummary);

    // ── Dimension coverage ───────────────────────────────────────────────
    final dimCoverage = _dimensionCoverage(dimensionSummary, stats);

    // ── Confidence ───────────────────────────────────────────────────────
    final confidenceExp = _confidenceExplanation(conf);

    // ── Ranking justifications ───────────────────────────────────────────
    final justifications = _rankingJustifications(report.recommendations);

    // ── Narrative ────────────────────────────────────────────────────────
    final narrative = _narrative(
      report: report,
      readiness: readiness,
      topPickRationale: topPickRationale,
      evidenceUsage: evidenceUsage,
    );

    return DecisionExplanation(
      assessmentReadinessExplanation: readiness,
      topPickRationale: topPickRationale,
      evidenceUsageSummary: evidenceUsage,
      dimensionCoverageSummary: dimCoverage,
      confidenceExplanation: confidenceExp,
      rankingJustifications: justifications,
      narrative: narrative,
      generatedAt: now,
    );
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  String _assessmentReadiness(
    AssessmentStatistics stats,
    RecommendationConfidence conf,
    StudentCognitiveProfile profile,
  ) {
    final coveragePct = stats.coveragePercent.toStringAsFixed(0);
    final confPct = (conf.profileConfidence * 100).toStringAsFixed(0);
    return 'The assessment covered $coveragePct% of the cognitive framework '
        'with $confPct% profile confidence and ${profile.evidenceCount} '
        'evidence records. '
        '${conf.tier.isActionable ? "This is sufficient for a recommendation." : "More assessment is recommended."}';
  }

  String _topPickRationale(
    MajorRecommendation top,
    DimensionSummary dimSummary,
  ) {
    final strengthNames =
        dimSummary.strengths.take(3).map((d) => d.label).join(', ');
    return '"${top.majorName}" was ranked #1 with a similarity score of '
        '${top.similarityScore}/100 and ${(top.confidence.score * 100).toStringAsFixed(0)}% '
        'recommendation confidence. '
        'Your strongest dimensions — $strengthNames — align well with '
        "this major's requirements. "
        '${top.missingSkills.isEmpty ? "No critical prerequisites are missing." : "Some prerequisite skills are still developing: ${top.missingSkills.take(2).join(", ")}."}';
  }

  String _evidenceUsage(EvidenceSummary evidenceSummary) =>
      '${evidenceSummary.accepted.length} evidence records were accepted and '
      'used to build the profile. '
      '${evidenceSummary.rejected.length} records were rejected (low quality). '
      '${evidenceSummary.conflicting.isEmpty ? "No conflicting signals detected." : "${evidenceSummary.conflicting.length} conflicting signals require further clarification."}';

  String _dimensionCoverage(
    DimensionSummary dimSummary,
    AssessmentStatistics stats,
  ) =>
      '${dimSummary.strengths.length} dimensions are assessed as strengths, '
      '${dimSummary.weaknesses.length} require development, '
      'and ${dimSummary.undiscovered.length} have not yet been explored. '
      'Overall coverage: ${stats.coveragePercent.toStringAsFixed(0)}%.';

  String _confidenceExplanation(RecommendationConfidence conf) =>
      '${conf.tier.label} (${(conf.score * 100).toStringAsFixed(1)}%). '
      '${conf.explanation}';

  List<String> _rankingJustifications(
    List<MajorRecommendation> recs,
  ) {
    if (recs.length < 2) return const [];
    final justifications = <String>[];
    for (int i = 0; i < recs.length - 1 && i < 5; i++) {
      final a = recs[i];
      final b = recs[i + 1];
      final diff = a.similarityScore - b.similarityScore;
      justifications.add(
        '"${a.majorName}" (${a.similarityScore}) ranked above '
        '"${b.majorName}" (${b.similarityScore}) by $diff points.',
      );
    }
    return justifications;
  }

  String _narrative({
    required RecommendationReport report,
    required String readiness,
    required String topPickRationale,
    required String evidenceUsage,
  }) {
    final buf = StringBuffer();
    buf.write('Based on your assessment, ');
    buf.write(readiness.toLowerCase());
    buf.writeln();
    if (report.hasRecommendations) {
      buf.write(topPickRationale);
      buf.writeln();
      buf.write(evidenceUsage);
    } else {
      buf.write(report.statusMessage);
    }
    return buf.toString();
  }
}
