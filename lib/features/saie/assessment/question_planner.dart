/// SAIE — QuestionPlanner
///
/// Evaluates candidate questions and selects the one with the highest
/// estimated value. Combines information gain, confidence gain, evidence gain,
/// and redundancy penalty.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/assessment/coverage_engine.dart';
import 'package:stustep/features/saie/assessment/knowledge_gap_engine.dart';
import 'package:stustep/features/saie/assessment/question_history.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionValue
// ─────────────────────────────────────────────────────────────────────────────

/// The computed value of a candidate question.
final class QuestionValue extends Equatable {
  final Question question;
  final double totalValue;
  final double infoGain;
  final double confidenceGain;
  final double evidenceGain;
  final double redundancyPenalty;
  final String valuationReason;

  const QuestionValue({
    required this.question,
    required this.totalValue,
    required this.infoGain,
    required this.confidenceGain,
    required this.evidenceGain,
    required this.redundancyPenalty,
    required this.valuationReason,
  });

  factory QuestionValue.fromJson(Map<String, dynamic> json) => QuestionValue(
    question: Question.fromJson(json['question'] as Map<String, dynamic>),
    totalValue: (json['total_value'] as num).toDouble(),
    infoGain: (json['info_gain'] as num).toDouble(),
    confidenceGain: (json['confidence_gain'] as num).toDouble(),
    evidenceGain: (json['evidence_gain'] as num).toDouble(),
    redundancyPenalty: (json['redundancy_penalty'] as num).toDouble(),
    valuationReason: json['valuation_reason'] as String,
  );

  Map<String, dynamic> toJson() => {
    'question': question.toJson(),
    'total_value': totalValue,
    'info_gain': infoGain,
    'confidence_gain': confidenceGain,
    'evidence_gain': evidenceGain,
    'redundancy_penalty': redundancyPenalty,
    'valuation_reason': valuationReason,
  };

  QuestionValue copyWith({
    Question? question,
    double? totalValue,
    double? infoGain,
    double? confidenceGain,
    double? evidenceGain,
    double? redundancyPenalty,
    String? valuationReason,
  }) => QuestionValue(
    question: question ?? this.question,
    totalValue: totalValue ?? this.totalValue,
    infoGain: infoGain ?? this.infoGain,
    confidenceGain: confidenceGain ?? this.confidenceGain,
    evidenceGain: evidenceGain ?? this.evidenceGain,
    redundancyPenalty: redundancyPenalty ?? this.redundancyPenalty,
    valuationReason: valuationReason ?? this.valuationReason,
  );

  @override
  List<Object?> get props => [question.id, totalValue];
}

// ─────────────────────────────────────────────────────────────────────────────
// QuestionPlanner
// ─────────────────────────────────────────────────────────────────────────────

/// Evaluates candidate questions and selects the highest-value one.
final class QuestionPlanner {
  const QuestionPlanner();

  /// Returns the highest-value [QuestionValue] from [candidates].
  /// Returns null if [candidates] is empty.
  QuestionValue? plan({
    required List<Question> candidates,
    required StudentCognitiveProfile profile,
    required CoverageReport coverageReport,
    required GapReport gapReport,
    required QuestionHistory history,
    required AssessmentConfiguration config,
    required AssessmentPhase currentPhase,
  }) {
    if (candidates.isEmpty) return null;

    final uncoveredKeys = coverageReport.uncoveredKeys.toSet();
    final gapKeys = gapReport.allGapKeys.toSet();
    final urgentKeys = gapReport.highUrgencyKeys.toSet();
    final recentDomains = history.recentDomainKeys(config.maxConsecutiveSameDomain * 2).toSet();

    final evaluated = candidates
        .map((q) => _evaluate(
              question: q,
              profile: profile,
              uncoveredKeys: uncoveredKeys,
              gapKeys: gapKeys,
              urgentKeys: urgentKeys,
              recentDomains: recentDomains,
              history: history,
              config: config,
              currentPhase: currentPhase,
            ))
        .toList()
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));

    return evaluated.isEmpty ? null : evaluated.first;
  }

  // ─── Evaluation ──────────────────────────────────────────────────────────

  QuestionValue _evaluate({
    required Question question,
    required StudentCognitiveProfile profile,
    required Set<String> uncoveredKeys,
    required Set<String> gapKeys,
    required Set<String> urgentKeys,
    required Set<String> recentDomains,
    required QuestionHistory history,
    required AssessmentConfiguration config,
    required AssessmentPhase currentPhase,
  }) {
    final domains = question.targetDomainIds;

    // ── Information Gain — uncertainty-weighted ───────────────────────────
    //
    // The expected information gain of asking this question is:
    //
    //   gain(q) = Σ_d [ w(d) × (1 − confidence(d)) ] / |domains|
    //
    // where w(d) is the option-level evidence_weight for dimension d.
    //
    // This ensures:
    //   • Questions targeting low-confidence dimensions score higher.
    //   • A question covering one highly-uncertain dimension outscores
    //     one covering three near-certain dimensions.
    //   • The uncovered/gap binary flags remain as priority multipliers.
    //
    double infoGain = 0.0;
    if (domains.isNotEmpty) {
      for (final d in domains) {
        final uncertainty = 1.0 - profile.confidenceFor(d);
        final evidenceWeight = _evidenceWeightFor(d, question);
        var gain = evidenceWeight * uncertainty;

        if (urgentKeys.contains(d)) {
          gain *= 1.50;
        } else if (gapKeys.contains(d)) {
          gain *= 1.25;
        } else if (uncoveredKeys.contains(d)) {
          gain *= 1.10;
        }

        infoGain += gain;
      }
      infoGain = (infoGain / domains.length).clamp(0.0, 1.0);
    }

    // ── Confidence Gain ───────────────────────────────────────────────────
    // Average remaining uncertainty across all target dimensions.
    double confGain = 0.0;
    for (final d in domains) {
      confGain += (1.0 - profile.confidenceFor(d));
    }
    confGain =
        domains.isEmpty ? 0.0 : (confGain / domains.length).clamp(0.0, 1.0);

    // ── Evidence Gain ─────────────────────────────────────────────────────
    // Structural richness of the question type.
    // situationalJudgment scores highest: reveals reasoning style implicitly.
    final evidenceGain = switch (question.type) {
      QuestionType.situationalJudgment => 0.90,
      QuestionType.openEnded           => 0.85,
      QuestionType.ranking             => 0.70,
      QuestionType.multipleChoice      => 0.65,
      QuestionType.multiSelect         => 0.60,
      QuestionType.likertScale         => 0.50,
      QuestionType.trueFalse           => 0.35,
    };

    // ── Redundancy Penalty ────────────────────────────────────────────────
    final overlapCount = domains.where(recentDomains.contains).length;
    final redundancy = domains.isEmpty
        ? 0.0
        : (overlapCount / domains.length).clamp(0.0, 1.0);

    // Phase bonus — increased from 0.15 to 0.20 to better respect
    // question-design intent when information gains are close.
    final phaseBonus = question.targetPhase == currentPhase ? 0.20 : 0.0;

    // ── Total Value ───────────────────────────────────────────────────────
    final total = (infoGain * config.infoGainWeight +
            confGain * config.confidenceGainWeight +
            evidenceGain * config.evidenceGainWeight -
            redundancy * config.redundancyPenalty +
            phaseBonus)
        .clamp(0.0, 1.5);

    return QuestionValue(
      question: question,
      totalValue: total,
      infoGain: infoGain,
      confidenceGain: confGain,
      evidenceGain: evidenceGain,
      redundancyPenalty: redundancy,
      valuationReason:
          'infoGain=${infoGain.toStringAsFixed(2)} '
          'confGain=${confGain.toStringAsFixed(2)} '
          'evidenceGain=${evidenceGain.toStringAsFixed(2)} '
          'redundancy=${redundancy.toStringAsFixed(2)} '
          'phase=${phaseBonus > 0 ? "matched" : "no_match"}',
    );
  }

  // ── Evidence weight lookup ───────────────────────────────────────────────
  //
  // Returns the evidence_weight declared for dimension [domainKey] in the
  // question options. Falls back to a difficulty-based default when no
  // option explicitly targets the dimension.
  static double _evidenceWeightFor(String domainKey, Question question) {
    for (final opt in question.options) {
      if (opt.targetDomainIds.contains(domainKey)) {
        return opt.evidenceWeight;
      }
    }
    return switch (question.difficulty) {
      QuestionDifficulty.advanced     => 0.85,
      QuestionDifficulty.intermediate => 0.75,
      QuestionDifficulty.basic        => 0.65,
      QuestionDifficulty.adaptive     => 0.75, // treat as intermediate
    };
  }
}
