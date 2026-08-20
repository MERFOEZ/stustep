/// SAIE LLM — LlmErrorHandler
///
/// Classifies HTTP and network errors into [LlmResponseStatus] values.
/// Never throws — always returns a handled result.
library;

import 'package:stustep/features/saie/llm/llm_response.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmErrorCategory
// ─────────────────────────────────────────────────────────────────────────────

enum LlmErrorCategory {
  /// 4xx client errors that are not retryable.
  clientError,

  /// 429 — provider rate limit exceeded.
  rateLimited,

  /// 5xx server errors — may be transient.
  serverError,

  /// Network timeout.
  timeout,

  /// DNS / socket / connectivity failure.
  networkFailure,

  /// Response was received but content is invalid.
  invalidContent,

  /// Unknown / unclassified.
  unknown,
}

// ─────────────────────────────────────────────────────────────────────────────
// LlmErrorHandler
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless error classifier and [LlmResponse] factory for failure paths.
final class LlmErrorHandler {
  const LlmErrorHandler();

  // ── Classification ─────────────────────────────────────────────────────────

  /// Classify an HTTP status code.
  LlmErrorCategory classifyHttpStatus(int statusCode) => switch (statusCode) {
    429 => LlmErrorCategory.rateLimited,
    >= 400 && < 500 => LlmErrorCategory.clientError,
    >= 500 => LlmErrorCategory.serverError,
    _ => LlmErrorCategory.unknown,
  };

  /// Whether [category] is safe to retry.
  bool isRetryable(LlmErrorCategory category) => switch (category) {
    LlmErrorCategory.serverError => true,
    LlmErrorCategory.networkFailure => true,
    LlmErrorCategory.timeout => true,
    LlmErrorCategory.rateLimited => true,
    _ => false,
  };

  // ── Response factories ─────────────────────────────────────────────────────

  /// Build a fallback [LlmResponse] for an HTTP error.
  LlmResponse handleHttpError({
    required LlmRequest request,
    required int statusCode,
    required String fallbackText,
    String? body,
  }) {
    final category = classifyHttpStatus(statusCode);
    final status = category == LlmErrorCategory.rateLimited
        ? LlmResponseStatus.rateLimited
        : LlmResponseStatus.error;

    return LlmResponse.error(
      request: request,
      message: 'HTTP $statusCode: ${body ?? category.name}',
      fallbackText: fallbackText,
      status: status,
    );
  }

  /// Build a fallback [LlmResponse] for a timeout.
  LlmResponse handleTimeout({
    required LlmRequest request,
    required String fallbackText,
  }) => LlmResponse.error(
    request: request,
    message: 'LLM request timed out.',
    fallbackText: fallbackText,
    status: LlmResponseStatus.timedOut,
  );

  /// Build a fallback [LlmResponse] for any unexpected exception.
  LlmResponse handleException({
    required LlmRequest request,
    required Object error,
    required String fallbackText,
  }) => LlmResponse.error(
    request: request,
    message: 'LLM error: ${error.runtimeType}: $error',
    fallbackText: fallbackText,
    status: LlmResponseStatus.error,
  );

  /// Build a fallback [LlmResponse] for invalid / empty content.
  LlmResponse handleInvalidContent({
    required LlmRequest request,
    required String reason,
    required String fallbackText,
  }) => LlmResponse(
    request: request,
    text: '',
    status: LlmResponseStatus.invalid,
    latency: Duration.zero,
    fallbackText: fallbackText,
    errorMessage: reason,
  );
}
