/// SAIE — StudentCognitiveProfile Model
///
/// Represents the inferred cognitive and personality characteristics of a
/// student, built up progressively by the SAIE reasoning engine during
/// assessment. This is entirely derived — never self-reported directly.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/confidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StudentCognitiveProfile
// ─────────────────────────────────────────────────────────────────────────────

/// Engine-inferred cognitive and personality profile of a student.
///
/// All fields are derived from evidence signals — none are user-inputted
/// directly. The engine updates this profile after each reasoning cycle.
/// Confidence values track how certain the engine is about each inference.
final class StudentCognitiveProfile extends Equatable {
  /// ID of the [StudentProfile] this cognitive profile belongs to.
  final String studentId;

  /// The dominant inferred learning style.
  final LearningStyle? dominantLearningStyle;

  /// Confidence in the [dominantLearningStyle] inference.
  final Confidence learningStyleConfidence;

  /// Inferred personality dimension scores.
  /// Key: [PersonalityDimension.name], Value: score in [-1.0, 1.0].
  /// Positive = higher end of the dimension, negative = lower end.
  final Map<String, double> personalityScores;

  /// Confidence for each personality dimension inference.
  /// Key: [PersonalityDimension.name], Value: [Confidence].
  final Map<String, Confidence> personalityConfidences;

  /// Inferred interest affinity per academic category.
  /// Key: [MajorCategory.name], Value: affinity score in [0.0, 1.0].
  final Map<String, double> categoryAffinities;

  /// IDs of skills the engine has inferred the student possesses.
  final List<String> inferredSkillIds;

  /// IDs of skills the engine has inferred as gaps.
  final List<String> skillGapIds;

  /// Overall academic confidence of the student (self-efficacy proxy).
  final double? academicSelfEfficacy;

  /// UTC timestamp of the last engine update.
  final DateTime lastUpdated;

  const StudentCognitiveProfile({
    required this.studentId,
    required this.learningStyleConfidence,
    required this.personalityScores,
    required this.personalityConfidences,
    required this.categoryAffinities,
    required this.inferredSkillIds,
    required this.skillGapIds,
    required this.lastUpdated,
    this.dominantLearningStyle,
    this.academicSelfEfficacy,
  });

  /// Creates a blank [StudentCognitiveProfile] for a new student.
  factory StudentCognitiveProfile.initial({required String studentId}) =>
      StudentCognitiveProfile(
        studentId: studentId,
        dominantLearningStyle: null,
        learningStyleConfidence: Confidence.zero,
        personalityScores: const {},
        personalityConfidences: const {},
        categoryAffinities: const {},
        inferredSkillIds: const [],
        skillGapIds: const [],
        academicSelfEfficacy: null,
        lastUpdated: DateTime.now().toUtc(),
      );

  /// Creates a [StudentCognitiveProfile] from a decoded JSON map.
  factory StudentCognitiveProfile.fromJson(Map<String, dynamic> json) =>
      StudentCognitiveProfile(
        studentId: json['student_id'] as String,
        dominantLearningStyle: json['dominant_learning_style'] != null
            ? LearningStyle.values.byName(
                json['dominant_learning_style'] as String,
              )
            : null,
        learningStyleConfidence: Confidence.fromJson(
          json['learning_style_confidence'] as Map<String, dynamic>,
        ),
        personalityScores:
            (json['personality_scores'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const {},
        personalityConfidences:
            (json['personality_confidences'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                k,
                Confidence.fromJson(v as Map<String, dynamic>),
              ),
            ) ??
            const {},
        categoryAffinities:
            (json['category_affinities'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const {},
        inferredSkillIds:
            (json['inferred_skill_ids'] as List<dynamic>?)?.cast<String>() ??
                const [],
        skillGapIds:
            (json['skill_gap_ids'] as List<dynamic>?)?.cast<String>() ??
                const [],
        academicSelfEfficacy: (json['academic_self_efficacy'] as num?)
            ?.toDouble(),
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );

  /// Serializes this [StudentCognitiveProfile] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    if (dominantLearningStyle != null)
      'dominant_learning_style': dominantLearningStyle!.name,
    'learning_style_confidence': learningStyleConfidence.toJson(),
    if (personalityScores.isNotEmpty) 'personality_scores': personalityScores,
    if (personalityConfidences.isNotEmpty)
      'personality_confidences': personalityConfidences.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
    if (categoryAffinities.isNotEmpty)
      'category_affinities': categoryAffinities,
    if (inferredSkillIds.isNotEmpty) 'inferred_skill_ids': inferredSkillIds,
    if (skillGapIds.isNotEmpty) 'skill_gap_ids': skillGapIds,
    if (academicSelfEfficacy != null)
      'academic_self_efficacy': academicSelfEfficacy,
    'last_updated': lastUpdated.toIso8601String(),
  };

  /// Returns a copy with specified fields replaced.
  StudentCognitiveProfile copyWith({
    String? studentId,
    LearningStyle? dominantLearningStyle,
    Confidence? learningStyleConfidence,
    Map<String, double>? personalityScores,
    Map<String, Confidence>? personalityConfidences,
    Map<String, double>? categoryAffinities,
    List<String>? inferredSkillIds,
    List<String>? skillGapIds,
    double? academicSelfEfficacy,
    DateTime? lastUpdated,
  }) => StudentCognitiveProfile(
    studentId: studentId ?? this.studentId,
    dominantLearningStyle:
        dominantLearningStyle ?? this.dominantLearningStyle,
    learningStyleConfidence:
        learningStyleConfidence ?? this.learningStyleConfidence,
    personalityScores: personalityScores ?? this.personalityScores,
    personalityConfidences:
        personalityConfidences ?? this.personalityConfidences,
    categoryAffinities: categoryAffinities ?? this.categoryAffinities,
    inferredSkillIds: inferredSkillIds ?? this.inferredSkillIds,
    skillGapIds: skillGapIds ?? this.skillGapIds,
    academicSelfEfficacy: academicSelfEfficacy ?? this.academicSelfEfficacy,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  @override
  List<Object?> get props => [
    studentId,
    dominantLearningStyle,
    personalityScores,
    categoryAffinities,
    lastUpdated,
  ];

  @override
  String toString() =>
      'StudentCognitiveProfile(student: $studentId, '
      'style: ${dominantLearningStyle?.name ?? "unknown"})';
}
