/// SAIE LLM — QulIntent
///
/// Identifies the five Question Understanding Layer interaction types
/// the student can request during an active assessment question.
///
/// The Conversation Layer detects the intent; [LLMExplanationService]
/// generates the response. The Assessment Engine is never involved.
library;

// ─────────────────────────────────────────────────────────────────────────────
// QulIntent
// ─────────────────────────────────────────────────────────────────────────────

/// The five question-level support intents.
///
/// None of these advance the assessment, update the student profile, or
/// modify [AssessmentState]. They only produce a conversational response.
enum QulIntent {
  /// Student asked for a general clarification of the question.
  clarification,

  /// Student asked what a specific word or concept means.
  wordMeaning,

  /// Student asked why this question is being asked.
  whyThisQuestion,

  /// Student asked for concrete examples before answering.
  examples,

  /// Student expressed that they don't know or are unsure (may escalate to skip).
  uncertainty,
}

extension QulIntentX on QulIntent {
  /// Short Arabic label used in logs.
  String get arabicLabel => switch (this) {
        QulIntent.clarification   => 'توضيح السؤال',
        QulIntent.wordMeaning     => 'معنى مصطلح',
        QulIntent.whyThisQuestion => 'سبب السؤال',
        QulIntent.examples        => 'أمثلة',
        QulIntent.uncertainty     => 'لا أعرف',
      };
}
