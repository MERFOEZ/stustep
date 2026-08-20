/// SAIE — MajorSimilarityCalculator
///
/// Computes the weighted similarity score between a [StudentCognitiveProfile]
/// and a single [Major].
///
/// Scoring algorithm:
/// 1. Dimension similarity  — weighted cosine-style comparison (70% weight).
/// 2. Personality fit       — dot-product against major's personalityWeights (15%).
/// 3. Learning style fit    — dot-product against learningStyleAffinities (10%).
/// 4. Interest alignment    — overlap between student interests and major tags (5%).
///
/// The raw composite is then optionally boosted by market demand.
library;

import 'package:stustep/features/saie/matching/major_score.dart';
import 'package:stustep/features/saie/matching/matching_configuration.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/profile/learning_style.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_personality.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MajorSimilarityCalculator
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless calculator that scores one major against one profile.
final class MajorSimilarityCalculator {
  /// Relative weight of cognitive-dimension alignment (0–1).
  static const double _wDimensions = 0.70;

  /// Relative weight of personality fit.
  static const double _wPersonality = 0.15;

  /// Relative weight of learning-style fit.
  static const double _wLearningStyle = 0.10;

  /// Relative weight of interest/tag alignment.
  static const double _wInterests = 0.05;

  const MajorSimilarityCalculator();

  /// Computes a [MajorScore] for [major] against [profile].
  MajorScore calculate({
    required Major major,
    required StudentCognitiveProfile profile,
    required MatchingConfiguration config,
  }) {
    // ── Build normalised weight map ──────────────────────────────────────
    final weights = _normaliseWeights(config.dimensionWeights);

    // ── 1. Dimension similarity ──────────────────────────────────────────
    final contributions = <DimensionContribution>[];
    double dimScore = 0.0;

    for (final key in DimensionKeys.all) {
      final weight = weights[key] ?? 0.0;
      if (weight == 0.0) continue;

      final studentScore = profile.scoreFor(key); // [0.0, 1.0]
      final confidence = profile.confidenceFor(key);

      // Major's expected value for this dimension is derived from:
      // - required skills → 1.0
      // - preferred skills → 0.6
      // - tag alignment → 0.4
      // - default → 0.3 (majors don't explicitly set every dimension)
      final majorExpectation = _majorExpectationFor(key, major);

      // Similarity for this dimension: 1 - |student - expected|
      // Scaled by confidence so low-confidence dimensions contribute less.
      final rawSim = (1.0 - (studentScore - majorExpectation).abs()).clamp(0.0, 1.0);
      final weightedSim = rawSim * weight * confidence;

      dimScore += weightedSim;

      final met = studentScore >= (majorExpectation - 0.15);

      contributions.add(DimensionContribution(
        dimensionKey: key,
        label: DimensionKeys.labels[key] ?? key,
        studentScore: studentScore,
        majorExpectation: majorExpectation,
        weight: weight,
        weightedContribution: weightedSim * 100,
        met: met,
      ));
    }

    // Normalise dimension score to [0, 1].
    // dimScore is already weighted, but confidence deflation means it can be
    // less than 1 even for perfect matches. Scale to 100-point space.
    final maxPossibleDimScore = weights.values.fold(0.0, (a, b) => a + b);
    final normDimScore = maxPossibleDimScore > 0
        ? (dimScore / maxPossibleDimScore).clamp(0.0, 1.0)
        : 0.0;

    // ── 2. Personality fit ───────────────────────────────────────────────
    final personalityFit = _personalityFit(major, profile.personality);

    // ── 3. Learning-style fit ────────────────────────────────────────────
    final learningStyleFit = _learningStyleFit(major, profile.learningStyle);

    // ── 4. Interest alignment ────────────────────────────────────────────
    final interestAlignment = _interestAlignment(major, profile);

    // ── Composite score ──────────────────────────────────────────────────
    final composite = (normDimScore * _wDimensions) +
        (personalityFit * _wPersonality) +
        (learningStyleFit * _wLearningStyle) +
        (interestAlignment * _wInterests);

    double raw = composite * 100.0;

    // ── Market demand boost ──────────────────────────────────────────────
    bool boosted = false;
    if (config.applyMarketDemandBoost) {
      raw += major.marketDemand * config.marketDemandBoostMax;
      boosted = true;
    }

    final finalScore = raw.round().clamp(0, 100);

    // ── Aggregate confidence ─────────────────────────────────────────────
    final overallConfidence = _computeOverallConfidence(profile, contributions);

    // ── Strengths / gaps ─────────────────────────────────────────────────
    final matched = contributions.where((c) => c.met).map((c) => c.dimensionKey).toList();
    final unmatched = contributions.where((c) => !c.met).map((c) => c.dimensionKey).toList();

    final topStrengths = _topStrengths(contributions, profile)
        .take(5)
        .map((c) => c.dimensionKey)
        .toList();
    final missingSkills = _missingSkills(major, profile);
    final weakAreas = _weakAreas(contributions)
        .take(5)
        .map((c) => c.dimensionKey)
        .toList();

    return MajorScore(
      majorId: major.id,
      majorName: major.name,
      majorNameAr: major.nameAr,
      category: major.category,
      similarityScore: finalScore,
      contributions: contributions,
      matchedDimensions: matched,
      unmatchedDimensions: unmatched,
      topStrengths: topStrengths,
      missingSkills: missingSkills,
      weakAreas: weakAreas,
      confidence: overallConfidence,
      evidenceUsed: profile.evidenceCount,
      personalityFit: personalityFit,
      learningStyleFit: learningStyleFit,
      marketDemandBoosted: boosted,
      explanation: _buildExplanation(
        major: major,
        finalScore: finalScore,
        normDimScore: normDimScore,
        personalityFit: personalityFit,
        learningStyleFit: learningStyleFit,
        matchedCount: matched.length,
        unmatchedCount: unmatched.length,
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, double> _normaliseWeights(Map<String, double> raw) {
    final total = raw.values.fold(0.0, (a, b) => a + b);
    if (total == 0.0) return raw;
    return raw.map((k, v) => MapEntry(k, v / total));
  }

  /// Derives the major's expected score [0.0, 1.0] for a given [DimensionKey].
  ///
  /// Lookup order:
  /// 1. [Major.requiredSkillIds] → 1.0  (must-have dimension)
  /// 2. [Major.preferredSkillIds] → 0.65 (beneficial dimension)
  /// 3. [Major.tags] that are canonical dimension keys → 0.45
  /// 4. No explicit expectation → 0.0 (not a requirement for this major)
  ///
  /// The previous fallback of `0.30` for unknown keys is removed. A flat 0.30
  /// for every unrecognised string silently accepted invalid skill IDs and made
  /// all majors score identically on unmapped dimensions. Now, if a major does
  /// not explicitly list a dimension as required or preferred, its expectation
  /// for that dimension is 0.0 — meaning it does not distinguish on that axis.
  double _majorExpectationFor(String key, Major major) {
    if (major.requiredSkillIds.contains(key)) return 1.0;
    if (major.preferredSkillIds.contains(key)) return 0.65;
    // Only treat tags as dimension proxies when they are canonical keys.
    if (major.tags.contains(key) && DimensionKeys.all.contains(key)) return 0.45;
    // No explicit expectation for this dimension.
    return 0.0;
  }

  double _personalityFit(Major major, StudentPersonality personality) {
    if (major.personalityWeights.isEmpty) return 0.5;

    double dot = 0.0;
    double norm = 0.0;

    for (final entry in major.personalityWeights.entries) {
      final axisKey = entry.key;
      final importance = entry.value;

      // Try to find matching PersonalityAxis.
      PersonalityAxis? axis;
      try {
        axis = PersonalityAxis.values.byName(axisKey);
      } catch (_) {
        continue;
      }

      final studentScore = personality.dimensionFor(axis).score;
      dot += studentScore * importance;
      norm += importance;
    }

    return norm > 0 ? (dot / norm).clamp(0.0, 1.0) : 0.5;
  }

  double _learningStyleFit(
    Major major,
    LearningStyleProfile learningStyle,
  ) {
    if (major.learningStyleAffinities.isEmpty) return 0.5;

    double dot = 0.0;
    double norm = 0.0;

    for (final entry in major.learningStyleAffinities.entries) {
      LearningModality? modality;
      try {
        modality = LearningModality.values.byName(entry.key);
      } catch (_) {
        continue;
      }

      final studentScore = learningStyle.dimensionFor(modality).score;
      dot += studentScore * entry.value;
      norm += entry.value;
    }

    return norm > 0 ? (dot / norm).clamp(0.0, 1.0) : 0.5;
  }

  double _interestAlignment(Major major, StudentCognitiveProfile profile) {
    if (profile.interests.isEmpty) return 0.0;

    // StudentInterest.relatedDomainIds contains the domain keys.
    final studentInterestIds = profile.interests
        .expand((i) => i.relatedDomainIds)
        .map((id) => id.toLowerCase())
        .toSet();
    if (studentInterestIds.isEmpty) return 0.0;

    final majorTagsLower = major.tags.map((t) => t.toLowerCase()).toSet();
    final majorCategoryTag = major.category.name.toLowerCase();

    final overlap = studentInterestIds
        .where((id) => majorTagsLower.contains(id) || id == majorCategoryTag)
        .length;

    return (overlap / studentInterestIds.length).clamp(0.0, 1.0);
  }

  double _computeOverallConfidence(
    StudentCognitiveProfile profile,
    List<DimensionContribution> contributions,
  ) {
    if (contributions.isEmpty) return 0.0;
    double total = 0.0;
    for (final c in contributions) {
      total += profile.confidenceFor(c.dimensionKey);
    }
    return (total / contributions.length).clamp(0.0, 1.0);
  }

  List<DimensionContribution> _topStrengths(
    List<DimensionContribution> contributions,
    StudentCognitiveProfile profile,
  ) {
    final result = contributions
        .where((c) => c.met && c.studentScore >= 0.6)
        .toList()
      ..sort((a, b) => b.studentScore.compareTo(a.studentScore));
    return result;
  }

  /// Returns dimension keys where the student's score is below the threshold
  /// for this major's requirements.
  ///
  /// Only canonical [DimensionKeys] are reported. Any skill ID in the major's
  /// JSON that is not a canonical dimension key is skipped — it cannot be
  /// meaningfully compared against the student's cognitive profile.
  List<String> _missingSkills(Major major, StudentCognitiveProfile profile) {
    final validKeys = DimensionKeys.all.toSet();
    final missing = <String>[];
    for (final skillId in major.requiredSkillIds) {
      // Only compare against dimensions that exist in the profile.
      if (!validKeys.contains(skillId)) continue;
      final score = profile.scoreFor(skillId);
      if (score < 0.40) missing.add(skillId);
    }
    for (final skillId in major.preferredSkillIds) {
      if (!validKeys.contains(skillId)) continue;
      final score = profile.scoreFor(skillId);
      if (score < 0.30) missing.add(skillId);
    }
    return missing;
  }

  List<DimensionContribution> _weakAreas(
    List<DimensionContribution> contributions,
  ) {
    final result = contributions
        .where((c) => !c.met && c.majorExpectation >= 0.50)
        .toList()
      ..sort((a, b) => a.studentScore.compareTo(b.studentScore));
    return result;
  }

  String _buildExplanation({
    required Major major,
    required int finalScore,
    required double normDimScore,
    required double personalityFit,
    required double learningStyleFit,
    required int matchedCount,
    required int unmatchedCount,
  }) =>
      '${major.name}: score=$finalScore | '
      'dim=${(normDimScore * 100).toStringAsFixed(1)}% '
      'personality=${(personalityFit * 100).toStringAsFixed(1)}% '
      'learning=${(learningStyleFit * 100).toStringAsFixed(1)}% | '
      'matched=$matchedCount unmatched=$unmatchedCount';
}
