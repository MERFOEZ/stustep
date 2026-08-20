/// SAIE — AssessmentStatistics
///
/// Generates statistical summaries of a completed or in-progress assessment.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/analysis/answer_history.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentStatistics
// ─────────────────────────────────────────────────────────────────────────────

/// Full statistical summary for an assessment session.
final class AssessmentStatistics extends Equatable {
  /// Coverage percentage [0.0, 100.0].
  final double coveragePercent;

  /// Overall confidence percentage [0.0, 100.0].
  final double confidencePercent;

  /// Percentage of questions answered vs. asked [0.0, 100.0].
  final double answeredPercent;

  /// Percentage of questions skipped vs. asked [0.0, 100.0].
  final double skippedPercent;

  /// Average score of all accepted answers [0.0, 100.0].
  final double averageAnswerQuality;

  /// Average evidence strength across accepted answers [0.0, 1.0].
  final double averageEvidenceStrength;

  /// Average information gain per question [0.0, 1.0].
  final double averageInformationGain;

  /// Total questions asked.
  final int totalQuestionsAsked;

  /// Total questions answered.
  final int totalQuestionsAnswered;

  /// Total questions skipped.
  final int totalQuestionsSkipped;

  /// Total evidence records collected.
  final int totalEvidenceCollected;

  /// Distribution of score bands.
  final Map<String, int> scoreBandDistribution;

  /// UTC timestamp when these statistics were computed.
  final DateTime computedAt;

  const AssessmentStatistics({
    required this.coveragePercent,
    required this.confidencePercent,
    required this.answeredPercent,
    required this.skippedPercent,
    required this.averageAnswerQuality,
    required this.averageEvidenceStrength,
    required this.averageInformationGain,
    required this.totalQuestionsAsked,
    required this.totalQuestionsAnswered,
    required this.totalQuestionsSkipped,
    required this.totalEvidenceCollected,
    required this.scoreBandDistribution,
    required this.computedAt,
  });

  factory AssessmentStatistics.fromJson(Map<String, dynamic> json) =>
      AssessmentStatistics(
        coveragePercent: (json['coverage_percent'] as num).toDouble(),
        confidencePercent: (json['confidence_percent'] as num).toDouble(),
        answeredPercent: (json['answered_percent'] as num).toDouble(),
        skippedPercent: (json['skipped_percent'] as num).toDouble(),
        averageAnswerQuality:
            (json['average_answer_quality'] as num).toDouble(),
        averageEvidenceStrength:
            (json['average_evidence_strength'] as num).toDouble(),
        averageInformationGain:
            (json['average_information_gain'] as num).toDouble(),
        totalQuestionsAsked: json['total_questions_asked'] as int,
        totalQuestionsAnswered: json['total_questions_answered'] as int,
        totalQuestionsSkipped: json['total_questions_skipped'] as int,
        totalEvidenceCollected: json['total_evidence_collected'] as int,
        scoreBandDistribution:
            (json['score_band_distribution'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        ),
        computedAt: DateTime.parse(json['computed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'coverage_percent': coveragePercent,
    'confidence_percent': confidencePercent,
    'answered_percent': answeredPercent,
    'skipped_percent': skippedPercent,
    'average_answer_quality': averageAnswerQuality,
    'average_evidence_strength': averageEvidenceStrength,
    'average_information_gain': averageInformationGain,
    'total_questions_asked': totalQuestionsAsked,
    'total_questions_answered': totalQuestionsAnswered,
    'total_questions_skipped': totalQuestionsSkipped,
    'total_evidence_collected': totalEvidenceCollected,
    'score_band_distribution': scoreBandDistribution,
    'computed_at': computedAt.toIso8601String(),
  };

  AssessmentStatistics copyWith({
    double? coveragePercent,
    double? confidencePercent,
    double? answeredPercent,
    double? skippedPercent,
    double? averageAnswerQuality,
    double? averageEvidenceStrength,
    double? averageInformationGain,
    int? totalQuestionsAsked,
    int? totalQuestionsAnswered,
    int? totalQuestionsSkipped,
    int? totalEvidenceCollected,
    Map<String, int>? scoreBandDistribution,
    DateTime? computedAt,
  }) => AssessmentStatistics(
    coveragePercent: coveragePercent ?? this.coveragePercent,
    confidencePercent: confidencePercent ?? this.confidencePercent,
    answeredPercent: answeredPercent ?? this.answeredPercent,
    skippedPercent: skippedPercent ?? this.skippedPercent,
    averageAnswerQuality: averageAnswerQuality ?? this.averageAnswerQuality,
    averageEvidenceStrength:
        averageEvidenceStrength ?? this.averageEvidenceStrength,
    averageInformationGain:
        averageInformationGain ?? this.averageInformationGain,
    totalQuestionsAsked: totalQuestionsAsked ?? this.totalQuestionsAsked,
    totalQuestionsAnswered:
        totalQuestionsAnswered ?? this.totalQuestionsAnswered,
    totalQuestionsSkipped:
        totalQuestionsSkipped ?? this.totalQuestionsSkipped,
    totalEvidenceCollected:
        totalEvidenceCollected ?? this.totalEvidenceCollected,
    scoreBandDistribution:
        scoreBandDistribution ?? this.scoreBandDistribution,
    computedAt: computedAt ?? this.computedAt,
  );

  @override
  List<Object?> get props => [
    coveragePercent,
    confidencePercent,
    totalQuestionsAsked,
    computedAt,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentStatisticsGenerator
// ─────────────────────────────────────────────────────────────────────────────

/// Generates [AssessmentStatistics] from [AssessmentProgress] + [AnswerHistory].
final class AssessmentStatisticsGenerator {
  const AssessmentStatisticsGenerator();

  AssessmentStatistics generate({
    required AssessmentProgress progress,
    required AnswerHistory answerHistory,
    required int totalEvidenceCollected,
  }) {
    final now = DateTime.now().toUtc();
    final entries = answerHistory.entries;

    // Average answer quality
    final avgQuality = entries.isEmpty
        ? 0.0
        : entries
                .map((e) => e.score.total.toDouble())
                .reduce((a, b) => a + b) /
            entries.length;

    // Average evidence strength (evidenceMultiplier proxy from score band)
    final avgEvidenceStrength = entries.isEmpty
        ? 0.0
        : entries
                .map((e) => e.score.band.evidenceMultiplier)
                .reduce((a, b) => a + b) /
            entries.length;

    // Score band distribution
    final bandDist = <String, int>{};
    for (final band in ScoreBand.values) {
      bandDist[band.name] = 0;
    }
    for (final entry in entries) {
      final key = entry.score.band.name;
      bandDist[key] = (bandDist[key] ?? 0) + 1;
    }

    // Average info gain approximation: proportion of non-invalid answers.
    final avgInfoGain = entries.isEmpty
        ? 0.0
        : entries.where((e) => e.score.band != ScoreBand.invalid).length /
            entries.length;

    return AssessmentStatistics(
      coveragePercent: progress.coverageRatio * 100.0,
      confidencePercent: progress.overallConfidence * 100.0,
      answeredPercent: progress.answeredPercent,
      skippedPercent: progress.skippedPercent,
      averageAnswerQuality: avgQuality,
      averageEvidenceStrength: avgEvidenceStrength,
      averageInformationGain: avgInfoGain,
      totalQuestionsAsked: progress.questionsAsked,
      totalQuestionsAnswered: progress.questionsAnswered,
      totalQuestionsSkipped: progress.questionsSkipped,
      totalEvidenceCollected: totalEvidenceCollected,
      scoreBandDistribution: bandDist,
      computedAt: now,
    );
  }
}
