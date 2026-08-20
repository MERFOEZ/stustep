/// SAIE LLM — LlmFactory
///
/// The single creation point for the entire LLM layer.
/// Validates configuration and wires all components together.
library;

import 'package:stustep/features/saie/llm/llm_client.dart';
import 'package:stustep/features/saie/llm/llm_configuration.dart';
import 'package:stustep/features/saie/llm/llm_context_builder.dart';
import 'package:stustep/features/saie/llm/llm_error_handler.dart';
import 'package:stustep/features/saie/llm/llm_fallback.dart';
import 'package:stustep/features/saie/llm/llm_prompt_builder.dart';
import 'package:stustep/features/saie/llm/llm_rate_limiter.dart';
import 'package:stustep/features/saie/llm/llm_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmFactory
// ─────────────────────────────────────────────────────────────────────────────

/// Creates a fully configured [LlmService] from an [LlmConfiguration].
///
/// Returns an offline-only service if the configuration is disabled.
final class LlmFactory {
  const LlmFactory();

  /// Build an [LlmService] from [config].
  LlmService create(LlmConfiguration config) {
    final errorHandler = const LlmErrorHandler();
    final rateLimiter = LlmRateLimiter(
      maxRequests: 60,
      window: const Duration(minutes: 1),
    );

    final client = LlmClient(
      config: config,
      errorHandler: errorHandler,
      rateLimiter: rateLimiter,
    );

    final contextBuilder = const LlmContextBuilder();
    final promptBuilder = const LlmPromptBuilder();
    final fallback = const LlmFallback();

    return LlmService(
      config: config,
      client: client,
      contextBuilder: contextBuilder,
      promptBuilder: promptBuilder,
      fallback: fallback,
    );
  }

  /// Build a fully offline [LlmService] (no API calls ever made).
  LlmService createOffline() => create(LlmConfiguration.offline);
}
