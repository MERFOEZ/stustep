/// SAIE — StructuredAnswerResolver
///
/// Converts a raw student answer string + active [Question] into a typed
/// [StructuredAnswerResult] that tells [EvidenceExtractor] exactly what the
/// student selected — or that the answer cannot be unambiguously resolved.
///
/// Resolution rules (STRICT):
/// - Exact match on [QuestionOption.key] (normalised) is tried first.
/// - Exact match on [QuestionOption.label] (normalised) is tried second.
/// - Partial / substring / fuzzy matching is NEVER used.
/// - If no exact match is found, [UnresolvedStructuredAnswer] is returned.
///
/// Open-ended questions return [OpenEndedAnswer] immediately — no option
/// lookup is attempted.
///
/// Likert questions parse the raw answer as an integer and validate it against
/// [Question.likertMin] / [Question.likertMax]. Out-of-range or non-numeric
/// answers return [UnresolvedStructuredAnswer].
///
/// Ranking questions parse a comma/space-separated list of option keys and
/// build an ordered list of resolved options.
///
/// MultiSelect questions parse the same separator-split format and return all
/// successfully resolved options.
///
/// RESPONSIBILITY BOUNDARY:
/// [StructuredAnswerResolver] lives entirely in the analysis layer.
/// [ConversationController] is NOT modified — it continues to pass only
/// the raw answer string and active question to [AnswerIntelligenceEngine].
library;

import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StructuredAnswerResult — sealed hierarchy
// ─────────────────────────────────────────────────────────────────────────────

/// The result of resolving a raw answer string against a [Question]'s options.
///
/// Sealed so that every case must be handled exhaustively in a switch.
sealed class StructuredAnswerResult {
  const StructuredAnswerResult();
}

/// The question is open-ended — no option resolution is required or attempted.
/// [EvidenceExtractor] will use the existing free-text evidence path.
final class OpenEndedAnswer extends StructuredAnswerResult {
  const OpenEndedAnswer();
}

/// The student selected exactly one option from a [QuestionType.multipleChoice]
/// (or equivalent single-select) question, and it was resolved unambiguously.
final class SingleOptionAnswer extends StructuredAnswerResult {
  /// The resolved [QuestionOption].
  final QuestionOption option;
  const SingleOptionAnswer(this.option);
}

/// The student provided a valid numeric Likert response for a
/// [QuestionType.likertScale] question.
final class LikertAnswer extends StructuredAnswerResult {
  /// The parsed numeric value (within [min, max]).
  final int value;

  /// Minimum of the Likert scale (from [Question.likertMin]).
  final int min;

  /// Maximum of the Likert scale (from [Question.likertMax]).
  final int max;

  /// Whether higher values signal positive cognitive evidence.
  /// Sourced from [Question.likertPositiveOrientation].
  final bool positiveOrientation;

  const LikertAnswer({
    required this.value,
    required this.min,
    required this.max,
    required this.positiveOrientation,
  });
}

/// The student provided an ordered ranking response for a
/// [QuestionType.ranking] question.
///
/// [orderedOptions] is ordered by rank: index 0 = rank 1 (highest priority).
/// Only successfully resolved options are included; unmatched tokens are
/// silently skipped. If no options at all could be resolved, the caller
/// receives [UnresolvedStructuredAnswer] instead.
final class RankedAnswer extends StructuredAnswerResult {
  /// Resolved options in descending priority order (index 0 = rank 1).
  final List<QuestionOption> orderedOptions;
  const RankedAnswer(this.orderedOptions);
}

/// The student selected one or more options for a [QuestionType.multiSelect]
/// question.
///
/// Each option in [selectedOptions] was individually resolved by exact match.
/// Unmatched tokens are silently skipped. If no options could be resolved,
/// [UnresolvedStructuredAnswer] is returned instead.
final class MultiSelectAnswer extends StructuredAnswerResult {
  /// All resolved selected options (no specific ordering).
  final List<QuestionOption> selectedOptions;
  const MultiSelectAnswer(this.selectedOptions);
}

/// The answer could not be resolved to any option unambiguously.
///
/// [EvidenceExtractor] returns an empty evidence list for this result.
/// NO question-level targets are used as a fallback — the system does not
/// know which dimensions were evidenced.
final class UnresolvedStructuredAnswer extends StructuredAnswerResult {
  /// Human-readable reason for the failure (for logging / debugging).
  final String reason;
  const UnresolvedStructuredAnswer(this.reason);
}

// ─────────────────────────────────────────────────────────────────────────────
// StructuredAnswerResolver
// ─────────────────────────────────────────────────────────────────────────────

/// Converts a raw student answer + [Question] into a [StructuredAnswerResult].
///
/// Stateless. Inject into [AnswerIntelligenceEngine] via the constructor.
final class StructuredAnswerResolver {
  const StructuredAnswerResolver();

  /// Resolves [rawAnswer] against [question] and returns the typed result.
  StructuredAnswerResult resolve({
    required Question question,
    required String rawAnswer,
  }) {
    return switch (question.type) {
      QuestionType.openEnded          => const OpenEndedAnswer(),
      QuestionType.multipleChoice     => _resolveSingleOption(question, rawAnswer),
      QuestionType.trueFalse          => _resolveSingleOption(question, rawAnswer),
      QuestionType.situationalJudgment => _resolveSingleOption(question, rawAnswer),
      QuestionType.likertScale        => _resolveLikert(question, rawAnswer),
      QuestionType.ranking            => _resolveRanking(question, rawAnswer),
      QuestionType.multiSelect        => _resolveMultiSelect(question, rawAnswer),
    };
  }

  // ─── Single-option resolution ────────────────────────────────────────────

  /// Resolves a single-choice answer by exact key or exact label match.
  ///
  /// No partial or substring matching is performed.
  StructuredAnswerResult _resolveSingleOption(
    Question question,
    String rawAnswer,
  ) {
    if (question.options.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: no options defined for ${question.type.name}.',
      );
    }

    final normalized = _normalize(rawAnswer);

    // Pass 1: exact key match (normalised).
    for (final option in question.options) {
      if (_normalize(option.key) == normalized) {
        return SingleOptionAnswer(option);
      }
    }

    // Pass 2: exact label match (normalised).
    for (final option in question.options) {
      if (_normalize(option.label) == normalized) {
        return SingleOptionAnswer(option);
      }
    }

    return UnresolvedStructuredAnswer(
      'Q[${question.id}]: "${rawAnswer.trim()}" did not match any option '
      'key or label exactly.',
    );
  }

  // ─── Likert resolution ────────────────────────────────────────────────────

  /// Resolves a Likert answer by parsing the raw string as an integer and
  /// validating it against the question's declared range.
  StructuredAnswerResult _resolveLikert(
    Question question,
    String rawAnswer,
  ) {
    final min = question.likertMin;
    final max = question.likertMax;

    if (min == null || max == null) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: likert_min or likert_max not configured.',
      );
    }

    if (question.likertPositiveOrientation == null) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: likert_positive_orientation not configured. '
        'Cannot safely interpret scale direction.',
      );
    }

    // Normalise Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) to ASCII digits.
    final ascii = _normalizeArabicNumerals(rawAnswer.trim());
    final value = int.tryParse(ascii);

    if (value == null) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: "$rawAnswer" cannot be parsed as an integer.',
      );
    }

    if (value < min || value > max) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: value $value is outside Likert range [$min, $max].',
      );
    }

    return LikertAnswer(
      value: value,
      min: min,
      max: max,
      positiveOrientation: question.likertPositiveOrientation!,
    );
  }

  // ─── Ranking resolution ───────────────────────────────────────────────────

  /// Resolves a ranking answer by splitting on separators and matching each
  /// token to an option by exact key or exact label.
  ///
  /// Unmatched tokens are silently skipped. Returns [UnresolvedStructuredAnswer]
  /// only if no tokens resolved at all.
  StructuredAnswerResult _resolveRanking(
    Question question,
    String rawAnswer,
  ) {
    if (question.options.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: no options defined for ranking question.',
      );
    }

    final tokens = _splitMultiValue(rawAnswer);
    if (tokens.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: ranking answer contains no tokens.',
      );
    }

    final orderedOptions = <QuestionOption>[];
    for (final token in tokens) {
      final option = _exactMatch(question.options, token);
      if (option != null && !orderedOptions.contains(option)) {
        orderedOptions.add(option);
      }
    }

    if (orderedOptions.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: no ranking tokens matched any option.',
      );
    }

    return RankedAnswer(orderedOptions);
  }

  // ─── Multi-select resolution ──────────────────────────────────────────────

  /// Resolves a multi-select answer by splitting on separators and matching
  /// each token to an option by exact key or exact label.
  ///
  /// Unmatched tokens are silently skipped. Returns [UnresolvedStructuredAnswer]
  /// only if no tokens resolved at all.
  StructuredAnswerResult _resolveMultiSelect(
    Question question,
    String rawAnswer,
  ) {
    if (question.options.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: no options defined for multi-select question.',
      );
    }

    final tokens = _splitMultiValue(rawAnswer);
    if (tokens.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: multi-select answer contains no tokens.',
      );
    }

    final selected = <QuestionOption>[];
    for (final token in tokens) {
      final option = _exactMatch(question.options, token);
      if (option != null && !selected.contains(option)) {
        selected.add(option);
      }
    }

    if (selected.isEmpty) {
      return UnresolvedStructuredAnswer(
        'Q[${question.id}]: no multi-select tokens matched any option.',
      );
    }

    return MultiSelectAnswer(selected);
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  /// Returns the first [QuestionOption] in [options] whose key or label
  /// exactly matches [token] after normalisation, or `null` if none matched.
  QuestionOption? _exactMatch(List<QuestionOption> options, String token) {
    final normalized = _normalize(token);

    for (final option in options) {
      if (_normalize(option.key) == normalized) return option;
    }
    for (final option in options) {
      if (_normalize(option.label) == normalized) return option;
    }
    return null;
  }

  /// Splits a multi-value answer string on commas, Arabic commas (،),
  /// semicolons, and whitespace runs, then trims each token.
  List<String> _splitMultiValue(String raw) => raw
      .split(RegExp(r'[,،;،\s]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  /// Normalises a string for comparison:
  /// - Trims leading/trailing whitespace.
  /// - Lowercases all ASCII characters.
  /// - Normalises Arabic Alef variants (أ إ آ) → ا.
  /// - Normalises Arabic Teh Marbuta (ة) → ه.
  /// - Normalises Arabic Alef Maqsura (ى) → ي.
  String _normalize(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  /// Converts Arabic-Indic digit characters (٠–٩) to ASCII digits (0–9).
  String _normalizeArabicNumerals(String s) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    var result = s;
    for (var i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
    }
    return result;
  }
}
