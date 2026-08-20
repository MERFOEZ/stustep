/// SAIE — AssessmentGoal Model
///
/// Represents the explicit learning objective for a single assessment session.
/// The engine uses the [AssessmentGoal] to constrain question selection and
/// tailor the synthesis logic toward the student's stated purpose.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentGoal
// ─────────────────────────────────────────────────────────────────────────────

/// Defines the purpose and scope of a single SAIE assessment session.
final class AssessmentGoal extends Equatable {
  /// Unique identifier for this goal instance.
  final String id;

  /// The primary type of goal being pursued.
  final AssessmentGoalType type;

  /// Optional IDs of specific domains (majors/careers) to focus on.
  /// When empty, the engine performs broad exploration.
  final List<String> focusDomainIds;

  /// Optional free-text description of what the student hopes to achieve.
  final String? studentStatement;

  /// Maximum number of questions the engine may ask to achieve this goal.
  final int? maxQuestions;

  /// UTC timestamp when this goal was set.
  final DateTime createdAt;

  const AssessmentGoal({
    required this.id,
    required this.type,
    required this.createdAt,
    this.focusDomainIds = const [],
    this.studentStatement,
    this.maxQuestions,
  });

  /// Creates an [AssessmentGoal] from a decoded JSON map.
  factory AssessmentGoal.fromJson(Map<String, dynamic> json) => AssessmentGoal(
    id: json['id'] as String,
    type: AssessmentGoalType.values.byName(json['type'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    focusDomainIds: (json['focus_domain_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    studentStatement: json['student_statement'] as String?,
    maxQuestions: json['max_questions'] as int?,
  );

  /// Serializes this [AssessmentGoal] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'created_at': createdAt.toIso8601String(),
    'focus_domain_ids': focusDomainIds,
    if (studentStatement != null) 'student_statement': studentStatement,
    if (maxQuestions != null) 'max_questions': maxQuestions,
  };

  /// Returns a copy of this [AssessmentGoal] with specified fields replaced.
  AssessmentGoal copyWith({
    String? id,
    AssessmentGoalType? type,
    DateTime? createdAt,
    List<String>? focusDomainIds,
    String? studentStatement,
    int? maxQuestions,
  }) => AssessmentGoal(
    id: id ?? this.id,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    focusDomainIds: focusDomainIds ?? this.focusDomainIds,
    studentStatement: studentStatement ?? this.studentStatement,
    maxQuestions: maxQuestions ?? this.maxQuestions,
  );

  @override
  List<Object?> get props => [id, type];

  @override
  String toString() =>
      'AssessmentGoal(id: $id, type: ${type.name})';
}
