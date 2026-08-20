/// SAIE — MajorScore
///
/// The complete evaluation result for a single major against a student profile.
/// Every field is populated — nothing is a guess.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimensionContribution
// ─────────────────────────────────────────────────────────────────────────────

/// How a single cognitive dimension contributed to the major's final score.
final class DimensionContribution extends Equatable {
  /// The dimension key (e.g., `'mathematics'`).
  final String dimensionKey;

  /// Human-readable label.
  final String label;

  /// Student's score for this dimension [0.0, 1.0].
  final double studentScore;

  /// Major's expected score for this dimension [0.0, 1.0].
  final double majorExpectation;

  /// The weight this dimension carries in the overall computation [0.0, 1.0].
  final double weight;

  /// Weighted contribution to the total score (0–100 scale).
  final double weightedContribution;

  /// Whether the student met the major's expectation for this dimension.
  final bool met;

  const DimensionContribution({
    required this.dimensionKey,
    required this.label,
    required this.studentScore,
    required this.majorExpectation,
    required this.weight,
    required this.weightedContribution,
    required this.met,
  });

  factory DimensionContribution.fromJson(Map<String, dynamic> json) =>
      DimensionContribution(
        dimensionKey: json['dimension_key'] as String,
        label: json['label'] as String,
        studentScore: (json['student_score'] as num).toDouble(),
        majorExpectation: (json['major_expectation'] as num).toDouble(),
        weight: (json['weight'] as num).toDouble(),
        weightedContribution:
            (json['weighted_contribution'] as num).toDouble(),
        met: json['met'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'dimension_key': dimensionKey,
    'label': label,
    'student_score': studentScore,
    'major_expectation': majorExpectation,
    'weight': weight,
    'weighted_contribution': weightedContribution,
    'met': met,
  };

  DimensionContribution copyWith({
    String? dimensionKey,
    String? label,
    double? studentScore,
    double? majorExpectation,
    double? weight,
    double? weightedContribution,
    bool? met,
  }) => DimensionContribution(
    dimensionKey: dimensionKey ?? this.dimensionKey,
    label: label ?? this.label,
    studentScore: studentScore ?? this.studentScore,
    majorExpectation: majorExpectation ?? this.majorExpectation,
    weight: weight ?? this.weight,
    weightedContribution: weightedContribution ?? this.weightedContribution,
    met: met ?? this.met,
  );

  @override
  List<Object?> get props => [dimensionKey, studentScore, majorExpectation, weight];
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorScore
// ─────────────────────────────────────────────────────────────────────────────

/// Complete scored evaluation of a single major against a student profile.
final class MajorScore extends Equatable {
  /// The major ID being scored.
  final String majorId;

  /// The major name (denormalised for convenience).
  final String majorName;

  /// Arabic name if available.
  final String? majorNameAr;

  /// The major's category.
  final MajorCategory category;

  /// Final composite similarity score [0, 100].
  final int similarityScore;

  /// Dimension-level breakdown of the score.
  final List<DimensionContribution> contributions;

  /// Dimension keys where the student exceeded expectations.
  final List<String> matchedDimensions;

  /// Dimension keys where the student fell short of expectations.
  final List<String> unmatchedDimensions;

  /// Top strengths relevant to this major.
  final List<String> topStrengths;

  /// Missing skills the student should develop for this major.
  final List<String> missingSkills;

  /// Weak dimension areas relative to what this major requires.
  final List<String> weakAreas;

  /// Engine's confidence in this score based on evidence quality [0.0, 1.0].
  final double confidence;

  /// Number of evidence records that contributed to this score.
  final int evidenceUsed;

  /// Personality fit score [0.0, 1.0].
  final double personalityFit;

  /// Learning style fit score [0.0, 1.0].
  final double learningStyleFit;

  /// Whether this major had a market demand boost applied.
  final bool marketDemandBoosted;

  /// Explanation of why this score was produced.
  final String explanation;

  const MajorScore({
    required this.majorId,
    required this.majorName,
    required this.category,
    required this.similarityScore,
    required this.contributions,
    required this.matchedDimensions,
    required this.unmatchedDimensions,
    required this.topStrengths,
    required this.missingSkills,
    required this.weakAreas,
    required this.confidence,
    required this.evidenceUsed,
    required this.personalityFit,
    required this.learningStyleFit,
    required this.marketDemandBoosted,
    required this.explanation,
    this.majorNameAr,
  });

  factory MajorScore.fromJson(Map<String, dynamic> json) => MajorScore(
    majorId: json['major_id'] as String,
    majorName: json['major_name'] as String,
    majorNameAr: json['major_name_ar'] as String?,
    category: MajorCategory.values.byName(json['category'] as String),
    similarityScore: json['similarity_score'] as int,
    contributions: (json['contributions'] as List<dynamic>)
        .map((e) =>
            DimensionContribution.fromJson(e as Map<String, dynamic>))
        .toList(),
    matchedDimensions:
        (json['matched_dimensions'] as List<dynamic>).cast<String>(),
    unmatchedDimensions:
        (json['unmatched_dimensions'] as List<dynamic>).cast<String>(),
    topStrengths: (json['top_strengths'] as List<dynamic>).cast<String>(),
    missingSkills: (json['missing_skills'] as List<dynamic>).cast<String>(),
    weakAreas: (json['weak_areas'] as List<dynamic>).cast<String>(),
    confidence: (json['confidence'] as num).toDouble(),
    evidenceUsed: json['evidence_used'] as int,
    personalityFit: (json['personality_fit'] as num).toDouble(),
    learningStyleFit: (json['learning_style_fit'] as num).toDouble(),
    marketDemandBoosted: json['market_demand_boosted'] as bool,
    explanation: json['explanation'] as String,
  );

  Map<String, dynamic> toJson() => {
    'major_id': majorId,
    'major_name': majorName,
    if (majorNameAr != null) 'major_name_ar': majorNameAr,
    'category': category.name,
    'similarity_score': similarityScore,
    'contributions': contributions.map((c) => c.toJson()).toList(),
    'matched_dimensions': matchedDimensions,
    'unmatched_dimensions': unmatchedDimensions,
    'top_strengths': topStrengths,
    'missing_skills': missingSkills,
    'weak_areas': weakAreas,
    'confidence': confidence,
    'evidence_used': evidenceUsed,
    'personality_fit': personalityFit,
    'learning_style_fit': learningStyleFit,
    'market_demand_boosted': marketDemandBoosted,
    'explanation': explanation,
  };

  MajorScore copyWith({
    String? majorId,
    String? majorName,
    String? majorNameAr,
    MajorCategory? category,
    int? similarityScore,
    List<DimensionContribution>? contributions,
    List<String>? matchedDimensions,
    List<String>? unmatchedDimensions,
    List<String>? topStrengths,
    List<String>? missingSkills,
    List<String>? weakAreas,
    double? confidence,
    int? evidenceUsed,
    double? personalityFit,
    double? learningStyleFit,
    bool? marketDemandBoosted,
    String? explanation,
  }) => MajorScore(
    majorId: majorId ?? this.majorId,
    majorName: majorName ?? this.majorName,
    majorNameAr: majorNameAr ?? this.majorNameAr,
    category: category ?? this.category,
    similarityScore: similarityScore ?? this.similarityScore,
    contributions: contributions ?? this.contributions,
    matchedDimensions: matchedDimensions ?? this.matchedDimensions,
    unmatchedDimensions: unmatchedDimensions ?? this.unmatchedDimensions,
    topStrengths: topStrengths ?? this.topStrengths,
    missingSkills: missingSkills ?? this.missingSkills,
    weakAreas: weakAreas ?? this.weakAreas,
    confidence: confidence ?? this.confidence,
    evidenceUsed: evidenceUsed ?? this.evidenceUsed,
    personalityFit: personalityFit ?? this.personalityFit,
    learningStyleFit: learningStyleFit ?? this.learningStyleFit,
    marketDemandBoosted: marketDemandBoosted ?? this.marketDemandBoosted,
    explanation: explanation ?? this.explanation,
  );

  @override
  List<Object?> get props => [majorId, similarityScore, confidence];

  @override
  String toString() =>
      'MajorScore(id: $majorId, score: $similarityScore, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}
