/// SAIE — RecommendationHistory
///
/// Append-only log of all recommendation reports generated for a student.
/// Enables comparison of how recommendations evolve over time.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoryEntry
// ─────────────────────────────────────────────────────────────────────────────

/// A single record in the recommendation history.
final class RecommendationHistoryEntry extends Equatable {
  final String reportId;
  final DateTime generatedAt;
  final ReportStatus status;
  final int recommendationsCount;
  final String? topMajorId;
  final String? topMajorName;
  final double topPickConfidence;
  final double overallConfidenceScore;

  const RecommendationHistoryEntry({
    required this.reportId,
    required this.generatedAt,
    required this.status,
    required this.recommendationsCount,
    required this.topPickConfidence,
    required this.overallConfidenceScore,
    this.topMajorId,
    this.topMajorName,
  });

  factory RecommendationHistoryEntry.fromReport(RecommendationReport report) =>
      RecommendationHistoryEntry(
        reportId: report.reportId,
        generatedAt: report.generatedAt,
        status: report.status,
        recommendationsCount: report.recommendations.length,
        topMajorId: report.topPick?.majorId,
        topMajorName: report.topPick?.majorName,
        topPickConfidence: report.topPick?.confidence.score ?? 0.0,
        overallConfidenceScore: report.overallConfidence.score,
      );

  factory RecommendationHistoryEntry.fromJson(Map<String, dynamic> json) =>
      RecommendationHistoryEntry(
        reportId: json['report_id'] as String,
        generatedAt: DateTime.parse(json['generated_at'] as String),
        status: ReportStatus.values.byName(json['status'] as String),
        recommendationsCount: json['recommendations_count'] as int,
        topMajorId: json['top_major_id'] as String?,
        topMajorName: json['top_major_name'] as String?,
        topPickConfidence: (json['top_pick_confidence'] as num).toDouble(),
        overallConfidenceScore:
            (json['overall_confidence_score'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'generated_at': generatedAt.toIso8601String(),
    'status': status.name,
    'recommendations_count': recommendationsCount,
    if (topMajorId != null) 'top_major_id': topMajorId,
    if (topMajorName != null) 'top_major_name': topMajorName,
    'top_pick_confidence': topPickConfidence,
    'overall_confidence_score': overallConfidenceScore,
  };

  @override
  List<Object?> get props => [reportId, generatedAt];
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Append-only log of all recommendation reports for a single student.
final class RecommendationHistory extends Equatable {
  final String studentId;
  final List<RecommendationHistoryEntry> entries;

  const RecommendationHistory({
    required this.studentId,
    this.entries = const [],
  });

  factory RecommendationHistory.empty(String studentId) =>
      RecommendationHistory(studentId: studentId);

  /// Appends [report] and returns a new immutable [RecommendationHistory].
  RecommendationHistory append(RecommendationReport report) =>
      RecommendationHistory(
        studentId: studentId,
        entries: [
          ...entries,
          RecommendationHistoryEntry.fromReport(report),
        ],
      );

  /// Returns the most recent entry, or null if empty.
  RecommendationHistoryEntry? get latest =>
      entries.isEmpty ? null : entries.last;

  /// Returns the most recent successfully produced report entry.
  RecommendationHistoryEntry? get latestSuccess => entries
      .reversed
      .where((e) => e.status == ReportStatus.ready)
      .cast<RecommendationHistoryEntry?>()
      .firstOrNull;

  /// True if the top recommended major has changed between the last two reports.
  bool get topPickChanged {
    if (entries.length < 2) return false;
    return entries[entries.length - 1].topMajorId !=
        entries[entries.length - 2].topMajorId;
  }

  factory RecommendationHistory.fromJson(Map<String, dynamic> json) =>
      RecommendationHistory(
        studentId: json['student_id'] as String,
        entries: (json['entries'] as List<dynamic>)
            .map((e) => RecommendationHistoryEntry.fromJson(
                  e as Map<String, dynamic>,
                ))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  RecommendationHistory copyWith({
    String? studentId,
    List<RecommendationHistoryEntry>? entries,
  }) => RecommendationHistory(
    studentId: studentId ?? this.studentId,
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [studentId, entries.length];
}
