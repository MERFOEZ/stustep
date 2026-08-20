/// SAIE — MajorMatchingEngine
///
/// The orchestrating entry point for Task 6.
///
/// Pipeline:
/// 1. Check profile readiness (evidence count + confidence gate).
/// 2. Load eligible majors from the knowledge base (auto-detects new majors).
/// 3. Filter majors via [MajorFilter].
/// 4. Score every eligible major via [MajorMatcher].
/// 5. Sort by score, take top N, wrap in [RecommendationCandidate].
/// 6. Compute [MatchingStatistics].
/// 7. Return [MajorRanking].
library;

import 'package:stustep/features/saie/matching/major_filter.dart';
import 'package:stustep/features/saie/matching/major_matcher.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/matching/major_score.dart';
import 'package:stustep/features/saie/matching/matching_configuration.dart';
import 'package:stustep/features/saie/matching/matching_statistics.dart';
import 'package:stustep/features/saie/matching/recommendation_candidate.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MajorMatchingEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the complete matching pipeline.
///
/// Stateless — all inputs are passed per call.
/// Automatically detects newly added majors through the [allMajors] parameter,
/// which should come directly from the [KnowledgeBase] repository.
final class MajorMatchingEngine {
  final MajorFilter _filter;
  final MajorMatcher _matcher;

  const MajorMatchingEngine({
    MajorFilter filter = const MajorFilter(),
    MajorMatcher matcher = const MajorMatcher(),
  })  : _filter = filter,
        _matcher = matcher;

  // ─── Core Entry Point ─────────────────────────────────────────────────────

  /// Runs the full matching pipeline and returns a [MajorRanking].
  ///
  /// [allMajors] must come from the live knowledge base so that newly added
  /// majors are automatically included without any code changes.
  MajorRanking match({
    required StudentCognitiveProfile profile,
    required List<Major> allMajors,
    MatchingConfiguration config = const MatchingConfiguration(),
    MajorFilterCriteria criteria = MajorFilterCriteria.none,
  }) {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now().toUtc();

    // ── Step 1: Guard — empty knowledge base ──
    if (allMajors.isEmpty) {
      stopwatch.stop();
      return MajorRanking(
        status: RankingStatus.emptyKnowledgeBase,
        candidates: const [],
        statistics: _emptyStats(
          profile: profile,
          majorsFiltered: 0,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
        message: RankingStatus.emptyKnowledgeBase.message,
        computedAt: now,
      );
    }

    // ── Step 2: Guard — insufficient evidence / confidence ──
    final stats = profile.computeStatistics();
    final profileConfidence = stats.overallConfidence;

    if (profile.evidenceCount < config.minimumEvidenceCount ||
        profileConfidence < config.minimumProfileConfidence) {
      stopwatch.stop();
      return MajorRanking(
        status: RankingStatus.needMoreEvidence,
        candidates: const [],
        statistics: MatchingStatistics(
          majorsEvaluated: 0,
          majorsPassed: 0,
          majorsFiltered: allMajors.length,
          highestScore: 0,
          lowestScore: 0,
          averageScore: 0.0,
          profileConfidence: profileConfidence,
          evidenceCount: profile.evidenceCount,
          evidencedDimensions: (stats.coverageRatio * DimensionKeys.all.length).round(),
          totalDimensions: DimensionKeys.all.length,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
        message: RankingStatus.needMoreEvidence.message,
        computedAt: now,
      );
    }

    // ── Step 3: Filter ──
    final eligible = _filter.apply(
      allMajors: allMajors,
      config: config,
      criteria: criteria,
    );

    final filtered = allMajors.length - eligible.length;

    // ── Step 4: Score ──
    final scores = _matcher.match(
      eligibleMajors: eligible,
      profile: profile,
      config: config,
    );

    if (scores.isEmpty) {
      stopwatch.stop();
      return MajorRanking(
        status: RankingStatus.noMatchesFound,
        candidates: const [],
        statistics: _buildStats(
          profile: profile,
          scores: const [],
          majorsEvaluated: eligible.length,
          majorsFiltered: filtered,
          profileConfidence: profileConfidence,
          evidencedDimCount: (stats.coverageRatio * DimensionKeys.all.length).round(),
          durationMs: stopwatch.elapsedMilliseconds,
        ),
        message: RankingStatus.noMatchesFound.message,
        computedAt: now,
      );
    }

    // ── Step 5: Sort + Rank ──
    scores.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    final topScores = scores.take(config.topN).toList();

    final candidates = [
      for (int i = 0; i < topScores.length; i++)
        RecommendationCandidate(rank: i + 1, score: topScores[i]),
    ];

    stopwatch.stop();

    // ── Step 6: Statistics ──
    final matchStats = _buildStats(
      profile: profile,
      scores: scores,
      majorsEvaluated: eligible.length,
      majorsFiltered: filtered,
      profileConfidence: profileConfidence,
      evidencedDimCount: (stats.coverageRatio * DimensionKeys.all.length).round(),
      durationMs: stopwatch.elapsedMilliseconds,
    );

    return MajorRanking(
      status: RankingStatus.success,
      candidates: candidates,
      statistics: matchStats,
      message: RankingStatus.success.message,
      computedAt: now,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  MatchingStatistics _buildStats({
    required StudentCognitiveProfile profile,
    required List<MajorScore> scores,
    required int majorsEvaluated,
    required int majorsFiltered,
    required double profileConfidence,
    required int evidencedDimCount,
    required int durationMs,
  }) {
    final highest = scores.isEmpty ? 0 : scores.first.similarityScore;
    final lowest = scores.isEmpty ? 0 : scores.last.similarityScore;
    final avg = scores.isEmpty
        ? 0.0
        : scores.map((s) => s.similarityScore).reduce((a, b) => a + b) /
            scores.length;

    return MatchingStatistics(
      majorsEvaluated: majorsEvaluated,
      majorsPassed: scores.length,
      majorsFiltered: majorsFiltered,
      highestScore: highest,
      lowestScore: lowest,
      averageScore: avg,
      profileConfidence: profileConfidence,
      evidenceCount: profile.evidenceCount,
      evidencedDimensions: evidencedDimCount,
      totalDimensions: DimensionKeys.all.length,
      durationMs: durationMs,
    );
  }

  MatchingStatistics _emptyStats({
    required StudentCognitiveProfile profile,
    required int majorsFiltered,
    required int durationMs,
  }) {
    final stats = profile.computeStatistics();
    return MatchingStatistics(
      majorsEvaluated: 0,
      majorsPassed: 0,
      majorsFiltered: majorsFiltered,
      highestScore: 0,
      lowestScore: 0,
      averageScore: 0.0,
      profileConfidence: stats.overallConfidence,
      evidenceCount: profile.evidenceCount,
      evidencedDimensions: (stats.coverageRatio * DimensionKeys.all.length).round(),
      totalDimensions: DimensionKeys.all.length,
      durationMs: durationMs,
    );
  }
}
