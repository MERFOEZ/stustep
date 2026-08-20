// SAIE — AiAdvisorViewModel
//
// The ViewModel is the ONLY bridge between Flutter UI and SAIEEngine.
// No widget communicates directly with any internal SAIE engine.
// All AI decisions come from SAIEEngine; the ViewModel only relays them.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stustep/features/gemini_config.dart';
import 'package:stustep/features/saie/domain/usecases/load_knowledge_base_use_case.dart';
import 'package:stustep/features/saie/engine_configuration.dart';
import 'package:stustep/features/saie/engine_exceptions.dart';
import 'package:stustep/features/saie/engine_result.dart';
import 'package:stustep/features/saie/llm/llm_client.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/presentation/viewmodels/advisor_ui_state.dart';
import 'package:stustep/features/saie/repositories/asset_knowledge_repository.dart';
import 'package:stustep/features/saie/saie_engine.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AiAdvisorViewModel
// ─────────────────────────────────────────────────────────────────────────────

class AiAdvisorViewModel extends Notifier<AdvisorUiState> {
  late final SAIEEngine _engine;
  static const _uuid = Uuid();

  @override
  AdvisorUiState build() {
    // Engine is created lazily in initialize().
    return const AdvisorUiState();
  }

  // ── Public API (called by UI only) ──────────────────────────────────────────

  /// Initialise the engine and start the assessment.
  ///
  /// Loads the complete knowledge base from Flutter assets via
  /// [AssetKnowledgeRepository] and [LoadKnowledgeBaseUseCase].
  /// If loading fails the engine is NOT started and an error message
  /// is displayed: "لا يمكن بدء التقييم لأن قاعدة المعرفة لم تُحمَّل."
  /// Full SAIE engine initialization — used by the student RIASEC path only.
  Future<void> initialize({required String studentId}) async {
    state = state.copyWith(status: AdvisorStatus.initialising, isTyping: true);

    try {
      // ── Step 1: Load the knowledge base from assets ──────────────────────
      final repository = AssetKnowledgeRepository();
      final useCase = LoadKnowledgeBaseUseCase(repository);
      final kbResult = await useCase();

      if (kbResult.isFailure) {
        state = state.copyWith(
          status: AdvisorStatus.error,
          errorMessage:
              'لا يمكن بدء التقييم لأن قاعدة المعرفة لم تُحمَّل.\n'
              '(${kbResult.failure.message})',
          isTyping: false,
        );
        return;
      }

      final kb = kbResult.value;

      // ── Step 2: Build and initialise the engine with real data ───────────
      _engine = SAIEEngine(
        config: EngineConfiguration(studentId: studentId),
        majors: kb.majors,
        questions: kb.questions,
      );

      await _engine.initialize();
      final result = await _engine.startAssessment();

      _applyResult(result, fromInit: true);
    } on SAIEException catch (e) {
      state = state.copyWith(
        status: AdvisorStatus.error,
        errorMessage: _localiseError(e),
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AdvisorStatus.error,
        errorMessage: 'حدث خطأ غير متوقع أثناء التهيئة.',
        isTyping: false,
      );
    }
  }

  /// Lightweight initialization for non-student roles (graduate / career / job).
  ///
  /// Skips the SAIE engine entirely — the AI is driven directly via
  /// [systemContext] + Gemini. Transitions status to [AdvisorStatus.ready]
  /// so the chat input is immediately enabled.
  void markAsReady() {
    state = state.copyWith(
      status: AdvisorStatus.ready,
      isTyping: false,
    );
  }

  /// Trigger an AI-led opening based on assessment results.
  ///
  /// Called once after [markAsReady] for fresh conversations.
  /// Sends a silent system-level prompt asking the AI to analyse the
  /// assessment and open discussion topics — the user sees the AI reply
  /// without having typed anything yet.
  Future<void> startWithAnalysis() async {
    if (state.systemContext.isEmpty) return;
    if (state.status == AdvisorStatus.processing) return;

    state = state.copyWith(
      status: AdvisorStatus.processing,
      isTyping: true,
      clearError: true,
    );

    // Silent system trigger — NOT shown as a user bubble in the chat.
    const trigger =
        '[SYSTEM_TRIGGER] Based on the assessment results provided in the system context, '
        'start the conversation by briefly greeting the user and providing a short, '
        'personalised analysis of their results. Then suggest 2–3 specific discussion '
        'topics they might want to explore. Keep the tone warm and professional. '
        'Respond in Arabic.';

    await _sendDirectToGemini(trigger, isSystemTrigger: true);
  }

  /// Send a message from the user.
  ///
  /// Routes automatically:
  ///   - systemContext set → direct Gemini call (graduate / career / job roles)
  ///   - systemContext empty → SAIE engine (student RIASEC path)
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.status == AdvisorStatus.processing) return;

    _addMessage(text, ChatSender.user);
    state = state.copyWith(
      status: AdvisorStatus.processing,
      isTyping: true,
      clearError: true,
      suggestionChips: [],
    );

    try {
      if (state.systemContext.isNotEmpty) {
        await _sendDirectToGemini(text);
      } else {
        final result = await _engine.processMessage(text);
        _applyResult(result);
      }
    } on SAIEException catch (e) {
      state = state.copyWith(
        status: AdvisorStatus.ready,
        isTyping: false,
        errorMessage: _localiseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AdvisorStatus.ready,
        isTyping: false,
        errorMessage: 'تعذّر الوصول للمستشار. تحقق من الاتصال وحاول مجدداً.',
      );
    }
  }

  /// Direct AI call — used by all roles in the new architecture.
  /// [isSystemTrigger]: if true, the userText is NOT shown as a user bubble.
  Future<void> _sendDirectToGemini(
    String userText, {
    bool isSystemTrigger = false,
  }) async {
    // Validate API key first.
    if (!GeminiConfig.isConfigured) {
      _addMessage(
        '⚠️ لم يتم ضبط مفتاح API بعد. يرجى التواصل مع المطوّر.',
        ChatSender.assistant,
      );
      state = state.copyWith(status: AdvisorStatus.ready, isTyping: false);
      return;
    }

    // Build messages: [system] + [history] + [current message]
    final systemMsg = LlmMessage.system(state.systemContext);

    final allMsgs = state.messages;
    // For system triggers the history IS the full message list.
    // For normal user messages exclude the last one (already added by caller).
    final historySlice = isSystemTrigger
        ? allMsgs
        : (allMsgs.length > 1
            ? allMsgs.sublist(0, allMsgs.length - 1)
            : <UiChatMessage>[]);

    final historyWindow = historySlice.length > 16
        ? historySlice.sublist(historySlice.length - 16)
        : historySlice;

    final historyMsgs = historyWindow
        .map((m) => m.sender == ChatSender.user
            ? LlmMessage.user(m.text)
            : LlmMessage.assistant(m.text))
        .toList();

    final request = LlmRequest(
      requestId: _uuid.v4(),
      task: LlmTask.academicDiscussion,
      modelId: GeminiConfig.config.modelId,
      provider: GeminiConfig.config.provider,
      messages: [systemMsg, ...historyMsgs, LlmMessage.user(userText)],
      maxTokens: GeminiConfig.config.maxResponseTokens,
      temperature: GeminiConfig.config.temperature,
      createdAt: DateTime.now(),
    );

    final client = LlmClient(config: GeminiConfig.config);
    final response = await client.send(
      request: request,
      fallbackText: 'عذراً، لا أستطيع الرد الآن. يرجى المحاولة لاحقاً.',
    );

    // Never show raw API errors, JSON, or model names to the user.
    final replyText = response.isUsable
        ? response.text
        : 'عذراً، لم أتمكن من معالجة طلبك الآن. يرجى المحاولة مجدداً. 🙏';

    _addMessage(replyText, ChatSender.assistant);
    state = state.copyWith(
      status: AdvisorStatus.ready,
      isTyping: false,
    );
  }


  /// Continue a discussion (after recommendation).
  Future<void> continueDiscussion(String text) async {
    if (text.trim().isEmpty) return;
    if (state.status == AdvisorStatus.processing) return;

    _addMessage(text, ChatSender.user);
    state = state.copyWith(
      status: AdvisorStatus.processing,
      isTyping: true,
      clearError: true,
    );

    try {
      final result = await _engine.continueDiscussion(text);
      _applyResult(result);
    } on SAIEException catch (e) {
      state = state.copyWith(
        status: AdvisorStatus.ready,
        isTyping: false,
        errorMessage: _localiseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AdvisorStatus.ready,
        isTyping: false,
        errorMessage: 'تعذّر معالجة رسالتك.',
      );
    }
  }

  /// Save the current session.
  Future<void> saveSession() async {
    try {
      await _engine.saveSession();
    } catch (_) {}
  }

  /// Restore a previous session.
  Future<void> loadSession() async {
    try {
      await _engine.loadSession();
    } catch (_) {}
  }

  /// Reset the engine and clear the conversation.
  Future<void> reset() async {
    await _engine.reset();
    state = const AdvisorUiState(status: AdvisorStatus.ready);
  }

  /// Dismiss the current error.
  void dismissError() => state = state.copyWith(clearError: true);

  /// Inject a custom role-specific intro message as the first AI greeting.
  ///
  /// Called from [AiAdvisorPage] when the user selected a role on the
  /// [RoleSelectionPage]. Replaces the engine's default greeting with one
  /// that matches the selected role context (student / graduate / etc.).
  void injectRoleIntro(String introMessage) {
    // Only inject if no messages exist yet (avoid double injection).
    if (state.messages.isNotEmpty) return;
    _addMessage(introMessage, ChatSender.assistant);
  }

  /// Restore a stored message from a previous session without triggering AI.
  ///
  /// Called during page init to rebuild the visible chat history from
  /// the persisted [Conversation]. The [sender] determines the bubble side.
  void injectStoredMessage(String text, ChatSender sender) {
    _addMessage(text, sender);
  }

  /// Store the layered system prompt built by [AiContextBuilder].
  ///
  /// This is passed to the LLM on the next API call so the model knows
  /// its role, the user's assessment result, and the StuStep identity.
  void setSystemContext(String systemPrompt) {
    // Store in state for use by the engine on next processMessage call.
    state = state.copyWith(systemContext: systemPrompt);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _applyResult(EngineResult result, {bool fromInit = false}) {
    // Add assistant response.
    _addMessage(result.assistantResponse, ChatSender.assistant);

    // Determine RTL from current language.
    final isRtl = result.currentLanguage.active.name != 'english';

    // Compute suggestion chips.
    final chips = _buildSuggestionChips(result);

    state = state.copyWith(
      status: AdvisorStatus.ready,
      isTyping: false,
      lastResult: result,
      recommendation:
          result.recommendationAvailable ? result.recommendationReport : null,
      isRtl: isRtl,
      suggestionChips: chips,
      clearError: true,
    );
  }

  void _addMessage(String text, ChatSender sender) {
    final msg = UiChatMessage(
      id: _uuid.v4(),
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      isRtl: state.isRtl,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  List<String> _buildSuggestionChips(EngineResult result) {
    if (result.recommendationAvailable) {
      return ['اشرح التوصية', 'المسارات المهنية', 'نقاط قوتي'];
    }
    if (result.currentQuestion != null) {
      return ['أحتاج توضيحاً', 'سؤال آخر', 'لا أعرف'];
    }
    return [];
  }

  String _localiseError(SAIEException e) => switch (e) {
    EngineNotInitializedException() =>
      'المحرك غير مُهيأ. يرجى إعادة تشغيل التطبيق.',
    RecommendationNotReadyException() =>
      'التقييم لم يكتمل بعد. يرجى الإجابة على المزيد من الأسئلة.',
    InvalidMessageException() =>
      'الرسالة فارغة. يرجى كتابة ردٍّ.',
    SessionNotStartedException() =>
      'لم تبدأ الجلسة. يرجى إعادة التشغيل.',
    KnowledgeBaseLoadException() =>
      'تعذّر تحميل قاعدة البيانات الأكاديمية.',
    SessionPersistenceException() =>
      'تعذّر حفظ الجلسة.',
    SAIEEngineStateException() =>
      'المحرك في حالة غير صحيحة. يرجى المحاولة مجدداً.',
  };
}
