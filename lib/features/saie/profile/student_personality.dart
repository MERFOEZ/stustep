/// SAIE — StudentPersonality
///
/// Engine-inferred personality profile of the student.
/// Uses a multi-axis model covering Big Five traits plus contextual
/// academic dimensions.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PersonalityAxis
// ─────────────────────────────────────────────────────────────────────────────

/// The set of personality axes tracked by the SAIE engine.
enum PersonalityAxis {
  /// Curiosity, imagination, and openness to novel ideas.
  openness,

  /// Organization, goal-orientation, and self-discipline.
  conscientiousness,

  /// Social energy, assertiveness, and preference for group activity.
  extraversion,

  /// Empathy, cooperation, and trust toward others.
  agreeableness,

  /// Stress tolerance and emotional regulation.
  emotionalStability,

  /// Preference for structured planning (judging) vs. flexibility (perceiving).
  judgingVsPerceiving,

  /// Preference for logical analysis (thinking) vs. values (feeling).
  thinkingVsFeeling,

  /// Preference for concrete detail (sensing) vs. abstract concepts (intuition).
  sensingVsIntuition,
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentPersonality
// ─────────────────────────────────────────────────────────────────────────────

/// The full engine-inferred personality profile of a student.
///
/// Each [PersonalityAxis] is backed by its own [CognitiveDimension]
/// for full evidence tracking and trend analysis.
final class StudentPersonality extends Equatable {
  /// Map from [PersonalityAxis.name] → tracked [CognitiveDimension].
  final Map<String, CognitiveDimension> axes;

  /// UTC timestamp of the last update.
  final DateTime lastUpdated;

  const StudentPersonality({
    required this.axes,
    required this.lastUpdated,
  });

  /// Creates a zeroed personality profile with all axes initialized.
  factory StudentPersonality.initial() {
    final now = DateTime.now().toUtc();
    return StudentPersonality(
      axes: {
        for (final axis in PersonalityAxis.values)
          axis.name: CognitiveDimension.initial(
            key: axis.name,
            label: _axisLabel(axis),
          ),
      },
      lastUpdated: now,
    );
  }

  factory StudentPersonality.fromJson(Map<String, dynamic> json) =>
      StudentPersonality(
        axes: (json['axes'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            CognitiveDimension.fromJson(v as Map<String, dynamic>),
          ),
        ),
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );

  Map<String, dynamic> toJson() => {
    'axes': axes.map((k, v) => MapEntry(k, v.toJson())),
    'last_updated': lastUpdated.toIso8601String(),
  };

  StudentPersonality copyWith({
    Map<String, CognitiveDimension>? axes,
    DateTime? lastUpdated,
  }) => StudentPersonality(
    axes: axes ?? this.axes,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  /// Returns the [CognitiveDimension] for [axis].
  CognitiveDimension dimensionFor(PersonalityAxis axis) =>
      axes[axis.name] ??
      CognitiveDimension.initial(key: axis.name, label: _axisLabel(axis));

  /// Returns the score for [axis], or 0.0 if not yet assessed.
  double scoreFor(PersonalityAxis axis) => dimensionFor(axis).score;

  /// Returns a new [StudentPersonality] with [axis] dimension replaced.
  StudentPersonality withUpdatedAxis(
    PersonalityAxis axis,
    CognitiveDimension dimension,
  ) => copyWith(
    axes: {...axes, axis.name: dimension},
    lastUpdated: DateTime.now().toUtc(),
  );

  static String _axisLabel(PersonalityAxis axis) => switch (axis) {
    PersonalityAxis.openness => 'Openness',
    PersonalityAxis.conscientiousness => 'Conscientiousness',
    PersonalityAxis.extraversion => 'Extraversion',
    PersonalityAxis.agreeableness => 'Agreeableness',
    PersonalityAxis.emotionalStability => 'Emotional Stability',
    PersonalityAxis.judgingVsPerceiving => 'Judging vs Perceiving',
    PersonalityAxis.thinkingVsFeeling => 'Thinking vs Feeling',
    PersonalityAxis.sensingVsIntuition => 'Sensing vs Intuition',
  };

  @override
  List<Object?> get props => [axes, lastUpdated];
}
