/// SAIE — StudentGoal
///
/// Represents an academic or career goal explicitly stated or inferred for
/// the student. Goals have priority, confidence, and evidence backing.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GoalType
// ─────────────────────────────────────────────────────────────────────────────

/// The nature of a student's goal.
enum GoalType {
  /// Selecting a university major.
  majorSelection,

  /// Choosing a graduate program or specialization.
  graduateSpecialization,

  /// Exploring career options in a domain.
  careerExploration,

  /// Developing a specific skill or competency.
  skillDevelopment,

  /// Checking readiness for a program or certification.
  readinessCheck,

  /// Improving academic performance in a subject area.
  academicImprovement,
}

// ─────────────────────────────────────────────────────────────────────────────
// GoalPriority
// ─────────────────────────────────────────────────────────────────────────────

/// The student's stated or inferred priority level for this goal.
enum GoalPriority { low, medium, high, critical }

// ─────────────────────────────────────────────────────────────────────────────
// StudentGoal
// ─────────────────────────────────────────────────────────────────────────────

/// A single goal with confidence and evidence tracking.
final class StudentGoal extends Equatable {
  /// Unique key for this goal (e.g., `"goal_major_cs"`).
  final String key;

  /// Human-readable description of the goal.
  final String description;

  /// The type of goal.
  final GoalType type;

  /// The student's priority for this goal.
  final GoalPriority priority;

  /// Whether this goal was explicitly stated by the student.
  final bool isExplicit;

  /// Optional domain ID this goal targets (e.g., `"major_computer_science"`).
  final String? targetDomainId;

  /// The underlying dimension tracking evidence-based confidence in this goal.
  final CognitiveDimension dimension;

  /// UTC timestamp when this goal was first identified.
  final DateTime identifiedAt;

  const StudentGoal({
    required this.key,
    required this.description,
    required this.type,
    required this.priority,
    required this.dimension,
    required this.identifiedAt,
    this.isExplicit = false,
    this.targetDomainId,
  });

  factory StudentGoal.initial({
    required String key,
    required String description,
    required GoalType type,
    required GoalPriority priority,
    bool isExplicit = false,
    String? targetDomainId,
  }) => StudentGoal(
    key: key,
    description: description,
    type: type,
    priority: priority,
    isExplicit: isExplicit,
    targetDomainId: targetDomainId,
    dimension: CognitiveDimension.initial(key: key, label: description),
    identifiedAt: DateTime.now().toUtc(),
  );

  factory StudentGoal.fromJson(Map<String, dynamic> json) => StudentGoal(
    key: json['key'] as String,
    description: json['description'] as String,
    type: GoalType.values.byName(json['type'] as String),
    priority: GoalPriority.values.byName(json['priority'] as String),
    isExplicit: json['is_explicit'] as bool? ?? false,
    targetDomainId: json['target_domain_id'] as String?,
    dimension: CognitiveDimension.fromJson(
      json['dimension'] as Map<String, dynamic>,
    ),
    identifiedAt: DateTime.parse(json['identified_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'description': description,
    'type': type.name,
    'priority': priority.name,
    'is_explicit': isExplicit,
    if (targetDomainId != null) 'target_domain_id': targetDomainId,
    'dimension': dimension.toJson(),
    'identified_at': identifiedAt.toIso8601String(),
  };

  StudentGoal copyWith({
    String? key,
    String? description,
    GoalType? type,
    GoalPriority? priority,
    bool? isExplicit,
    String? targetDomainId,
    CognitiveDimension? dimension,
    DateTime? identifiedAt,
  }) => StudentGoal(
    key: key ?? this.key,
    description: description ?? this.description,
    type: type ?? this.type,
    priority: priority ?? this.priority,
    isExplicit: isExplicit ?? this.isExplicit,
    targetDomainId: targetDomainId ?? this.targetDomainId,
    dimension: dimension ?? this.dimension,
    identifiedAt: identifiedAt ?? this.identifiedAt,
  );

  double get confidence => dimension.confidence;
  bool get isHighPriority =>
      priority == GoalPriority.high || priority == GoalPriority.critical;

  @override
  List<Object?> get props => [key, type, priority, isExplicit];

  @override
  String toString() =>
      'StudentGoal(key: $key, type: ${type.name}, priority: ${priority.name})';
}
