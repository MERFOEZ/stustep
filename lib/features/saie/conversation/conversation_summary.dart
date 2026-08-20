/// SAIE — ConversationSummary
///
/// Periodic compressed summary of a conversation window.
/// Replaces unbounded history to keep the context token-efficient.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationSummary
// ─────────────────────────────────────────────────────────────────────────────

/// A compressed summary of [n] conversation turns produced periodically.
final class ConversationSummary extends Equatable {
  final String summaryId;
  final String sessionId;

  /// Concise summary of what was discussed.
  final String text;

  /// Key facts the student revealed (e.g. "prefers mathematics", "dislikes art").
  final List<String> studentFacts;

  /// Questions answered during the summarised window.
  final List<String> answeredQuestionIds;

  /// Questions skipped during the summarised window.
  final List<String> skippedQuestionIds;

  /// Number of turns this summary covers.
  final int turnsCovered;

  /// Phase snapshot at the time of summary.
  final ConversationPhase phaseSnapshot;

  /// Top cognitive dimensions identified so far.
  final Map<String, double> topDimensions;

  final DateTime generatedAt;

  const ConversationSummary({
    required this.summaryId,
    required this.sessionId,
    required this.text,
    required this.studentFacts,
    required this.answeredQuestionIds,
    required this.skippedQuestionIds,
    required this.turnsCovered,
    required this.phaseSnapshot,
    required this.topDimensions,
    required this.generatedAt,
  });

  factory ConversationSummary.generate({
    required String summaryId,
    required String sessionId,
    required List<ConversationTurnRecord> turns,
    required ConversationPhase phase,
    required StudentCognitiveProfile profile,
  }) {
    final answered = turns
        .where((t) => t.wasAssessmentTurn && t.isStudent)
        .map((t) => t.turnId)
        .toList();
    final facts = _extractFacts(turns);
    final topDims = _topDimensions(profile);
    final text = _buildText(turns, facts, phase);

    return ConversationSummary(
      summaryId: summaryId,
      sessionId: sessionId,
      text: text,
      studentFacts: facts,
      answeredQuestionIds: answered,
      skippedQuestionIds: turns
          .where((t) => t.wasAssessmentTurn && t.intentName == 'skipQuestion')
          .map((t) => t.turnId)
          .toList(),
      turnsCovered: turns.length,
      phaseSnapshot: phase,
      topDimensions: topDims,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  static List<String> _extractFacts(List<ConversationTurnRecord> turns) {
    final facts = <String>[];
    for (final t in turns.where((t) => t.isStudent)) {
      final msg = t.content.toLowerCase();
      if (msg.contains('أحب') ||
          msg.contains('أفضل') ||
          msg.contains('I like') ||
          msg.contains('I prefer') ||
          msg.contains('I enjoy')) {
        final fact = t.content.length > 80
            ? '${t.content.substring(0, 80)}…'
            : t.content;
        facts.add(fact);
      }
    }
    return facts.take(10).toList();
  }

  static Map<String, double> _topDimensions(StudentCognitiveProfile profile) {
    final all = DimensionKeys.all
        .map((k) => MapEntry(k, profile.scoreFor(k)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(all.take(5));
  }

  static String _buildText(
    List<ConversationTurnRecord> turns,
    List<String> facts,
    ConversationPhase phase,
  ) {
    final studentMsgs = turns.where((t) => t.isStudent).length;
    final interruptions = turns.where((t) => t.wasInterruption).length;
    return 'Session summary: $studentMsgs student turns, '
        '$interruptions interruptions. '
        'Current stage: ${phase.stage.name}. '
        'Key facts: ${facts.isEmpty ? "none yet" : facts.join("; ")}.';
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        summaryId: json['summary_id'] as String,
        sessionId: json['session_id'] as String,
        text: json['text'] as String,
        studentFacts:
            (json['student_facts'] as List<dynamic>).cast<String>(),
        answeredQuestionIds:
            (json['answered_question_ids'] as List<dynamic>).cast<String>(),
        skippedQuestionIds:
            (json['skipped_question_ids'] as List<dynamic>).cast<String>(),
        turnsCovered: json['turns_covered'] as int,
        phaseSnapshot: ConversationPhase.fromJson(
            json['phase_snapshot'] as Map<String, dynamic>),
        topDimensions:
            (json['top_dimensions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'summary_id': summaryId,
    'session_id': sessionId,
    'text': text,
    'student_facts': studentFacts,
    'answered_question_ids': answeredQuestionIds,
    'skipped_question_ids': skippedQuestionIds,
    'turns_covered': turnsCovered,
    'phase_snapshot': phaseSnapshot.toJson(),
    'top_dimensions': topDimensions,
    'generated_at': generatedAt.toIso8601String(),
  };

  ConversationSummary copyWith({
    String? summaryId,
    String? sessionId,
    String? text,
    List<String>? studentFacts,
    List<String>? answeredQuestionIds,
    List<String>? skippedQuestionIds,
    int? turnsCovered,
    ConversationPhase? phaseSnapshot,
    Map<String, double>? topDimensions,
    DateTime? generatedAt,
  }) => ConversationSummary(
    summaryId: summaryId ?? this.summaryId,
    sessionId: sessionId ?? this.sessionId,
    text: text ?? this.text,
    studentFacts: studentFacts ?? this.studentFacts,
    answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
    skippedQuestionIds: skippedQuestionIds ?? this.skippedQuestionIds,
    turnsCovered: turnsCovered ?? this.turnsCovered,
    phaseSnapshot: phaseSnapshot ?? this.phaseSnapshot,
    topDimensions: topDimensions ?? this.topDimensions,
    generatedAt: generatedAt ?? this.generatedAt,
  );

  @override
  List<Object?> get props => [summaryId, turnsCovered, generatedAt];
}
