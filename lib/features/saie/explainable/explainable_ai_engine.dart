/// SAIE — ExplainableAIEngine
///
/// Master orchestrator for the explainable AI layer (Task 8).
///
/// Given a [RecommendationReport] and [StudentCognitiveProfile]:
/// 1. Computes [EvidenceSummary].
/// 2. Computes [DimensionSummary].
/// 3. Produces [DecisionExplanation].
/// 4. Optionally generates comparison explanations between any two majors.
/// 5. Generates richer improvement suggestions.
///
/// Output: [ExplainableReport] — a self-contained, serialisable document.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/explainable/comparison_explainer.dart';
import 'package:stustep/features/saie/explainable/decision_explainer.dart';
import 'package:stustep/features/saie/explainable/dimension_summary.dart';
import 'package:stustep/features/saie/explainable/evidence_summary.dart';
import 'package:stustep/features/saie/explainable/improvement_suggestions.dart';
import 'package:stustep/features/saie/explainable/reason_builder.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/matching/major_score.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_reason.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExplainableReport
// ─────────────────────────────────────────────────────────────────────────────

/// Complete explainable output produced by the [ExplainableAIEngine].
final class ExplainableReport extends Equatable {
  final String reportId;
  final String studentId;
  final DecisionExplanation decisionExplanation;
  final EvidenceSummary evidenceSummary;
  final DimensionSummary dimensionSummary;
  final List<ImprovementSuggestion> improvementSuggestions;
  final DateTime generatedAt;

  const ExplainableReport({
    required this.reportId,
    required this.studentId,
    required this.decisionExplanation,
    required this.evidenceSummary,
    required this.dimensionSummary,
    required this.improvementSuggestions,
    required this.generatedAt,
  });

  factory ExplainableReport.fromJson(Map<String, dynamic> json) =>
      ExplainableReport(
        reportId: json['report_id'] as String,
        studentId: json['student_id'] as String,
        decisionExplanation: DecisionExplanation.fromJson(
          json['decision_explanation'] as Map<String, dynamic>,
        ),
        evidenceSummary: EvidenceSummary.fromJson(
          json['evidence_summary'] as Map<String, dynamic>,
        ),
        dimensionSummary: DimensionSummary.fromJson(
          json['dimension_summary'] as Map<String, dynamic>,
        ),
        improvementSuggestions:
            (json['improvement_suggestions'] as List<dynamic>)
                .map((e) =>
                    ImprovementSuggestion.fromJson(e as Map<String, dynamic>))
                .toList(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'student_id': studentId,
    'decision_explanation': decisionExplanation.toJson(),
    'evidence_summary': evidenceSummary.toJson(),
    'dimension_summary': dimensionSummary.toJson(),
    'improvement_suggestions':
        improvementSuggestions.map((s) => s.toJson()).toList(),
    'generated_at': generatedAt.toIso8601String(),
  };

  ExplainableReport copyWith({
    String? reportId,
    String? studentId,
    DecisionExplanation? decisionExplanation,
    EvidenceSummary? evidenceSummary,
    DimensionSummary? dimensionSummary,
    List<ImprovementSuggestion>? improvementSuggestions,
    DateTime? generatedAt,
  }) => ExplainableReport(
    reportId: reportId ?? this.reportId,
    studentId: studentId ?? this.studentId,
    decisionExplanation: decisionExplanation ?? this.decisionExplanation,
    evidenceSummary: evidenceSummary ?? this.evidenceSummary,
    dimensionSummary: dimensionSummary ?? this.dimensionSummary,
    improvementSuggestions:
        improvementSuggestions ?? this.improvementSuggestions,
    generatedAt: generatedAt ?? this.generatedAt,
  );

  @override
  List<Object?> get props => [reportId, generatedAt];

  @override
  String toString() =>
      'ExplainableReport(id: $reportId, '
      'strengths: ${dimensionSummary.strengths.length}, '
      'suggestions: ${improvementSuggestions.length})';
}

// ─────────────────────────────────────────────────────────────────────────────
// ExplainableAIEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates full explainability for a [RecommendationReport].
final class ExplainableAIEngine {
  final DecisionExplainer _decisionExplainer;
  final ReasonBuilder _reasonBuilder;
  final ComparisonExplainer _comparisonExplainer;
  final ImprovementSuggestionsEngine _suggestionsEngine;

  const ExplainableAIEngine({
    DecisionExplainer decisionExplainer = const DecisionExplainer(),
    ReasonBuilder reasonBuilder = const ReasonBuilder(),
    ComparisonExplainer comparisonExplainer = const ComparisonExplainer(),
    ImprovementSuggestionsEngine suggestionsEngine =
        const ImprovementSuggestionsEngine(),
  })  : _decisionExplainer = decisionExplainer,
        _reasonBuilder = reasonBuilder,
        _comparisonExplainer = comparisonExplainer,
        _suggestionsEngine = suggestionsEngine;

  // ── Primary API ────────────────────────────────────────────────────────────

  /// Generates a complete [ExplainableReport] from a [RecommendationReport].
  ExplainableReport explain({
    required RecommendationReport report,
    required StudentCognitiveProfile profile,
    required MajorRanking ranking,
  }) {
    // ── Build sub-summaries ───────────────────────────────────────────────
    final evidenceSummary = EvidenceSummary.fromProfile(profile);
    final dimensionSummary = DimensionSummary.fromProfile(profile);

    // ── Decision explanation ─────────────────────────────────────────────
    final decisionExplanation = _decisionExplainer.explain(
      report: report,
      profile: profile,
      evidenceSummary: evidenceSummary,
      dimensionSummary: dimensionSummary,
    );

    // ── Improvement suggestions ──────────────────────────────────────────
    final suggestions = _suggestionsEngine.generate(
      profile: profile,
      dimensionSummary: dimensionSummary,
      topRecommendations: report.recommendations,
    );

    return ExplainableReport(
      reportId: report.reportId,
      studentId: report.studentId,
      decisionExplanation: decisionExplanation,
      evidenceSummary: evidenceSummary,
      dimensionSummary: dimensionSummary,
      improvementSuggestions: suggestions,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  // ── Comparison API ────────────────────────────────────────────────────────

  /// Explains why [a] ranked above [b].
  MajorComparisonExplanation compareRecommendations({
    required MajorRecommendation a,
    required MajorRecommendation b,
    required MajorRanking ranking,
    required StudentCognitiveProfile profile,
  }) {
    final scoreA = _scoreFor(a.majorId, ranking);
    final scoreB = _scoreFor(b.majorId, ranking);

    return _comparisonExplainer.explain(
      a: a,
      b: b,
      scoreA: scoreA,
      scoreB: scoreB,
      profile: profile,
    );
  }

  // ── Reason API ────────────────────────────────────────────────────────────

  /// Builds rich reasons for a single recommendation (beyond what the ranker
  /// produced), using the full [MajorRanking] data.
  List<RecommendationReason> buildReasonsFor({
    required MajorRecommendation recommendation,
    required MajorRanking ranking,
    required StudentCognitiveProfile profile,
  }) {
    final score = _scoreFor(recommendation.majorId, ranking);
    return _reasonBuilder.buildFor(score: score, profile: profile);
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  MajorScore _scoreFor(String majorId, MajorRanking ranking) {
    final candidate = ranking.candidates.firstWhere(
      (c) => c.score.majorId == majorId,
      orElse: () => ranking.candidates.first,
    );
    return candidate.score;
  }
}
