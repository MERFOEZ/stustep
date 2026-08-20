/// SAIE — RecommendationRanker
///
/// Converts raw [RecommendationCandidate] output from the Major Matching Engine
/// into ranked [MajorRecommendation] objects with full explanations.
library;

import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/matching/recommendation_candidate.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_confidence.dart';
import 'package:stustep/features/saie/recommendation/recommendation_reason.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationRanker
// ─────────────────────────────────────────────────────────────────────────────

/// Converts matching candidates into enriched [MajorRecommendation] objects.
final class RecommendationRanker {
  static const int _maxRecommendations = 10;

  const RecommendationRanker();

  /// Produces up to 10 [MajorRecommendation] objects from [ranking].
  List<MajorRecommendation> rank({
    required MajorRanking ranking,
    required StudentCognitiveProfile profile,
    required AssessmentStatistics stats,
  }) {
    final candidates = ranking.candidates
        .take(_maxRecommendations)
        .toList();

    final profileStats = profile.computeStatistics();
    final coverage = profileStats.coverageRatio;
    final profileConf = profileStats.overallConfidence;

    return candidates.indexed.map((record) {
      final idx = record.$1;
      final candidate = record.$2;
      final score = candidate.score;

      final confidence = RecommendationConfidence.compute(
        profileConfidence: profileConf,
        evidenceCount: profile.evidenceCount,
        coverageRatio: coverage,
        matchSimilarityScore: score.similarityScore,
      );

      final reasons = _buildReasons(candidate, profile);

      return MajorRecommendation(
        rank: idx + 1,
        majorId: score.majorId,
        majorName: score.majorName,
        majorNameAr: score.majorNameAr,
        category: score.category,
        similarityScore: score.similarityScore,
        confidence: confidence,
        reasons: reasons,
        topStrengths: score.topStrengths,
        weakAreas: score.weakAreas,
        missingSkills: score.missingSkills,
        careerPaths: const [], // Populated by RecommendationGenerator
        explanation: score.explanation,
      );
    }).toList();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  List<RecommendationReason> _buildReasons(
    RecommendationCandidate candidate,
    StudentCognitiveProfile profile,
  ) {
    final reasons = <RecommendationReason>[];
    final score = candidate.score;

    // ── Positive: matched dimension strengths ─────────────────────────────
    for (final key in score.topStrengths.take(5)) {
      final label = DimensionKeys.labelsAr[key] ?? DimensionKeys.labels[key] ?? key;
      final studentScore = profile.scoreFor(key);
      final evidenceCount = profile.dimension(key).evidenceCount;
      final pct = (studentScore * 100).round();

      reasons.add(RecommendationReason(
        type: ReasonType.dimensionStrength,
        title: 'قوة في $label',
        explanation: 'درجتك في $label: $pct٪'
            '${evidenceCount > 0 ? " (بناءً على $evidenceCount ${evidenceCount == 1 ? "دليل" : "أدلة"})" : ""}'
            '. هذا التخصص يتطلب مستوى عالياً في هذا المجال.',
        influence: studentScore,
        positive: true,
      ));
    }

    // ── Negative: dimension gaps ──────────────────────────────────────────
    for (final key in score.weakAreas.take(3)) {
      final label = DimensionKeys.labelsAr[key] ?? DimensionKeys.labels[key] ?? key;
      final studentScore = profile.scoreFor(key);
      final evidenceCount = profile.dimension(key).evidenceCount;
      final pct = (studentScore * 100).round();

      reasons.add(RecommendationReason(
        type: ReasonType.dimensionWeakness,
        title: 'نقص في $label',
        explanation: 'درجتك في $label: $pct٪'
            '${evidenceCount > 0 ? " (بناءً على $evidenceCount ${evidenceCount == 1 ? "دليل" : "أدلة"})" : " (لم يُقيَّم بعد)"}'
            '. هذا التخصص يتطلب مستوى أعلى في هذا المجال.',
        influence: 1.0 - studentScore,
        positive: false,
      ));
    }

    // ── Missing skills ────────────────────────────────────────────────────
    for (final skill in score.missingSkills.take(3)) {
      final label = DimensionKeys.labelsAr[skill] ?? DimensionKeys.labels[skill] ?? skill;
      final evidenceCount = profile.dimension(skill).evidenceCount;

      reasons.add(RecommendationReason(
        type: ReasonType.missingSkill,
        title: 'مهارة مطلوبة غير مؤكدة: $label',
        explanation: evidenceCount == 0
            ? 'هذا التخصص يتطلب "$label" بشكل أساسي، لكن لم تظهر أدلة كافية على هذه المهارة بعد.'
            : 'درجتك في "$label" لم تبلغ الحد المطلوب لهذا التخصص بعد.',
        influence: 0.4,
        positive: false,
      ));
    }

    // ── Market demand ─────────────────────────────────────────────────────
    if (score.marketDemandBoosted) {
      reasons.add(const RecommendationReason(
        type: ReasonType.marketDemand,
        title: 'طلب سوقي مرتفع',
        explanation: 'هذا التخصص يتمتع بطلب توظيف قوي، مما رفع درجته الإجمالية.',
        influence: 0.5,
        positive: true,
      ));
    }

    // Sort: positive first, then by influence descending.
    reasons.sort((a, b) {
      if (a.positive != b.positive) return a.positive ? -1 : 1;
      return b.influence.compareTo(a.influence);
    });
    return reasons;
  }
}
