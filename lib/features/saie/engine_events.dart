/// SAIE — EngineEvents
///
/// Typed events emitted by the SAIEEngine during a session.
/// These allow the Flutter UI layer to react to state changes
/// without coupling directly to internal engine state.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EngineEventType
// ─────────────────────────────────────────────────────────────────────────────

enum EngineEventType {
  assessmentStarted,
  questionAsked,
  answerAccepted,
  clarificationRequested,
  recommendationGenerated,
  discussionStarted,
  discussionEnded,
  sessionSaved,
  sessionRestored,
  languageSwitched,
  assessmentCompleted,
  engineInitialised,
  engineReset,
}

// ─────────────────────────────────────────────────────────────────────────────
// EngineEvent
// ─────────────────────────────────────────────────────────────────────────────

/// An immutable event record emitted by the SAIEEngine.
final class EngineEvent extends Equatable {
  final String eventId;
  final EngineEventType type;
  final DateTime occurredAt;

  /// Optional: the question that triggered this event.
  final Question? question;

  /// Optional: the recommendation produced.
  final RecommendationReport? recommendation;

  /// Optional: current assessment progress.
  final AssessmentProgress? progress;

  /// Optional: current conversation stage.
  final ConversationStage? stage;

  /// Optional: free-form payload (e.g. language name, clarification text).
  final String? payload;

  const EngineEvent({
    required this.eventId,
    required this.type,
    required this.occurredAt,
    this.question,
    this.recommendation,
    this.progress,
    this.stage,
    this.payload,
  });

  factory EngineEvent.fromJson(Map<String, dynamic> json) => EngineEvent(
    eventId: json['event_id'] as String,
    type: EngineEventType.values.byName(json['type'] as String),
    occurredAt: DateTime.parse(json['occurred_at'] as String),
    payload: json['payload'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'type': type.name,
    'occurred_at': occurredAt.toIso8601String(),
    if (payload != null) 'payload': payload,
  };

  EngineEvent copyWith({
    String? eventId,
    EngineEventType? type,
    DateTime? occurredAt,
    String? payload,
  }) => EngineEvent(
    eventId: eventId ?? this.eventId,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    payload: payload ?? this.payload,
  );

  @override
  List<Object?> get props => [eventId, type, occurredAt];
}
