/// SAIE — StudentDigitalTwin Model
///
/// The StudentDigitalTwin is the complete, unified representation of a student
/// within the SAIE engine. It merges the static [StudentProfile] with the
/// dynamic [StudentCognitiveProfile] and the student's full session history.
///
/// The Digital Twin is the primary entity the engine reasons about.
/// It is never constructed directly by UI — only by the SAIE engine.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/models/student_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StudentDigitalTwin
// ─────────────────────────────────────────────────────────────────────────────

/// A unified, living representation of a student for the SAIE reasoning engine.
///
/// The [StudentDigitalTwin] aggregates:
/// - [profile]: Demographic and academic background ([StudentProfile])
/// - [cognitiveProfile]: Engine-inferred psychological and aptitude data
/// - [sessionIds]: All session IDs linked to this student
/// - [completedSessionIds]: Sessions that reached the [AssessmentPhase.completed] phase
/// - [activeSessionId]: The currently active session, if any
final class StudentDigitalTwin extends Equatable {
  /// The base demographic and academic profile.
  final StudentProfile profile;

  /// The engine-derived cognitive and personality profile.
  final StudentCognitiveProfile cognitiveProfile;

  /// IDs of all sessions this student has participated in.
  final List<String> sessionIds;

  /// IDs of sessions that were completed successfully.
  final List<String> completedSessionIds;

  /// ID of the currently active session, if any.
  final String? activeSessionId;

  /// UTC timestamp of the last engine update to this twin.
  final DateTime lastSyncedAt;

  const StudentDigitalTwin({
    required this.profile,
    required this.cognitiveProfile,
    required this.sessionIds,
    required this.completedSessionIds,
    required this.lastSyncedAt,
    this.activeSessionId,
  });

  /// Creates a brand-new [StudentDigitalTwin] for a first-time student.
  factory StudentDigitalTwin.create({required StudentProfile profile}) =>
      StudentDigitalTwin(
        profile: profile,
        cognitiveProfile: StudentCognitiveProfile.initial(
          studentId: profile.id,
        ),
        sessionIds: const [],
        completedSessionIds: const [],
        activeSessionId: null,
        lastSyncedAt: DateTime.now().toUtc(),
      );

  /// Creates a [StudentDigitalTwin] from a decoded JSON map.
  factory StudentDigitalTwin.fromJson(Map<String, dynamic> json) =>
      StudentDigitalTwin(
        profile: StudentProfile.fromJson(
          json['profile'] as Map<String, dynamic>,
        ),
        cognitiveProfile: StudentCognitiveProfile.fromJson(
          json['cognitive_profile'] as Map<String, dynamic>,
        ),
        sessionIds:
            (json['session_ids'] as List<dynamic>?)?.cast<String>() ??
                const [],
        completedSessionIds:
            (json['completed_session_ids'] as List<dynamic>?)
                    ?.cast<String>() ??
                const [],
        activeSessionId: json['active_session_id'] as String?,
        lastSyncedAt: DateTime.parse(json['last_synced_at'] as String),
      );

  /// Serializes this [StudentDigitalTwin] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'cognitive_profile': cognitiveProfile.toJson(),
    'session_ids': sessionIds,
    'completed_session_ids': completedSessionIds,
    if (activeSessionId != null) 'active_session_id': activeSessionId,
    'last_synced_at': lastSyncedAt.toIso8601String(),
  };

  /// Returns a copy of this [StudentDigitalTwin] with specified fields replaced.
  StudentDigitalTwin copyWith({
    StudentProfile? profile,
    StudentCognitiveProfile? cognitiveProfile,
    List<String>? sessionIds,
    List<String>? completedSessionIds,
    String? activeSessionId,
    bool clearActiveSession = false,
    DateTime? lastSyncedAt,
  }) => StudentDigitalTwin(
    profile: profile ?? this.profile,
    cognitiveProfile: cognitiveProfile ?? this.cognitiveProfile,
    sessionIds: sessionIds ?? this.sessionIds,
    completedSessionIds: completedSessionIds ?? this.completedSessionIds,
    activeSessionId: clearActiveSession
        ? null
        : activeSessionId ?? this.activeSessionId,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  // ─── Derived helpers ──────────────────────────────────────────────────────

  /// Unique student ID (delegates to profile).
  String get id => profile.id;

  /// Student's name (delegates to profile).
  String get name => profile.name;

  /// Returns `true` if this student has an active session.
  bool get hasActiveSession => activeSessionId != null;

  /// Total number of completed assessments.
  int get totalCompletedSessions => completedSessionIds.length;

  @override
  List<Object?> get props => [profile.id, lastSyncedAt];

  @override
  String toString() =>
      'StudentDigitalTwin(id: ${profile.id}, name: ${profile.name}, '
      'sessions: ${sessionIds.length})';
}
