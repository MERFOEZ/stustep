/// SAIE — Utils Layer
///
/// Pure utility functions with no Flutter or domain dependencies.
library;

import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ID Generation
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless UUID v4 generator wrapper.
///
/// Provides deterministic ID generation for all SAIE entities.
final class IdGenerator {
  const IdGenerator._();

  static const Uuid _uuid = Uuid();

  /// Generates a new unique UUID v4 string.
  static String generate() => _uuid.v4();

  /// Generates a new UUID v4 and prefixes it with [prefix].
  ///
  /// Example: `IdGenerator.prefixed('session')` → `"session_a1b2c3d4-..."`
  static String prefixed(String prefix) => '${prefix}_${_uuid.v4()}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Date/Time Utilities
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless date/time helpers for SAIE engine use.
final class DateTimeUtils {
  const DateTimeUtils._();

  /// Returns the current UTC [DateTime].
  static DateTime nowUtc() => DateTime.now().toUtc();

  /// Returns the difference in minutes between [from] and [to].
  static int minutesBetween(DateTime from, DateTime to) =>
      to.difference(from).inMinutes.abs();

  /// Returns `true` if [timestamp] is older than [minutes] minutes.
  static bool isOlderThan(DateTime timestamp, int minutes) =>
      minutesBetween(timestamp, nowUtc()) >= minutes;
}

// ─────────────────────────────────────────────────────────────────────────────
// Scoring Math
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless math utilities for evidence scoring and normalization.
final class ScoringMath {
  const ScoringMath._();

  /// Clamps [value] to the range [min, max].
  static double clamp(double value, {double min = 0.0, double max = 1.0}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Computes a weighted average of [scores] using parallel [weights].
  ///
  /// [scores] and [weights] must have the same length.
  /// Returns 0.0 if lists are empty.
  static double weightedAverage(List<double> scores, List<double> weights) {
    assert(
      scores.length == weights.length,
      'scores and weights must have the same length',
    );
    if (scores.isEmpty) return 0.0;

    double numerator = 0;
    double denominator = 0;
    for (int i = 0; i < scores.length; i++) {
      numerator += scores[i] * weights[i];
      denominator += weights[i];
    }
    return denominator == 0 ? 0.0 : clamp(numerator / denominator);
  }

  /// Normalizes a list of raw scores to sum to 1.0.
  ///
  /// Returns an equal distribution if all scores are zero.
  static List<double> normalize(List<double> scores) {
    final total = scores.fold(0.0, (sum, s) => sum + s);
    if (total == 0.0) {
      return List.filled(scores.length, 1.0 / scores.length);
    }
    return scores.map((s) => s / total).toList();
  }

  /// Applies exponential decay to a score over [elapsedMinutes].
  ///
  /// [halfLifeMinutes] is the time in minutes for a score to halve.
  static double decayed(
    double score, {
    required int elapsedMinutes,
    int halfLifeMinutes = 10080, // default: 1 week
  }) {
    if (elapsedMinutes <= 0) return score;
    final decay = 0.693147 / halfLifeMinutes; // ln(2) / halfLife
    return clamp(score * (1 - decay * elapsedMinutes));
  }
}
