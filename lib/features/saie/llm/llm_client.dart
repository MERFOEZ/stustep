/// SAIE LLM — LlmClient
///
/// The HTTP transport layer. Sends [LlmRequest]s to the configured provider
/// using dart:io HttpClient (pure Dart — no Flutter, no http package required).
///
/// All failures are caught and converted to [LlmResponse.fallback] via
/// [LlmErrorHandler]. The engine NEVER crashes because of LLM failures.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stustep/features/saie/llm/llm_configuration.dart';
import 'package:stustep/features/saie/llm/llm_error_handler.dart';
import 'package:stustep/features/saie/llm/llm_provider.dart';
import 'package:stustep/features/saie/llm/llm_rate_limiter.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/llm/llm_response.dart';
import 'package:stustep/features/saie/llm/llm_retry_policy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmClient
// ─────────────────────────────────────────────────────────────────────────────

/// Pure Dart HTTP client for OpenAI-compatible LLM endpoints.
///
/// Uses [dart:io] HttpClient — no third-party HTTP package needed.
/// All I/O errors, timeouts, and invalid responses are caught internally.
final class LlmClient {
  final LlmConfiguration _config;
  final LlmErrorHandler _errorHandler;
  final LlmRateLimiter _rateLimiter;


  LlmClient({
    required LlmConfiguration config,
    LlmErrorHandler errorHandler = const LlmErrorHandler(),
    LlmRateLimiter? rateLimiter,
  })  : _config = config,
        _errorHandler = errorHandler,
        _rateLimiter = rateLimiter ??
            LlmRateLimiter(maxRequests: 60, window: const Duration(minutes: 1));

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Send [request] to the LLM and return a [LlmResponse].
  ///
  /// Never throws. All failures produce a [LlmResponse] with fallback content.
  Future<LlmResponse> send({
    required LlmRequest request,
    required String fallbackText,
  }) async {
    if (!_config.isEnabled) {
      return LlmResponse.fallback(
        request: request,
        fallbackText: fallbackText,
        reason: 'LLM disabled — offline mode.',
      );
    }

    if (!_rateLimiter.isAllowed) {
      return _errorHandler.handleHttpError(
        request: request,
        statusCode: 429,
        fallbackText: fallbackText,
        body: 'Local rate limit exceeded.',
      );
    }

    return _sendWithRetry(
      request: request,
      fallbackText: fallbackText,
      policy: _config.retryPolicy,
    );
  }

  // ── Private: retry loop ─────────────────────────────────────────────────────

  Future<LlmResponse> _sendWithRetry({
    required LlmRequest request,
    required String fallbackText,
    required LlmRetryPolicy policy,
  }) async {
    LlmResponse? last;
    for (var attempt = 0; attempt <= policy.maxAttempts; attempt++) {
      if (attempt > 0) {
        final delay = policy.delayForAttempt(attempt);
        await Future<void>.delayed(delay);
      }
      last = await _sendOnce(request: request, fallbackText: fallbackText);
      if (last.isUsable) return last;
      if (!_errorHandler.isRetryable(
        _categoryFromResponse(last),
      )) { break; }
    }
    return last!;
  }

  LlmErrorCategory _categoryFromResponse(LlmResponse r) => switch (r.status) {
    LlmResponseStatus.rateLimited => LlmErrorCategory.rateLimited,
    LlmResponseStatus.timedOut => LlmErrorCategory.timeout,
    LlmResponseStatus.error => LlmErrorCategory.serverError,
    _ => LlmErrorCategory.unknown,
  };

  // ── Private: single attempt ─────────────────────────────────────────────────

  Future<LlmResponse> _sendOnce({
    required LlmRequest request,
    required String fallbackText,
  }) async {
    final sw = Stopwatch()..start();
    final client = HttpClient();
    client.connectionTimeout = _config.timeout;

    try {
      final url = _resolveUrl(request);
      final uri = Uri.parse(url);

      final httpRequest = await client
          .postUrl(uri)
          .timeout(_config.timeout);

      // Headers.
      httpRequest.headers.contentType = ContentType.json;
      _buildHeaders(request.provider).forEach((k, v) {
        httpRequest.headers.set(k, v);
      });
      _config.customHeaders.forEach((k, v) {
        httpRequest.headers.set(k, v);
      });

      // Body.
      final body = jsonEncode(request.toOpenAiBody());
      httpRequest.write(body);

      final httpResponse = await httpRequest.close().timeout(_config.timeout);
      sw.stop();

      final responseBody =
          await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode != 200) {
        return _errorHandler.handleHttpError(
          request: request,
          statusCode: httpResponse.statusCode,
          fallbackText: fallbackText,
          body: responseBody,
        );
      }

      _rateLimiter.recordRequest();
      return _parseResponse(
        request: request,
        body: responseBody,
        fallbackText: fallbackText,
        latency: sw.elapsed,
      );
    } on TimeoutException {
      sw.stop();
      return _errorHandler.handleTimeout(
        request: request,
        fallbackText: fallbackText,
      );
    } catch (e) {
      sw.stop();
      return _errorHandler.handleException(
        request: request,
        error: e,
        fallbackText: fallbackText,
      );
    } finally {
      client.close(force: true);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _resolveUrl(LlmRequest request) {
    final base = _config.effectiveBaseUrl.trimRight();
    if (request.provider == LlmProvider.azureOpenAI) {
      final deployment = _config.azureDeploymentName ?? request.modelId;
      final version = _config.azureApiVersion ?? '2024-02-01';
      return '$base/openai/deployments/$deployment'
          '/chat/completions?api-version=$version';
    }
    return '$base/chat/completions';
  }

  Map<String, String> _buildHeaders(LlmProvider provider) => switch (provider) {
    LlmProvider.openAI || LlmProvider.ollama || LlmProvider.lmStudio ||
    LlmProvider.custom => {
      if (_config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${_config.apiKey}',
    },
    LlmProvider.azureOpenAI => {
      if (_config.apiKey.isNotEmpty) 'api-key': _config.apiKey,
    },
    LlmProvider.openRouter => {
      if (_config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${_config.apiKey}',
      'HTTP-Referer': 'https://sustep.app',
      'X-Title': 'StuStep SAIE',
    },
    // Gemini OpenAI-compatible endpoint uses X-goog-api-key
    LlmProvider.gemini => {
      if (_config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${_config.apiKey}',
    },
    LlmProvider.none => const {},
  };


  LlmResponse _parseResponse({
    required LlmRequest request,
    required String body,
    required String fallbackText,
    required Duration latency,
  }) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return _errorHandler.handleInvalidContent(
          request: request,
          reason: 'No choices in response.',
          fallbackText: fallbackText,
        );
      }
      final message =
          (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final text = (message?['content'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        return _errorHandler.handleInvalidContent(
          request: request,
          reason: 'Empty content in response.',
          fallbackText: fallbackText,
        );
      }

      final usage = json['usage'] != null
          ? LlmTokenUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : LlmTokenUsage.zero;

      return LlmResponse(
        request: request,
        text: text,
        status: LlmResponseStatus.success,
        latency: latency,
        usage: usage,
      );
    } catch (e) {
      return _errorHandler.handleInvalidContent(
        request: request,
        reason: 'Parse error: $e',
        fallbackText: fallbackText,
      );
    }
  }
}
