/// SAIE — Core Extensions & Utilities
///
/// Extension methods and pure utility functions that are domain-agnostic
/// and safe to import from any layer.
library;

import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConfidenceLevel Extensions
// ─────────────────────────────────────────────────────────────────────────────

extension ConfidenceLevelX on ConfidenceLevel {
  /// Returns a numeric score in [0.0, 1.0] representing this confidence level.
  double get score => switch (this) {
    ConfidenceLevel.veryLow => 0.1,
    ConfidenceLevel.low => 0.3,
    ConfidenceLevel.moderate => 0.5,
    ConfidenceLevel.high => 0.75,
    ConfidenceLevel.veryHigh => 0.95,
  };

  /// Returns a human-readable label.
  String get label => switch (this) {
    ConfidenceLevel.veryLow => 'Very Low',
    ConfidenceLevel.low => 'Low',
    ConfidenceLevel.moderate => 'Moderate',
    ConfidenceLevel.high => 'High',
    ConfidenceLevel.veryHigh => 'Very High',
  };

  /// Constructs a [ConfidenceLevel] from a [0.0, 1.0] score.
  static ConfidenceLevel fromScore(double score) {
    if (score < 0.2) return ConfidenceLevel.veryLow;
    if (score < 0.4) return ConfidenceLevel.low;
    if (score < 0.6) return ConfidenceLevel.moderate;
    if (score < 0.85) return ConfidenceLevel.high;
    return ConfidenceLevel.veryHigh;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AssessmentPhase Extensions
// ─────────────────────────────────────────────────────────────────────────────

extension AssessmentPhaseX on AssessmentPhase {
  /// Returns `true` if the session can still accept new questions.
  bool get isActive =>
      this != AssessmentPhase.completed &&
      this != AssessmentPhase.synthesis;

  /// Returns the phase that follows this one (if any).
  AssessmentPhase? get next => switch (this) {
    AssessmentPhase.onboarding => AssessmentPhase.exploration,
    AssessmentPhase.exploration => AssessmentPhase.deepening,
    AssessmentPhase.deepening => AssessmentPhase.calibration,
    AssessmentPhase.calibration => AssessmentPhase.synthesis,
    AssessmentPhase.synthesis => AssessmentPhase.completed,
    AssessmentPhase.completed => null,
  };

  /// Human-readable phase label.
  String get label => switch (this) {
    AssessmentPhase.onboarding => 'Onboarding',
    AssessmentPhase.exploration => 'Exploration',
    AssessmentPhase.deepening => 'Deepening',
    AssessmentPhase.calibration => 'Calibration',
    AssessmentPhase.synthesis => 'Synthesis',
    AssessmentPhase.completed => 'Completed',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerQuality Extensions
// ─────────────────────────────────────────────────────────────────────────────

extension AnswerQualityX on AnswerQuality {
  /// Returns a weight multiplier used when scoring evidence signals.
  double get evidenceWeight => switch (this) {
    AnswerQuality.strong => 1.0,
    AnswerQuality.moderate => 0.6,
    AnswerQuality.weak => 0.3,
    AnswerQuality.invalid => 0.0,
    AnswerQuality.skipped => 0.0,
  };

  /// Returns `true` if this answer quality contributes positive evidence.
  bool get isContributory =>
      this == AnswerQuality.strong || this == AnswerQuality.moderate;
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorCategory Extensions
// ─────────────────────────────────────────────────────────────────────────────

extension MajorCategoryX on MajorCategory {
  /// Returns a human-readable display name for the category.
  String get displayName => switch (this) {
    MajorCategory.stem => 'Science & Technology',
    MajorCategory.business => 'Business & Economics',
    MajorCategory.healthAndMedicine => 'Health & Medicine',
    MajorCategory.lawAndGovernance => 'Law & Governance',
    MajorCategory.computingAndTechnology => 'Computing & Technology',
    MajorCategory.artsAndDesign => 'Arts & Design',
    MajorCategory.socialAndHumanities => 'Social Sciences & Humanities',
    MajorCategory.education => 'Education',
    MajorCategory.agricultureAndEnvironment => 'Agriculture & Environment',
    MajorCategory.languagesAndCommunication => 'Languages & Communication',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// String Extensions
// ─────────────────────────────────────────────────────────────────────────────

extension StringSafeX on String {
  /// Returns `null` if the string is blank, otherwise returns `this`.
  String? get nullIfBlank => trim().isEmpty ? null : this;

  /// Capitalizes the first letter of each word.
  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// List Extensions
// ─────────────────────────────────────────────────────────────────────────────

extension ListSafeX<T> on List<T> {
  /// Returns the element at [index], or [defaultValue] if out of range.
  T getOrDefault(int index, T defaultValue) =>
      index >= 0 && index < length ? this[index] : defaultValue;

  /// Returns a new list with [element] appended, without mutating the original.
  List<T> appended(T element) => [...this, element];

  /// Returns a new list with the element at [index] replaced by [element].
  List<T> replaced(int index, T element) => [
    ...sublist(0, index),
    element,
    ...sublist(index + 1),
  ];
}
