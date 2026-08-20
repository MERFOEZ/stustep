/// SAIE — SessionSnapshot
///
/// A fully serialisable snapshot of an entire SAIE session.
/// Used by [SessionManager] to persist and restore sessions.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_state.dart';
import 'package:stustep/features/saie/conversation/conversation_language.dart';
import 'package:stustep/features/saie/conversation/conversation_memory.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionSnapshot
// ─────────────────────────────────────────────────────────────────────────────

/// Serialisable session snapshot for persistence and restoration.
final class SessionSnapshot extends Equatable {
  final String sessionId;
  final String studentId;
  final StudentCognitiveProfile profile;
  final ConversationMemory memory;
  final ConversationPhase phase;
  final ConversationLanguage language;
  final AssessmentState? assessmentState;
  final RecommendationReport? recommendationReport;
  final bool recommendationAvailable;
  final DateTime savedAt;
  final int schemaVersion;

  const SessionSnapshot({
    required this.sessionId,
    required this.studentId,
    required this.profile,
    required this.memory,
    required this.phase,
    required this.language,
    required this.savedAt,
    this.assessmentState,
    this.recommendationReport,
    this.recommendationAvailable = false,
    this.schemaVersion = 1,
  });

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) =>
      SessionSnapshot(
        sessionId: json['session_id'] as String,
        studentId: json['student_id'] as String,
        profile: StudentCognitiveProfile.fromJson(
          json['profile'] as Map<String, dynamic>,
        ),
        memory: ConversationMemory.fromJson(
          json['memory'] as Map<String, dynamic>,
        ),
        phase: ConversationPhase.fromJson(
          json['phase'] as Map<String, dynamic>,
        ),
        language: ConversationLanguage.fromJson(
          json['language'] as Map<String, dynamic>,
        ),
        assessmentState: json['assessment_state'] != null
            ? AssessmentState.fromJson(
                json['assessment_state'] as Map<String, dynamic>,
              )
            : null,
        recommendationReport: json['recommendation_report'] != null
            ? RecommendationReport.fromJson(
                json['recommendation_report'] as Map<String, dynamic>,
              )
            : null,
        recommendationAvailable:
            (json['recommendation_available'] as bool?) ?? false,
        savedAt: DateTime.parse(json['saved_at'] as String),
        schemaVersion: (json['schema_version'] as int?) ?? 1,
      );

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'student_id': studentId,
    'profile': profile.toJson(),
    'memory': memory.toJson(),
    'phase': phase.toJson(),
    'language': language.toJson(),
    if (assessmentState != null)
      'assessment_state': assessmentState!.toJson(),
    if (recommendationReport != null)
      'recommendation_report': recommendationReport!.toJson(),
    'recommendation_available': recommendationAvailable,
    'saved_at': savedAt.toIso8601String(),
    'schema_version': schemaVersion,
  };

  SessionSnapshot copyWith({
    String? sessionId,
    String? studentId,
    StudentCognitiveProfile? profile,
    ConversationMemory? memory,
    ConversationPhase? phase,
    ConversationLanguage? language,
    AssessmentState? assessmentState,
    RecommendationReport? recommendationReport,
    bool? recommendationAvailable,
    DateTime? savedAt,
  }) => SessionSnapshot(
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    profile: profile ?? this.profile,
    memory: memory ?? this.memory,
    phase: phase ?? this.phase,
    language: language ?? this.language,
    assessmentState: assessmentState ?? this.assessmentState,
    recommendationReport: recommendationReport ?? this.recommendationReport,
    recommendationAvailable:
        recommendationAvailable ?? this.recommendationAvailable,
    savedAt: savedAt ?? this.savedAt,
    schemaVersion: schemaVersion,
  );

  @override
  List<Object?> get props => [sessionId, savedAt];
}
