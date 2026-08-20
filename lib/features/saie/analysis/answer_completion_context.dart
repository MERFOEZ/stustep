/// SAIE — AnswerCompletionContext
///
/// The single immutable input to [AnswerCompletionEvaluator.evaluate].
///
/// Design principle:
///   This is NOT a parameter bag. It is a domain object that:
///   - Holds raw inputs required for the evaluation.
///   - Pre-computes derived signals in its factory so the evaluator
///     never has to re-derive them from raw data.
///   - Exposes a vocabulary specific to completion-evaluation semantics
///     (e.g. [isStructuredQuestion], [answerMatchesDefinedOption]).
///   - Is immutable — the evaluator reads it as a snapshot, never mutates it.
///
/// All pre-computed signals are computed ONCE in [AnswerCompletionContext.build].
/// The evaluator reads them as boolean facts, never runs its own regex or
/// parses the raw answer again.
library;

import 'package:stustep/features/saie/analysis/answer_features.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/models/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerCompletionContext
// ─────────────────────────────────────────────────────────────────────────────

/// The complete evaluation context for a single answer-completion decision.
///
/// Construct via [AnswerCompletionContext.build] — this is the only public way
/// to create an instance. All pre-computed signals are derived in the factory.
final class AnswerCompletionContext {
  // ── Raw inputs ───────────────────────────────────────────────────────────

  /// The assessment question currently being evaluated.
  final Question question;

  /// The student's raw answer text as received (before normalisation).
  final String rawAnswer;

  /// Pre-extracted structural and semantic features.
  /// Produced by [AnswerFeatureExtractor] — never re-extracted here.
  final AnswerFeatures features;

  /// The quality score already computed for this answer.
  /// Produced by [AnswerQualityEvaluator] — never re-scored here.
  final AnswerScore score;

  /// The last N turns of conversation (student + engine), newest-first.
  /// Used to detect recent explanations, repeated failures, and prior answers.
  final List<ConversationTurnRecord> recentHistory;

  /// How many clarification requests the student has already made
  /// for THIS specific question (not the session total).
  ///
  /// A value > 0 means the student already received at least one explanation
  /// for this question. Used for escalation logic.
  final int clarificationsOnThisQuestion;

  /// Active conversation language.
  /// Used to select the correct gap message and threshold labels.
  final Language language;

  // ── Pre-computed signals ─────────────────────────────────────────────────
  // Computed once in [build]. The evaluator reads these as facts.

  /// True if the question has a fixed, enumerated set of answer options.
  ///
  /// Structured types: [QuestionType.multipleChoice], [QuestionType.multiSelect],
  /// [QuestionType.likertScale], [QuestionType.ranking], [QuestionType.trueFalse].
  ///
  /// When true: completion is determined by option-match logic.
  /// When false: completion requires open-ended content analysis.
  final bool isStructuredQuestion;

  /// True if the normalised answer approximately matches one of the defined
  /// [Question.options] by key, label-prefix, or numeric index.
  ///
  /// Pre-computed to avoid O(n) option-scan inside the evaluator.
  /// Meaningful only when [isStructuredQuestion] is true.
  final bool answerMatchesDefinedOption;

  /// True if the answer text syntactically resembles a question rather than
  /// a statement — ends with "؟"/"?", or starts with a known question opener.
  ///
  /// Strong signal for [CompletionReason.clarificationRequest] or
  /// [CompletionReason.metaQuestion].
  final bool messageLooksLikeAQuestion;

  /// True if the most recent engine turn in [recentHistory] contained an
  /// explanation (clarification, examples, word-meaning, or "why" response).
  ///
  /// When true: the student may be replying to the explanation rather than
  /// answering the assessment question directly. Reduces confidence in
  /// treating the next message as a complete answer.
  final bool lastTurnWasExplanation;

  /// True when [clarificationsOnThisQuestion] > 0.
  /// Convenience alias used by escalation policy.
  final bool isRepeatedAttempt;

  // ── Private constructor ──────────────────────────────────────────────────

  const AnswerCompletionContext._({
    required this.question,
    required this.rawAnswer,
    required this.features,
    required this.score,
    required this.recentHistory,
    required this.clarificationsOnThisQuestion,
    required this.language,
    required this.isStructuredQuestion,
    required this.answerMatchesDefinedOption,
    required this.messageLooksLikeAQuestion,
    required this.lastTurnWasExplanation,
    required this.isRepeatedAttempt,
  });

  // ── Public factory ───────────────────────────────────────────────────────

  /// Constructs an [AnswerCompletionContext] from the components that are
  /// already available inside [ConversationController._handleContinueAssessment].
  ///
  /// All pre-computed signals are derived here. The evaluator receives a
  /// fully-resolved context and never has to examine raw data directly.
  factory AnswerCompletionContext.build({
    required Question question,
    required String rawAnswer,
    required AnswerFeatures features,
    required AnswerScore score,
    required List<ConversationTurnRecord> recentHistory,
    required int clarificationsOnThisQuestion,
    required Language language,
  }) {
    final structured = _isStructuredType(question.type);
    return AnswerCompletionContext._(
      question: question,
      rawAnswer: rawAnswer,
      features: features,
      score: score,
      recentHistory: recentHistory,
      clarificationsOnThisQuestion: clarificationsOnThisQuestion,
      language: language,
      isStructuredQuestion: structured,
      answerMatchesDefinedOption: structured
          ? _matchesDefinedOption(rawAnswer, question)
          : false,
      messageLooksLikeAQuestion: _detectsQuestion(rawAnswer),
      lastTurnWasExplanation: _wasExplanation(recentHistory),
      isRepeatedAttempt: clarificationsOnThisQuestion > 0,
    );
  }

  // ── Computed properties (derived lazily from stored fields) ──────────────
  // These keep the evaluator's condition expressions readable and
  // semantically named rather than inline boolean algebra.

  /// The type of the active question.
  /// Pass-through convenience accessor — avoids `ctx.question.type` noise.
  QuestionType get questionType => question.type;

  /// True for question types that require descriptive, substantive answers.
  bool get isOpenEndedQuestion =>
      question.type == QuestionType.openEnded ||
      question.type == QuestionType.situationalJudgment;

  /// True when the answer is very short AND the question requires depth.
  ///
  /// A "نعم" answer to an open-ended question is the canonical case.
  bool get isLikelySurfaceAnswer =>
      features.isVeryShort &&
      isOpenEndedQuestion &&
      !features.containsPersonalExperience;

  /// True when the answer contains both negation AND affirmation signals.
  ///
  /// Example: "لا أحب كثيراً ولكن أحياناً نعم" — ambiguous intent.
  bool get isAmbiguousAnswer =>
      features.containsNegation && features.containsAffirmation;

  /// True when [Language] is Arabic.
  bool get isArabic => language == Language.arabic;

  // ── Pre-computation helpers (private, called only in factory) ────────────

  static bool _isStructuredType(QuestionType type) =>
      type == QuestionType.multipleChoice ||
      type == QuestionType.multiSelect ||
      type == QuestionType.likertScale ||
      type == QuestionType.ranking ||
      type == QuestionType.trueFalse;

  static bool _matchesDefinedOption(String rawAnswer, Question question) {
    final lower = rawAnswer.toLowerCase().trim();

    for (var i = 0; i < question.options.length; i++) {
      final opt = question.options[i];

      // Key match: student typed "a", "b", "1", "2" ...
      if (lower == opt.key.toLowerCase()) return true;

      // Label-prefix match: first word of the option label is at least 3 chars
      // and the answer starts with it.
      final labelWords = opt.label.trim().split(' ');
      if (labelWords.isNotEmpty) {
        final prefix = labelWords.first.toLowerCase();
        if (prefix.length >= 3 && lower.startsWith(prefix)) return true;
      }

      // Numeric index match: "1" → first option, "2" → second, etc.
      if (lower == '${i + 1}') return true;
    }

    // Bare numeric in Likert range [1..5].
    if (question.type == QuestionType.likertScale) {
      final n = int.tryParse(lower);
      if (n != null && n >= 1 && n <= 5) return true;
    }

    return false;
  }

  static bool _detectsQuestion(String rawAnswer) {
    final trimmed = rawAnswer.trim();

    // Ends with a question mark (Arabic or English).
    if (trimmed.endsWith('؟') || trimmed.endsWith('?')) return true;

    final lower = trimmed.toLowerCase();

    // Arabic question openers at the start of the message.
    if (RegExp(r'^(هل|ما|ماذا|كيف|متى|لماذا|من|أين)\b').hasMatch(lower)) {
      return true;
    }

    // English question openers at the start of the message.
    if (RegExp(r'^(what|why|how|when|where|who|is it|does|do you|can i|could i)\b')
        .hasMatch(lower)) {
      return true;
    }

    return false;
  }

  static bool _wasExplanation(List<ConversationTurnRecord> history) {
    // Find the most recent engine turn (history is newest-first).
    final lastEngine =
        history.where((t) => t.isEngine).firstOrNull;
    if (lastEngine == null) return false;

    final content = lastEngine.content.toLowerCase();

    // Arabic explanation fingerprints.
    if (content.contains('أوضّح') ||
        content.contains('أوضح') ||
        content.contains('هذا السؤال يساعد') ||
        content.contains('إليك بعض الأمثلة') ||
        content.contains('خلّني أحاول') ||
        content.contains('بعبارة أبسط')) {
      return true;
    }

    // English explanation fingerprints.
    if (content.contains("here's what this question") ||
        content.contains('this question helps me') ||
        content.contains('some example answers') ||
        content.contains('some possible answers') ||
        content.contains('let me try a different angle')) {
      return true;
    }

    return false;
  }
}
