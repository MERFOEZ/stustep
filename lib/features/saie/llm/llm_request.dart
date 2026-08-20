/// SAIE LLM — LlmRequest / LlmTask
///
/// Represents a single request sent to the LLM.
/// Typed by [LlmTask] so the engine can gate what the LLM is allowed to do.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/llm/llm_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmTask
// ─────────────────────────────────────────────────────────────────────────────

/// All tasks the LLM is permitted to perform.
///
/// The LLM MUST NEVER:
/// - Recommend majors.
/// - Update the student cognitive profile.
/// - Make assessment decisions.
enum LlmTask {
  /// Discuss an academic topic the student raised.
  academicDiscussion,

  /// Explain a specific assessment question in plain language.
  questionExplanation,

  // ── Question Understanding Layer tasks ──────────────────────────────────
  // These tasks generate conversational responses without touching
  // the assessment state, student profile, or question selection.

  /// Student asked what a specific word or concept means.
  wordMeaning,

  /// Student asked why this particular question is being asked.
  whyThisQuestion,

  /// Student asked for concrete examples before answering.
  questionExamples,

  /// Student asked for a general clarification of the current question.
  questionClarification,

  /// Student expressed uncertainty — simplify and provide examples.
  uncertaintyHelp,

  // ── Recommendation tasks ─────────────────────────────────────────────────

  /// Explain why a major was recommended.
  recommendationExplanation,

  /// Describe career paths related to a recommended major.
  careerExplanation,

  /// Provide information about a specific university.
  universityExplanation,

  /// Generate a compact summary of the conversation so far.
  conversationSummarization,

  /// Rewrite an engine-generated response in more natural language.
  responsePolishing,

  /// Translate a response to the student's active language.
  translation,
}

extension LlmTaskX on LlmTask {
  /// Whether this task requires the recommendation report in context.
  bool get requiresRecommendation =>
      this == LlmTask.recommendationExplanation ||
      this == LlmTask.careerExplanation;

  /// Whether this task requires recent conversation history.
  bool get requiresHistory =>
      this == LlmTask.conversationSummarization ||
      this == LlmTask.academicDiscussion ||
      this == LlmTask.responsePolishing;

  /// Whether this is a QUL (Question Understanding Layer) task.
  bool get isQulTask =>
      this == LlmTask.wordMeaning ||
      this == LlmTask.whyThisQuestion ||
      this == LlmTask.questionExamples ||
      this == LlmTask.questionClarification ||
      this == LlmTask.uncertaintyHelp;

  /// Human-readable label.
  String get label => switch (this) {
    LlmTask.academicDiscussion      => 'Academic Discussion',
    LlmTask.questionExplanation     => 'Question Explanation',
    LlmTask.wordMeaning             => 'Word Meaning',
    LlmTask.whyThisQuestion         => 'Why This Question',
    LlmTask.questionExamples        => 'Question Examples',
    LlmTask.questionClarification   => 'Question Clarification',
    LlmTask.uncertaintyHelp         => 'Uncertainty Help',
    LlmTask.recommendationExplanation => 'Recommendation Explanation',
    LlmTask.careerExplanation       => 'Career Explanation',
    LlmTask.universityExplanation   => 'University Explanation',
    LlmTask.conversationSummarization => 'Conversation Summarization',
    LlmTask.responsePolishing       => 'Response Polishing',
    LlmTask.translation             => 'Translation',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmMessage
// ─────────────────────────────────────────────────────────────────────────────

/// A single chat message in the OpenAI messages array format.
final class LlmMessage extends Equatable {
  final String role; // 'system' | 'user' | 'assistant'
  final String content;

  const LlmMessage({required this.role, required this.content});

  factory LlmMessage.system(String content) =>
      LlmMessage(role: 'system', content: content);

  factory LlmMessage.user(String content) =>
      LlmMessage(role: 'user', content: content);

  factory LlmMessage.assistant(String content) =>
      LlmMessage(role: 'assistant', content: content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory LlmMessage.fromJson(Map<String, dynamic> json) => LlmMessage(
    role: json['role'] as String,
    content: json['content'] as String,
  );

  @override
  List<Object?> get props => [role, content];
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmRequest
// ─────────────────────────────────────────────────────────────────────────────

/// A fully-built LLM request — ready to be executed by [LlmClient].
final class LlmRequest extends Equatable {
  /// Unique ID for tracing.
  final String requestId;

  /// The task this request fulfils.
  final LlmTask task;

  /// The model to use (resolved from [LlmConfiguration]).
  final String modelId;

  /// Messages in OpenAI chat format.
  final List<LlmMessage> messages;

  /// Maximum tokens for the response.
  final int maxTokens;

  /// Generation temperature.
  final double temperature;

  /// Target provider — used by the client to build headers.
  final LlmProvider provider;

  /// Whether to request a streaming response.
  final bool stream;

  /// Timestamp of creation.
  final DateTime createdAt;

  const LlmRequest({
    required this.requestId,
    required this.task,
    required this.modelId,
    required this.messages,
    required this.provider,
    this.maxTokens = 800,
    this.temperature = 0.5,
    this.stream = false,
    required this.createdAt,
  });

  Map<String, dynamic> toOpenAiBody() => {
    'model': modelId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'max_tokens': maxTokens,
    'temperature': temperature,
    if (stream) 'stream': true,
  };

  @override
  List<Object?> get props => [requestId, task, modelId];
}
