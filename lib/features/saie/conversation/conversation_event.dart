/// SAIE — ConversationEvent
///
/// Discrete, typed events that flow through the conversation pipeline.
/// Every action the conversation engine takes or receives is an event.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationEventType
// ─────────────────────────────────────────────────────────────────────────────

enum ConversationEventType {
  /// Student sent a message.
  studentMessage,

  /// Engine produced a response.
  engineResponse,

  /// Assessment question was asked.
  questionAsked,

  /// Student answered a question.
  questionAnswered,

  /// Question was skipped.
  questionSkipped,

  /// Question was explained (not counted as an answer).
  questionExplained,

  /// Assessment phase advanced.
  phaseAdvanced,

  /// Assessment completed.
  assessmentCompleted,

  /// Recommendation was generated.
  recommendationGenerated,

  /// Recommendation discussed (student asking follow-up).
  recommendationDiscussed,

  /// Academic discussion interrupted the assessment.
  academicDiscussion,

  /// Greeting received.
  greeting,

  /// Off-topic message handled.
  offTopic,

  /// Clarification requested.
  clarificationRequested,

  /// Language switched.
  languageSwitched,

  /// Assessment paused.
  assessmentPaused,

  /// Assessment resumed.
  assessmentResumed,

  /// Assessment restarted.
  assessmentRestarted,

  /// Goodbye.
  goodbye,

  /// Unknown event.
  unknown,
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationEvent
// ─────────────────────────────────────────────────────────────────────────────

/// An immutable event record in the conversation timeline.
final class ConversationEvent extends Equatable {
  final String eventId;
  final ConversationEventType type;
  final SupportedIntent? triggerIntent;
  final String? payload;
  final DateTime occurredAt;

  const ConversationEvent({
    required this.eventId,
    required this.type,
    required this.occurredAt,
    this.triggerIntent,
    this.payload,
  });

  factory ConversationEvent.fromJson(Map<String, dynamic> json) =>
      ConversationEvent(
        eventId: json['event_id'] as String,
        type: ConversationEventType.values.byName(json['type'] as String),
        triggerIntent: json['trigger_intent'] == null
            ? null
            : SupportedIntent.values.byName(json['trigger_intent'] as String),
        payload: json['payload'] as String?,
        occurredAt: DateTime.parse(json['occurred_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'type': type.name,
    if (triggerIntent != null) 'trigger_intent': triggerIntent!.name,
    if (payload != null) 'payload': payload,
    'occurred_at': occurredAt.toIso8601String(),
  };

  ConversationEvent copyWith({
    String? eventId,
    ConversationEventType? type,
    SupportedIntent? triggerIntent,
    String? payload,
    DateTime? occurredAt,
  }) => ConversationEvent(
    eventId: eventId ?? this.eventId,
    type: type ?? this.type,
    triggerIntent: triggerIntent ?? this.triggerIntent,
    payload: payload ?? this.payload,
    occurredAt: occurredAt ?? this.occurredAt,
  );

  @override
  List<Object?> get props => [eventId, type, occurredAt];
}
