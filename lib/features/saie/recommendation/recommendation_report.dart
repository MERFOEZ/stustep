/// SAIE — RecommendationReport
///
/// The complete, structured output of the Recommendation Engine.
/// Every report is self-contained — no further engine calls needed to display it.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/recommendation/recommendation_confidence.dart';
import 'package:stustep/features/saie/recommendation/recommendation_reason.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReportStatus
// ─────────────────────────────────────────────────────────────────────────────

enum ReportStatus {
  /// Recommendations produced successfully.
  ready,

  /// Profile does not have enough evidence.
  needMoreAssessment,

  /// Assessment complete but no major passed the confidence threshold.
  noConfidentMatch,
}

extension ReportStatusX on ReportStatus {
  bool get hasRecommendations => this == ReportStatus.ready;
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorRecommendation
// ─────────────────────────────────────────────────────────────────────────────

/// A single major recommendation with full explanation.
final class MajorRecommendation extends Equatable {
  final int rank;
  final String majorId;
  final String majorName;
  final String? majorNameAr;
  final MajorCategory category;
  final int similarityScore;
  final RecommendationConfidence confidence;
  final List<RecommendationReason> reasons;
  final List<String> topStrengths;
  final List<String> weakAreas;
  final List<String> missingSkills;
  final List<String> careerPaths;
  final String explanation;

  const MajorRecommendation({
    required this.rank,
    required this.majorId,
    required this.majorName,
    required this.category,
    required this.similarityScore,
    required this.confidence,
    required this.reasons,
    required this.topStrengths,
    required this.weakAreas,
    required this.missingSkills,
    required this.careerPaths,
    required this.explanation,
    this.majorNameAr,
  });

  bool get isTopPick => rank == 1;

  List<RecommendationReason> get positiveReasons =>
      reasons.where((r) => r.positive).toList();

  List<RecommendationReason> get negativeReasons =>
      reasons.where((r) => !r.positive).toList();

  factory MajorRecommendation.fromJson(Map<String, dynamic> json) =>
      MajorRecommendation(
        rank: json['rank'] as int,
        majorId: json['major_id'] as String,
        majorName: json['major_name'] as String,
        majorNameAr: json['major_name_ar'] as String?,
        category: MajorCategory.values.byName(json['category'] as String),
        similarityScore: json['similarity_score'] as int,
        confidence: RecommendationConfidence.fromJson(
          json['confidence'] as Map<String, dynamic>,
        ),
        reasons: (json['reasons'] as List<dynamic>)
            .map((e) =>
                RecommendationReason.fromJson(e as Map<String, dynamic>))
            .toList(),
        topStrengths:
            (json['top_strengths'] as List<dynamic>).cast<String>(),
        weakAreas: (json['weak_areas'] as List<dynamic>).cast<String>(),
        missingSkills:
            (json['missing_skills'] as List<dynamic>).cast<String>(),
        careerPaths: (json['career_paths'] as List<dynamic>).cast<String>(),
        explanation: json['explanation'] as String,
      );

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'major_id': majorId,
    'major_name': majorName,
    if (majorNameAr != null) 'major_name_ar': majorNameAr,
    'category': category.name,
    'similarity_score': similarityScore,
    'confidence': confidence.toJson(),
    'reasons': reasons.map((r) => r.toJson()).toList(),
    'top_strengths': topStrengths,
    'weak_areas': weakAreas,
    'missing_skills': missingSkills,
    'career_paths': careerPaths,
    'explanation': explanation,
  };

  MajorRecommendation copyWith({
    int? rank,
    String? majorId,
    String? majorName,
    String? majorNameAr,
    MajorCategory? category,
    int? similarityScore,
    RecommendationConfidence? confidence,
    List<RecommendationReason>? reasons,
    List<String>? topStrengths,
    List<String>? weakAreas,
    List<String>? missingSkills,
    List<String>? careerPaths,
    String? explanation,
  }) => MajorRecommendation(
    rank: rank ?? this.rank,
    majorId: majorId ?? this.majorId,
    majorName: majorName ?? this.majorName,
    majorNameAr: majorNameAr ?? this.majorNameAr,
    category: category ?? this.category,
    similarityScore: similarityScore ?? this.similarityScore,
    confidence: confidence ?? this.confidence,
    reasons: reasons ?? this.reasons,
    topStrengths: topStrengths ?? this.topStrengths,
    weakAreas: weakAreas ?? this.weakAreas,
    missingSkills: missingSkills ?? this.missingSkills,
    careerPaths: careerPaths ?? this.careerPaths,
    explanation: explanation ?? this.explanation,
  );

  @override
  List<Object?> get props => [rank, majorId, similarityScore];
}

// ─────────────────────────────────────────────────────────────────────────────
// ImprovementSuggestion
// ─────────────────────────────────────────────────────────────────────────────

/// A concrete development suggestion for the student.
final class ImprovementSuggestion extends Equatable {
  final String dimensionKey;
  final String title;
  final String suggestion;
  final String rationale;
  final double priority;

  const ImprovementSuggestion({
    required this.dimensionKey,
    required this.title,
    required this.suggestion,
    required this.rationale,
    required this.priority,
  });

  factory ImprovementSuggestion.fromJson(Map<String, dynamic> json) =>
      ImprovementSuggestion(
        dimensionKey: json['dimension_key'] as String,
        title: json['title'] as String,
        suggestion: json['suggestion'] as String,
        rationale: json['rationale'] as String,
        priority: (json['priority'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'dimension_key': dimensionKey,
    'title': title,
    'suggestion': suggestion,
    'rationale': rationale,
    'priority': priority,
  };

  ImprovementSuggestion copyWith({
    String? dimensionKey,
    String? title,
    String? suggestion,
    String? rationale,
    double? priority,
  }) => ImprovementSuggestion(
    dimensionKey: dimensionKey ?? this.dimensionKey,
    title: title ?? this.title,
    suggestion: suggestion ?? this.suggestion,
    rationale: rationale ?? this.rationale,
    priority: priority ?? this.priority,
  );

  @override
  List<Object?> get props => [dimensionKey, priority];
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationReport
// ─────────────────────────────────────────────────────────────────────────────

/// The complete structured recommendation report.
final class RecommendationReport extends Equatable {
  final String reportId;
  final String studentId;
  final ReportStatus status;
  final String statusMessage;

  /// Top ranked major recommendations (up to 10).
  final List<MajorRecommendation> recommendations;

  /// Overall confidence of the recommendation set.
  final RecommendationConfidence overallConfidence;

  /// Student's top cognitive strengths.
  final List<String> globalStrengths;

  /// Student's weakest cognitive dimensions.
  final List<String> globalWeaknesses;

  /// Dominant learning style label.
  final String dominantLearningStyle;

  /// Dominant personality trait labels.
  final List<String> personalityHighlights;

  /// Assessment statistics at the time of report generation.
  final AssessmentStatistics assessmentStats;

  /// Improvement suggestions, sorted by priority.
  final List<ImprovementSuggestion> improvementSuggestions;

  /// Raw ranking used to produce this report.
  final MajorRanking sourceRanking;

  final DateTime generatedAt;

  const RecommendationReport({
    required this.reportId,
    required this.studentId,
    required this.status,
    required this.statusMessage,
    required this.recommendations,
    required this.overallConfidence,
    required this.globalStrengths,
    required this.globalWeaknesses,
    required this.dominantLearningStyle,
    required this.personalityHighlights,
    required this.assessmentStats,
    required this.improvementSuggestions,
    required this.sourceRanking,
    required this.generatedAt,
  });

  bool get hasRecommendations => status.hasRecommendations;
  MajorRecommendation? get topPick =>
      recommendations.isEmpty ? null : recommendations.first;

  factory RecommendationReport.fromJson(Map<String, dynamic> json) =>
      RecommendationReport(
        reportId: json['report_id'] as String,
        studentId: json['student_id'] as String,
        status: ReportStatus.values.byName(json['status'] as String),
        statusMessage: json['status_message'] as String,
        recommendations: (json['recommendations'] as List<dynamic>)
            .map((e) =>
                MajorRecommendation.fromJson(e as Map<String, dynamic>))
            .toList(),
        overallConfidence: RecommendationConfidence.fromJson(
          json['overall_confidence'] as Map<String, dynamic>,
        ),
        globalStrengths:
            (json['global_strengths'] as List<dynamic>).cast<String>(),
        globalWeaknesses:
            (json['global_weaknesses'] as List<dynamic>).cast<String>(),
        dominantLearningStyle: json['dominant_learning_style'] as String,
        personalityHighlights:
            (json['personality_highlights'] as List<dynamic>).cast<String>(),
        assessmentStats: AssessmentStatistics.fromJson(
          json['assessment_stats'] as Map<String, dynamic>,
        ),
        improvementSuggestions: (json['improvement_suggestions']
                as List<dynamic>)
            .map((e) =>
                ImprovementSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        sourceRanking: MajorRanking.fromJson(
          json['source_ranking'] as Map<String, dynamic>,
        ),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'student_id': studentId,
    'status': status.name,
    'status_message': statusMessage,
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
    'overall_confidence': overallConfidence.toJson(),
    'global_strengths': globalStrengths,
    'global_weaknesses': globalWeaknesses,
    'dominant_learning_style': dominantLearningStyle,
    'personality_highlights': personalityHighlights,
    'assessment_stats': assessmentStats.toJson(),
    'improvement_suggestions':
        improvementSuggestions.map((s) => s.toJson()).toList(),
    'source_ranking': sourceRanking.toJson(),
    'generated_at': generatedAt.toIso8601String(),
  };

  RecommendationReport copyWith({
    String? reportId,
    String? studentId,
    ReportStatus? status,
    String? statusMessage,
    List<MajorRecommendation>? recommendations,
    RecommendationConfidence? overallConfidence,
    List<String>? globalStrengths,
    List<String>? globalWeaknesses,
    String? dominantLearningStyle,
    List<String>? personalityHighlights,
    AssessmentStatistics? assessmentStats,
    List<ImprovementSuggestion>? improvementSuggestions,
    MajorRanking? sourceRanking,
    DateTime? generatedAt,
  }) => RecommendationReport(
    reportId: reportId ?? this.reportId,
    studentId: studentId ?? this.studentId,
    status: status ?? this.status,
    statusMessage: statusMessage ?? this.statusMessage,
    recommendations: recommendations ?? this.recommendations,
    overallConfidence: overallConfidence ?? this.overallConfidence,
    globalStrengths: globalStrengths ?? this.globalStrengths,
    globalWeaknesses: globalWeaknesses ?? this.globalWeaknesses,
    dominantLearningStyle:
        dominantLearningStyle ?? this.dominantLearningStyle,
    personalityHighlights:
        personalityHighlights ?? this.personalityHighlights,
    assessmentStats: assessmentStats ?? this.assessmentStats,
    improvementSuggestions:
        improvementSuggestions ?? this.improvementSuggestions,
    sourceRanking: sourceRanking ?? this.sourceRanking,
    generatedAt: generatedAt ?? this.generatedAt,
  );

  @override
  List<Object?> get props => [reportId, status, recommendations.length];

  @override
  String toString() =>
      'RecommendationReport(id: $reportId, status: ${status.name}, '
      'recommendations: ${recommendations.length})';
}
