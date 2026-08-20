/// SAIE — EngineConfiguration
///
/// Immutable configuration for the SAIEEngine.
/// Passed once at construction and never mutated.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/conversation/conversation_policy.dart';
import 'package:stustep/features/saie/matching/matching_configuration.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EngineConfiguration
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration governing the runtime behaviour of [SAIEEngine].
final class EngineConfiguration extends Equatable {
  /// Student identifier. Required to initialise a profile.
  final String studentId;

  /// Session identifier. Auto-generated if empty at init time.
  final String sessionId;

  /// Conversation policy (max interruptions, context window, etc.).
  final ConversationPolicy conversationPolicy;

  /// Assessment engine configuration.
  final AssessmentConfiguration assessmentConfiguration;

  /// Major matching configuration.
  final MatchingConfiguration matchingConfiguration;

  /// Whether to auto-persist the session after each turn.
  final bool autoPersist;

  /// Whether to emit verbose event logs.
  final bool verboseEvents;

  const EngineConfiguration({
    required this.studentId,
    this.sessionId = '',
    this.conversationPolicy = const ConversationPolicy(),
    this.assessmentConfiguration = const AssessmentConfiguration(),
    this.matchingConfiguration = const MatchingConfiguration(),
    this.autoPersist = false,
    this.verboseEvents = false,
  });

  factory EngineConfiguration.fromJson(Map<String, dynamic> json) =>
      EngineConfiguration(
        studentId: json['student_id'] as String,
        sessionId: (json['session_id'] as String?) ?? '',
        autoPersist: (json['auto_persist'] as bool?) ?? false,
        verboseEvents: (json['verbose_events'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'session_id': sessionId,
    'auto_persist': autoPersist,
    'verbose_events': verboseEvents,
  };

  EngineConfiguration copyWith({
    String? studentId,
    String? sessionId,
    ConversationPolicy? conversationPolicy,
    AssessmentConfiguration? assessmentConfiguration,
    MatchingConfiguration? matchingConfiguration,
    bool? autoPersist,
    bool? verboseEvents,
  }) => EngineConfiguration(
    studentId: studentId ?? this.studentId,
    sessionId: sessionId ?? this.sessionId,
    conversationPolicy: conversationPolicy ?? this.conversationPolicy,
    assessmentConfiguration:
        assessmentConfiguration ?? this.assessmentConfiguration,
    matchingConfiguration:
        matchingConfiguration ?? this.matchingConfiguration,
    autoPersist: autoPersist ?? this.autoPersist,
    verboseEvents: verboseEvents ?? this.verboseEvents,
  );

  @override
  List<Object?> get props => [studentId, sessionId, autoPersist];
}
