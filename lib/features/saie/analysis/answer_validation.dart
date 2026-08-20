/// SAIE — AnswerValidation
///
/// Validates a raw answer string before it enters the scoring pipeline.
/// Invalid answers are rejected immediately — no evidence is extracted and
/// no profile update occurs.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ValidationStatus
// ─────────────────────────────────────────────────────────────────────────────

/// The result of answer validation.
enum ValidationStatus {
  /// Answer is valid and may proceed to scoring.
  valid,

  /// Answer is empty or contains only whitespace.
  empty,

  /// Answer is a random string of characters with no semantic content.
  random,

  /// Answer is meaninglessly short (e.g. a single punctuation character).
  meaningless,

  /// Answer is spam — identical to a recently submitted answer.
  spam,
}

extension ValidationStatusX on ValidationStatus {
  bool get isValid => this == ValidationStatus.valid;
  String get reason => switch (this) {
    ValidationStatus.valid => 'Answer is valid.',
    ValidationStatus.empty => 'Answer is empty or whitespace-only.',
    ValidationStatus.random => 'Answer appears to be random text.',
    ValidationStatus.meaningless =>
      'Answer is too short to carry meaning.',
    ValidationStatus.spam => 'Answer is a duplicate of a recent submission.',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ValidationResult
// ─────────────────────────────────────────────────────────────────────────────

/// The result of validating a raw answer.
final class ValidationResult extends Equatable {
  /// The validation status.
  final ValidationStatus status;

  /// The normalised answer text (if valid).
  final String normalisedText;

  /// A human-readable description of why the answer was rejected (if any).
  final String reason;

  const ValidationResult({
    required this.status,
    required this.normalisedText,
    required this.reason,
  });

  bool get isValid => status.isValid;

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      ValidationResult(
        status: ValidationStatus.values.byName(json['status'] as String),
        normalisedText: json['normalised_text'] as String,
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'normalised_text': normalisedText,
    'reason': reason,
  };

  ValidationResult copyWith({
    ValidationStatus? status,
    String? normalisedText,
    String? reason,
  }) => ValidationResult(
    status: status ?? this.status,
    normalisedText: normalisedText ?? this.normalisedText,
    reason: reason ?? this.reason,
  );

  @override
  List<Object?> get props => [status, normalisedText];
}

// ─────────────────────────────────────────────────────────────────────────────
// AnswerValidator
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless validator that rejects invalid answers before scoring.
final class AnswerValidator {
  /// Maximum ratio of unique characters to total characters for random detection.
  static const double _maxRandomnessRatio = 0.85;

  /// Minimum word count for a non-meaningless answer.
  static const int _minWords = 1;

  const AnswerValidator();

  /// Validates [rawAnswer] against [recentAnswers] (for spam detection).
  ValidationResult validate({
    required String rawAnswer,
    List<String> recentAnswers = const [],
  }) {
    final trimmed = rawAnswer.trim().replaceAll(RegExp(r'\s+'), ' ');

    // ── Empty ──
    if (trimmed.isEmpty) {
      return const ValidationResult(
        status: ValidationStatus.empty,
        normalisedText: '',
        reason: 'Answer is empty.',
      );
    }

    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // ── Meaningless (single punctuation, emoji-only, etc.) ──
    if (words.length < _minWords || trimmed.replaceAll(RegExp(r'[^\w]'), '').isEmpty) {
      return ValidationResult(
        status: ValidationStatus.meaningless,
        normalisedText: trimmed,
        reason: 'Answer contains no meaningful words.',
      );
    }

    // ── Spam (exact duplicate of recent answer) ──
    final lowerTrimmed = trimmed.toLowerCase();
    for (final recent in recentAnswers) {
      if (recent.trim().toLowerCase() == lowerTrimmed) {
        return ValidationResult(
          status: ValidationStatus.spam,
          normalisedText: trimmed,
          reason: 'Answer is identical to a recent submission.',
        );
      }
    }

    // ── Random text detection ──
    // Heuristic: very high ratio of unique characters suggests keyboard mashing.
    if (trimmed.length >= 8) {
      final uniqueChars = trimmed.replaceAll(' ', '').split('').toSet().length;
      final totalChars = trimmed.replaceAll(' ', '').length;
      final randomnessRatio = uniqueChars / totalChars;
      // Also check for no vowels (Arabic or English) as a secondary signal.
      final hasVowels = RegExp(r'[aeiouAEIOUاوي]').hasMatch(trimmed);
      if (randomnessRatio > _maxRandomnessRatio && !hasVowels) {
        return ValidationResult(
          status: ValidationStatus.random,
          normalisedText: trimmed,
          reason: 'Answer appears to be random keyboard input.',
        );
      }
    }

    return ValidationResult(
      status: ValidationStatus.valid,
      normalisedText: trimmed,
      reason: 'Answer is valid.',
    );
  }
}
