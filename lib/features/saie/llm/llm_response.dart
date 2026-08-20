/// SAIE LLM — LlmResponse
///
/// Represents a validated response returned by the LLM layer.
/// Includes status, raw text, token usage, and latency.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmResponseStatus
// ─────────────────────────────────────────────────────────────────────────────

enum LlmResponseStatus {
  /// LLM returned a valid, usable response.
  success,

  /// LLM was skipped — fallback applied.
  fallback,

  /// LLM returned an empty or malformed response.
  invalid,

  /// Network or provider error.
  error,

  /// Rate limit hit — fallback applied.
  rateLimited,

  /// Timeout exceeded.
  timedOut,
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmTokenUsage
// ─────────────────────────────────────────────────────────────────────────────

final class LlmTokenUsage extends Equatable {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const LlmTokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  static const zero = LlmTokenUsage(
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
  );

  factory LlmTokenUsage.fromJson(Map<String, dynamic> json) => LlmTokenUsage(
    promptTokens: (json['prompt_tokens'] as int?) ?? 0,
    completionTokens: (json['completion_tokens'] as int?) ?? 0,
    totalTokens: (json['total_tokens'] as int?) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'total_tokens': totalTokens,
  };

  @override
  List<Object?> get props => [promptTokens, completionTokens];
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmResponse
// ─────────────────────────────────────────────────────────────────────────────

/// The validated, normalised output of one LLM call.
final class LlmResponse extends Equatable {
  /// The corresponding request.
  final LlmRequest request;

  /// Validated response text (empty if [status] != success).
  final String text;

  /// Response status.
  final LlmResponseStatus status;

  /// Token usage reported by the provider.
  final LlmTokenUsage usage;

  /// Round-trip latency.
  final Duration latency;

  /// Fallback text used when [status] is [LlmResponseStatus.fallback].
  final String? fallbackText;

  /// Error message when [status] is [LlmResponseStatus.error].
  final String? errorMessage;

  const LlmResponse({
    required this.request,
    required this.text,
    required this.status,
    required this.latency,
    this.usage = LlmTokenUsage.zero,
    this.fallbackText,
    this.errorMessage,
  });

  /// Whether the response contains usable content.
  bool get isUsable =>
      status == LlmResponseStatus.success && text.trim().isNotEmpty;

  /// The text to surface to the student — LLM text if usable, else fallback.
  String get effectiveText =>
      isUsable ? text : (fallbackText ?? '');

  factory LlmResponse.fallback({
    required LlmRequest request,
    required String fallbackText,
    LlmResponseStatus status = LlmResponseStatus.fallback,
    String? reason,
  }) => LlmResponse(
    request: request,
    text: '',
    status: status,
    latency: Duration.zero,
    fallbackText: fallbackText,
    errorMessage: reason,
  );

  factory LlmResponse.error({
    required LlmRequest request,
    required String message,
    required String fallbackText,
    LlmResponseStatus status = LlmResponseStatus.error,
  }) => LlmResponse(
    request: request,
    text: '',
    status: status,
    latency: Duration.zero,
    fallbackText: fallbackText,
    errorMessage: message,
  );

  @override
  List<Object?> get props => [request.requestId, status, text];
}
