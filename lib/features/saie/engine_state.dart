/// SAIE — EngineState
///
/// Immutable snapshot of the entire engine state at one point in time.
/// Held inside [SAIEEngine] and updated atomically after each turn.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';
import 'package:stustep/features/saie/assessment/assessment_state.dart';
import 'package:stustep/features/saie/conversation/conversation_language.dart';
import 'package:stustep/features/saie/conversation/conversation_memory.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EngineStatus
// ─────────────────────────────────────────────────────────────────────────────

enum EngineStatus {
  /// Engine created but not yet initialised.
  uninitialised,

  /// Knowledge base loading.
  initialising,

  /// Ready and awaiting first message.
  ready,

  /// Assessment is in progress.
  assessing,

  /// Recommendation produced; in discussion mode.
  recommending,

  /// Engine has been reset.
  reset,
}

// ─────────────────────────────────────────────────────────────────────────────
// EngineState
// ─────────────────────────────────────────────────────────────────────────────

/// Full immutable engine state — updated atomically on each turn.
final class EngineState extends Equatable {
  final String sessionId;
  final String studentId;
  final EngineStatus status;
  final StudentCognitiveProfile profile;
  final ConversationMemory memory;
  final ConversationPhase phase;
  final ConversationLanguage language;
  final AssessmentProgress assessmentProgress;
  final AssessmentState? assessmentState;
  final RecommendationReport? recommendationReport;
  final Question? activeQuestion;
  final bool recommendationAvailable;
  final DateTime? lastActivityAt;

  const EngineState({
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.profile,
    required this.memory,
    required this.phase,
    required this.language,
    required this.assessmentProgress,
    this.assessmentState,
    this.recommendationReport,
    this.activeQuestion,
    this.recommendationAvailable = false,
    this.lastActivityAt,
  });

  factory EngineState.initial({
    required String sessionId,
    required String studentId,
  }) => EngineState(
    sessionId: sessionId,
    studentId: studentId,
    status: EngineStatus.uninitialised,
    profile: StudentCognitiveProfile.initial(studentId: studentId),
    memory: ConversationMemory.empty(sessionId),
    phase: ConversationPhase.initial(),
    language: ConversationLanguage.initial(),
    assessmentProgress: AssessmentProgress.initial(),
  );

  EngineState copyWith({
    String? sessionId,
    String? studentId,
    EngineStatus? status,
    StudentCognitiveProfile? profile,
    ConversationMemory? memory,
    ConversationPhase? phase,
    ConversationLanguage? language,
    AssessmentProgress? assessmentProgress,
    AssessmentState? assessmentState,
    RecommendationReport? recommendationReport,
    Question? activeQuestion,
    bool? recommendationAvailable,
    DateTime? lastActivityAt,
  }) => EngineState(
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    status: status ?? this.status,
    profile: profile ?? this.profile,
    memory: memory ?? this.memory,
    phase: phase ?? this.phase,
    language: language ?? this.language,
    assessmentProgress:
        assessmentProgress ?? this.assessmentProgress,
    assessmentState: assessmentState ?? this.assessmentState,
    recommendationReport:
        recommendationReport ?? this.recommendationReport,
    activeQuestion: activeQuestion ?? this.activeQuestion,
    recommendationAvailable:
        recommendationAvailable ?? this.recommendationAvailable,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );

  @override
  List<Object?> get props => [sessionId, studentId, status, lastActivityAt];
}
