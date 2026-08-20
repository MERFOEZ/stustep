/// SAIE — LearningStyleProfile
///
/// Tracks the student's learning modality preferences across four primary
/// dimensions, each backed by a [CognitiveDimension] for full evidence tracking.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LearningModality
// ─────────────────────────────────────────────────────────────────────────────

/// The four primary VARK learning modalities tracked by SAIE.
enum LearningModality {
  /// Prefers diagrams, charts, spatial layouts, and visual structure.
  visual,

  /// Prefers reading text, writing notes, and lists.
  readWrite,

  /// Prefers listening to explanations, discussions, and verbal instruction.
  auditory,

  /// Prefers hands-on practice, experimentation, and physical activity.
  kinesthetic,
}

// ─────────────────────────────────────────────────────────────────────────────
// LearningStyleProfile
// ─────────────────────────────────────────────────────────────────────────────

/// Full VARK-based learning style profile with evidence tracking per modality.
///
/// The dominant modality is computed from the dimension scores.
/// If no modality exceeds the dominance threshold, [isMultimodal] is true.
final class LearningStyleProfile extends Equatable {
  /// Map from [LearningModality.name] → tracked [CognitiveDimension].
  final Map<String, CognitiveDimension> modalities;

  /// UTC timestamp of the last update.
  final DateTime lastUpdated;

  /// Minimum score for a modality to be considered dominant.
  static const double _dominanceThreshold = 0.55;

  const LearningStyleProfile({
    required this.modalities,
    required this.lastUpdated,
  });

  factory LearningStyleProfile.initial() {
    final now = DateTime.now().toUtc();
    return LearningStyleProfile(
      modalities: {
        for (final m in LearningModality.values)
          m.name: CognitiveDimension.initial(
            key: m.name,
            label: _modalityLabel(m),
          ),
      },
      lastUpdated: now,
    );
  }

  factory LearningStyleProfile.fromJson(Map<String, dynamic> json) =>
      LearningStyleProfile(
        modalities: (json['modalities'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            CognitiveDimension.fromJson(v as Map<String, dynamic>),
          ),
        ),
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );

  Map<String, dynamic> toJson() => {
    'modalities': modalities.map((k, v) => MapEntry(k, v.toJson())),
    'last_updated': lastUpdated.toIso8601String(),
  };

  LearningStyleProfile copyWith({
    Map<String, CognitiveDimension>? modalities,
    DateTime? lastUpdated,
  }) => LearningStyleProfile(
    modalities: modalities ?? this.modalities,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  /// Returns the [CognitiveDimension] for [modality].
  CognitiveDimension dimensionFor(LearningModality modality) =>
      modalities[modality.name] ??
      CognitiveDimension.initial(
        key: modality.name,
        label: _modalityLabel(modality),
      );

  /// Returns a new profile with [modality] dimension replaced.
  LearningStyleProfile withUpdatedModality(
    LearningModality modality,
    CognitiveDimension dimension,
  ) => copyWith(
    modalities: {...modalities, modality.name: dimension},
    lastUpdated: DateTime.now().toUtc(),
  );

  /// Returns the dominant modality, or `null` if multimodal.
  LearningModality? get dominantModality {
    LearningModality? best;
    double bestScore = _dominanceThreshold;
    for (final m in LearningModality.values) {
      final score = dimensionFor(m).score;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  /// Returns `true` if no single modality is clearly dominant.
  bool get isMultimodal => dominantModality == null;

  static String _modalityLabel(LearningModality m) => switch (m) {
    LearningModality.visual => 'Visual',
    LearningModality.readWrite => 'Read / Write',
    LearningModality.auditory => 'Auditory',
    LearningModality.kinesthetic => 'Kinesthetic',
  };

  @override
  List<Object?> get props => [modalities, lastUpdated];
}
