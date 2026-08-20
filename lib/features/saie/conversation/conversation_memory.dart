/// SAIE — ConversationMemory
///
/// Maintains the full working memory of one conversation session:
/// - Full history (all turns)
/// - Active context window (last N turns)
/// - List of summaries (replace old history)
/// - Important student facts
/// - Current assessment + recommendation contexts
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/assessment/assessment_state.dart';
import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/conversation/conversation_policy.dart';
import 'package:stustep/features/saie/conversation/conversation_summary.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationMemory
// ─────────────────────────────────────────────────────────────────────────────

/// Full working memory for a single conversation session.
final class ConversationMemory extends Equatable {
  final String sessionId;

  /// Complete append-only history.
  final ConversationHistory history;

  /// Periodic compressed summaries.
  final List<ConversationSummary> summaries;

  /// Important facts the student has revealed (keyed by topic).
  final Map<String, String> studentFacts;

  /// Active assessment state.
  final AssessmentState? assessmentState;

  /// Last generated recommendation report (may be null pre-assessment).
  final RecommendationReport? recommendationReport;

  /// Whether a recommendation has been presented to the student.
  final bool recommendationPresented;

  /// The turn number when the last summary was generated.
  final int lastSummaryAtTurn;

  const ConversationMemory({
    required this.sessionId,
    required this.history,
    required this.summaries,
    required this.studentFacts,
    required this.lastSummaryAtTurn,
    this.assessmentState,
    this.recommendationReport,
    this.recommendationPresented = false,
  });

  factory ConversationMemory.empty(String sessionId) => ConversationMemory(
    sessionId: sessionId,
    history: ConversationHistory.empty(sessionId),
    summaries: const [],
    studentFacts: const {},
    lastSummaryAtTurn: 0,
  );

  // ── Context window ────────────────────────────────────────────────────────

  /// Returns the active context window (last N turns).
  List<ConversationTurnRecord> contextWindow(ConversationPolicy policy) =>
      history.window(policy.contextWindowSize);

  // ── Append ────────────────────────────────────────────────────────────────

  ConversationMemory appendTurn(ConversationTurnRecord turn) =>
      copyWith(history: history.append(turn));

  // ── Summary ───────────────────────────────────────────────────────────────

  ConversationMemory addSummary(ConversationSummary summary) =>
      copyWith(
        summaries: [...summaries, summary],
        lastSummaryAtTurn: history.length,
      );

  bool shouldSummarise(ConversationPolicy policy) =>
      history.length - lastSummaryAtTurn >= policy.summaryEveryNTurns;

  List<ConversationTurnRecord> turnsSinceLastSummary() =>
      history.turns.sublist(lastSummaryAtTurn);

  // ── Facts ─────────────────────────────────────────────────────────────────

  ConversationMemory storeFact(String key, String value) =>
      copyWith(studentFacts: {...studentFacts, key: value});

  // ── Assessment / Recommendation ───────────────────────────────────────────

  ConversationMemory updateAssessmentState(AssessmentState state) =>
      copyWith(assessmentState: state);

  ConversationMemory storeRecommendation(RecommendationReport report) =>
      copyWith(
        recommendationReport: report,
        recommendationPresented: true,
      );

  // ── JSON ──────────────────────────────────────────────────────────────────

  factory ConversationMemory.fromJson(Map<String, dynamic> json) =>
      ConversationMemory(
        sessionId: json['session_id'] as String,
        history: ConversationHistory.fromJson(
          json['history'] as Map<String, dynamic>,
        ),
        summaries: (json['summaries'] as List<dynamic>)
            .map((e) =>
                ConversationSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        studentFacts: (json['student_facts'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
        lastSummaryAtTurn: json['last_summary_at_turn'] as int,
        recommendationPresented:
            (json['recommendation_presented'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'history': history.toJson(),
    'summaries': summaries.map((s) => s.toJson()).toList(),
    'student_facts': studentFacts,
    'last_summary_at_turn': lastSummaryAtTurn,
    'recommendation_presented': recommendationPresented,
  };

  ConversationMemory copyWith({
    String? sessionId,
    ConversationHistory? history,
    List<ConversationSummary>? summaries,
    Map<String, String>? studentFacts,
    int? lastSummaryAtTurn,
    AssessmentState? assessmentState,
    RecommendationReport? recommendationReport,
    bool? recommendationPresented,
  }) => ConversationMemory(
    sessionId: sessionId ?? this.sessionId,
    history: history ?? this.history,
    summaries: summaries ?? this.summaries,
    studentFacts: studentFacts ?? this.studentFacts,
    lastSummaryAtTurn: lastSummaryAtTurn ?? this.lastSummaryAtTurn,
    assessmentState: assessmentState ?? this.assessmentState,
    recommendationReport:
        recommendationReport ?? this.recommendationReport,
    recommendationPresented:
        recommendationPresented ?? this.recommendationPresented,
  );

  @override
  List<Object?> get props => [
    sessionId,
    history.length,
    summaries.length,
    recommendationPresented,
  ];
}
