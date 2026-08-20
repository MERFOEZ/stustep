/// SAIE — AnswerFeatureExtractor
///
/// Stateless service that extracts [AnswerFeatures] from a raw answer string.
/// All signal detection runs here once — downstream evaluators read the
/// pre-computed feature object.
library;

import 'package:stustep/features/saie/analysis/answer_features.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Signal banks
// ─────────────────────────────────────────────────────────────────────────────

const _reasoningSignals = [
  // Arabic
  'لأن', 'لأنني', 'بسبب', 'لذلك', 'لذا', 'ولكن', 'ومع ذلك', 'من ناحية',
  'علاوة على ذلك', 'في الواقع', 'أعتقد أن', 'أرى أن',
  // English
  'because', 'therefore', 'however', 'although', 'since', 'as a result',
  'consequently', 'furthermore', 'in addition', 'i believe', 'i think',
  'in my opinion', 'which means', 'this is why',
];

const _personalExperienceSignals = [
  // Arabic
  'أنا', 'أنني', 'كنت', 'قمت', 'فعلت', 'جربت', 'عشت', 'أحب', 'أكره',
  'شعرت', 'تعلمت', 'لاحظت', 'في حياتي', 'عندما كنت',
  // English
  'i have', 'i am', 'i was', 'i did', 'i tried', 'i love', 'i hate',
  'i enjoy', 'i feel', 'i learned', 'in my experience', 'personally',
  'when i was', 'growing up',
];

const _exampleSignals = [
  // Arabic
  'مثلاً', 'مثل', 'على سبيل المثال', 'كمثال', 'كـ',
  // English
  'for example', 'for instance', 'such as', 'like', 'e.g.', 'namely',
];

const _negationSignals = [
  // Arabic
  'لا', 'لن', 'لم', 'لست', 'ليس', 'أكره', 'لا أحب', 'لا أريد',
  'لا يمكنني',
  // English
  'not', 'no', 'never', 'hate', 'dislike', 'don\'t', 'doesn\'t', 'won\'t',
  'can\'t', 'cannot', 'nor',
];

const _affirmationSignals = [
  // Arabic
  'نعم', 'أجل', 'بالتأكيد', 'طبعاً', 'أحب', 'أستمتع', 'ممتاز', 'رائع',
  // English
  'yes', 'yeah', 'of course', 'absolutely', 'love', 'enjoy', 'definitely',
  'always', 'exactly',
];

// ─────────────────────────────────────────────────────────────────────────────
// AnswerFeatureExtractor
// ─────────────────────────────────────────────────────────────────────────────

/// Extracts [AnswerFeatures] from a raw answer.
final class AnswerFeatureExtractor {
  const AnswerFeatureExtractor();

  /// Extracts features from [rawAnswer] using [context] for history checks.
  AnswerFeatures extract({
    required String rawAnswer,
    required ConversationContext context,
    List<String> recentAnswerTexts = const [],
  }) {
    final now = DateTime.now().toUtc();
    final normalised =
        rawAnswer.trim().replaceAll(RegExp(r'\s+'), ' ');
    final lower = normalised.toLowerCase();
    final words = normalised
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final wordCount = words.length;
    final charCount = normalised.replaceAll(' ', '').length;
    final sentences = normalised
        .split(RegExp(r'[.!?؟،\n]'))
        .where((s) => s.trim().isNotEmpty)
        .length;

    // Unique chars / total chars → randomness heuristic.
    final uniqueChars = lower.replaceAll(' ', '').split('').toSet().length;
    final totalCharsNoSpace = lower.replaceAll(' ', '').length;
    final charRatio = totalCharsNoSpace > 0
        ? uniqueChars / totalCharsNoSpace
        : 0.0;

    final hasVowels = RegExp(r'[aeiouAEIOUاوي]').hasMatch(normalised);
    final looksRandom = totalCharsNoSpace >= 8 &&
        charRatio > 0.85 &&
        !hasVowels;

    // Spam: exact match with any recent answer.
    final lowerNorm = lower;
    final isRepetition = recentAnswerTexts.any(
      (a) => a.trim().toLowerCase() == lowerNorm,
    );

    // Lexical diversity.
    final uniqueWords = words.map((w) => w.toLowerCase()).toSet().length;
    final lexicalDiversity =
        wordCount > 0 ? uniqueWords / wordCount : 0.0;

    // Average word length.
    final totalWordChars = words.fold<int>(0, (sum, w) => sum + w.length);
    final avgWordLength =
        wordCount > 0 ? totalWordChars / wordCount : 0.0;

    // Context reference: does current answer reference prior conversation?
    final referencesCtx = _referencesHistory(lower, context);

    return AnswerFeatures(
      normalisedText: normalised,
      wordCount: wordCount,
      charCount: charCount,
      sentenceCount: sentences,
      isEmpty: normalised.isEmpty,
      isSingleWord: wordCount == 1,
      isVeryShort: wordCount <= 3,
      looksRandom: looksRandom,
      isRepetition: isRepetition,
      containsPersonalExperience: _any(lower, _personalExperienceSignals),
      containsExamples: _any(lower, _exampleSignals),
      containsReasoning: _any(lower, _reasoningSignals),
      containsNegation: _any(lower, _negationSignals),
      containsAffirmation: _any(lower, _affirmationSignals),
      referencesContext: referencesCtx,
      containsNumeric: RegExp(r'\d').hasMatch(normalised),
      lexicalDiversity: lexicalDiversity,
      avgWordLength: avgWordLength,
      extractedAt: now,
    );
  }

  bool _referencesHistory(String lower, ConversationContext context) {
    final priorContent = context
        .lastNTurns(6)
        .where((t) => t.isStudent || t.isEngine)
        .skip(1)
        .expand((t) => t.content.toLowerCase().split(RegExp(r'\s+')))
        .where((w) => w.length > 4)
        .toSet();
    return priorContent.any((w) => lower.contains(w));
  }

  static bool _any(String text, List<String> signals) =>
      signals.any((s) => text.contains(s.toLowerCase()));
}
