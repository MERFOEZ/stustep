/// SAIE — AnswerFeatures
///
/// The structural and semantic feature set extracted from a raw answer string
/// before scoring. The [AnswerQualityEvaluator] reads exclusively from this
/// object — it never re-parses the raw text.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerFeatures
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-extracted structural and semantic features of a student answer.
final class AnswerFeatures extends Equatable {
  /// The normalised (trimmed, whitespace-collapsed) answer text.
  final String normalisedText;

  /// Word count of the answer.
  final int wordCount;

  /// Character count (excluding whitespace).
  final int charCount;

  /// Number of sentences detected in the answer.
  final int sentenceCount;

  /// Whether the answer is completely empty.
  final bool isEmpty;

  /// Whether the answer is a single word (highly incomplete).
  final bool isSingleWord;

  /// Whether the answer is very short (≤ 3 words).
  final bool isVeryShort;

  /// Whether the answer appears to be random or meaningless text.
  final bool looksRandom;

  /// Whether the answer is spam or a simple repetition.
  final bool isRepetition;

  /// Whether the answer contains a personal experience (first-person narrative).
  final bool containsPersonalExperience;

  /// Whether the answer contains concrete examples.
  final bool containsExamples;

  /// Whether the answer contains reasoning connectors
  /// (because, therefore, however, لأن, لذا, ولكن...).
  final bool containsReasoning;

  /// Whether the answer contains a negation.
  final bool containsNegation;

  /// Whether the answer contains an affirmation.
  final bool containsAffirmation;

  /// Whether the answer references something said earlier in the conversation.
  final bool referencesContext;

  /// Whether the answer contains numeric values (may indicate Likert responses).
  final bool containsNumeric;

  /// Approximate lexical diversity: unique words / total words.
  final double lexicalDiversity;

  /// Average word length (proxy for vocabulary sophistication).
  final double avgWordLength;

  /// UTC timestamp when features were extracted.
  final DateTime extractedAt;

  const AnswerFeatures({
    required this.normalisedText,
    required this.wordCount,
    required this.charCount,
    required this.sentenceCount,
    required this.isEmpty,
    required this.isSingleWord,
    required this.isVeryShort,
    required this.looksRandom,
    required this.isRepetition,
    required this.containsPersonalExperience,
    required this.containsExamples,
    required this.containsReasoning,
    required this.containsNegation,
    required this.containsAffirmation,
    required this.referencesContext,
    required this.containsNumeric,
    required this.lexicalDiversity,
    required this.avgWordLength,
    required this.extractedAt,
  });

  factory AnswerFeatures.fromJson(Map<String, dynamic> json) => AnswerFeatures(
    normalisedText: json['normalised_text'] as String,
    wordCount: json['word_count'] as int,
    charCount: json['char_count'] as int,
    sentenceCount: json['sentence_count'] as int,
    isEmpty: json['is_empty'] as bool,
    isSingleWord: json['is_single_word'] as bool,
    isVeryShort: json['is_very_short'] as bool,
    looksRandom: json['looks_random'] as bool,
    isRepetition: json['is_repetition'] as bool,
    containsPersonalExperience: json['contains_personal_experience'] as bool,
    containsExamples: json['contains_examples'] as bool,
    containsReasoning: json['contains_reasoning'] as bool,
    containsNegation: json['contains_negation'] as bool,
    containsAffirmation: json['contains_affirmation'] as bool,
    referencesContext: json['references_context'] as bool,
    containsNumeric: json['contains_numeric'] as bool,
    lexicalDiversity: (json['lexical_diversity'] as num).toDouble(),
    avgWordLength: (json['avg_word_length'] as num).toDouble(),
    extractedAt: DateTime.parse(json['extracted_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'normalised_text': normalisedText,
    'word_count': wordCount,
    'char_count': charCount,
    'sentence_count': sentenceCount,
    'is_empty': isEmpty,
    'is_single_word': isSingleWord,
    'is_very_short': isVeryShort,
    'looks_random': looksRandom,
    'is_repetition': isRepetition,
    'contains_personal_experience': containsPersonalExperience,
    'contains_examples': containsExamples,
    'contains_reasoning': containsReasoning,
    'contains_negation': containsNegation,
    'contains_affirmation': containsAffirmation,
    'references_context': referencesContext,
    'contains_numeric': containsNumeric,
    'lexical_diversity': lexicalDiversity,
    'avg_word_length': avgWordLength,
    'extracted_at': extractedAt.toIso8601String(),
  };

  AnswerFeatures copyWith({
    String? normalisedText,
    int? wordCount,
    int? charCount,
    int? sentenceCount,
    bool? isEmpty,
    bool? isSingleWord,
    bool? isVeryShort,
    bool? looksRandom,
    bool? isRepetition,
    bool? containsPersonalExperience,
    bool? containsExamples,
    bool? containsReasoning,
    bool? containsNegation,
    bool? containsAffirmation,
    bool? referencesContext,
    bool? containsNumeric,
    double? lexicalDiversity,
    double? avgWordLength,
    DateTime? extractedAt,
  }) => AnswerFeatures(
    normalisedText: normalisedText ?? this.normalisedText,
    wordCount: wordCount ?? this.wordCount,
    charCount: charCount ?? this.charCount,
    sentenceCount: sentenceCount ?? this.sentenceCount,
    isEmpty: isEmpty ?? this.isEmpty,
    isSingleWord: isSingleWord ?? this.isSingleWord,
    isVeryShort: isVeryShort ?? this.isVeryShort,
    looksRandom: looksRandom ?? this.looksRandom,
    isRepetition: isRepetition ?? this.isRepetition,
    containsPersonalExperience:
        containsPersonalExperience ?? this.containsPersonalExperience,
    containsExamples: containsExamples ?? this.containsExamples,
    containsReasoning: containsReasoning ?? this.containsReasoning,
    containsNegation: containsNegation ?? this.containsNegation,
    containsAffirmation: containsAffirmation ?? this.containsAffirmation,
    referencesContext: referencesContext ?? this.referencesContext,
    containsNumeric: containsNumeric ?? this.containsNumeric,
    lexicalDiversity: lexicalDiversity ?? this.lexicalDiversity,
    avgWordLength: avgWordLength ?? this.avgWordLength,
    extractedAt: extractedAt ?? this.extractedAt,
  );

  @override
  List<Object?> get props => [
    normalisedText,
    wordCount,
    looksRandom,
    isRepetition,
    lexicalDiversity,
  ];

  @override
  String toString() =>
      'AnswerFeatures(words: $wordCount, diversity: '
      '${lexicalDiversity.toStringAsFixed(2)}, '
      'reasoning: $containsReasoning, '
      'personal: $containsPersonalExperience)';
}
