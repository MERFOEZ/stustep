/// SAIE — ReasonBuilder
///
/// Builds structured, human-readable [RecommendationReason] lists from
/// [MajorScore] contributions and [StudentCognitiveProfile] signals.
library;

import 'package:stustep/features/saie/matching/major_score.dart';
import 'package:stustep/features/saie/profile/learning_style.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_personality.dart';
import 'package:stustep/features/saie/recommendation/recommendation_reason.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReasonBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Constructs [RecommendationReason] lists from matching engine output.
final class ReasonBuilder {
  const ReasonBuilder();

  /// Builds the full reason list for one [MajorScore].
  List<RecommendationReason> buildFor({
    required MajorScore score,
    required StudentCognitiveProfile profile,
  }) {
    final reasons = <RecommendationReason>[];

    reasons.addAll(_dimensionReasons(score, profile));
    reasons.addAll(_personalityReasons(score, profile));
    reasons.addAll(_learningStyleReasons(score, profile));
    reasons.addAll(_missingSkillReasons(score));
    reasons.addAll(_evidenceReasons(score, profile));
    if (score.marketDemandBoosted) {
      reasons.add(_marketDemandReason());
    }

    // Sort: positive first, then by influence descending.
    reasons.sort((a, b) {
      if (a.positive != b.positive) return b.positive ? 1 : -1;
      return b.influence.compareTo(a.influence);
    });

    return reasons;
  }

  // ─── Dimension contributions ─────────────────────────────────────────────

  List<RecommendationReason> _dimensionReasons(
    MajorScore score,
    StudentCognitiveProfile profile,
  ) {
    final reasons = <RecommendationReason>[];

    for (final contrib in score.contributions) {
      final label = DimensionKeys.labels[contrib.dimensionKey] ??
          contrib.dimensionKey;
      final studentPct =
          (contrib.studentScore * 100).toStringAsFixed(0);
      final expectPct =
          (contrib.majorExpectation * 100).toStringAsFixed(0);

      if (contrib.met) {
        reasons.add(RecommendationReason(
          type: ReasonType.dimensionStrength,
          title: 'Strong in $label',
          explanation:
              'Your $label score ($studentPct%) meets or exceeds what '
              'this major expects ($expectPct%). This contributed '
              '${(contrib.weightedContribution * 100).toStringAsFixed(1)} '
              'points to the matching score.',
          influence: contrib.weightedContribution.clamp(0.0, 1.0),
          positive: true,
        ));
      } else {
        reasons.add(RecommendationReason(
          type: ReasonType.dimensionWeakness,
          title: 'Gap in $label',
          explanation:
              'Your $label score ($studentPct%) is below what this major '
              'requires ($expectPct%). Developing this area will '
              'significantly improve your fit.',
          influence: (contrib.majorExpectation - contrib.studentScore)
              .abs()
              .clamp(0.0, 1.0),
          positive: false,
        ));
      }
    }

    return reasons;
  }

  // ─── Personality alignment ───────────────────────────────────────────────

  List<RecommendationReason> _personalityReasons(
    MajorScore score,
    StudentCognitiveProfile profile,
  ) {
    final reasons = <RecommendationReason>[];
    final axes = profile.personality.axes;
    if (axes.isEmpty) return reasons;

    double totalAlignment = 0.0;
    int axisCount = 0;

    for (final entry in axes.entries) {
      final axisEnum = PersonalityAxis.values.firstWhere(
        (a) => a.name == entry.key,
        orElse: () => PersonalityAxis.values.first,
      );
      final studentValue = entry.value.score; // range [-1.0, 1.0]
      // Build a descriptive label from the axis name and polarity.
      final label = studentValue >= 0
          ? '${_capitalise(axisEnum.name)} (high)'
          : '${_capitalise(axisEnum.name)} (low)';
      totalAlignment += studentValue.abs();
      axisCount++;

      if (studentValue.abs() >= 0.5) {
        reasons.add(RecommendationReason(
          type: ReasonType.personalityAlignment,
          title: 'Personality: $label',
          explanation:
              'Your personality profile shows a strong tendency toward '
              '"$label", which aligns with this major\'s expected traits.',
          influence: studentValue.abs().clamp(0.0, 1.0),
          positive: true,
        ));
      }
    }

    if (axisCount > 0 && totalAlignment / axisCount < 0.30) {
      reasons.add(const RecommendationReason(
        type: ReasonType.personalityAlignment,
        title: 'Personality profile unclear',
        explanation:
            'Not enough personality signals were collected to fully '
            'assess the fit. Further assessment may refine this.',
        influence: 0.2,
        positive: false,
      ));
    }

    return reasons;
  }

  // ─── Learning style ──────────────────────────────────────────────────────

  List<RecommendationReason> _learningStyleReasons(
    MajorScore score,
    StudentCognitiveProfile profile,
  ) {
    final dominant = profile.learningStyle.dominantModality;
    if (dominant == null) return const [];
    final label = _modalityLabel(dominant);
    return [
      RecommendationReason(
        type: ReasonType.learningStyleMatch,
        title: 'Learning Style: $label',
        explanation:
            'Your dominant learning style is "$label". '
            'This major is well-suited to this learning approach.',
        influence: 0.60,
        positive: true,
      ),
    ];
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _modalityLabel(LearningModality m) => switch (m) {
    LearningModality.visual => 'Visual',
    LearningModality.readWrite => 'Read/Write',
    LearningModality.auditory => 'Auditory',
    LearningModality.kinesthetic => 'Kinesthetic',
  };

  // ─── Missing skills ──────────────────────────────────────────────────────

  List<RecommendationReason> _missingSkillReasons(MajorScore score) =>
      score.missingSkills.take(4).map((skill) => RecommendationReason(
        type: ReasonType.missingSkill,
        title: 'Missing prerequisite: $skill',
        explanation:
            'This major requires "$skill". This has not yet been '
            'demonstrated in your assessment. It represents a development '
            'opportunity before or during your studies.',
        influence: 0.40,
        positive: false,
      )).toList();

  // ─── Evidence signals ────────────────────────────────────────────────────

  List<RecommendationReason> _evidenceReasons(
    MajorScore score,
    StudentCognitiveProfile profile,
  ) {
    final reasons = <RecommendationReason>[];
    final highWeightEvidence = profile.evidence
        .where((e) => e.weight >= 0.70)
        .take(3)
        .toList();

    for (final ev in highWeightEvidence) {
      reasons.add(RecommendationReason(
        type: ReasonType.supportingEvidence,
        title: 'Strong evidence: "${ev.rawValue.length > 60 ? "${ev.rawValue.substring(0, 60)}…" : ev.rawValue}"',
        explanation: ev.reason,
        influence: ev.weight.clamp(0.0, 1.0),
        positive: true,
      ));
    }

    final lowWeightEvidence = profile.evidence
        .where((e) => e.weight < 0.20 && e.weight > 0.0)
        .take(2)
        .toList();

    for (final ev in lowWeightEvidence) {
      reasons.add(RecommendationReason(
        type: ReasonType.conflictingEvidence,
        title: 'Weak signal: "${ev.rawValue.length > 60 ? "${ev.rawValue.substring(0, 60)}…" : ev.rawValue}"',
        explanation:
            'This answer had low evidence weight and contributed less '
            'to the overall profile.',
        influence: ev.weight.clamp(0.0, 1.0),
        positive: false,
      ));
    }

    return reasons;
  }

  // ─── Market demand ───────────────────────────────────────────────────────

  RecommendationReason _marketDemandReason() => const RecommendationReason(
    type: ReasonType.marketDemand,
    title: 'High Market Demand',
    explanation:
        'This major has strong employment market demand, which increased '
        'its score. Graduates in this field have strong career prospects.',
    influence: 0.50,
    positive: true,
  );
}
