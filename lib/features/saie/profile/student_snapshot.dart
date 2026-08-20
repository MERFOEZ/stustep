/// SAIE — StudentSnapshot
///
/// An immutable point-in-time snapshot of the student's complete cognitive
/// profile state. Generated on demand by the engine — never mutated after
/// creation. Used for rollback, comparison, and recommendation anchoring.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';
import 'package:stustep/features/saie/profile/learning_style.dart';
import 'package:stustep/features/saie/profile/profile_statistics.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';
import 'package:stustep/features/saie/profile/student_goal.dart';
import 'package:stustep/features/saie/profile/student_interest.dart';
import 'package:stustep/features/saie/profile/student_personality.dart';
import 'package:stustep/features/saie/profile/student_skill.dart';
import 'package:stustep/features/saie/profile/student_strength.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StudentSnapshot
// ─────────────────────────────────────────────────────────────────────────────

/// A frozen, immutable image of the student's cognitive profile at a specific
/// moment in time.
///
/// Snapshots are created:
/// - At the end of each assessment phase.
/// - Before every synthesis cycle.
/// - On session completion.
/// - On explicit engine request.
///
/// They are stored in [StudentHistory] as rollback anchors.
final class StudentSnapshot extends Equatable {
  /// Unique identifier for this snapshot.
  final String id;

  /// ID of the student this snapshot belongs to.
  final String studentId;

  /// ID of the session during which this snapshot was taken.
  final String sessionId;

  /// All core cognitive dimensions at snapshot time.
  /// Key: dimension key, Value: [CognitiveDimension].
  final Map<String, CognitiveDimension> dimensions;

  /// All interests at snapshot time.
  final List<StudentInterest> interests;

  /// All skills at snapshot time.
  final List<StudentSkill> skills;

  /// The personality profile at snapshot time.
  final StudentPersonality personality;

  /// The learning style profile at snapshot time.
  final LearningStyleProfile learningStyle;

  /// All goals at snapshot time.
  final List<StudentGoal> goals;

  /// All detected strengths at snapshot time.
  final List<StudentStrength> strengths;

  /// All detected weaknesses at snapshot time.
  final List<StudentWeakness> weaknesses;

  /// All evidence collected up to snapshot time.
  final List<StudentEvidence> evidence;

  /// Pre-computed statistics at snapshot time.
  final ProfileStatistics statistics;

  /// UTC timestamp when this snapshot was taken.
  final DateTime takenAt;

  /// Optional label for this snapshot (e.g., `"post_onboarding"`).
  final String? label;

  const StudentSnapshot({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.dimensions,
    required this.interests,
    required this.skills,
    required this.personality,
    required this.learningStyle,
    required this.goals,
    required this.strengths,
    required this.weaknesses,
    required this.evidence,
    required this.statistics,
    required this.takenAt,
    this.label,
  });

  factory StudentSnapshot.fromJson(Map<String, dynamic> json) =>
      StudentSnapshot(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        sessionId: json['session_id'] as String,
        dimensions: (json['dimensions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            CognitiveDimension.fromJson(v as Map<String, dynamic>),
          ),
        ),
        interests: (json['interests'] as List<dynamic>)
            .map((e) => StudentInterest.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: (json['skills'] as List<dynamic>)
            .map((e) => StudentSkill.fromJson(e as Map<String, dynamic>))
            .toList(),
        personality: StudentPersonality.fromJson(
          json['personality'] as Map<String, dynamic>,
        ),
        learningStyle: LearningStyleProfile.fromJson(
          json['learning_style'] as Map<String, dynamic>,
        ),
        goals: (json['goals'] as List<dynamic>)
            .map((e) => StudentGoal.fromJson(e as Map<String, dynamic>))
            .toList(),
        strengths: (json['strengths'] as List<dynamic>)
            .map((e) => StudentStrength.fromJson(e as Map<String, dynamic>))
            .toList(),
        weaknesses: (json['weaknesses'] as List<dynamic>)
            .map((e) => StudentWeakness.fromJson(e as Map<String, dynamic>))
            .toList(),
        evidence: (json['evidence'] as List<dynamic>)
            .map((e) => StudentEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        statistics: ProfileStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>,
        ),
        takenAt: DateTime.parse(json['taken_at'] as String),
        label: json['label'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'session_id': sessionId,
    'dimensions': dimensions.map((k, v) => MapEntry(k, v.toJson())),
    'interests': interests.map((e) => e.toJson()).toList(),
    'skills': skills.map((e) => e.toJson()).toList(),
    'personality': personality.toJson(),
    'learning_style': learningStyle.toJson(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'strengths': strengths.map((e) => e.toJson()).toList(),
    'weaknesses': weaknesses.map((e) => e.toJson()).toList(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'statistics': statistics.toJson(),
    'taken_at': takenAt.toIso8601String(),
    if (label != null) 'label': label,
  };

  StudentSnapshot copyWith({
    String? id,
    String? studentId,
    String? sessionId,
    Map<String, CognitiveDimension>? dimensions,
    List<StudentInterest>? interests,
    List<StudentSkill>? skills,
    StudentPersonality? personality,
    LearningStyleProfile? learningStyle,
    List<StudentGoal>? goals,
    List<StudentStrength>? strengths,
    List<StudentWeakness>? weaknesses,
    List<StudentEvidence>? evidence,
    ProfileStatistics? statistics,
    DateTime? takenAt,
    String? label,
  }) => StudentSnapshot(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    sessionId: sessionId ?? this.sessionId,
    dimensions: dimensions ?? this.dimensions,
    interests: interests ?? this.interests,
    skills: skills ?? this.skills,
    personality: personality ?? this.personality,
    learningStyle: learningStyle ?? this.learningStyle,
    goals: goals ?? this.goals,
    strengths: strengths ?? this.strengths,
    weaknesses: weaknesses ?? this.weaknesses,
    evidence: evidence ?? this.evidence,
    statistics: statistics ?? this.statistics,
    takenAt: takenAt ?? this.takenAt,
    label: label ?? this.label,
  );

  /// Total number of evidence signals in this snapshot.
  int get evidenceCount => evidence.length;

  @override
  List<Object?> get props => [id, studentId, sessionId, takenAt];

  @override
  String toString() =>
      'StudentSnapshot(id: $id, student: $studentId, '
      'evidence: $evidenceCount, takenAt: $takenAt)';
}
