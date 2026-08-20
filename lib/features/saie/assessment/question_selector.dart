/// SAIE — QuestionSelector
///
/// Bridges the Knowledge Base question pool with the [QuestionPlanner].
/// Filters ineligible questions (asked, skipped, non-repeatable) before
/// passing candidates to the planner for valuation.
library;

import 'package:stustep/features/saie/assessment/assessment_configuration.dart';
import 'package:stustep/features/saie/assessment/coverage_engine.dart';
import 'package:stustep/features/saie/assessment/knowledge_gap_engine.dart';
import 'package:stustep/features/saie/assessment/question_history.dart';
import 'package:stustep/features/saie/assessment/question_planner.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionSelector
// ─────────────────────────────────────────────────────────────────────────────

/// Selects the next best [Question] from the live knowledge base pool.
final class QuestionSelector {
  final QuestionPlanner _planner;

  const QuestionSelector({
    QuestionPlanner planner = const QuestionPlanner(),
  }) : _planner = planner;

  /// Returns the next [Question] to ask, or null if the pool is exhausted.
  ///
  /// [allQuestions] must come from the live knowledge base — new questions
  /// are automatically picked up without code changes.
  Question? selectNext({
    required List<Question> allQuestions,
    required StudentCognitiveProfile profile,
    required QuestionHistory history,
    required CoverageReport coverageReport,
    required GapReport gapReport,
    required AssessmentConfiguration config,
    required AssessmentPhase currentPhase,
  }) {
    // ── Step 1: Filter ineligible questions ──────────────────────────────
    final askedIds = history.allAskedIds.toSet();
    final skippedIds = history.skippedIds.toSet();

    final candidates = allQuestions.where((q) {
      // Already asked and not repeatable → exclude.
      if (askedIds.contains(q.id) && !q.repeatable) return false;
      // Skip-listed → exclude (unless repeatable and wasn't answered).
      if (skippedIds.contains(q.id) && !q.repeatable) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // ── Step 2: Diversity filter — avoid same domain too many times ───────
    final recentDomains = history.recentDomainKeys(
      config.maxConsecutiveSameDomain,
    ).toSet();

    // Prefer questions that don't overlap with very recent domains, but
    // fall back to any candidate if all are from recent domains.
    final diverse = candidates
        .where((q) => !q.targetDomainIds.every(recentDomains.contains))
        .toList();
    final pool = diverse.isNotEmpty ? diverse : candidates;

    // ── Step 3: Plan (evaluate + pick best) ─────────────────────────────
    final best = _planner.plan(
      candidates: pool,
      profile: profile,
      coverageReport: coverageReport,
      gapReport: gapReport,
      history: history,
      config: config,
      currentPhase: currentPhase,
    );

    return best?.question;
  }
}
