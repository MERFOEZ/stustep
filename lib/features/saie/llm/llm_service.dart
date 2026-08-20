/// SAIE LLM — LlmService
///
/// The public API of the entire LLM integration layer.
/// The only class that SAIEEngine calls directly.
///
/// Responsibilities:
/// - Decide whether the LLM is needed (requiresLlm gate).
/// - Build context and prompt.
/// - Call [LlmClient] or apply [LlmFallback] immediately.
/// - Validate the response.
/// - Never crash. Never recommend majors. Never update profile.
library;

import 'package:stustep/features/saie/conversation/conversation_memory.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/conversation/conversation_language.dart';
import 'package:stustep/features/saie/llm/llm_client.dart';
import 'package:stustep/features/saie/llm/llm_configuration.dart';
import 'package:stustep/features/saie/llm/llm_context_builder.dart';
import 'package:stustep/features/saie/llm/llm_error_handler.dart';
import 'package:stustep/features/saie/llm/llm_fallback.dart';
import 'package:stustep/features/saie/llm/llm_prompt_builder.dart';
import 'package:stustep/features/saie/llm/llm_rate_limiter.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/llm/llm_response.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmService
// ─────────────────────────────────────────────────────────────────────────────

/// Public surface of the LLM integration layer.
///
/// Instantiate via [LlmFactory], not directly.
final class LlmService {
  final LlmConfiguration _config;
  final LlmClient _client;
  final LlmContextBuilder _contextBuilder;
  final LlmPromptBuilder _promptBuilder;
  final LlmFallback _fallback;

  static const _uuid = Uuid();

  const LlmService({
    required LlmConfiguration config,
    required LlmClient client,
    required LlmContextBuilder contextBuilder,
    required LlmPromptBuilder promptBuilder,
    required LlmFallback fallback,
  })  : _config = config,
        _client = client,
        _contextBuilder = contextBuilder,
        _promptBuilder = promptBuilder,
        _fallback = fallback;

  /// Create a fully offline [LlmService] with no API calls.
  ///
  /// Used as the default when no LLM configuration is provided.
  factory LlmService.disabled() {
    const config = LlmConfiguration.offline;
    const errorHandler = LlmErrorHandler();
    final rateLimiter = LlmRateLimiter(
      maxRequests: 60,
      window: const Duration(minutes: 1),
    );
    final client = LlmClient(
      config: config,
      errorHandler: errorHandler,
      rateLimiter: rateLimiter,
    );
    return LlmService(
      config: config,
      client: client,
      contextBuilder: const LlmContextBuilder(),
      promptBuilder: const LlmPromptBuilder(),
      fallback: const LlmFallback(),
    );
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Whether the LLM is configured and enabled.
  bool get isEnabled => _config.isEnabled;

  /// Process [task] with the given engine state.
  ///
  /// Returns a [LlmResponse] — always. Never throws.
  Future<LlmResponse> process({
    required LlmTask task,
    required StudentCognitiveProfile profile,
    required ConversationMemory memory,
    required ConversationPhase phase,
    required ConversationLanguage language,
    String? studentMessage,
    Question? activeQuestion,
    RecommendationReport? report,
    String? rawText,
    required String fallbackText,
  }) async {
    // ── Gate: should LLM be used? ─────────────────────────────────────────────
    if (!requiresLlm(task)) {
      return _fallback.buildFallback(request: _dummyRequest(task), report: report);
    }

    if (!_config.isEnabled) {
      return _fallback.buildFallback(request: _dummyRequest(task), report: report);
    }

    try {
      // ── Build context and prompt ──────────────────────────────────────────
      final context = _contextBuilder.build(
        task: task,
        profile: profile,
        memory: memory,
        phase: phase,
        language: language,
        studentMessage: studentMessage,
        activeQuestion: activeQuestion,
        report: report,
        rawText: rawText,
      );

      final messages = _promptBuilder.build(context);

      final request = LlmRequest(
        requestId: _uuid.v4(),
        task: task,
        modelId: _config.modelId,
        messages: messages,
        provider: _config.provider,
        maxTokens: _config.maxResponseTokens,
        temperature: _config.temperature,
        stream: false,
        createdAt: DateTime.now().toUtc(),
      );

      // ── Send to LLM ───────────────────────────────────────────────────────
      final response = await _client.send(
        request: request,
        fallbackText: fallbackText,
      );

      // ── Validate ──────────────────────────────────────────────────────────
      if (!_validate(response)) {
        return _fallback.buildFallback(request: request, report: report);
      }

      return response;
    } catch (_) {
      // Absolute last-resort: if something unexpected happens, use fallback.
      return _fallback.buildFallback(
        request: _dummyRequest(task),
        report: report,
      );
    }
  }

  // ── requiresLlm gate ───────────────────────────────────────────────────────

  /// Sends a pre-built [userPrompt] to the LLM for [task].
  ///
  /// Unlike [process], this bypasses [LlmContextBuilder] and uses the
  /// provided [userPrompt] directly as the user message. The system prompt
  /// is still generated from [LlmPromptBuilder] based on [task].
  ///
  /// Used by [LLMExplanationService] for QUL tasks where the prompt is
  /// assembled externally from structured question data.
  ///
  /// Returns a [LlmResponse] — always. Never throws.
  Future<LlmResponse> processRaw({
    required LlmTask task,
    required String userPrompt,
    required bool isArabic,
  }) async {
    if (!_config.isEnabled) {
      return _fallback.buildFallback(request: _dummyRequest(task));
    }

    try {
      // Build a minimal bundle just for the system prompt.
      // We pass the user prompt directly as the user message.
      final systemPrompt = _promptBuilder.buildSystemPromptOnly(task, isArabic);
      final messages = [
        LlmMessage.system(systemPrompt),
        LlmMessage.user(userPrompt),
      ];

      final request = LlmRequest(
        requestId: _uuid.v4(),
        task: task,
        modelId: _config.modelId,
        messages: messages,
        provider: _config.provider,
        maxTokens: _config.maxResponseTokens,
        temperature: _config.temperature,
        stream: false,
        createdAt: DateTime.now().toUtc(),
      );

      final response = await _client.send(
        request: request,
        fallbackText: '',
      );

      if (!_validate(response)) {
        return _fallback.buildFallback(request: request);
      }

      return response;
    } catch (_) {
      return _fallback.buildFallback(request: _dummyRequest(task));
    }
  }

  /// QUL-optimised variant of [processRaw] with a higher token budget.
  ///
  /// Used exclusively by [LLMExplanationService] for Question Understanding
  /// Layer tasks. Uses:
  ///   - [maxTokens] = 1200 (vs the default 800) for richer, complete responses.
  ///   - [temperature] = 0.7 for more natural, varied phrasing.
  ///
  /// The system prompt is the QUL academic-advisor persona from
  /// [LlmPromptBuilder.buildSystemPromptOnly].
  ///
  /// Returns a [LlmResponse] — always. Never throws.
  Future<LlmResponse> processQul({
    required LlmTask task,
    required String userPrompt,
    required bool isArabic,
  }) async {
    assert(task.isQulTask, 'processQul must only be called with QUL tasks');

    if (!_config.isEnabled) {
      return _fallback.buildFallback(request: _dummyRequest(task));
    }

    try {
      final systemPrompt = _promptBuilder.buildSystemPromptOnly(task, isArabic);
      final messages = [
        LlmMessage.system(systemPrompt),
        LlmMessage.user(userPrompt),
      ];

      // Higher token budget for QUL: allows complete, thorough explanations.
      const qulMaxTokens = 1200;
      // Slightly higher temperature for natural, non-repetitive phrasing.
      const qulTemperature = 0.7;

      final request = LlmRequest(
        requestId: _uuid.v4(),
        task: task,
        modelId: _config.modelId,
        messages: messages,
        provider: _config.provider,
        maxTokens: qulMaxTokens,
        temperature: qulTemperature,
        stream: false,
        createdAt: DateTime.now().toUtc(),
      );

      final response = await _client.send(
        request: request,
        fallbackText: '',
      );

      if (!_validate(response)) {
        return _fallback.buildFallback(request: request);
      }

      return response;
    } catch (_) {
      return _fallback.buildFallback(request: _dummyRequest(task));
    }
  }


  /// Determines whether this [task] should involve the LLM at all.
  ///
  /// The LLM is NEVER used for:
  /// - Assessment decisions.
  /// - Profile updates.
  /// - Major recommendations.
  bool requiresLlm(LlmTask task) {
    // All allowed tasks are safe to delegate to LLM when enabled.
    // The enum itself only contains permitted tasks.
    return true;
  }

  // ── Response validation ────────────────────────────────────────────────────

  bool _validate(LlmResponse response) {
    if (!response.isUsable) return false;
    final text = response.text;

    // Reject empty.
    if (text.trim().isEmpty) return false;

    // Reject unexpectedly short (likely error message).
    if (text.length < 5) return false;

    // Reject potential prompt leakage indicators.
    final lower = text.toLowerCase();
    if (lower.contains('as an ai') || lower.contains('i cannot recommend')) {
      return false;
    }

    return true;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  LlmRequest _dummyRequest(LlmTask task) => LlmRequest(
    requestId: _uuid.v4(),
    task: task,
    modelId: _config.modelId,
    messages: const [],
    provider: _config.provider,
    createdAt: DateTime.now().toUtc(),
  );
}
