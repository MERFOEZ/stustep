/// SAIE — AssessmentCompletion
///
/// Evaluates whether the adaptive assessment should stop.
/// Never terminates after a fixed number of questions.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/assessment/coverage_engine.dart';
import 'package:stustep/features/saie/assessment/knowledge_gap_engine.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CompletionDecision
// ─────────────────────────────────────────────────────────────────────────────

/// The reason the engine decided to stop or continue.
enum CompletionReason {
  /// All criteria met — assessment is complete.
  allCriteriaMet,

  /// Maximum question ceiling reached (safety stop).
  maximumQuestionsReached,

  /// No more questions available in the knowledge base pool.
  questionPoolExhausted,

  /// Assessment has not yet met completion criteria — continue.
  continueAssessment,
}

/// The outcome of a completion check.
final class CompletionDecision extends Equatable {
  /// True if the assessment should stop now.
  final bool shouldComplete;

  /// The reason for this decision.
  final CompletionReason reason;

  /// Coverage at decision time.
  final double coverageRatio;

  /// Overall confidence at decision time.
  final double confidence;

  /// Any unresolved gaps that prevented completion.
  final List<String> unresolvedGapKeys;

  /// Human-readable summary.
  final String summary;

  const CompletionDecision({
    required this.shouldComplete,
    required this.reason,
    required this.coverageRatio,
    required this.confidence,
    required this.unresolvedGapKeys,
    required this.summary,
  });

  factory CompletionDecision.fromJson(Map<String, dynamic> json) =>
      CompletionDecision(
        shouldComplete: json['should_complete'] as bool,
        reason: CompletionReason.values.byName(json['reason'] as String),
        coverageRatio: (json['coverage_ratio'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        unresolvedGapKeys:
            (json['unresolved_gap_keys'] as List<dynamic>).cast<String>(),
        summary: json['summary'] as String,
      );

  Map<String, dynamic> toJson() => {
    'should_complete': shouldComplete,
    'reason': reason.name,
    'coverage_ratio': coverageRatio,
    'confidence': confidence,
    'unresolved_gap_keys': unresolvedGapKeys,
    'summary': summary,
  };

  CompletionDecision copyWith({
    bool? shouldComplete,
    CompletionReason? reason,
    double? coverageRatio,
    double? confidence,
    List<String>? unresolvedGapKeys,
    String? summary,
  }) => CompletionDecision(
    shouldComplete: shouldComplete ?? this.shouldComplete,
    reason: reason ?? this.reason,
    coverageRatio: coverageRatio ?? this.coverageRatio,
    confidence: confidence ?? this.confidence,
    unresolvedGapKeys: unresolvedGapKeys ?? this.unresolvedGapKeys,
    summary: summary ?? this.summary,
  );

  @override
  List<Object?> get props => [shouldComplete, reason];
}

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentCompletion
// ─────────────────────────────────────────────────────────────────────────────

/// Evaluates adaptive completion criteria every time it is called.
final class AssessmentCompletion {
  const AssessmentCompletion();

  /// Evaluates whether the assessment should stop.
  CompletionDecision evaluate({
    required StudentCognitiveProfile profile,
    required CoverageReport coverageReport,
    required GapReport gapReport,
    required int questionsAsked,
    required int availableQuestions,
    required AssessmentConfiguration config,
  }) {
    final stats = profile.computeStatistics();
    final confidence = stats.overallConfidence;
    final coverage = coverageReport.overallCoverageRatio;

    // ── Gate 1: Minimum questions — never stop too early ────────────────
    if (questionsAsked < config.minimumQuestions) {
      return CompletionDecision(
        shouldComplete: false,
        reason: CompletionReason.continueAssessment,
        coverageRatio: coverage,
        confidence: confidence,
        unresolvedGapKeys: gapReport.allGapKeys,
        summary:
            'Too few questions asked ($questionsAsked < ${config.minimumQuestions}). Continuing.',
      );
    }

    // ── Gate 2: Maximum questions safety ceiling ─────────────────────────
    if (questionsAsked >= config.maximumQuestions) {
      return CompletionDecision(
        shouldComplete: true,
        reason: CompletionReason.maximumQuestionsReached,
        coverageRatio: coverage,
        confidence: confidence,
        unresolvedGapKeys: gapReport.allGapKeys,
        summary:
            'Maximum question limit reached (${config.maximumQuestions}). Stopping.',
      );
    }

    // ── Gate 3: Pool exhausted ───────────────────────────────────────────
    // IMPORTANT: Only fire this gate if at least one question has been
    // asked. An empty pool at session start means the knowledge base is
    // not loaded yet — that is NOT a "completed" condition.
    if (availableQuestions == 0 && questionsAsked > 0) {
      return CompletionDecision(
        shouldComplete: true,
        reason: CompletionReason.questionPoolExhausted,
        coverageRatio: coverage,
        confidence: confidence,
        unresolvedGapKeys: gapReport.allGapKeys,
        summary: 'No more questions available in the knowledge base.',
      );
    }

    // ── Gate 4: All adaptive criteria ───────────────────────────────────
    final coverageMet = coverage >= config.minimumCoverageRatio;
    final confidenceMet = confidence >= config.minimumCompletionConfidence;
    final noSignificantGaps = !gapReport.hasSignificantGaps;

    if (coverageMet && confidenceMet && noSignificantGaps) {
      return CompletionDecision(
        shouldComplete: true,
        reason: CompletionReason.allCriteriaMet,
        coverageRatio: coverage,
        confidence: confidence,
        unresolvedGapKeys: const [],
        summary:
            'All criteria met: coverage=${(coverage * 100).toStringAsFixed(1)}% '
            'confidence=${(confidence * 100).toStringAsFixed(1)}% '
            'gaps=none.',
      );
    }

    // ── Continue ─────────────────────────────────────────────────────────
    final reasons = <String>[];
    if (!coverageMet) {
      reasons.add(
        'coverage ${(coverage * 100).toStringAsFixed(1)}% '
        '< ${(config.minimumCoverageRatio * 100).toStringAsFixed(0)}%',
      );
    }
    if (!confidenceMet) {
      reasons.add(
        'confidence ${(confidence * 100).toStringAsFixed(1)}% '
        '< ${(config.minimumCompletionConfidence * 100).toStringAsFixed(0)}%',
      );
    }
    if (!noSignificantGaps) {
      reasons.add('${gapReport.gaps.length} knowledge gap(s) remain');
    }

    return CompletionDecision(
      shouldComplete: false,
      reason: CompletionReason.continueAssessment,
      coverageRatio: coverage,
      confidence: confidence,
      unresolvedGapKeys: gapReport.allGapKeys,
      summary: 'Continuing — ${reasons.join(", ")}.',
    );
  }
}
