/// SAIE — AnswerHistory
///
/// Immutable, append-only log of all processed answers in a session.
/// Used by the [AnswerIntelligenceEngine] for repetition detection,
/// semantic duplicate prevention, and trend analysis.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerDecision
// ─────────────────────────────────────────────────────────────────────────────

/// The final action taken after processing a scored answer.
enum AnswerDecision {
  /// Answer was accepted; evidence was extracted and applied.
  accepted,

  /// Answer was accepted but produced only minor evidence (weak band).
  acceptedWeak,

  /// Answer was rejected by validation.
  rejectedInvalid,

  /// Answer was rejected as a semantic duplicate.
  rejectedDuplicate,

  /// Answer was accepted but marked as contradicting prior evidence.
  acceptedContradiction,
}

extension AnswerDecisionX on AnswerDecision {
  bool get wasAccepted => this == AnswerDecision.accepted ||
      this == AnswerDecision.acceptedWeak ||
      this == AnswerDecision.acceptedContradiction;
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerHistoryEntry
// ─────────────────────────────────────────────────────────────────────────────

/// A single entry in the answer history log.
final class AnswerHistoryEntry extends Equatable {
  /// Unique ID for this history entry.
  final String entryId;

  /// ID of the question this answer was for.
  final String questionId;

  /// The raw answer text as submitted by the student.
  final String rawAnswer;

  /// The computed score for this answer.
  final AnswerScore score;

  /// All evidence objects extracted from this answer.
  final List<StudentEvidence> extractedEvidence;

  /// The keys of cognitive dimensions that were updated.
  final List<String> updatedDimensionKeys;

  /// The final engine decision for this answer.
  final AnswerDecision decision;

  /// UTC timestamp when this entry was recorded.
  final DateTime recordedAt;

  const AnswerHistoryEntry({
    required this.entryId,
    required this.questionId,
    required this.rawAnswer,
    required this.score,
    required this.extractedEvidence,
    required this.updatedDimensionKeys,
    required this.decision,
    required this.recordedAt,
  });

  factory AnswerHistoryEntry.fromJson(Map<String, dynamic> json) =>
      AnswerHistoryEntry(
        entryId: json['entry_id'] as String,
        questionId: json['question_id'] as String,
        rawAnswer: json['raw_answer'] as String,
        score: AnswerScore.fromJson(
          json['score'] as Map<String, dynamic>,
        ),
        extractedEvidence: (json['extracted_evidence'] as List<dynamic>)
            .map((e) => StudentEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        updatedDimensionKeys:
            (json['updated_dimension_keys'] as List<dynamic>).cast<String>(),
        decision:
            AnswerDecision.values.byName(json['decision'] as String),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'entry_id': entryId,
    'question_id': questionId,
    'raw_answer': rawAnswer,
    'score': score.toJson(),
    'extracted_evidence': extractedEvidence.map((e) => e.toJson()).toList(),
    'updated_dimension_keys': updatedDimensionKeys,
    'decision': decision.name,
    'recorded_at': recordedAt.toIso8601String(),
  };

  AnswerHistoryEntry copyWith({
    String? entryId,
    String? questionId,
    String? rawAnswer,
    AnswerScore? score,
    List<StudentEvidence>? extractedEvidence,
    List<String>? updatedDimensionKeys,
    AnswerDecision? decision,
    DateTime? recordedAt,
  }) => AnswerHistoryEntry(
    entryId: entryId ?? this.entryId,
    questionId: questionId ?? this.questionId,
    rawAnswer: rawAnswer ?? this.rawAnswer,
    score: score ?? this.score,
    extractedEvidence: extractedEvidence ?? this.extractedEvidence,
    updatedDimensionKeys: updatedDimensionKeys ?? this.updatedDimensionKeys,
    decision: decision ?? this.decision,
    recordedAt: recordedAt ?? this.recordedAt,
  );

  @override
  List<Object?> get props => [entryId, questionId, recordedAt];

  @override
  String toString() =>
      'AnswerHistoryEntry(q: $questionId, score: ${score.total}, '
      'decision: ${decision.name})';
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Append-only log of all answer history entries in the current session.
///
/// Used for repetition detection, trend analysis, and semantic deduplication.
final class AnswerHistory extends Equatable {
  /// The student ID this history belongs to.
  final String studentId;

  /// All history entries, oldest first.
  final List<AnswerHistoryEntry> entries;

  const AnswerHistory({
    required this.studentId,
    this.entries = const [],
  });

  factory AnswerHistory.empty({required String studentId}) =>
      AnswerHistory(studentId: studentId);

  factory AnswerHistory.fromJson(Map<String, dynamic> json) => AnswerHistory(
    studentId: json['student_id'] as String,
    entries: (json['entries'] as List<dynamic>)
        .map(
          (e) => AnswerHistoryEntry.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  /// Appends a new entry and returns the updated history.
  AnswerHistory append(AnswerHistoryEntry entry) =>
      copyWith(entries: [...entries, entry]);

  /// Returns all raw answer texts for a specific [questionId].
  List<String> answersForQuestion(String questionId) => entries
      .where((e) => e.questionId == questionId)
      .map((e) => e.rawAnswer)
      .toList();

  /// Returns all accepted raw answer texts in this session.
  List<String> get acceptedAnswerTexts => entries
      .where((e) => e.decision.wasAccepted)
      .map((e) => e.rawAnswer)
      .toList();

  /// Returns the last N entries.
  List<AnswerHistoryEntry> lastN(int n) =>
      entries.length <= n ? List.from(entries) : entries.sublist(entries.length - n);

  /// Average score across all accepted entries.
  double get averageScore {
    final accepted = entries.where((e) => e.decision.wasAccepted).toList();
    if (accepted.isEmpty) return 0.0;
    return accepted.map((e) => e.score.total).reduce((a, b) => a + b) /
        accepted.length;
  }

  int get totalAnswers => entries.length;
  int get acceptedCount =>
      entries.where((e) => e.decision.wasAccepted).length;
  int get rejectedCount => totalAnswers - acceptedCount;

  AnswerHistory copyWith({
    String? studentId,
    List<AnswerHistoryEntry>? entries,
  }) => AnswerHistory(
    studentId: studentId ?? this.studentId,
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [studentId, entries.length];

  @override
  String toString() =>
      'AnswerHistory(student: $studentId, total: $totalAnswers, '
      'accepted: $acceptedCount)';
}
