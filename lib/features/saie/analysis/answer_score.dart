/// SAIE — AnswerScore
///
/// The final scored evaluation of a single student answer.
/// Produced by the [AnswerQualityEvaluator]. Downstream systems read the
/// [total] to decide how strongly to apply evidence to the profile.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScoreBand
// ─────────────────────────────────────────────────────────────────────────────

/// Interpretation band for an [AnswerScore.total].
enum ScoreBand {
  /// 0–20: Invalid — ignore answer, no profile update.
  invalid,

  /// 21–40: Weak — tiny profile update allowed.
  weak,

  /// 41–60: Acceptable — small profile update.
  acceptable,

  /// 61–80: Good — normal profile update.
  good,

  /// 81–100: Excellent — strong profile update.
  excellent,
}

extension ScoreBandX on ScoreBand {
  /// Returns the weight multiplier applied to evidence deltas.
  double get evidenceMultiplier => switch (this) {
    ScoreBand.invalid => 0.0,
    ScoreBand.weak => 0.10,
    ScoreBand.acceptable => 0.35,
    ScoreBand.good => 0.65,
    ScoreBand.excellent => 1.0,
  };

  /// Returns `true` if the answer should update the profile at all.
  bool get allowsProfileUpdate => this != ScoreBand.invalid;

  String get label => switch (this) {
    ScoreBand.invalid => 'Invalid',
    ScoreBand.weak => 'Weak',
    ScoreBand.acceptable => 'Acceptable',
    ScoreBand.good => 'Good',
    ScoreBand.excellent => 'Excellent',
  };

  static ScoreBand fromTotal(int total) {
    if (total <= 20) return ScoreBand.invalid;
    if (total <= 40) return ScoreBand.weak;
    if (total <= 60) return ScoreBand.acceptable;
    if (total <= 80) return ScoreBand.good;
    return ScoreBand.excellent;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerScore
// ─────────────────────────────────────────────────────────────────────────────

/// The complete quality evaluation of a single student answer.
///
/// [total] is in [0, 100]. Each dimension contributes a sub-score.
/// The [band] determines how aggressively evidence is applied to the profile.
final class AnswerScore extends Equatable {
  /// The question ID this score is for.
  final String questionId;

  /// The raw answer text that was scored.
  final String answerText;

  // ─── Sub-dimension scores (each 0–100) ───────────────────────────────────

  /// How relevant the answer is to the question asked.
  final int relevance;

  /// How complete the answer is (addresses all question aspects).
  final int completeness;

  /// How specific and concrete the answer is.
  final int specificity;

  /// How consistent the answer is with prior profile evidence.
  final int consistency;

  /// Engine's confidence that it understood the answer correctly.
  final int confidence;

  /// How much usable evidence the answer provides.
  final int evidenceStrength;

  /// Depth of reasoning shown in the answer.
  final int reasoningDepth;

  /// Information content relative to answer length.
  final int informationDensity;

  /// Whether the answer references context from the conversation.
  final int contextAwareness;

  /// Final composite score in [0, 100].
  final int total;

  /// The interpreted band for this score.
  final ScoreBand band;

  /// Human-readable explanation of the scoring decision.
  final String scoringReason;

  /// UTC timestamp when this score was computed.
  final DateTime scoredAt;

  const AnswerScore({
    required this.questionId,
    required this.answerText,
    required this.relevance,
    required this.completeness,
    required this.specificity,
    required this.consistency,
    required this.confidence,
    required this.evidenceStrength,
    required this.reasoningDepth,
    required this.informationDensity,
    required this.contextAwareness,
    required this.total,
    required this.band,
    required this.scoringReason,
    required this.scoredAt,
  });

  factory AnswerScore.fromJson(Map<String, dynamic> json) => AnswerScore(
    questionId: json['question_id'] as String,
    answerText: json['answer_text'] as String,
    relevance: json['relevance'] as int,
    completeness: json['completeness'] as int,
    specificity: json['specificity'] as int,
    consistency: json['consistency'] as int,
    confidence: json['confidence'] as int,
    evidenceStrength: json['evidence_strength'] as int,
    reasoningDepth: json['reasoning_depth'] as int,
    informationDensity: json['information_density'] as int,
    contextAwareness: json['context_awareness'] as int,
    total: json['total'] as int,
    band: ScoreBand.values.byName(json['band'] as String),
    scoringReason: json['scoring_reason'] as String,
    scoredAt: DateTime.parse(json['scored_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer_text': answerText,
    'relevance': relevance,
    'completeness': completeness,
    'specificity': specificity,
    'consistency': consistency,
    'confidence': confidence,
    'evidence_strength': evidenceStrength,
    'reasoning_depth': reasoningDepth,
    'information_density': informationDensity,
    'context_awareness': contextAwareness,
    'total': total,
    'band': band.name,
    'scoring_reason': scoringReason,
    'scored_at': scoredAt.toIso8601String(),
  };

  AnswerScore copyWith({
    String? questionId,
    String? answerText,
    int? relevance,
    int? completeness,
    int? specificity,
    int? consistency,
    int? confidence,
    int? evidenceStrength,
    int? reasoningDepth,
    int? informationDensity,
    int? contextAwareness,
    int? total,
    ScoreBand? band,
    String? scoringReason,
    DateTime? scoredAt,
  }) => AnswerScore(
    questionId: questionId ?? this.questionId,
    answerText: answerText ?? this.answerText,
    relevance: relevance ?? this.relevance,
    completeness: completeness ?? this.completeness,
    specificity: specificity ?? this.specificity,
    consistency: consistency ?? this.consistency,
    confidence: confidence ?? this.confidence,
    evidenceStrength: evidenceStrength ?? this.evidenceStrength,
    reasoningDepth: reasoningDepth ?? this.reasoningDepth,
    informationDensity: informationDensity ?? this.informationDensity,
    contextAwareness: contextAwareness ?? this.contextAwareness,
    total: total ?? this.total,
    band: band ?? this.band,
    scoringReason: scoringReason ?? this.scoringReason,
    scoredAt: scoredAt ?? this.scoredAt,
  );

  /// Returns `true` if this answer is allowed to update the profile.
  bool get allowsProfileUpdate => band.allowsProfileUpdate;

  /// Returns the weight multiplier to apply to evidence deltas.
  double get evidenceMultiplier => band.evidenceMultiplier;

  @override
  List<Object?> get props => [questionId, total, scoredAt];

  @override
  String toString() =>
      'AnswerScore(q: $questionId, total: $total, band: ${band.name})';
}
