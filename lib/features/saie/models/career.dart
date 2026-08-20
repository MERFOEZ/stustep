/// SAIE — Career Model
///
/// Represents a professional career path loaded from the knowledge base.
/// Careers are NEVER hardcoded. Add new careers by dropping JSON files
/// into `assets/knowledge/careers/` — no Dart code changes required.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Career
// ─────────────────────────────────────────────────────────────────────────────

/// A professional career path the SAIE may recommend to a student.
///
/// Each career carries domain metadata, skill requirements, personality
/// alignment data, and market information — all sourced from JSON.
final class Career extends Equatable {
  /// Unique domain identifier (e.g., `"career_software_engineer"`).
  final String id;

  /// Display name of this career.
  final String name;

  /// Arabic name, if applicable.
  final String? nameAr;

  /// Detailed description of this career and its day-to-day work.
  final String description;

  /// The primary work environment for this career.
  final CareerEnvironment environment;

  /// IDs of majors that most commonly lead to this career.
  final List<String> relatedMajorIds;

  /// IDs of skills required for this career.
  final List<String> requiredSkillIds;

  /// IDs of skills that are advantageous for this career.
  final List<String> preferredSkillIds;

  /// Personality dimension weights for career-fit scoring.
  /// Key: [PersonalityDimension.name], Value: importance weight in [0.0, 1.0].
  final Map<String, double> personalityWeights;

  /// Job market demand level in [0.0, 1.0].
  final double marketDemand;

  /// Expected salary range in USD-equivalent: [min, max].
  final List<int>? salaryRangeUsd;

  /// Typical years of experience before reaching senior level.
  final int? yearsToSenior;

  /// Tags for search and filtering.
  final List<String> tags;

  const Career({
    required this.id,
    required this.name,
    required this.description,
    required this.environment,
    required this.relatedMajorIds,
    required this.requiredSkillIds,
    this.nameAr,
    this.preferredSkillIds = const [],
    this.personalityWeights = const {},
    this.marketDemand = 0.5,
    this.salaryRangeUsd,
    this.yearsToSenior,
    this.tags = const [],
  });

  /// Creates a [Career] from a decoded JSON map.
  factory Career.fromJson(Map<String, dynamic> json) => Career(
    id: json['id'] as String,
    name: json['name'] as String,
    nameAr: json['name_ar'] as String?,
    description: json['description'] as String,
    environment: CareerEnvironment.values.byName(json['environment'] as String),
    relatedMajorIds: (json['related_major_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    requiredSkillIds: (json['required_skill_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    preferredSkillIds: (json['preferred_skill_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    personalityWeights:
        (json['personality_weights'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        const {},
    marketDemand: (json['market_demand'] as num?)?.toDouble() ?? 0.5,
    salaryRangeUsd: (json['salary_range_usd'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
    yearsToSenior: json['years_to_senior'] as int?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  /// Serializes this [Career] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameAr != null) 'name_ar': nameAr,
    'description': description,
    'environment': environment.name,
    'related_major_ids': relatedMajorIds,
    'required_skill_ids': requiredSkillIds,
    'preferred_skill_ids': preferredSkillIds,
    if (personalityWeights.isNotEmpty)
      'personality_weights': personalityWeights,
    'market_demand': marketDemand,
    if (salaryRangeUsd != null) 'salary_range_usd': salaryRangeUsd,
    if (yearsToSenior != null) 'years_to_senior': yearsToSenior,
    if (tags.isNotEmpty) 'tags': tags,
  };

  /// Returns a copy of this [Career] with specified fields replaced.
  Career copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    CareerEnvironment? environment,
    List<String>? relatedMajorIds,
    List<String>? requiredSkillIds,
    List<String>? preferredSkillIds,
    Map<String, double>? personalityWeights,
    double? marketDemand,
    List<int>? salaryRangeUsd,
    int? yearsToSenior,
    List<String>? tags,
  }) => Career(
    id: id ?? this.id,
    name: name ?? this.name,
    nameAr: nameAr ?? this.nameAr,
    description: description ?? this.description,
    environment: environment ?? this.environment,
    relatedMajorIds: relatedMajorIds ?? this.relatedMajorIds,
    requiredSkillIds: requiredSkillIds ?? this.requiredSkillIds,
    preferredSkillIds: preferredSkillIds ?? this.preferredSkillIds,
    personalityWeights: personalityWeights ?? this.personalityWeights,
    marketDemand: marketDemand ?? this.marketDemand,
    salaryRangeUsd: salaryRangeUsd ?? this.salaryRangeUsd,
    yearsToSenior: yearsToSenior ?? this.yearsToSenior,
    tags: tags ?? this.tags,
  );

  @override
  List<Object?> get props => [id, name, environment];

  @override
  String toString() =>
      'Career(id: $id, name: $name, env: ${environment.name})';
}
