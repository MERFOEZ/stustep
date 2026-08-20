/// SAIE LLM — LlmContextBuilder
///
/// Assembles the minimum necessary context from SAIE internal state
/// for inclusion in a [LlmRequest]. Never sends unnecessary information.
library;

import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/conversation/conversation_language.dart';
import 'package:stustep/features/saie/conversation/conversation_memory.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmContextBundle
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum context package used by [LlmPromptBuilder].
final class LlmContextBundle {
  /// The task being performed.
  final LlmTask task;

  /// The student's raw message (for discussion / explanation tasks).
  final String? studentMessage;

  /// The question being explained (for questionExplanation).
  final Question? activeQuestion;

  /// Recent conversation turns (capped for token budget).
  final List<ConversationTurnRecord> recentTurns;

  /// Lightweight profile summary (top dimensions only).
  final Map<String, double> topDimensions;

  /// Dominant learning style.
  final String? dominantLearningStyle;

  /// Overall assessment confidence.
  final double overallConfidence;

  /// Current conversation stage.
  final ConversationStage stage;

  /// Active response language.
  final ConversationLanguage language;

  /// The recommendation report (only for relevant tasks).
  final RecommendationReport? report;

  /// Raw text to polish / translate (for those tasks).
  final String? rawText;

  const LlmContextBundle({
    required this.task,
    required this.recentTurns,
    required this.topDimensions,
    required this.overallConfidence,
    required this.stage,
    required this.language,
    this.studentMessage,
    this.activeQuestion,
    this.dominantLearningStyle,
    this.report,
    this.rawText,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmContextBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a [LlmContextBundle] from engine state — minimum context only.
final class LlmContextBuilder {
  /// Maximum number of recent conversation turns to include.
  static const int _maxTurns = 8;

  /// Maximum number of top profile dimensions to include.
  static const int _maxDimensions = 5;

  const LlmContextBuilder();

  /// Build a context bundle for [task] using the provided engine state.
  LlmContextBundle build({
    required LlmTask task,
    required StudentCognitiveProfile profile,
    required ConversationMemory memory,
    required ConversationPhase phase,
    required ConversationLanguage language,
    String? studentMessage,
    Question? activeQuestion,
    RecommendationReport? report,
    String? rawText,
  }) {
    final topDims = _topDimensions(profile);
    final stats = profile.computeStatistics();
    final turns = _recentTurns(memory, task);

    return LlmContextBundle(
      task: task,
      studentMessage: studentMessage,
      activeQuestion: activeQuestion,
      recentTurns: turns,
      topDimensions: topDims,
      dominantLearningStyle:
          profile.learningStyle.dominantModality?.name,
      overallConfidence: stats.overallConfidence,
      stage: phase.stage,
      language: language,
      report: task.requiresRecommendation ? report : null,
      rawText: rawText,
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Map<String, double> _topDimensions(StudentCognitiveProfile profile) {
    final all = DimensionKeys.all
        .map((k) => MapEntry(k, profile.scoreFor(k)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(all.take(_maxDimensions));
  }

  List<ConversationTurnRecord> _recentTurns(
    ConversationMemory memory,
    LlmTask task,
  ) {
    if (!task.requiresHistory) return const [];
    final turns = memory.history.turns;
    final start = turns.length - _maxTurns;
    return turns.sublist(start < 0 ? 0 : start);
  }
}
