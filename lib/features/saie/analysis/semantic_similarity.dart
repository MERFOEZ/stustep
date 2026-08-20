/// SAIE — SemanticSimilarity
///
/// Computes a similarity score between two answer strings to detect when a
/// student is expressing the same meaning with different words.
/// Prevents duplicate evidence from being injected into the profile.
///
/// Implementation uses:
/// - Token overlap (Jaccard similarity) as the primary signal.
/// - Shared n-gram (bigram) overlap as a secondary signal.
/// - Length ratio penalty for answers of very different length.
///
/// No external ML models or network calls. Pure Dart.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SimilarityResult
// ─────────────────────────────────────────────────────────────────────────────

/// The result of comparing two answers for semantic similarity.
final class SimilarityResult extends Equatable {
  /// The first answer text.
  final String textA;

  /// The second answer text.
  final String textB;

  /// Similarity score in [0.0, 1.0].
  /// 1.0 = identical meaning, 0.0 = completely different.
  final double score;

  /// Whether the two answers are considered duplicates (score ≥ threshold).
  final bool isDuplicate;

  /// The threshold used for duplicate detection.
  final double threshold;

  const SimilarityResult({
    required this.textA,
    required this.textB,
    required this.score,
    required this.isDuplicate,
    required this.threshold,
  });

  factory SimilarityResult.fromJson(Map<String, dynamic> json) =>
      SimilarityResult(
        textA: json['text_a'] as String,
        textB: json['text_b'] as String,
        score: (json['score'] as num).toDouble(),
        isDuplicate: json['is_duplicate'] as bool,
        threshold: (json['threshold'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'text_a': textA,
    'text_b': textB,
    'score': score,
    'is_duplicate': isDuplicate,
    'threshold': threshold,
  };

  SimilarityResult copyWith({
    String? textA,
    String? textB,
    double? score,
    bool? isDuplicate,
    double? threshold,
  }) => SimilarityResult(
    textA: textA ?? this.textA,
    textB: textB ?? this.textB,
    score: score ?? this.score,
    isDuplicate: isDuplicate ?? this.isDuplicate,
    threshold: threshold ?? this.threshold,
  );

  @override
  List<Object?> get props => [textA, textB, score];

  @override
  String toString() =>
      'SimilarityResult(score: ${score.toStringAsFixed(3)}, '
      'duplicate: $isDuplicate)';
}

// ─────────────────────────────────────────────────────────────────────────────
// SemanticSimilarityService
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless service that computes semantic similarity between two answers.
final class SemanticSimilarityService {
  /// Default similarity threshold above which answers are considered duplicates.
  static const double _defaultThreshold = 0.75;

  const SemanticSimilarityService();

  /// Computes a [SimilarityResult] between [textA] and [textB].
  SimilarityResult compare(
    String textA,
    String textB, {
    double threshold = _defaultThreshold,
  }) {
    final normA = _normalise(textA);
    final normB = _normalise(textB);

    // Exact match shortcut.
    if (normA == normB) {
      return SimilarityResult(
        textA: textA,
        textB: textB,
        score: 1.0,
        isDuplicate: true,
        threshold: threshold,
      );
    }

    final tokensA = _tokenise(normA);
    final tokensB = _tokenise(normB);

    if (tokensA.isEmpty || tokensB.isEmpty) {
      return SimilarityResult(
        textA: textA,
        textB: textB,
        score: 0.0,
        isDuplicate: false,
        threshold: threshold,
      );
    }

    // Jaccard token similarity.
    final setA = Set<String>.from(tokensA);
    final setB = Set<String>.from(tokensB);
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    final jaccard = union > 0 ? intersection / union : 0.0;

    // Bigram overlap.
    final bigramA = _bigrams(tokensA);
    final bigramB = _bigrams(tokensB);
    final bigramSim = _bigramSimilarity(bigramA, bigramB);

    // Length ratio penalty — penalise very different lengths.
    final maxLen = tokensA.length > tokensB.length ? tokensA.length : tokensB.length;
    final minLen = tokensA.length < tokensB.length ? tokensA.length : tokensB.length;
    final lengthRatio = minLen / maxLen;

    // Weighted composite.
    final score = (jaccard * 0.50 + bigramSim * 0.35 + lengthRatio * 0.15)
        .clamp(0.0, 1.0);

    return SimilarityResult(
      textA: textA,
      textB: textB,
      score: score,
      isDuplicate: score >= threshold,
      threshold: threshold,
    );
  }

  /// Checks [candidate] against all [priorAnswers] for duplicates.
  /// Returns the highest similarity result found.
  SimilarityResult? findDuplicate(
    String candidate,
    List<String> priorAnswers, {
    double threshold = _defaultThreshold,
  }) {
    SimilarityResult? best;
    for (final prior in priorAnswers) {
      final result = compare(candidate, prior, threshold: threshold);
      if (result.isDuplicate) {
        if (best == null || result.score > best.score) {
          best = result;
        }
      }
    }
    return best;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _normalise(String text) =>
      text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ');

  List<String> _tokenise(String text) =>
      text.split(' ').where((t) => t.length > 1).toList();

  Set<String> _bigrams(List<String> tokens) {
    final bigrams = <String>{};
    for (var i = 0; i < tokens.length - 1; i++) {
      bigrams.add('${tokens[i]}_${tokens[i + 1]}');
    }
    return bigrams;
  }

  double _bigramSimilarity(Set<String> bigramsA, Set<String> bigramsB) {
    if (bigramsA.isEmpty && bigramsB.isEmpty) return 1.0;
    if (bigramsA.isEmpty || bigramsB.isEmpty) return 0.0;
    final intersection = bigramsA.intersection(bigramsB).length;
    final union = bigramsA.union(bigramsB).length;
    return union > 0 ? intersection / union : 0.0;
  }
}
