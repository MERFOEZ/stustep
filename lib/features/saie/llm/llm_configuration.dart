/// SAIE LLM — LlmConfiguration
///
/// Immutable configuration for the LLM integration layer.
/// Validated at construction. No I/O.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/llm/llm_provider.dart';
import 'package:stustep/features/saie/llm/llm_retry_policy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmConfiguration
// ─────────────────────────────────────────────────────────────────────────────

/// Full configuration for the LLM layer.
///
/// If [provider] is [LlmProvider.none] or [apiKey] is empty for remote
/// providers, the engine automatically falls back to local offline processing.
final class LlmConfiguration extends Equatable {
  /// Active provider.
  final LlmProvider provider;

  /// API key (empty for local providers / offline mode).
  final String apiKey;

  /// Model identifier (e.g. "gpt-4o", "mistral", "llama3").
  final String modelId;

  /// Base URL override. Empty = use provider default.
  final String baseUrl;

  /// Deployment name (Azure OpenAI only).
  final String? azureDeploymentName;

  /// API version (Azure OpenAI only).
  final String? azureApiVersion;

  /// Request timeout.
  final Duration timeout;

  /// Retry policy applied to transient failures.
  final LlmRetryPolicy retryPolicy;

  /// Additional HTTP headers injected into every request.
  final Map<String, String> customHeaders;

  /// Maximum tokens in the LLM response.
  final int maxResponseTokens;

  /// Temperature for generation (0.0 = deterministic, 1.0 = creative).
  final double temperature;

  /// Whether to enable streaming responses.
  final bool streamingEnabled;

  const LlmConfiguration({
    this.provider = LlmProvider.none,
    this.apiKey = '',
    this.modelId = 'gpt-4o-mini',
    this.baseUrl = '',
    this.azureDeploymentName,
    this.azureApiVersion,
    this.timeout = const Duration(seconds: 30),
    this.retryPolicy = const LlmRetryPolicy(),
    this.customHeaders = const {},
    this.maxResponseTokens = 800,
    this.temperature = 0.5,
    this.streamingEnabled = false,
  });

  /// Offline-only configuration — no LLM will be called.
  static const offline = LlmConfiguration(provider: LlmProvider.none);

  /// Effective base URL (provider default if not overridden).
  String get effectiveBaseUrl =>
      baseUrl.isNotEmpty ? baseUrl : provider.defaultBaseUrl;

  /// Whether this configuration can make LLM requests.
  bool get isEnabled =>
      provider != LlmProvider.none &&
      (provider.isLocal || apiKey.isNotEmpty);

  factory LlmConfiguration.fromJson(Map<String, dynamic> json) =>
      LlmConfiguration(
        provider:
            LlmProvider.values.byName((json['provider'] as String?) ?? 'none'),
        apiKey: (json['api_key'] as String?) ?? '',
        modelId: (json['model_id'] as String?) ?? 'gpt-4o-mini',
        baseUrl: (json['base_url'] as String?) ?? '',
        azureDeploymentName: json['azure_deployment_name'] as String?,
        azureApiVersion: json['azure_api_version'] as String?,
        timeout: Duration(
          seconds: (json['timeout_seconds'] as int?) ?? 30,
        ),
        maxResponseTokens: (json['max_response_tokens'] as int?) ?? 800,
        temperature: ((json['temperature'] as num?) ?? 0.5).toDouble(),
        streamingEnabled: (json['streaming_enabled'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'api_key': apiKey,
    'model_id': modelId,
    'base_url': baseUrl,
    if (azureDeploymentName != null)
      'azure_deployment_name': azureDeploymentName,
    if (azureApiVersion != null) 'azure_api_version': azureApiVersion,
    'timeout_seconds': timeout.inSeconds,
    'max_response_tokens': maxResponseTokens,
    'temperature': temperature,
    'streaming_enabled': streamingEnabled,
  };

  LlmConfiguration copyWith({
    LlmProvider? provider,
    String? apiKey,
    String? modelId,
    String? baseUrl,
    String? azureDeploymentName,
    String? azureApiVersion,
    Duration? timeout,
    LlmRetryPolicy? retryPolicy,
    Map<String, String>? customHeaders,
    int? maxResponseTokens,
    double? temperature,
    bool? streamingEnabled,
  }) => LlmConfiguration(
    provider: provider ?? this.provider,
    apiKey: apiKey ?? this.apiKey,
    modelId: modelId ?? this.modelId,
    baseUrl: baseUrl ?? this.baseUrl,
    azureDeploymentName: azureDeploymentName ?? this.azureDeploymentName,
    azureApiVersion: azureApiVersion ?? this.azureApiVersion,
    timeout: timeout ?? this.timeout,
    retryPolicy: retryPolicy ?? this.retryPolicy,
    customHeaders: customHeaders ?? this.customHeaders,
    maxResponseTokens: maxResponseTokens ?? this.maxResponseTokens,
    temperature: temperature ?? this.temperature,
    streamingEnabled: streamingEnabled ?? this.streamingEnabled,
  );

  @override
  List<Object?> get props =>
      [provider, modelId, baseUrl, maxResponseTokens];
}
