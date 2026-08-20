/// SAIE — ContradictionDetector
///
/// Detects semantic contradictions between the current message and what the
/// student has previously expressed in the conversation. When a contradiction
/// is found, the engine does NOT immediately update the profile — it generates
/// a [ContradictionSignal] and issues a clarification question instead.
library;

import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_result.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ContradictionPattern
// ─────────────────────────────────────────────────────────────────────────────

/// A rule defining opposing sentiment/topic pairs that indicate contradiction.
final class ContradictionPattern {
  final String dimensionKey;
  final List<String> positiveSignals;
  final List<String> negativeSignals;

  const ContradictionPattern({
    required this.dimensionKey,
    required this.positiveSignals,
    required this.negativeSignals,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ContradictionDetector
// ─────────────────────────────────────────────────────────────────────────────

/// Analyses conversation history for semantic contradictions.
///
/// Strategy:
/// 1. Scan recent history for affirmation signals on cognitive dimensions.
/// 2. Check if the current message contains opposing signals on the same dimensions.
/// 3. Compute a contradiction confidence.
/// 4. Return a [ContradictionSignal] if confidence ≥ threshold.
final class ContradictionDetector {
  /// Minimum confidence to report a contradiction.
  static const double _threshold = 0.60;

  /// Maximum history turns to scan for prior statements.
  static const int _historyWindow = 10;

  /// Contradiction patterns — opposing signal pairs per cognitive dimension.
  static const _patterns = [
    ContradictionPattern(
      dimensionKey: 'mathematics',
      positiveSignals: [
        'أحب الرياضيات', 'أستمتع بالرياضيات', 'رياضيات ممتازة',
        'love math', 'enjoy math', 'good at math', 'like numbers',
      ],
      negativeSignals: [
        'أكره الرياضيات', 'لا أحب الأرقام', 'الرياضيات صعبة جدًا',
        'hate math', 'hate numbers', 'dislike math', 'bad at math',
        'not good at math',
      ],
    ),
    ContradictionPattern(
      dimensionKey: 'programming',
      positiveSignals: [
        'أحب البرمجة', 'أستمتع بالبرمجة', 'أكود', 'أبرمج',
        'love coding', 'enjoy programming', 'like to code',
      ],
      negativeSignals: [
        'أكره البرمجة', 'البرمجة صعبة', 'لا أحب الكود',
        'hate coding', 'hate programming', 'dislike coding',
      ],
    ),
    ContradictionPattern(
      dimensionKey: 'teamwork',
      positiveSignals: [
        'أحب العمل مع الآخرين', 'العمل الجماعي', 'أفضّل الفريق',
        'love teamwork', 'prefer working with others', 'enjoy collaboration',
      ],
      negativeSignals: [
        'أفضّل العمل منفردًا', 'لا أحب الفريق', 'أعمل وحيدًا',
        'prefer working alone', 'dislike teamwork', 'hate group work',
      ],
    ),
    ContradictionPattern(
      dimensionKey: 'science',
      positiveSignals: [
        'أحب العلوم', 'العلوم ممتعة', 'أستمتع بالفيزياء', 'أحب الكيمياء',
        'love science', 'enjoy physics', 'like chemistry', 'love biology',
      ],
      negativeSignals: [
        'أكره العلوم', 'لا أحب الفيزياء', 'لا أحب الكيمياء',
        'hate science', 'dislike physics', 'hate chemistry',
      ],
    ),
    ContradictionPattern(
      dimensionKey: 'creativity',
      positiveSignals: [
        'أحب الإبداع', 'أحب الفن', 'التصميم ممتع',
        'love creativity', 'enjoy art', 'like design',
      ],
      negativeSignals: [
        'لا أحب الفن', 'الإبداع ليس لي', 'لا أرسم',
        'hate art', 'not creative', 'dislike design',
      ],
    ),
  ];

  const ContradictionDetector();

  /// Analyses the [analysis] and [context] for contradictions.
  ///
  /// Returns a [ContradictionSignal] if found, else null.
  ({ContradictionSignal? signal, String? clarificationMessage})? detect(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    if (!analysis.looksLikeContradiction &&
        !analysis.tokens.containsNegation) {
      return null;
    }

    final currentMsg = analysis.tokens.normalised.toLowerCase();

    // Extract recent student history (window).
    final studentTurns = context
        .lastNTurns(_historyWindow)
        .where((t) => t.isStudent)
        .toList();

    if (studentTurns.length < 2) return null;

    // Concatenate prior student messages (exclude current).
    final priorText = studentTurns
        .skip(1) // skip the most recent (current message)
        .map((t) => t.content.toLowerCase())
        .join(' ');

    // Scan patterns.
    for (final pattern in _patterns) {
      final priorWasPositive = pattern.positiveSignals
          .any((s) => priorText.contains(s.toLowerCase()));
      final currentIsNegative = pattern.negativeSignals
          .any((s) => currentMsg.contains(s.toLowerCase()));

      final priorWasNegative = pattern.negativeSignals
          .any((s) => priorText.contains(s.toLowerCase()));
      final currentIsPositive = pattern.positiveSignals
          .any((s) => currentMsg.contains(s.toLowerCase()));

      final isContradiction =
          (priorWasPositive && currentIsNegative) ||
          (priorWasNegative && currentIsPositive);

      if (!isContradiction) continue;

      // Compute confidence based on profile dimension evidence.
      final dim = context.cognitiveProfile.dimension(pattern.dimensionKey);
      final profileConfidence = dim.evidenceCount > 0
          ? (dim.confidence * 0.4 + 0.50).clamp(0.0, 1.0)
          : 0.60;

      if (profileConfidence < _threshold) continue;

      final prior = priorWasPositive
          ? pattern.positiveSignals
              .firstWhere((s) => priorText.contains(s.toLowerCase()),
                  orElse: () => priorText)
          : pattern.negativeSignals.firstWhere(
              (s) => priorText.contains(s.toLowerCase()),
              orElse: () => priorText,
            );

      final current = currentIsNegative
          ? pattern.negativeSignals
              .firstWhere((s) => currentMsg.contains(s.toLowerCase()),
                  orElse: () => currentMsg)
          : pattern.positiveSignals.firstWhere(
              (s) => currentMsg.contains(s.toLowerCase()),
              orElse: () => currentMsg,
            );

      final signal = ContradictionSignal(
        dimensionKey: pattern.dimensionKey,
        priorStatement: prior,
        currentStatement: current,
        confidence: profileConfidence,
      );

      return (
        signal: signal,
        clarificationMessage: _contradictionMessage(
          signal,
          context.activeLanguage,
        ),
      );
    }

    return null;
  }

  String _contradictionMessage(
    ContradictionSignal signal,
    Language lang,
  ) {
    return lang == Language.arabic
        ? 'لاحظت شيئًا مثيرًا للاهتمام: '
          'سابقًا ذكرت "${signal.priorStatement}"، '
          'لكنك الآن تقول "${signal.currentStatement}". '
          'هل يمكنك توضيح ما تقصده؟'
        : 'I noticed something interesting: '
          'Earlier you mentioned "${signal.priorStatement}", '
          'but now you\'re saying "${signal.currentStatement}". '
          'Could you clarify what you mean?';
  }
}
