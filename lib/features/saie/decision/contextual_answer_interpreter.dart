/// SAIE — ContextualAnswerInterpreter
///
/// Interprets the student's message within the semantic frame of the
/// currently active assessment question.
///
/// === WHY THIS EXISTS ===
/// The same message can mean completely different things depending on the
/// active question. "All of them" is a valid answer to a multiSelect question,
/// a structural mismatch for a ranking question, and ambiguous for a
/// singleChoice question.
///
/// Keyword lists cannot solve this: they grow forever and still fail on
/// messages they don't recognise. The correct solution is to interpret the
/// message *relative to what the question requires*.
///
/// === RESPONSIBILITY ===
/// This component answers ONE question:
///   "Does this message constitute an interpretable answer to the active
///   question, and if so, how complete is it?"
///
/// It does NOT:
/// - Advance the assessment state.
/// - Score the answer.
/// - Generate a response.
/// - Modify the student profile.
///
/// === SCALABILITY ===
/// Adding a new QuestionType requires adding exactly one case to the
/// [_interpretForType] switch. No keyword lists change.
/// Adding a new answer pattern (e.g. voice transcription quirks) is isolated
/// to the per-type interpreter, not scattered across global signal lists.
library;

import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerInterpretation
// ─────────────────────────────────────────────────────────────────────────────

/// The semantic interpretation of a student message within the context of
/// the active assessment question.
enum AnswerInterpretation {
  /// The message is structurally compatible with this question type and
  /// can be treated as a valid answer. Route to [continueAssessment].
  compatible,

  /// The message is a valid expression of intent (e.g. "all of them") but
  /// does NOT satisfy the structural requirements of the question (e.g.
  /// a ranking question requires an ordered list).
  ///
  /// The system MUST preserve the assessment objective: explain what is
  /// needed and ask the student to provide the required format.
  /// Do NOT simplify the question. Do NOT skip it.
  structuralMismatch,

  /// The message contains partial answer content but is incomplete.
  /// Example: "I like programming" for a multiSelect question with 6 options.
  /// Acknowledge the content and invite the student to complete the answer.
  partialAnswer,

  /// The question has no active pending question, so answer
  /// interpretation is not applicable.
  noActiveQuestion,
}

// ─────────────────────────────────────────────────────────────────────────────
// ContextualAnswerInterpreter
// ─────────────────────────────────────────────────────────────────────────────

/// Interprets a normalised student message within the semantic context of
/// the active assessment question.
///
/// Stateless — purely functional. No side effects.
final class ContextualAnswerInterpreter {
  const ContextualAnswerInterpreter();

  // ── "All of them" signals across Arabic dialects and English ───────────────
  // These are phrases that express: "I choose / like / want all the options".
  // They are NOT generic affirmations — they are total-selection expressions.
  // This is the ONLY static list in this component and it is universal:
  // it does not change with question type, topic, or domain.
  static const _totalSelectionSignals = <String>[
    // Arabic — standard
    'كلها', 'كلهم', 'جميعها', 'جميعهم', 'كل الخيارات', 'كل الأنشطة',
    'كل المجالات', 'جميع الخيارات', 'أحبهم كلهم', 'أحبها كلها',
    'احبهم كامل', 'احبهم كلهم', 'احبها كلها',
    'كلهم كامل', 'كلها كامل',
    // Arabic — Gulf colloquial
    'وايد', 'كل شي', 'كل شيء', 'الكل', 'ما عندي مشكلة بأي واحد',
    'ما عندي مشكلة فيها', 'كل الخيارات زينة', 'كلها زينة', 'كلها حلوة',
    'كلها واجد', 'وايد منهم',
    // Arabic — Levantine / Egyptian
    'كلهم كويسين', 'كلها كويسة', 'كلهم تمام', 'كلها تمام',
    'بحب كلهم', 'بحبهم كلهم', 'كل الحاجات', 'كلهم زي بعض',
    // English
    'all of them', 'all of it', 'all options', 'every option',
    'i like all', 'i love all', 'i love them all', 'i like them all',
    'all the above', 'all of the above', 'everything', 'each one',
    'i enjoy all', 'all choices', 'every single one',
  ];

  // ── Ranking pattern signals ────────────────────────────────────────────────
  // Detect when the student has provided a ranked/ordered list.
  // These appear at the beginning of a ranked item.
  static const _rankingOrderSignals = <String>[
    // Numeric ordinals (Arabic-Indic and Latin)
    '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
    // Ordinal words — Arabic
    'أولاً', 'ثانياً', 'ثالثاً', 'رابعاً', 'خامساً',
    'اول', 'ثاني', 'ثالث', 'رابع',
    // Ordinal words — English
    'first', 'second', 'third', 'fourth', 'fifth',
    '1st', '2nd', '3rd', '4th', '5th',
  ];

  // ── Numeric value signals for Likert ───────────────────────────────────────
  // Likert validation uses a range check (_containsValidLikertValue), not
  // a static signal list, because valid values depend on question configuration.

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Interprets [normalisedMessage] in the context of [activeQuestion].
  ///
  /// [normalisedMessage] must be lowercase and whitespace-collapsed.
  ///
  /// Returns [AnswerInterpretation.noActiveQuestion] when [activeQuestion]
  /// is null — no interpretation is possible without a question frame.
  AnswerInterpretation interpret({
    required String normalisedMessage,
    required Question? activeQuestion,
  }) {
    if (activeQuestion == null) {
      return AnswerInterpretation.noActiveQuestion;
    }

    return _interpretForType(
      message: normalisedMessage,
      question: activeQuestion,
    );
  }

  // ── Per-type interpretation ────────────────────────────────────────────────

  AnswerInterpretation _interpretForType({
    required String message,
    required Question question,
  }) {
    return switch (question.type) {
      // ── multiSelect ────────────────────────────────────────────────────────
      // The student is asked to pick one or more items from a list.
      // "All of them" is a VALID complete answer — the student is selecting
      // every available option. Compatible.
      QuestionType.multiSelect => _interpretMultiSelect(message, question),

      // ── multipleChoice ─────────────────────────────────────────────────────
      // The student must pick exactly ONE option.
      // "All of them" is a structural mismatch — only one option is valid.
      QuestionType.multipleChoice => _interpretMultipleChoice(message, question),

      // ── ranking ────────────────────────────────────────────────────────────
      // The student must order the options.
      // "All of them" expresses a preference direction but not an ordering.
      // Structural mismatch: the system must preserve the ranking objective
      // and ask the student to provide an ordered list.
      QuestionType.ranking => _interpretRanking(message, question),

      // ── openEnded ─────────────────────────────────────────────────────────
      // The student answers in free text. Almost any substantive message is
      // compatible — the quality scorer handles depth later.
      QuestionType.openEnded => _interpretOpenEnded(message, question),

      // ── likertScale ────────────────────────────────────────────────────────
      // The student must give a numeric rating on a defined scale.
      // "All of them" is a structural mismatch — a number is expected.
      QuestionType.likertScale => _interpretLikert(message, question),

      // ── trueFalse ─────────────────────────────────────────────────────────
      // Boolean: yes/no, true/false.
      QuestionType.trueFalse => _interpretTrueFalse(message),

      // ── situationalJudgment ────────────────────────────────────────────────
      // Open-ended scenario response — similar to openEnded in structural terms.
      QuestionType.situationalJudgment => _interpretOpenEnded(message, question),
    };
  }

  // ── multiSelect ─────────────────────────────────────────────────────────────

  AnswerInterpretation _interpretMultiSelect(String message, Question question) {
    // "All of them" → selects every option → structurally valid.
    if (_isTotalSelection(message)) return AnswerInterpretation.compatible;

    // Message identifies at least one option → compatible.
    if (question.options.isNotEmpty && _identifiesAnyOption(message, question)) {
      return AnswerInterpretation.compatible;
    }

    // Non-empty message that passed keyword signal checks already (by the time
    // we reach the interpreter, clarification/uncertainty signals have been
    // eliminated upstream). Treat as partial — invite the student to be more
    // specific.
    if (_isSubstantive(message)) return AnswerInterpretation.partialAnswer;

    return AnswerInterpretation.partialAnswer;
  }

  // ── multipleChoice ──────────────────────────────────────────────────────────

  AnswerInterpretation _interpretMultipleChoice(String message, Question question) {
    // "All of them" for a single-choice question → structural mismatch.
    if (_isTotalSelection(message)) return AnswerInterpretation.structuralMismatch;

    // Identifies exactly one option → compatible.
    if (question.options.isNotEmpty && _identifiesAnyOption(message, question)) {
      return AnswerInterpretation.compatible;
    }

    if (_isSubstantive(message)) return AnswerInterpretation.partialAnswer;

    return AnswerInterpretation.partialAnswer;
  }

  // ── ranking ─────────────────────────────────────────────────────────────────

  AnswerInterpretation _interpretRanking(String message, Question question) {
    // "All of them" without ordering → structural mismatch.
    // The system must explain that an ordering is needed.
    if (_isTotalSelection(message)) return AnswerInterpretation.structuralMismatch;

    // Message contains ranking order signals → compatible.
    if (_containsRankingOrder(message)) return AnswerInterpretation.compatible;

    // Message references options but without ordering → partial.
    if (question.options.isNotEmpty && _identifiesAnyOption(message, question)) {
      return AnswerInterpretation.partialAnswer;
    }

    // Substantive message without ordering cues → partial.
    if (_isSubstantive(message)) return AnswerInterpretation.partialAnswer;

    return AnswerInterpretation.partialAnswer;
  }

  // ── openEnded / situationalJudgment ─────────────────────────────────────────

  AnswerInterpretation _interpretOpenEnded(String message, Question question) {
    // "All of them" for an open-ended question — the student is expressing
    // a general affirmative. This is substantive content for an open-ended
    // question (unlike ranking where structure is required).
    // Treat as partial — the system can acknowledge and invite elaboration.
    if (_isTotalSelection(message)) {
      // A multiSelect-style question formatted as openEnded: still compatible
      // if options exist and the student expresses selecting all.
      if (question.options.isNotEmpty) return AnswerInterpretation.compatible;
      return AnswerInterpretation.partialAnswer;
    }

    // Any substantive message is compatible for open-ended questions.
    if (_isSubstantive(message)) return AnswerInterpretation.compatible;

    return AnswerInterpretation.partialAnswer;
  }

  // ── likertScale ─────────────────────────────────────────────────────────────

  AnswerInterpretation _interpretLikert(String message, Question question) {
    // "All of them" → not a numeric rating → structural mismatch.
    if (_isTotalSelection(message)) return AnswerInterpretation.structuralMismatch;

    // Extract the Likert range.
    final min = question.likertMin ?? 1;
    final max = question.likertMax ?? 5;

    // Check if message contains a valid number in the allowed range.
    if (_containsValidLikertValue(message, min, max)) {
      return AnswerInterpretation.compatible;
    }

    // Verbal scale responses (e.g. "أوافق بشدة" → maps to high end).
    if (_containsVerbalScaleResponse(message)) {
      return AnswerInterpretation.compatible;
    }

    // Substantive message without clear numeric/verbal rating → partial.
    if (_isSubstantive(message)) return AnswerInterpretation.partialAnswer;

    return AnswerInterpretation.partialAnswer;
  }

  // ── trueFalse ───────────────────────────────────────────────────────────────

  AnswerInterpretation _interpretTrueFalse(String message) {
    // "All of them" for a true/false question → structural mismatch.
    if (_isTotalSelection(message)) return AnswerInterpretation.structuralMismatch;

    const trueSignals = [
      'نعم', 'أجل', 'صح', 'صحيح', 'صواب', 'موافق', 'إي', 'اي',
      'yes', 'true', 'correct', 'right', 'agree', 'yep', 'yeah',
    ];
    const falseSignals = [
      'لا', 'خطأ', 'خطا', 'غير صحيح', 'رفض', 'لا أوافق',
      'no', 'false', 'incorrect', 'wrong', 'disagree', 'nope', 'nah',
    ];

    if (_anySignalIn(message, trueSignals) || _anySignalIn(message, falseSignals)) {
      return AnswerInterpretation.compatible;
    }

    return AnswerInterpretation.partialAnswer;
  }

  // ── Structural helpers ───────────────────────────────────────────────────────

  /// Returns true when the message expresses total selection of all options.
  static bool _isTotalSelection(String message) =>
      _anySignalIn(message, _totalSelectionSignals);

  /// Returns true when the message contains ordering indicators for ranking.
  static bool _containsRankingOrder(String message) =>
      _anySignalIn(message, _rankingOrderSignals);

  /// Returns true when the message identifies any option from the question
  /// by key or by partial label match.
  static bool _identifiesAnyOption(String message, Question question) {
    for (final opt in question.options) {
      // Option key match (single letter like "a", "b", "أ", "ب").
      if (message.contains(opt.key.toLowerCase())) return true;
      // Partial label match (first meaningful word of the option label).
      final labelWords = opt.label
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .toList();
      if (labelWords.any((w) => message.contains(w))) return true;
    }
    return false;
  }

  /// Returns true when the message contains a numeric value in the Likert range.
  static bool _containsValidLikertValue(String message, int min, int max) {
    // Try each integer in the valid range.
    for (var i = min; i <= max; i++) {
      // Match Latin digits.
      if (message.contains(i.toString())) return true;
      // Match Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩).
      if (message.contains(_toArabicIndic(i))) return true;
    }
    return false;
  }

  /// Converts a Latin integer to its Arabic-Indic equivalent string.
  static String _toArabicIndic(int n) {
    const map = {'0': '٠','1': '١','2': '٢','3': '٣','4': '٤',
                  '5': '٥','6': '٦','7': '٧','8': '٨','9': '٩'};
    return n.toString().split('').map((c) => map[c] ?? c).join();
  }

  /// Returns true if the message contains verbal agreement-level terms
  /// commonly used as Likert scale responses.
  static bool _containsVerbalScaleResponse(String message) {
    const verbalScaleSignals = [
      // Arabic — strong agreement → high
      'أوافق بشدة', 'موافق بشدة', 'بشدة',
      // Arabic — agreement
      'أوافق', 'موافق', 'نعم',
      // Arabic — neutral
      'محايد', 'لا أعرف', 'ما أدري',
      // Arabic — disagreement
      'لا أوافق', 'لا أتفق', 'مو موافق',
      // Arabic — strong disagreement
      'لا أوافق بشدة', 'أرفض',
      // English
      'strongly agree', 'agree', 'neutral', 'disagree', 'strongly disagree',
      'somewhat agree', 'somewhat disagree',
    ];
    return _anySignalIn(message, verbalScaleSignals);
  }

  /// Returns true when the message is substantive (more than a filler word).
  static bool _isSubstantive(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return false;
    // At least 2 characters and not purely punctuation.
    if (trimmed.length < 2) return false;
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.isNotEmpty;
  }

  /// Returns true if any signal in [signals] is found as a substring of
  /// [message]. Case-insensitive via the caller normalising to lowercase.
  static bool _anySignalIn(String message, List<String> signals) {
    for (final s in signals) {
      if (message.contains(s)) return true;
    }
    return false;
  }
}
