/// SAIE — AssessmentProgress
///
/// Tracks real-time progress metrics for the running assessment.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentProgress
// ─────────────────────────────────────────────────────────────────────────────

/// Real-time progress metrics for an ongoing assessment.
final class AssessmentProgress extends Equatable {
  /// Total questions asked so far.
  final int questionsAsked;

  /// Questions answered (not skipped).
  final int questionsAnswered;

  /// Questions explicitly skipped.
  final int questionsSkipped;

  /// Clarification exchanges (student asked a question back).
  final int clarificationCount;

  /// Times the student went off-topic or conversation was interrupted.
  final int interruptionCount;

  /// Current overall coverage ratio [0.0, 1.0].
  final double coverageRatio;

  /// Current overall confidence [0.0, 1.0].
  final double overallConfidence;

  /// Estimated number of questions remaining.
  final int estimatedRemainingQuestions;

  /// Average quality score of all accepted answers [0.0, 100.0].
  final double averageAnswerQuality;

  /// Average evidence strength of all accepted answers [0.0, 1.0].
  final double averageEvidenceStrength;

  /// UTC timestamp of the last update.
  final DateTime updatedAt;

  const AssessmentProgress({
    required this.questionsAsked,
    required this.questionsAnswered,
    required this.questionsSkipped,
    required this.clarificationCount,
    required this.interruptionCount,
    required this.coverageRatio,
    required this.overallConfidence,
    required this.estimatedRemainingQuestions,
    required this.averageAnswerQuality,
    required this.averageEvidenceStrength,
    required this.updatedAt,
  });

  factory AssessmentProgress.initial() => AssessmentProgress(
    questionsAsked: 0,
    questionsAnswered: 0,
    questionsSkipped: 0,
    clarificationCount: 0,
    interruptionCount: 0,
    coverageRatio: 0.0,
    overallConfidence: 0.0,
    estimatedRemainingQuestions: 10,
    averageAnswerQuality: 0.0,
    averageEvidenceStrength: 0.0,
    updatedAt: DateTime.now().toUtc(),
  );

  /// Percentage of questions answered vs asked [0.0, 100.0].
  double get answeredPercent => questionsAsked == 0
      ? 0.0
      : (questionsAnswered / questionsAsked) * 100.0;

  /// Percentage of questions skipped vs asked [0.0, 100.0].
  double get skippedPercent => questionsAsked == 0
      ? 0.0
      : (questionsSkipped / questionsAsked) * 100.0;

  factory AssessmentProgress.fromJson(Map<String, dynamic> json) =>
      AssessmentProgress(
        questionsAsked: json['questions_asked'] as int,
        questionsAnswered: json['questions_answered'] as int,
        questionsSkipped: json['questions_skipped'] as int,
        clarificationCount: json['clarification_count'] as int,
        interruptionCount: json['interruption_count'] as int,
        coverageRatio: (json['coverage_ratio'] as num).toDouble(),
        overallConfidence: (json['overall_confidence'] as num).toDouble(),
        estimatedRemainingQuestions:
            json['estimated_remaining_questions'] as int,
        averageAnswerQuality:
            (json['average_answer_quality'] as num).toDouble(),
        averageEvidenceStrength:
            (json['average_evidence_strength'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'questions_asked': questionsAsked,
    'questions_answered': questionsAnswered,
    'questions_skipped': questionsSkipped,
    'clarification_count': clarificationCount,
    'interruption_count': interruptionCount,
    'coverage_ratio': coverageRatio,
    'overall_confidence': overallConfidence,
    'estimated_remaining_questions': estimatedRemainingQuestions,
    'average_answer_quality': averageAnswerQuality,
    'average_evidence_strength': averageEvidenceStrength,
    'updated_at': updatedAt.toIso8601String(),
  };

  AssessmentProgress copyWith({
    int? questionsAsked,
    int? questionsAnswered,
    int? questionsSkipped,
    int? clarificationCount,
    int? interruptionCount,
    double? coverageRatio,
    double? overallConfidence,
    int? estimatedRemainingQuestions,
    double? averageAnswerQuality,
    double? averageEvidenceStrength,
    DateTime? updatedAt,
  }) => AssessmentProgress(
    questionsAsked: questionsAsked ?? this.questionsAsked,
    questionsAnswered: questionsAnswered ?? this.questionsAnswered,
    questionsSkipped: questionsSkipped ?? this.questionsSkipped,
    clarificationCount: clarificationCount ?? this.clarificationCount,
    interruptionCount: interruptionCount ?? this.interruptionCount,
    coverageRatio: coverageRatio ?? this.coverageRatio,
    overallConfidence: overallConfidence ?? this.overallConfidence,
    estimatedRemainingQuestions:
        estimatedRemainingQuestions ?? this.estimatedRemainingQuestions,
    averageAnswerQuality: averageAnswerQuality ?? this.averageAnswerQuality,
    averageEvidenceStrength:
        averageEvidenceStrength ?? this.averageEvidenceStrength,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    questionsAsked,
    questionsAnswered,
    coverageRatio,
    overallConfidence,
  ];
}
