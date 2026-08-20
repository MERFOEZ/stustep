/// SAIE — Skill Model
///
/// Represents a single measurable skill or competency within the
/// knowledge taxonomy. Loaded exclusively from JSON asset files.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Skill
// ─────────────────────────────────────────────────────────────────────────────

/// An atomic, measurable competency used to match students to majors and careers.
///
/// Skills are loaded from `assets/knowledge/skills/` and are never hardcoded.
/// A skill may be technical (e.g., "Linear Algebra") or soft (e.g., "Empathy").
final class Skill extends Equatable {
  /// Unique identifier for this skill (e.g., `"skill_linear_algebra"`).
  final String id;

  /// Human-readable name of the skill.
  final String name;

  /// Detailed description of what this skill entails.
  final String description;

  /// Whether this is a technical/hard skill (`true`) or soft skill (`false`).
  final bool isTechnical;

  /// IDs of related skills (for graph-based reasoning).
  final List<String> relatedSkillIds;

  /// Optional tags for search and filtering.
  final List<String> tags;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.isTechnical,
    this.relatedSkillIds = const [],
    this.tags = const [],
  });

  /// Creates a [Skill] from a decoded JSON map.
  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    isTechnical: json['is_technical'] as bool? ?? false,
    relatedSkillIds: (json['related_skill_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  /// Serializes this [Skill] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'is_technical': isTechnical,
    'related_skill_ids': relatedSkillIds,
    'tags': tags,
  };

  /// Returns a copy of this [Skill] with specified fields replaced.
  Skill copyWith({
    String? id,
    String? name,
    String? description,
    bool? isTechnical,
    List<String>? relatedSkillIds,
    List<String>? tags,
  }) => Skill(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    isTechnical: isTechnical ?? this.isTechnical,
    relatedSkillIds: relatedSkillIds ?? this.relatedSkillIds,
    tags: tags ?? this.tags,
  );

  @override
  List<Object?> get props => [id, name, description, isTechnical];

  @override
  String toString() => 'Skill(id: $id, name: $name, technical: $isTechnical)';
}
