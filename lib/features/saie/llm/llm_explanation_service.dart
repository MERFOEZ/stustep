/// SAIE LLM — LLMExplanationService
///
/// The single entry point for generating all Question Understanding Layer (QUL)
/// conversational responses.
///
/// Architecture:
///   - Receives full context: [QulIntent], [Question], student message,
///     [StudentCognitiveProfile], [AssessmentPhase], recent history.
///   - Builds a rich, unified reasoning prompt via [LlmExplanationPromptBuilder].
///   - Calls [LlmService] with the appropriate [LlmTask] and higher token budget.
///   - Falls back to [LocalExplanationFallback] if LLM unavailable or times out.
///
/// CRITICAL GUARANTEES:
///   - Never modifies AssessmentState.
///   - Never calls AdaptiveAssessmentEngine or AssessmentController.
///   - Never updates StudentCognitiveProfile.
///   - Never selects or changes questions.
///   - The Assessment Engine remains the sole owner of assessment state.
library;

import 'dart:async';
import 'dart:developer' as dev;

import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/llm/llm_explanation_prompt_builder.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/llm/llm_service.dart';
import 'package:stustep/features/saie/llm/local_explanation_fallback.dart';
import 'package:stustep/features/saie/llm/qul_intent.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// _____________________________________________________________________________
// LLMExplanationService
// _____________________________________________________________________________

/// Generates QUL conversational responses via LLM or local fallback.
///
/// Inject via [ConversationController] constructor — never instantiate inline.
final class LLMExplanationService {
  /// Maximum time to wait for an LLM response before falling back locally.
  static const _timeout = Duration(seconds: 10);

  final LlmService _llmService;
  final LocalExplanationFallback _fallback;

  const LLMExplanationService({
    required LlmService llmService,
    LocalExplanationFallback fallback = const LocalExplanationFallback(),
  })  : _llmService = llmService,
        _fallback = fallback;

  /// Whether the LLM integration is enabled and available.
  bool get isLlmEnabled => _llmService.isEnabled;


  // ── Public API ──────────────────────────────────────────────────────────────

  /// Generate an explanation response for [intent] in the context of [question].
  ///
  /// [studentMessage]   — the student's raw message (verbatim).
  /// [isArabic]         — detected language flag for fallback generation.
  /// [recentHistory]    — last N conversation turns for continuity.
  /// [clarificationCount] — how many times the student has asked for help on
  ///   this question; used to vary the response angle.
  /// [profile]          — student cognitive profile; used to tailor context.
  /// [assessmentPhase]  — current assessment phase; included in prompt.
  ///
  /// Returns the explanation text. The caller is responsible for appending the
  /// question repeat (if policy requires it).
  ///
  /// Never throws. Falls back silently to [LocalExplanationFallback] on any
  /// LLM failure.
  Future<String> generate({
    required QulIntent intent,
    required Question question,
    required String studentMessage,
    required bool isArabic,
    List<ConversationTurnRecord> recentHistory = const [],
    int clarificationCount = 0,
    StudentCognitiveProfile? profile,
    AssessmentPhase assessmentPhase = AssessmentPhase.onboarding,
  }) async {
    // Always try LLM first when enabled.
    if (_llmService.isEnabled) {
      try {
        final text = await _callLlm(
          intent: intent,
          question: question,
          studentMessage: studentMessage,
          isArabic: isArabic,
          recentHistory: recentHistory,
          clarificationCount: clarificationCount,
          profile: profile,
          assessmentPhase: assessmentPhase,
        ).timeout(_timeout);

        if (text != null && text.trim().isNotEmpty) {
          return text;
        }
      } on TimeoutException {
        dev.log(
          '[LLMExplanationService] LLM timed out for intent=${intent.name} '
          'question=${question.id}. Using local fallback.',
          name: 'SAIE.LLM',
        );
      } catch (e) {
        dev.log(
          '[LLMExplanationService] LLM error for intent=${intent.name}: $e. '
          'Using local fallback.',
          name: 'SAIE.LLM',
        );
      }
    }

    // Local fallback — always works offline.
    return _fallback.generate(
      intent: intent,
      question: question,
      studentMessage: studentMessage,
      isArabic: isArabic,
      clarificationCount: clarificationCount,
    );
  }

  /// Generate an academic discussion response for a free-form student question.
  ///
  /// Unlike [generate], this method is used for general academic discussions
  /// that occur within the assessment flow — not strictly QUL tasks.
  ///
  /// [prompt]   — the fully assembled context prompt (built by caller).
  /// [isArabic] — detected language flag.
  ///
  /// Returns the response text, or empty string on failure.
  Future<String> generateAcademicResponse({
    required String prompt,
    required bool isArabic,
  }) async {
    if (!_llmService.isEnabled) return '';
    try {
      final response = await _llmService.processRaw(
        task: LlmTask.questionClarification,
        userPrompt: prompt,
        isArabic: isArabic,
      ).timeout(_timeout);

      if (response.isUsable && response.text.trim().isNotEmpty) {
        return response.text;
      }
    } on TimeoutException {
      dev.log(
        '[LLMExplanationService] Academic discussion LLM timed out. Using empty fallback.',
        name: 'SAIE.LLM',
      );
    } catch (e) {
      dev.log(
        '[LLMExplanationService] Academic discussion LLM error: $e.',
        name: 'SAIE.LLM',
      );
    }
    return '';
  }


  // ── Private ─────────────────────────────────────────────────────────────────

  Future<String?> _callLlm({
    required QulIntent intent,
    required Question question,
    required String studentMessage,
    required bool isArabic,
    required List<ConversationTurnRecord> recentHistory,
    required int clarificationCount,
    required StudentCognitiveProfile? profile,
    required AssessmentPhase assessmentPhase,
  }) async {
    final task = _taskFor(intent);

    // Build the unified rich context prompt.
    final promptText = LlmExplanationPromptBuilder.build(
      intent: intent,
      question: question,
      studentMessage: studentMessage,
      isArabic: isArabic,
      recentHistory: recentHistory,
      clarificationCount: clarificationCount,
      profile: profile,
      assessmentPhase: assessmentPhase,
    );

    // Use the QUL-specific higher token budget for richer responses.
    final response = await _llmService.processQul(
      task: task,
      userPrompt: promptText,
      isArabic: isArabic,
    );

    if (response.isUsable && response.text.trim().isNotEmpty) {
      return response.text;
    }
    return null;
  }

  /// Maps [QulIntent] to the correct [LlmTask] enum value.
  LlmTask _taskFor(QulIntent intent) => switch (intent) {
        QulIntent.clarification   => LlmTask.questionClarification,
        QulIntent.wordMeaning     => LlmTask.wordMeaning,
        QulIntent.whyThisQuestion => LlmTask.whyThisQuestion,
        QulIntent.examples        => LlmTask.questionExamples,
        QulIntent.uncertainty     => LlmTask.uncertaintyHelp,
      };
}