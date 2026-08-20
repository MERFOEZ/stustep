/// SAIE — RecommendationExport
///
/// Converts a [RecommendationReport] into JSON, Markdown, or a PDF-ready
/// data model. No network, no Flutter, no external dependencies.
library;

import 'dart:convert';
import 'package:stustep/features/saie/recommendation/recommendation_confidence.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';
import 'package:stustep/features/saie/recommendation/recommendation_statistics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PdfReadyData
// ─────────────────────────────────────────────────────────────────────────────

/// A flat, PDF-renderer-friendly data model extracted from the report.
final class PdfReadyData {
  final String reportId;
  final String studentId;
  final String generatedAt;
  final String status;
  final String statusMessage;
  final List<Map<String, dynamic>> recommendations;
  final List<Map<String, String>> suggestions;
  final List<String> globalStrengths;
  final List<String> globalWeaknesses;
  final String dominantLearningStyle;
  final List<String> personalityHighlights;
  final Map<String, dynamic> statistics;

  const PdfReadyData({
    required this.reportId,
    required this.studentId,
    required this.generatedAt,
    required this.status,
    required this.statusMessage,
    required this.recommendations,
    required this.suggestions,
    required this.globalStrengths,
    required this.globalWeaknesses,
    required this.dominantLearningStyle,
    required this.personalityHighlights,
    required this.statistics,
  });

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'student_id': studentId,
    'generated_at': generatedAt,
    'status': status,
    'status_message': statusMessage,
    'recommendations': recommendations,
    'suggestions': suggestions,
    'global_strengths': globalStrengths,
    'global_weaknesses': globalWeaknesses,
    'dominant_learning_style': dominantLearningStyle,
    'personality_highlights': personalityHighlights,
    'statistics': statistics,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationExport
// ─────────────────────────────────────────────────────────────────────────────

/// Exports [RecommendationReport] to JSON, Markdown, or [PdfReadyData].
final class RecommendationExport {
  const RecommendationExport();

  // ── JSON ──────────────────────────────────────────────────────────────────

  /// Returns the report as a pretty-printed JSON string.
  String toJsonString(RecommendationReport report) =>
      const JsonEncoder.withIndent('  ').convert(report.toJson());

  // ── Markdown ──────────────────────────────────────────────────────────────

  /// Returns the report as a Markdown document.
  String toMarkdown(RecommendationReport report) {
    final buf = StringBuffer();

    buf.writeln('# StuStep Academic Recommendation Report');
    buf.writeln();
    buf.writeln('**Report ID:** ${report.reportId}');
    buf.writeln('**Student ID:** ${report.studentId}');
    buf.writeln(
        '**Generated At:** ${report.generatedAt.toIso8601String()}');
    buf.writeln('**Status:** ${report.status.name}');
    buf.writeln();

    if (!report.hasRecommendations) {
      buf.writeln('## Result');
      buf.writeln();
      buf.writeln('> ⚠️ ${report.statusMessage}');
      buf.writeln();
      return buf.toString();
    }

    buf.writeln('## Overall Confidence');
    buf.writeln();
    buf.writeln(
        '**Score:** ${(report.overallConfidence.score * 100).toStringAsFixed(1)}%  ');
    buf.writeln('**Tier:** ${report.overallConfidence.tier.label}  ');
    buf.writeln(report.overallConfidence.explanation);
    buf.writeln();

    buf.writeln('## Student Summary');
    buf.writeln();
    buf.writeln('**Learning Style:** ${report.dominantLearningStyle}  ');
    buf.writeln(
        '**Personality Highlights:** ${report.personalityHighlights.join(", ")}');
    buf.writeln();

    buf.writeln('### Strengths');
    for (final s in report.globalStrengths) {
      buf.writeln('- $s');
    }
    buf.writeln();

    buf.writeln('### Areas to Develop');
    for (final w in report.globalWeaknesses) {
      buf.writeln('- $w');
    }
    buf.writeln();

    buf.writeln('## Top Recommended Majors');
    buf.writeln();

    for (final rec in report.recommendations) {
      buf.writeln('### ${rec.rank}. ${rec.majorName}');
      buf.writeln();
      buf.writeln(
          '| Field | Value |');
      buf.writeln('|---|---|');
      buf.writeln(
          '| Similarity Score | ${rec.similarityScore}/100 |');
      buf.writeln(
          '| Confidence | ${(rec.confidence.score * 100).toStringAsFixed(1)}% (${rec.confidence.tier.label}) |');
      buf.writeln('| Category | ${rec.category.name} |');
      buf.writeln();

      buf.writeln('**Why this major?**');
      buf.writeln();
      buf.writeln(rec.explanation);
      buf.writeln();

      if (rec.topStrengths.isNotEmpty) {
        buf.writeln('**Matching Dimensions:**');
        for (final s in rec.topStrengths) {
          buf.writeln('- ✅ $s');
        }
        buf.writeln();
      }

      if (rec.weakAreas.isNotEmpty) {
        buf.writeln('**Gaps:**');
        for (final w in rec.weakAreas) {
          buf.writeln('- ⚠️ $w');
        }
        buf.writeln();
      }

      if (rec.careerPaths.isNotEmpty) {
        buf.writeln('**Career Paths:**');
        for (final c in rec.careerPaths) {
          buf.writeln('- 💼 $c');
        }
        buf.writeln();
      }
    }

    buf.writeln('## Improvement Suggestions');
    buf.writeln();
    for (final sug in report.improvementSuggestions) {
      buf.writeln('### ${sug.title}');
      buf.writeln();
      buf.writeln(sug.suggestion);
      buf.writeln();
      buf.writeln('*${sug.rationale}*');
      buf.writeln();
    }

    buf.writeln('---');
    buf.writeln('*Generated by StuStep Academic Intelligence Engine (SAIE)*');

    return buf.toString();
  }

  // ── PDF-ready ─────────────────────────────────────────────────────────────

  /// Returns a flat [PdfReadyData] model for a PDF renderer.
  PdfReadyData toPdfReady(RecommendationReport report) {
    final stats = RecommendationStatistics.fromReport(report);

    return PdfReadyData(
      reportId: report.reportId,
      studentId: report.studentId,
      generatedAt: report.generatedAt.toIso8601String(),
      status: report.status.name,
      statusMessage: report.statusMessage,
      recommendations: report.recommendations
          .map((r) => {
                'rank': r.rank,
                'major_name': r.majorName,
                'similarity_score': r.similarityScore,
                'confidence_score': r.confidence.score,
                'confidence_label': r.confidence.tier.label,
                'explanation': r.explanation,
                'strengths': r.topStrengths,
                'gaps': r.weakAreas,
                'missing_skills': r.missingSkills,
                'career_paths': r.careerPaths,
              })
          .toList(),
      suggestions: report.improvementSuggestions
          .map((s) => {
                'title': s.title,
                'suggestion': s.suggestion,
                'rationale': s.rationale,
              })
          .toList(),
      globalStrengths: report.globalStrengths,
      globalWeaknesses: report.globalWeaknesses,
      dominantLearningStyle: report.dominantLearningStyle,
      personalityHighlights: report.personalityHighlights,
      statistics: stats.toJson(),
    );
  }
}
