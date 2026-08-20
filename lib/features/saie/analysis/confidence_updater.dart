/// SAIE — ConfidenceUpdater
///
/// Governs how quickly cognitive dimension confidence increases.
///
/// Rules:
/// - Repeated weak answers do NOT rapidly raise confidence.
/// - Confidence rises faster when backed by strong, diverse evidence.
/// - Contradictory signals reduce confidence instead of increasing it.
/// - Each dimension is evaluated independently.
library;

import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConfidenceUpdatePolicy
// ─────────────────────────────────────────────────────────────────────────────

/// Defines how aggressively confidence is updated for a given context.
enum ConfidenceUpdatePolicy {
  /// Standard update — confidence changes proportionally to evidence quality.
  standard,

  /// Conservative update — used when repeated weak answers are detected.
  conservative,

  /// Aggressive update — used for excellent, well-reasoned answers.
  aggressive,

  /// Decay — contradiction detected; reduce confidence slightly.
  decay,
}

// ─────────────────────────────────────────────────────────────────────────────
// ConfidenceUpdater
// ─────────────────────────────────────────────────────────────────────────────

/// Computes per-dimension confidence deltas and applies them.
///
/// Does NOT modify the profile directly — returns an updated profile.
final class ConfidenceUpdater {
  /// Maximum confidence delta per update cycle for standard policy.
  static const double _standardMaxDelta = 0.08;

  /// Maximum confidence delta for conservative policy.
  static const double _conservativeMaxDelta = 0.02;

  /// Maximum confidence delta for aggressive policy.
  static const double _aggressiveMaxDelta = 0.15;

  /// Decay delta for contradictory signals.
  static const double _decayDelta = -0.05;

  const ConfidenceUpdater();

  /// Applies confidence updates to [profile] for the given [dimensionKeys].
  ///
  /// [consecutiveWeakCount] = how many weak answers the student has given
  /// in a row on the same question set (triggers conservative policy).
  StudentCognitiveProfile update({
    required StudentCognitiveProfile profile,
    required List<String> dimensionKeys,
    required AnswerScore score,
    required bool contradictionDetected,
    int consecutiveWeakCount = 0,
  }) {
    if (dimensionKeys.isEmpty) return profile;

    final policy = _selectPolicy(
      score: score,
      contradictionDetected: contradictionDetected,
      consecutiveWeakCount: consecutiveWeakCount,
    );

    var updatedDimensions = Map<String, CognitiveDimension>.from(
      profile.dimensions,
    );
    bool changed = false;

    for (final key in dimensionKeys) {
      final dim = updatedDimensions[key];
      if (dim == null) continue;

      final newConfidence = _computeNewConfidence(
        current: dim.confidence,
        policy: policy,
        score: score,
      );

      if ((newConfidence - dim.confidence).abs() < 0.001) continue;

      // Apply confidence update (score unchanged, only confidence shifts).
      final now = DateTime.now().toUtc();
      final dimUpdate = DimensionUpdate(
        evidenceId: 'confidence_update',
        previousScore: dim.score,
        newScore: dim.score,
        newConfidence: newConfidence,
        timestamp: now,
        reason: 'ConfidenceUpdater[$policy]: score=${score.total}',
      );
      final updated = dim.withUpdate(
        newScore: dim.score,
        newConfidence: newConfidence,
        update: dimUpdate,
      );

      updatedDimensions[key] = updated;
      changed = true;
    }

    if (!changed) return profile;
    return profile.copyWith(dimensions: updatedDimensions);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  ConfidenceUpdatePolicy _selectPolicy({
    required AnswerScore score,
    required bool contradictionDetected,
    required int consecutiveWeakCount,
  }) {
    if (contradictionDetected) return ConfidenceUpdatePolicy.decay;
    if (consecutiveWeakCount >= 3) return ConfidenceUpdatePolicy.conservative;
    if (score.band == ScoreBand.excellent) return ConfidenceUpdatePolicy.aggressive;
    return ConfidenceUpdatePolicy.standard;
  }

  double _computeNewConfidence({
    required double current,
    required ConfidenceUpdatePolicy policy,
    required AnswerScore score,
  }) {
    final qualityFactor = score.total / 100.0;

    final delta = switch (policy) {
      ConfidenceUpdatePolicy.standard =>
        _standardMaxDelta * qualityFactor,
      ConfidenceUpdatePolicy.conservative =>
        _conservativeMaxDelta * qualityFactor,
      ConfidenceUpdatePolicy.aggressive =>
        _aggressiveMaxDelta * qualityFactor,
      ConfidenceUpdatePolicy.decay => _decayDelta,
    };

    return (current + delta).clamp(0.0, 1.0);
  }
}
