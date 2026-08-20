/// SAIE — QuestionHistory
///
/// Tracks which questions have been asked, answered, or skipped in a session.
/// Also detects recently used domain keys for diversity enforcement.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/models/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionRecord
// ─────────────────────────────────────────────────────────────────────────────

/// The outcome of a single question during the assessment.
enum QuestionOutcome {
  /// Student provided a valid answer.
  answered,

  /// Student skipped this question.
  skipped,

  /// Student asked for clarification (still pending).
  clarified,

  /// Question was shown but no response yet (only valid for activeQuestion).
  pending,
}

/// A historical record of one asked question.
final class QuestionRecord extends Equatable {
  final String questionId;
  final QuestionOutcome outcome;
  final DateTime askedAt;
  final List<String> domainKeys;
  final String? rawAnswer;

  const QuestionRecord({
    required this.questionId,
    required this.outcome,
    required this.askedAt,
    required this.domainKeys,
    this.rawAnswer,
  });

  factory QuestionRecord.fromJson(Map<String, dynamic> json) => QuestionRecord(
    questionId: json['question_id'] as String,
    outcome: QuestionOutcome.values.byName(json['outcome'] as String),
    askedAt: DateTime.parse(json['asked_at'] as String),
    domainKeys: (json['domain_keys'] as List<dynamic>).cast<String>(),
    rawAnswer: json['raw_answer'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'outcome': outcome.name,
    'asked_at': askedAt.toIso8601String(),
    'domain_keys': domainKeys,
    if (rawAnswer != null) 'raw_answer': rawAnswer,
  };

  QuestionRecord copyWith({
    String? questionId,
    QuestionOutcome? outcome,
    DateTime? askedAt,
    List<String>? domainKeys,
    String? rawAnswer,
  }) => QuestionRecord(
    questionId: questionId ?? this.questionId,
    outcome: outcome ?? this.outcome,
    askedAt: askedAt ?? this.askedAt,
    domainKeys: domainKeys ?? this.domainKeys,
    rawAnswer: rawAnswer ?? this.rawAnswer,
  );

  @override
  List<Object?> get props => [questionId, outcome];
}

// ─────────────────────────────────────────────────────────────────────────────
// QuestionHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Append-only log of all question records for the current session.
final class QuestionHistory extends Equatable {
  final List<QuestionRecord> records;

  const QuestionHistory({this.records = const []});

  factory QuestionHistory.empty() => const QuestionHistory();

  /// Appends a record and returns a new immutable [QuestionHistory].
  QuestionHistory append(QuestionRecord record) =>
      QuestionHistory(records: [...records, record]);

  /// Returns IDs of all questions asked (any outcome).
  List<String> get allAskedIds =>
      records.map((r) => r.questionId).toList();

  /// Returns IDs of questions answered.
  List<String> get answeredIds => records
      .where((r) => r.outcome == QuestionOutcome.answered)
      .map((r) => r.questionId)
      .toList();

  /// Returns IDs of questions skipped.
  List<String> get skippedIds => records
      .where((r) => r.outcome == QuestionOutcome.skipped)
      .map((r) => r.questionId)
      .toList();

  /// Returns the last N domain keys used (for diversity control).
  List<String> recentDomainKeys(int n) => records
      .reversed
      .take(n)
      .expand((r) => r.domainKeys)
      .toList();

  /// True if [questionId] has already been asked.
  bool wasAsked(String questionId) =>
      records.any((r) => r.questionId == questionId);

  /// True if [questionId] was answered (not skipped).
  bool wasAnswered(String questionId) => records.any(
    (r) => r.questionId == questionId && r.outcome == QuestionOutcome.answered,
  );

  /// Counts how many of the last [n] questions targeted [domainKey].
  int recentDomainCount(String domainKey, int n) => records.reversed
      .take(n)
      .where((r) => r.domainKeys.contains(domainKey))
      .length;

  /// How many times a given domain has been addressed in total.
  int totalDomainCount(String domainKey) =>
      records.where((r) => r.domainKeys.contains(domainKey)).length;

  /// Questions that touched a given [Question]'s domain but are not the same id.
  bool hasRecentlyAskedSameDomain(Question question, int windowSize) {
    final recentKeys = recentDomainKeys(windowSize).toSet();
    return question.targetDomainIds.any(recentKeys.contains);
  }

  factory QuestionHistory.fromJson(Map<String, dynamic> json) =>
      QuestionHistory(
        records: (json['records'] as List<dynamic>)
            .map((e) => QuestionRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'records': records.map((r) => r.toJson()).toList(),
  };

  QuestionHistory copyWith({List<QuestionRecord>? records}) =>
      QuestionHistory(records: records ?? this.records);

  @override
  List<Object?> get props => [records.length];
}
