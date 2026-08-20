/// SAIE — EvidenceExtractor
///
/// Transforms an accepted, scored student answer into a list of structured
/// [StudentEvidence] objects that can be applied to the [StudentCognitiveProfile]
/// via [applyEvidence()].
///
/// SEMANTIC CONTRACT (Phase 2B.2):
/// ┌──────────────────────────────────────────────────────────────────────────┐
/// │ OpenEndedAnswer       → question.targetDomainIds + text-negation dir    │
/// │ SingleOptionAnswer    → option.targetDomainIds ONLY (not supplemented)  │
/// │ LikertAnswer          → question.targetDomainIds; direction from value  │
/// │ RankedAnswer          → per-option targetDomainIds; triangular weights  │
/// │ MultiSelectAnswer     → per-option targetDomainIds; one record/option   │
/// │ UnresolvedStructured  → empty list (no fabricated evidence)             │
/// └──────────────────────────────────────────────────────────────────────────┘
///
/// DIRECTION ENCODING:
/// - For MC/multiSelect/ranking: direction is read from [QuestionOption.direction].
///   `"positive"` → +1.0, `"negative"` → -1.0, `"neutral"` → no evidence,
///   `null` (missing) → no evidence.
/// - For Likert: direction comes from the numeric value relative to the neutral
///   midpoint and the question's declared [Question.likertPositiveOrientation].
/// - For open-ended: direction comes from [AnswerFeatures.containsNegation].
///
/// EVIDENCE FORMULA (per dimension key):
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │ Applied profile delta = delta × StudentEvidence.weight                 │
/// │                                                                         │
/// │ MC / multiSelect:                                                       │
/// │   delta  = directionSign (+1.0 or −1.0)                                │
/// │   weight = option.evidenceWeight × score.evidenceMultiplier            │
/// │   → profile change ≈ dirSign × optWeight × qualityMultiplier           │
/// │                                                                         │
/// │ Likert:                                                                 │
/// │   delta  = likertDelta (sign + magnitude, e.g. +0.5 or −1.0)          │
/// │   weight = score.evidenceMultiplier                                     │
/// │   → profile change ≈ likertDelta × qualityMultiplier                   │
/// │   Neutral (delta == 0) → empty list, profile unchanged.                │
/// │                                                                         │
/// │ Ranking (triangular normalization):                                     │
/// │   rankNorm = (N − rank + 1) / (N × (N+1) / 2)   [sums to 1.0]        │
/// │   delta    = directionSign (+1.0 for preference)                       │
/// │   weight   = option.evidenceWeight × rankNorm × score.evidenceMultiplier│
/// │   → higher rank → larger weight → stronger profile update              │
/// │                                                                         │
/// │ Open-ended:                                                             │
/// │   delta  = directionSign (from text negation)                          │
/// │   weight = (evidenceMultiplier / numDimensions) [existing behaviour]   │
/// └─────────────────────────────────────────────────────────────────────────┘
///
/// INVALID DIMENSION KEYS: Any key not in [DimensionKeys.all] is silently
/// excluded (release-safe). An assertion fires in debug mode so configuration
/// errors are caught early.
library;

import 'package:uuid/uuid.dart';
import 'package:stustep/features/saie/analysis/answer_features.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/analysis/structured_answer_resolver.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EvidenceExtractor
// ─────────────────────────────────────────────────────────────────────────────

/// Converts a scored answer into [StudentEvidence] objects for profile update.
///
/// Stateless — all state is passed in via parameters.
final class EvidenceExtractor {
  static const _uuid = Uuid();

  const EvidenceExtractor();

  // ─── Entry point ─────────────────────────────────────────────────────────

  /// Extracts all [StudentEvidence] for a scored answer.
  ///
  /// Returns an empty list if:
  /// - The score band is [ScoreBand.invalid].
  /// - The [structuredAnswer] is [UnresolvedStructuredAnswer].
  /// - The resolved option or question has no valid dimension targets.
  List<StudentEvidence> extract({
    required Question question,
    required String rawAnswer,
    required AnswerScore score,
    required AnswerFeatures features,
    required StructuredAnswerResult structuredAnswer,
  }) {
    // Hard gate — invalid answers produce no evidence.
    if (!score.allowsProfileUpdate) return const [];

    return switch (structuredAnswer) {
      OpenEndedAnswer()                => _extractOpenEnded(question, rawAnswer, score, features),
      SingleOptionAnswer(:final option) => _extractSingleOption(question, option, score, features),
      LikertAnswer()                   => _extractLikert(structuredAnswer, question, score, features),
      RankedAnswer()                   => _extractRanking(structuredAnswer, question, score, features),
      MultiSelectAnswer()              => _extractMultiSelect(structuredAnswer, question, score, features),
      // Unresolved: return empty. Do NOT fabricate question-level evidence.
      UnresolvedStructuredAnswer()     => const [],
    };
  }

  // ─── Open-ended ────────────────────────────────────────────────────────────

  /// Existing open-ended behaviour — unchanged by Phase 2B.2.
  ///
  /// Uses [question.targetDomainIds] + tags and derives direction from the
  /// text negation features. This path is never taken for structured questions.
  List<StudentEvidence> _extractOpenEnded(
    Question question,
    String rawAnswer,
    AnswerScore score,
    AnswerFeatures features,
  ) {
    final dimensionKeys = _resolveFromQuestion(question);
    if (dimensionKeys.isEmpty) return const [];

    final now = DateTime.now().toUtc();
    final multiplier = score.evidenceMultiplier;
    final perDimensionWeight =
        multiplier / (dimensionKeys.isNotEmpty ? dimensionKeys.length : 1);
    final confidenceBoost = _computeConfidenceBoost(features, score);
    final direction = features.containsNegation && !features.containsAffirmation
        ? -1.0
        : 1.0;

    return [
      for (final key in dimensionKeys)
        _makeEvidence(
          questionId: question.id,
          rawValue: rawAnswer,
          source: EvidenceSource.questionAnswer,
          key: key,
          delta: (perDimensionWeight * direction).clamp(-1.0, 1.0),
          weight: perDimensionWeight.clamp(0.0, 1.0),
          confidence: confidenceBoost.clamp(0.10, 0.95),
          reason: _openEndedReason(question, score, features, key,
              (perDimensionWeight * direction).clamp(-1.0, 1.0)),
          now: now,
        ),
    ];
  }

  // ─── Single option (multipleChoice, trueFalse, situationalJudgment) ────────

  /// Evidence for a single resolved [QuestionOption].
  ///
  /// Dimension targets come ONLY from [option.targetDomainIds]. The question's
  /// own [targetDomainIds] are NOT appended under any circumstances.
  ///
  /// If the option has no valid dimension targets, returns an empty list.
  /// If [option.direction] is null or unrecognised, returns an empty list.
  List<StudentEvidence> _extractSingleOption(
    Question question,
    QuestionOption option,
    AnswerScore score,
    AnswerFeatures features,
  ) {
    final directionSign = _parseDirection(option.direction);
    if (directionSign == null) return const []; // direction missing → no evidence
    if (directionSign == 0.0) return const [];   // neutral → no evidence

    final dimensionKeys = _resolveFromOption(option, question.id);
    if (dimensionKeys.isEmpty) return const [];

    final now = DateTime.now().toUtc();
    final weight = (option.evidenceWeight * score.evidenceMultiplier).clamp(0.0, 1.0);
    final confidence = _computeConfidenceBoost(features, score).clamp(0.10, 0.95);

    return [
      for (final key in dimensionKeys)
        _makeEvidence(
          questionId: question.id,
          rawValue: option.key,
          source: EvidenceSource.questionAnswer,
          key: key,
          delta: directionSign,
          weight: weight,
          confidence: confidence,
          reason: 'Q[${question.id}] opt[${option.key}] → dim[$key]: '
              '${directionSign > 0 ? "positive" : "negative"} evidence '
              '(optWeight: ${option.evidenceWeight.toStringAsFixed(2)}, '
              'qScore: ${score.total})',
          now: now,
        ),
    ];
  }

  // ─── Likert ───────────────────────────────────────────────────────────────

  /// Evidence for a Likert numeric response.
  ///
  /// Formula (documented in file header):
  ///   midpoint = (min + max) / 2
  ///   halfRange = (max - min) / 2
  ///   delta = ((value - midpoint) / halfRange).clamp(−1.0, +1.0)
  ///   if !positiveOrientation: delta = -delta
  ///   weight = score.evidenceMultiplier
  ///
  /// Neutral midpoint (delta == 0) returns an empty list — no evidence.
  List<StudentEvidence> _extractLikert(
    LikertAnswer likert,
    Question question,
    AnswerScore score,
    AnswerFeatures features,
  ) {
    final midpoint = (likert.min + likert.max) / 2.0;
    final halfRange = (likert.max - likert.min) / 2.0;
    if (halfRange == 0.0) return const []; // degenerate single-point scale

    var delta = ((likert.value - midpoint) / halfRange).clamp(-1.0, 1.0);
    if (!likert.positiveOrientation) delta = -delta;

    // Neutral → no directional evidence.
    if (delta.abs() < 1e-9) return const [];

    final dimensionKeys = _resolveFromQuestion(question);
    if (dimensionKeys.isEmpty) return const [];

    final now = DateTime.now().toUtc();
    final weight = score.evidenceMultiplier.clamp(0.0, 1.0);
    final confidence = _computeConfidenceBoost(features, score).clamp(0.10, 0.95);

    return [
      for (final key in dimensionKeys)
        _makeEvidence(
          questionId: question.id,
          rawValue: likert.value.toString(),
          source: EvidenceSource.likertRating,
          key: key,
          delta: delta,
          weight: weight,
          confidence: confidence,
          reason: 'Q[${question.id}] Likert[${likert.value}/${likert.max}, '
              '${likert.positiveOrientation ? "+" : "-"}orientation] '
              '→ dim[$key]: delta=${delta.toStringAsFixed(3)}, '
              'weight=${weight.toStringAsFixed(2)}',
          now: now,
        ),
    ];
  }

  // ─── Ranking ─────────────────────────────────────────────────────────────

  /// Evidence for an ordered ranking response.
  ///
  /// Triangular normalisation formula (works for any number of ranked items N):
  ///
  ///   triangularSum = N × (N + 1) / 2
  ///   rankNorm(rank r, 1-based) = (N − r + 1) / triangularSum
  ///
  /// Example for N = 4:
  ///   rank 1 → 4/10 = 0.400   (highest priority)
  ///   rank 2 → 3/10 = 0.300
  ///   rank 3 → 2/10 = 0.200
  ///   rank 4 → 1/10 = 0.100   (lowest priority)
  ///   Sum = 1.0
  ///
  /// Final weight per dimension:
  ///   weight = option.evidenceWeight × rankNorm × score.evidenceMultiplier
  ///
  /// Direction: options declared [QuestionOption.direction] == "positive" (or
  /// null, handled as preference) → +1.0. Ranking always represents a
  /// preference ordering; negative-direction ranking options are unusual but
  /// are respected if explicitly set.
  List<StudentEvidence> _extractRanking(
    RankedAnswer ranked,
    Question question,
    AnswerScore score,
    AnswerFeatures features,
  ) {
    final n = ranked.orderedOptions.length;
    if (n == 0) return const [];

    final triangularSum = n * (n + 1) / 2.0;
    final now = DateTime.now().toUtc();
    final confidence = _computeConfidenceBoost(features, score).clamp(0.10, 0.95);
    final evidenceList = <StudentEvidence>[];

    for (var i = 0; i < n; i++) {
      final option = ranked.orderedOptions[i];
      final rank = i + 1; // 1-based
      final rankNorm = (n - rank + 1) / triangularSum;

      // For ranking, respect explicit direction; if null treat as positive
      // (ranking = relative preference, so absent direction means preference).
      final dirSign = _parseDirection(option.direction) ?? 1.0;
      if (dirSign == 0.0) continue; // neutral ranked option → skip

      final dimensionKeys = _resolveFromOption(option, question.id);
      if (dimensionKeys.isEmpty) continue;

      final weight =
          (option.evidenceWeight * rankNorm * score.evidenceMultiplier).clamp(0.0, 1.0);

      for (final key in dimensionKeys) {
        evidenceList.add(_makeEvidence(
          questionId: question.id,
          rawValue: option.key,
          source: EvidenceSource.ranking,
          key: key,
          delta: dirSign,
          weight: weight,
          confidence: confidence,
          reason: 'Q[${question.id}] rank[$rank/$n] opt[${option.key}] '
              '→ dim[$key]: rankNorm=${rankNorm.toStringAsFixed(3)}, '
              'weight=${weight.toStringAsFixed(3)}',
          now: now,
        ));
      }
    }

    return evidenceList;
  }

  // ─── Multi-select ─────────────────────────────────────────────────────────

  /// Evidence for a multi-select response.
  ///
  /// Each resolved option produces its own independent group of
  /// [StudentEvidence] records (one per affected dimension key).
  /// Options with missing direction, neutral direction, or no valid dimension
  /// targets are silently skipped.
  List<StudentEvidence> _extractMultiSelect(
    MultiSelectAnswer multiSelect,
    Question question,
    AnswerScore score,
    AnswerFeatures features,
  ) {
    final now = DateTime.now().toUtc();
    final confidence = _computeConfidenceBoost(features, score).clamp(0.10, 0.95);
    final evidenceList = <StudentEvidence>[];

    for (final option in multiSelect.selectedOptions) {
      final dirSign = _parseDirection(option.direction);
      if (dirSign == null || dirSign == 0.0) continue;

      final dimensionKeys = _resolveFromOption(option, question.id);
      if (dimensionKeys.isEmpty) continue;

      final weight =
          (option.evidenceWeight * score.evidenceMultiplier).clamp(0.0, 1.0);

      for (final key in dimensionKeys) {
        evidenceList.add(_makeEvidence(
          questionId: question.id,
          rawValue: option.key,
          source: EvidenceSource.multiSelect,
          key: key,
          delta: dirSign,
          weight: weight,
          confidence: confidence,
          reason: 'Q[${question.id}] multiSelect opt[${option.key}] '
              '→ dim[$key]: ${dirSign > 0 ? "positive" : "negative"} evidence '
              '(optWeight: ${option.evidenceWeight.toStringAsFixed(2)}, '
              'qScore: ${score.total})',
          now: now,
        ));
      }
    }

    return evidenceList;
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  /// Validates and collects dimension keys from a [QuestionOption].
  ///
  /// Only keys present in [DimensionKeys.all] are accepted.
  /// An assertion fires in debug mode for any unrecognised key.
  List<String> _resolveFromOption(QuestionOption option, String questionId) {
    final validKeys = DimensionKeys.all.toSet();
    final resolved = <String>[];

    for (final id in option.targetDomainIds) {
      if (id.isEmpty) continue;
      assert(
        validKeys.contains(id),
        '[EvidenceExtractor] Q["$questionId"] option["${option.key}"] '
        'references invalid targetDomainId "$id" which is not a canonical '
        'DimensionKey. Fix the knowledge base before running assessments.',
      );
      if (validKeys.contains(id) && !resolved.contains(id)) {
        resolved.add(id);
      }
    }

    return resolved;
  }

  /// Validates and collects dimension keys from a [Question]'s own
  /// [targetDomainIds] and matching tags.
  ///
  /// Used for open-ended questions and Likert questions (which have no options).
  List<String> _resolveFromQuestion(Question question) {
    final validKeys = DimensionKeys.all.toSet();
    final resolved = <String>[];

    for (final id in question.targetDomainIds) {
      if (id.isEmpty) continue;
      assert(
        validKeys.contains(id),
        '[EvidenceExtractor] Question "${question.id}" references invalid '
        'targetDomainId "$id". Domain labels must not be used as dimension keys.',
      );
      if (validKeys.contains(id) && !resolved.contains(id)) {
        resolved.add(id);
      }
    }

    // Tags that coincide with canonical keys are supplementary signals.
    for (final tag in question.tags) {
      if (validKeys.contains(tag) && !resolved.contains(tag)) {
        resolved.add(tag);
      }
    }

    return resolved;
  }

  /// Converts a [QuestionOption.direction] string to a numeric sign.
  ///
  /// - `"positive"` → +1.0
  /// - `"negative"` → -1.0
  /// - `"neutral"`  → 0.0  (caller should treat as no evidence)
  /// - `null` / any other → `null` (direction unknown, no evidence produced)
  double? _parseDirection(String? direction) => switch (direction) {
        'positive' => 1.0,
        'negative' => -1.0,
        'neutral'  => 0.0,
        _          => null,
      };

  /// Computes a confidence value for extracted evidence.
  double _computeConfidenceBoost(AnswerFeatures features, AnswerScore score) {
    var confidence = 0.40; // base

    // Quality score contribution.
    confidence += (score.total / 100.0) * 0.30;

    // Reasoning depth bonus.
    if (features.containsReasoning) confidence += 0.10;

    // Personal experience bonus.
    if (features.containsPersonalExperience) confidence += 0.10;

    // Examples bonus.
    if (features.containsExamples) confidence += 0.05;

    // Lexical diversity bonus.
    if (features.lexicalDiversity > 0.6) confidence += 0.05;

    return confidence;
  }

  /// Factory helper that creates a single [StudentEvidence] record.
  StudentEvidence _makeEvidence({
    required String questionId,
    required String rawValue,
    required EvidenceSource source,
    required String key,
    required double delta,
    required double weight,
    required double confidence,
    required String reason,
    required DateTime now,
  }) =>
      StudentEvidence(
        id: _uuid.v4(),
        questionId: questionId,
        rawValue: rawValue,
        source: source,
        affectedDimensions: {key: delta},
        weight: weight.clamp(0.0, 1.0),
        confidence: confidence.clamp(0.10, 0.95),
        reason: reason,
        timestamp: now,
      );

  String _openEndedReason(
    Question question,
    AnswerScore score,
    AnswerFeatures features,
    String dimensionKey,
    double delta,
  ) {
    final direction = delta >= 0 ? 'positive' : 'negative';
    return 'Q[${question.id}] open-ended → dim[$dimensionKey]: '
        '$direction evidence (score: ${score.total}, '
        'band: ${score.band.name}, '
        'reasoning: ${features.containsReasoning}, '
        'personal: ${features.containsPersonalExperience})';
  }
}
