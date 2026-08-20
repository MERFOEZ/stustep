/// SAIE LLM — LlmProvider Enum
///
/// Enumerates all supported LLM providers.
/// Adding a new provider requires only a new enum value.
library;

/// All supported LLM back-ends.
///
/// Every provider uses an OpenAI-compatible HTTP interface,
/// so switching providers requires only a URL/header change.
enum LlmProvider {
  /// OpenAI public API (api.openai.com).
  openAI,

  /// Azure OpenAI Service.
  azureOpenAI,

  /// OpenRouter aggregator (openrouter.ai).
  openRouter,

  /// Google Gemini via OpenAI-compatible endpoint.
  gemini,

  /// Ollama local inference server.
  ollama,

  /// LM Studio local inference server.
  lmStudio,

  /// Any other OpenAI-compatible REST endpoint.
  custom,

  /// No LLM configured — engine runs fully offline.
  none,
}

extension LlmProviderX on LlmProvider {
  bool get isLocal =>
      this == LlmProvider.ollama || this == LlmProvider.lmStudio;

  bool get isRemote =>
      this == LlmProvider.openAI ||
      this == LlmProvider.azureOpenAI ||
      this == LlmProvider.openRouter ||
      this == LlmProvider.gemini;

  bool get isNone => this == LlmProvider.none;

  /// Default base URL for the provider.
  String get defaultBaseUrl => switch (this) {
    LlmProvider.openAI => 'https://api.openai.com/v1',
    LlmProvider.azureOpenAI => '',
    LlmProvider.openRouter => 'https://openrouter.ai/api/v1',
    LlmProvider.gemini =>
      'https://generativelanguage.googleapis.com/v1beta/openai',
    LlmProvider.ollama => 'http://localhost:11434/v1',
    LlmProvider.lmStudio => 'http://localhost:1234/v1',
    LlmProvider.custom => '',
    LlmProvider.none => '',
  };

  /// Display name.
  String get displayName => switch (this) {
    LlmProvider.openAI => 'OpenAI',
    LlmProvider.azureOpenAI => 'Azure OpenAI',
    LlmProvider.openRouter => 'OpenRouter',
    LlmProvider.gemini => 'Google Gemini',
    LlmProvider.ollama => 'Ollama',
    LlmProvider.lmStudio => 'LM Studio',
    LlmProvider.custom => 'Custom',
    LlmProvider.none => 'None (Offline)',
  };
}
