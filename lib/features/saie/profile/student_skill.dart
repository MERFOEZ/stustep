/// SAIE — StudentSkill
///
/// Represents a single skill the engine has inferred the student possesses
/// or lacks. Skill scores evolve as evidence accumulates.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SkillProficiency
// ─────────────────────────────────────────────────────────────────────────────

/// The inferred proficiency level for a student skill.
enum SkillProficiency {
  /// No evidence of this skill.
  none,

  /// Beginner-level understanding or exposure.
  beginner,

  /// Functional working knowledge.
  intermediate,

  /// Advanced mastery.
  advanced,

  /// Expert-level or beyond typical curriculum.
  expert,
}

extension SkillProficiencyX on SkillProficiency {
  static SkillProficiency fromScore(double score) {
    if (score < 0.1) return SkillProficiency.none;
    if (score < 0.35) return SkillProficiency.beginner;
    if (score < 0.60) return SkillProficiency.intermediate;
    if (score < 0.85) return SkillProficiency.advanced;
    return SkillProficiency.expert;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentSkill
// ─────────────────────────────────────────────────────────────────────────────

/// An inferred skill with full evidence tracking.
final class StudentSkill extends Equatable {
  /// Matches a skill ID in the knowledge base (e.g., `"skill_logical_reasoning"`).
  final String skillId;

  /// Human-readable label.
  final String label;

  /// Whether this is a technical/hard skill.
  final bool isTechnical;

  /// The underlying tracked dimension for scoring this skill.
  final CognitiveDimension dimension;

  /// Whether this skill was self-reported (vs. engine-inferred).
  final bool isSelfReported;

  /// UTC timestamp when this skill was first added to the profile.
  final DateTime addedAt;

  const StudentSkill({
    required this.skillId,
    required this.label,
    required this.isTechnical,
    required this.dimension,
    required this.addedAt,
    this.isSelfReported = false,
  });

  factory StudentSkill.initial({
    required String skillId,
    required String label,
    required bool isTechnical,
    bool isSelfReported = false,
    double initialScore = 0.0,
  }) {
    final now = DateTime.now().toUtc();
    return StudentSkill(
      skillId: skillId,
      label: label,
      isTechnical: isTechnical,
      dimension: CognitiveDimension.initial(key: skillId, label: label)
          .copyWith(score: initialScore),
      addedAt: now,
      isSelfReported: isSelfReported,
    );
  }

  factory StudentSkill.fromJson(Map<String, dynamic> json) => StudentSkill(
    skillId: json['skill_id'] as String,
    label: json['label'] as String,
    isTechnical: json['is_technical'] as bool,
    dimension: CognitiveDimension.fromJson(
      json['dimension'] as Map<String, dynamic>,
    ),
    isSelfReported: json['is_self_reported'] as bool? ?? false,
    addedAt: DateTime.parse(json['added_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'skill_id': skillId,
    'label': label,
    'is_technical': isTechnical,
    'dimension': dimension.toJson(),
    'is_self_reported': isSelfReported,
    'added_at': addedAt.toIso8601String(),
  };

  StudentSkill copyWith({
    String? skillId,
    String? label,
    bool? isTechnical,
    CognitiveDimension? dimension,
    bool? isSelfReported,
    DateTime? addedAt,
  }) => StudentSkill(
    skillId: skillId ?? this.skillId,
    label: label ?? this.label,
    isTechnical: isTechnical ?? this.isTechnical,
    dimension: dimension ?? this.dimension,
    isSelfReported: isSelfReported ?? this.isSelfReported,
    addedAt: addedAt ?? this.addedAt,
  );

  double get score => dimension.score;
  double get confidence => dimension.confidence;

  /// The discretized proficiency level derived from [score].
  SkillProficiency get proficiency =>
      SkillProficiencyX.fromScore(dimension.score);

  @override
  List<Object?> get props => [skillId, isTechnical, dimension.score];

  @override
  String toString() =>
      'StudentSkill(id: $skillId, proficiency: ${proficiency.name}, '
      'score: ${score.toStringAsFixed(2)})';
}
