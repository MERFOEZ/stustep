/// StuStep — AI Configuration (HuggingFace Router)
///
/// Uses HuggingFace Router as the LLM gateway — OpenAI-compatible endpoint.
/// Set your HF_TOKEN from https://huggingface.co/settings/tokens
library;

import 'package:stustep/features/saie/llm/llm_configuration.dart';
import 'package:stustep/features/saie/llm/llm_provider.dart';
import 'package:stustep/features/saie/llm/llm_retry_policy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GeminiConfig  (now backed by HuggingFace Router)
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-built [LlmConfiguration] backed by HuggingFace Router.
/// Keeping the class name to avoid changing all imports.
abstract final class GeminiConfig {
  // HuggingFace token — get yours from https://huggingface.co/settings/tokens
  static const _apiKey = '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';

  /// Model routed via HuggingFace → Novita provider.
  static const String _modelId = 'zai-org/GLM-5.2:novita';

  /// HuggingFace Router base URL.
  static const String _baseUrl = 'https://router.huggingface.co/v1';

  /// Returns a ready-to-use [LlmConfiguration] via HuggingFace Router.
  static LlmConfiguration get config => const LlmConfiguration(
        provider: LlmProvider.custom,
        apiKey: _apiKey,
        modelId: _modelId,
        baseUrl: _baseUrl,
        temperature: 0.4,
        maxResponseTokens: 1024,
        retryPolicy: LlmRetryPolicy(
          maxAttempts: 2,
          initialDelay: Duration(seconds: 2),
        ),
        timeout: Duration(seconds: 30),
      );

  /// Returns true if a real API key is configured.
  static bool get isConfigured =>
      _apiKey.isNotEmpty && !_apiKey.startsWith('YOUR_');
}
