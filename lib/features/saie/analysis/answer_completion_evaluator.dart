/// SAIE — AnswerCompletionEvaluator
///
/// Decides whether the current assessment question has been answered
/// sufficiently to allow the assessment to advance.
///
/// This component is the answer to the question:
///   "Has the assessment OBJECTIVE for this question been satisfied?"
///
/// It is NOT:
///   - A language understander (that is the Decision Engine).
///   - A quality scorer (that is [AnswerQualityEvaluator]).
///   - A profile updater (that is [DimensionUpdater]).
///
/// It is a pure completion gate. Its only output is a [CompletionEvaluation].
///
/// Pipeline placement:
///   AnswerIntelligenceEngine.process()      → [AnswerProcessingResult]
///   AnswerCompletionEvaluator.evaluate()    → [CompletionEvaluation]  ← HERE
///   AdaptiveAssessmentEngine.advance()      (only when state == complete)
///
/// Stateless — all state is passed in via [AnswerCompletionContext].
/// Pure Dart. No Flutter. No HTTP. No external dependencies.
library;

import 'package:stustep/features/saie/analysis/answer_completion_context.dart';
import 'package:stustep/features/saie/analysis/answer_completion_evaluation.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerCompletionEvaluator
// ─────────────────────────────────────────────────────────────────────────────

/// Evaluates whether the assessment question has been sufficiently answered.
///
/// The evaluator consults three signals in priority order:
///
///   1. **Conversational intent** — Is the message actually an answer at all?
///      (If it is a question or meta-remark, no scoring is needed.)
///
///   2. **Question-type objective** — Each [QuestionType] defines what
///      "done" looks like. A Likert "done" is a number 1–5. An open-ended
///      "done" requires substantive content.
///
///   3. **Score band** — The [AnswerScore] computed by [AnswerQualityEvaluator]
///      provides a quality floor. Very low scores trigger probe behaviour even
///      when the answer structurally looks valid.
///
/// Confidence floor: if the evaluator's confidence drops below [_minConfidence],
/// the result is [CompletionEvaluation.lowConfidence] rather than a false
/// [CompletionEvaluation.complete].
final class AnswerCompletionEvaluator {
  /// Minimum score (0–100) for a structured answer to be considered complete.
  static const int _structuredMinScore = 20;

  /// Minimum score (0–100) for an open-ended answer to be considered complete.
  static const int _openEndedMinScore = 35;

  /// Confidence below this threshold triggers [CompletionReason.lowEvaluatorConfidence].
  static const double _minConfidence = 0.45;

  const AnswerCompletionEvaluator();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Evaluates whether [ctx.question] has been sufficiently answered.
  ///
  /// Returns a [CompletionEvaluation] that drives the controller's next action.
  CompletionEvaluation evaluate(AnswerCompletionContext ctx) {
    try {
      return _doEvaluate(ctx);
    } catch (_) {
      // The evaluator must never throw — a blocked result is safe.
      return CompletionEvaluation.blocked(
        rationale: 'Unexpected error in AnswerCompletionEvaluator.',
      );
    }
  }

  // ── Core evaluation ───────────────────────────────────────────────────────

  CompletionEvaluation _doEvaluate(AnswerCompletionContext ctx) {
    // ── Signal 1: Conversational Intent ──────────────────────────────────────
    // Check this FIRST before any structural analysis.
    // A clarification request or meta-question is never an answer — no
    // quality score can override this.

    if (ctx.messageLooksLikeAQuestion) {
      return _classifyQuestionMessage(ctx);
    }

    // ── Signal 2: Question-Type Objective ─────────────────────────────────────
    // Each question type has a concrete definition of "done".

    return ctx.isStructuredQuestion
        ? _evaluateStructured(ctx)
        : _evaluateOpenEnded(ctx);
  }

  // ── Signal 1 handler ──────────────────────────────────────────────────────

  /// Classifies a message that looks like a question.
  ///
  /// Distinguishes between:
  ///   - Clarification requests about the question content (QUL handler).
  ///   - Meta-questions about the assessment structure (meta handler).
  CompletionEvaluation _classifyQuestionMessage(AnswerCompletionContext ctx) {
    final lower = ctx.rawAnswer.toLowerCase();

    // Meta-question indicators: about the assessment itself, not the content.
    final isMetaAr =
        lower.contains('لماذا تسألني') ||
        lower.contains('ما فائدة') ||
        lower.contains('يمكنني تخطي') ||
        lower.contains('هل يمكنني') ||
        lower.contains('هل هذا ضروري');
    final isMetaEn =
        lower.contains('why are you asking') ||
        lower.contains('can i skip') ||
        lower.contains('is this necessary') ||
        lower.contains('what is the point');

    if (isMetaAr || isMetaEn) {
      return CompletionEvaluation.metaQuestion(
        rationale: 'Student is questioning the assessment structure.',
      );
    }

    // Default: treat as a clarification request (QUL handler).
    return CompletionEvaluation.clarificationRequest(
      rationale: 'Message ends with a question mark or begins with a question opener.',
    );
  }

  // ── Signal 2: Structured question evaluation ───────────────────────────────

  /// Evaluates a structured question (MC, Likert, true/false, ranking, multi-select).
  ///
  /// "Done" criteria:
  ///   - Answer matches a defined option OR is a valid numeric response, AND
  ///   - Score band is not [ScoreBand.invalid].
  CompletionEvaluation _evaluateStructured(AnswerCompletionContext ctx) {
    // Option match is the primary signal for structured questions.
    if (ctx.answerMatchesDefinedOption) {
      if (ctx.score.total >= _structuredMinScore) {
        return CompletionEvaluation.complete(
          confidence: 0.95,
          rationale: 'Structured answer matches a defined option with valid score.',
        );
      }
      // Option matched but score is suspiciously low.
      return CompletionEvaluation.lowConfidence(
        gap: _gapForStructured(ctx),
        rationale: 'Option matched but score (${ctx.score.total}) below structured threshold.',
      );
    }

    // No option match — check if the answer is completely empty/invalid.
    if (ctx.score.band == ScoreBand.invalid) {
      return CompletionEvaluation.insufficient(
        gap: _gapForStructured(ctx),
        rationale: 'Answer does not match any defined option and has invalid score.',
      );
    }

    // Partial: the student said something but it doesn't clearly match an option.
    return CompletionEvaluation.partial(
      gap: _gapForStructured(ctx),
      confidence: 0.6,
      rationale: 'Answer does not match a defined option. Probing for clarity.',
    );
  }

  // ── Signal 2: Open-ended question evaluation ───────────────────────────────

  /// Evaluates an open-ended or situational-judgment question.
  ///
  /// "Done" criteria:
  ///   - Score band is [ScoreBand.acceptable] or better, AND
  ///   - Answer is not a surface-level single-word/very-short response.
  CompletionEvaluation _evaluateOpenEnded(AnswerCompletionContext ctx) {
    // Hard minimum: score must clear the open-ended floor.
    if (ctx.score.total < _openEndedMinScore ||
        ctx.score.band == ScoreBand.invalid) {
      return CompletionEvaluation.insufficient(
        gap: _gapForOpenEnded(ctx),
        confidence: 0.85,
        rationale: 'Open-ended score (${ctx.score.total}) below minimum threshold.',
      );
    }

    // Surface answer: very short, no personal experience, no reasoning.
    if (ctx.isLikelySurfaceAnswer) {
      return CompletionEvaluation.partial(
        gap: _gapForOpenEnded(ctx),
        confidence: 0.80,
        rationale: 'Answer is too short for an open-ended question without personal grounding.',
      );
    }

    // Ambiguous: contains both negation and affirmation.
    if (ctx.isAmbiguousAnswer && ctx.score.total < 55) {
      return CompletionEvaluation.partial(
        gap: _gapForAmbiguous(ctx),
        confidence: 0.65,
        rationale: 'Answer contains conflicting signals (negation + affirmation).',
      );
    }

    // Last-turn was an explanation: reduce confidence slightly.
    // The student may be replying to the explanation rather than answering.
    if (ctx.lastTurnWasExplanation && ctx.score.total < 50) {
      final confidence = 0.55;
      if (confidence < _minConfidence) {
        return CompletionEvaluation.lowConfidence(
          gap: _gapForOpenEnded(ctx),
          confidence: confidence,
          rationale: 'Last turn was an explanation; answer score is marginal.',
        );
      }
    }

    // Acceptable or better — question is complete.
    return CompletionEvaluation.complete(
      confidence: _confidenceFromScore(ctx.score.total),
      rationale: 'Open-ended answer meets minimum content and score requirements.',
    );
  }

  // ── Gap message builders ──────────────────────────────────────────────────
  // These produce the student-facing gap descriptions.
  // They are question-type-aware and language-aware.

  String _gapForStructured(AnswerCompletionContext ctx) {
    if (ctx.isArabic) {
      return switch (ctx.questionType) {
        QuestionType.likertScale =>
          'يرجى إدخال رقم من 1 إلى 5، أو اختر الخيار الذي يعبّر عن مدى اهتمامك.',
        QuestionType.trueFalse =>
          'يرجى الإجابة بـ "نعم" أو "لا"، أو اختر من الخيارين المتاحين.',
        QuestionType.multipleChoice =>
          'يرجى اختيار الخيار الأقرب لشخصيتك من بين الخيارات المتاحة.',
        QuestionType.multiSelect =>
          'يرجى اختيار الخيارات التي تنطبق عليك.',
        QuestionType.ranking =>
          'يرجى ترتيب الخيارات من الأهم إلى الأقل أهمية بالنسبة لك.',
        _ => 'يرجى اختيار إجابة واضحة من الخيارات المتاحة.',
      };
    } else {
      return switch (ctx.questionType) {
        QuestionType.likertScale =>
          'Please enter a number from 1 to 5, or choose the option that best reflects your interest.',
        QuestionType.trueFalse =>
          'Please answer with "yes" or "no", or choose from the two available options.',
        QuestionType.multipleChoice =>
          'Please choose the option that best matches your personality from the available choices.',
        QuestionType.multiSelect =>
          'Please select the options that apply to you.',
        QuestionType.ranking =>
          'Please rank the options from most to least important to you.',
        _ => 'Please select a clear answer from the available options.',
      };
    }
  }

  String _gapForOpenEnded(AnswerCompletionContext ctx) {
    if (ctx.isArabic) {
      if (ctx.isRepeatedAttempt) {
        return 'في بضع كلمات، هل يمكنك إخباري عن تجربة شخصية أو موقف ملموس يعكس إجابتك؟';
      }
      return 'هل يمكنك إخباري أكثر قليلاً؟ حتى جملة واحدة توضّح رأيك الحقيقي تكفي.';
    } else {
      if (ctx.isRepeatedAttempt) {
        return 'Could you share a personal experience or a concrete situation that reflects your answer?';
      }
      return 'Could you tell me a little more? Even one sentence that clarifies your genuine view is enough.';
    }
  }

  String _gapForAmbiguous(AnswerCompletionContext ctx) {
    if (ctx.isArabic) {
      return 'يبدو أن إجابتك تحتوي على وجهتي نظر. أي منهما هو شعورك الأقرب للحقيقة؟';
    } else {
      return 'Your answer seems to contain two perspectives. Which one is closer to how you genuinely feel?';
    }
  }

  // ── Internal utilities ────────────────────────────────────────────────────

  /// Converts a raw score (0–100) to a confidence value in [0.5, 1.0].
  double _confidenceFromScore(int total) {
    // Map [35..100] → [0.50..1.00] linearly.
    final clamped = total.clamp(35, 100);
    return 0.50 + (clamped - 35) / (100 - 35) * 0.50;
  }
}
