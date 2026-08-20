/// SAIE — DimensionUpdater
///
/// Applies extracted [StudentEvidence] to the [StudentCognitiveProfile],
/// updating only the dimensions referenced by the evidence.
/// Unrelated dimensions are NEVER touched.
///
/// Also computes an updated list of unevidenced dimension keys for the
/// [ConversationContext].
library;

import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimensionUpdateResult
// ─────────────────────────────────────────────────────────────────────────────

/// The result of applying evidence to the cognitive profile.
final class DimensionUpdateResult {
  /// The updated profile after applying all evidence.
  final StudentCognitiveProfile updatedProfile;

  /// Keys of the dimensions that were actually modified.
  final List<String> updatedDimensionKeys;

  /// Dimension keys that still have zero evidence (not yet evidenced).
  final List<String> remainingUnevidencedKeys;

  const DimensionUpdateResult({
    required this.updatedProfile,
    required this.updatedDimensionKeys,
    required this.remainingUnevidencedKeys,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DimensionUpdater
// ─────────────────────────────────────────────────────────────────────────────

/// Applies evidence to a profile and returns an immutable updated profile.
///
/// - Only dimensions referenced in [evidence.affectedDimensions] are updated.
/// - Evidence is applied via [StudentCognitiveProfile.applyEvidence()].
/// - Confidence increases only when the evidence quality justifies it.
final class DimensionUpdater {
  const DimensionUpdater();

  /// Applies all [evidenceList] to [profile] and returns a [DimensionUpdateResult].
  ///
  /// [sessionId] is forwarded to [StudentCognitiveProfile.applyEvidence].
  DimensionUpdateResult apply({
    required StudentCognitiveProfile profile,
    required List<StudentEvidence> evidenceList,
    String sessionId = 'analysis_session',
  }) {
    if (evidenceList.isEmpty) {
      return DimensionUpdateResult(
        updatedProfile: profile,
        updatedDimensionKeys: const [],
        remainingUnevidencedKeys: _unevidencedKeys(profile),
      );
    }

    StudentCognitiveProfile current = profile;
    final updatedKeys = <String>{};

    for (final evidence in evidenceList) {
      current = current.applyEvidence(evidence, sessionId: sessionId);
      updatedKeys.addAll(evidence.affectedDimensions.keys);
    }

    return DimensionUpdateResult(
      updatedProfile: current,
      updatedDimensionKeys: updatedKeys.toList(),
      remainingUnevidencedKeys: _unevidencedKeys(current),
    );
  }

  /// Returns dimension keys with zero evidence count in [profile].
  List<String> _unevidencedKeys(StudentCognitiveProfile profile) =>
      profile.dimensions.entries
          .where((e) => e.value.evidenceCount == 0)
          .map((e) => e.key)
          .toList();
}
