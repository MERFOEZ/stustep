/// SAIE — Major Model
///
/// Represents an academic major loaded from the knowledge base.
/// Majors are NEVER hardcoded in Dart. The architecture supports adding
/// new majors by dropping a JSON file into `assets/knowledge/majors/`.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Major
// ─────────────────────────────────────────────────────────────────────────────

/// An academic major or program of study.
///
/// Each major carries:
/// - Domain metadata ([category], [name], [description])
/// - Required and preferred [skillIds] for alignment scoring
/// - Compatible [careerIds] for downstream career recommendation
/// - [personalityFit] weights for personality-alignment scoring
/// - [prerequisites] for readiness checking
final class Major extends Equatable {
  /// Unique domain identifier (e.g., `"major_computer_science"`).
  final String id;

  /// Official name of the major.
  final String name;

  /// Arabic name, if applicable.
  final String? nameAr;

  /// Detailed description of the major and its scope.
  final String description;

  /// High-level academic category this major belongs to.
  final MajorCategory category;

  /// IDs of skills that are required for success in this major.
  final List<String> requiredSkillIds;

  /// IDs of skills that are beneficial but not required.
  final List<String> preferredSkillIds;

  /// IDs of careers this major commonly leads to.
  final List<String> relatedCareerIds;

  /// Typical number of years to complete this major.
  final int durationYears;

  /// Personality dimension weights for fit scoring.
  /// Key: [PersonalityDimension.name], Value: importance weight in [0.0, 1.0].
  final Map<String, double> personalityWeights;

  /// Learning style affinities for this major.
  /// Key: [LearningStyle.name], Value: affinity score in [0.0, 1.0].
  final Map<String, double> learningStyleAffinities;

  /// Optional subject prerequisites (e.g., `["math", "physics"]`).
  final List<String> prerequisites;

  /// Job market demand level in [0.0, 1.0] (sourced from knowledge JSON).
  final double marketDemand;

  /// Expected salary range: [min, max] in USD-equivalent.
  final List<int>? salaryRangeUsd;

  /// Tags for additional search and filtering.
  final List<String> tags;

  const Major({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requiredSkillIds,
    this.nameAr,
    this.preferredSkillIds = const [],
    this.relatedCareerIds = const [],
    this.durationYears = 4,
    this.personalityWeights = const {},
    this.learningStyleAffinities = const {},
    this.prerequisites = const [],
    this.marketDemand = 0.5,
    this.salaryRangeUsd,
    this.tags = const [],
  });

  /// Creates a [Major] from a decoded JSON map.
  factory Major.fromJson(Map<String, dynamic> json) => Major(
    id: json['id'] as String,
    name: json['name'] as String,
    nameAr: json['name_ar'] as String?,
    description: json['description'] as String,
    category: MajorCategory.values.byName(json['category'] as String),
    requiredSkillIds: (json['required_skill_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    preferredSkillIds: (json['preferred_skill_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    relatedCareerIds: (json['related_career_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    durationYears: json['duration_years'] as int? ?? 4,
    personalityWeights:
        (json['personality_weights'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        const {},
    learningStyleAffinities:
        (json['learning_style_affinities'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        const {},
    prerequisites: (json['prerequisites'] as List<dynamic>?)?.cast<String>() ??
        const [],
    marketDemand: (json['market_demand'] as num?)?.toDouble() ?? 0.5,
    salaryRangeUsd: (json['salary_range_usd'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  /// Serializes this [Major] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameAr != null) 'name_ar': nameAr,
    'description': description,
    'category': category.name,
    'required_skill_ids': requiredSkillIds,
    'preferred_skill_ids': preferredSkillIds,
    'related_career_ids': relatedCareerIds,
    'duration_years': durationYears,
    if (personalityWeights.isNotEmpty)
      'personality_weights': personalityWeights,
    if (learningStyleAffinities.isNotEmpty)
      'learning_style_affinities': learningStyleAffinities,
    if (prerequisites.isNotEmpty) 'prerequisites': prerequisites,
    'market_demand': marketDemand,
    if (salaryRangeUsd != null) 'salary_range_usd': salaryRangeUsd,
    if (tags.isNotEmpty) 'tags': tags,
  };

  /// Returns a copy of this [Major] with specified fields replaced.
  Major copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    MajorCategory? category,
    List<String>? requiredSkillIds,
    List<String>? preferredSkillIds,
    List<String>? relatedCareerIds,
    int? durationYears,
    Map<String, double>? personalityWeights,
    Map<String, double>? learningStyleAffinities,
    List<String>? prerequisites,
    double? marketDemand,
    List<int>? salaryRangeUsd,
    List<String>? tags,
  }) => Major(
    id: id ?? this.id,
    name: name ?? this.name,
    nameAr: nameAr ?? this.nameAr,
    description: description ?? this.description,
    category: category ?? this.category,
    requiredSkillIds: requiredSkillIds ?? this.requiredSkillIds,
    preferredSkillIds: preferredSkillIds ?? this.preferredSkillIds,
    relatedCareerIds: relatedCareerIds ?? this.relatedCareerIds,
    durationYears: durationYears ?? this.durationYears,
    personalityWeights: personalityWeights ?? this.personalityWeights,
    learningStyleAffinities:
        learningStyleAffinities ?? this.learningStyleAffinities,
    prerequisites: prerequisites ?? this.prerequisites,
    marketDemand: marketDemand ?? this.marketDemand,
    salaryRangeUsd: salaryRangeUsd ?? this.salaryRangeUsd,
    tags: tags ?? this.tags,
  );

  @override
  List<Object?> get props => [id, name, category];

  @override
  String toString() => 'Major(id: $id, name: $name, category: ${category.name})';
}
