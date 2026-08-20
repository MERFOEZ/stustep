// SAIE — AdvisorUiState
//
// Immutable UI state for the AI Advisor screen.
// This is the ONLY state object the ViewModel manages.
// All AI data comes from EngineResult — never duplicated here.

import 'package:stustep/features/saie/assessment/assessment_progress.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/engine_result.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdvisorStatus
// ─────────────────────────────────────────────────────────────────────────────

enum AdvisorStatus {
  initialising,
  ready,
  processing,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatMessage (UI model)
// ─────────────────────────────────────────────────────────────────────────────

enum ChatSender { user, assistant }

final class UiChatMessage {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime timestamp;
  final bool isRtl;

  const UiChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRtl = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AdvisorUiState
// ─────────────────────────────────────────────────────────────────────────────

final class AdvisorUiState {
  final AdvisorStatus status;
  final List<UiChatMessage> messages;
  final bool isTyping;
  final String? errorMessage;
  final EngineResult? lastResult;
  final RecommendationReport? recommendation;
  final bool isRtl;
  final List<String> suggestionChips;

  /// The layered system prompt (Base + Role + Assessment).
  /// Built by [AiContextBuilder] and stored here for use in API calls.
  final String systemContext;

  const AdvisorUiState({
    this.status = AdvisorStatus.initialising,
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
    this.lastResult,
    this.recommendation,
    this.isRtl = true,
    this.suggestionChips = const [],
    this.systemContext = '',
  });

  AdvisorUiState copyWith({
    AdvisorStatus? status,
    List<UiChatMessage>? messages,
    bool? isTyping,
    String? errorMessage,
    EngineResult? lastResult,
    RecommendationReport? recommendation,
    bool? isRtl,
    List<String>? suggestionChips,
    String? systemContext,
    bool clearError = false,
  }) => AdvisorUiState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    lastResult: lastResult ?? this.lastResult,
    recommendation: recommendation ?? this.recommendation,
    isRtl: isRtl ?? this.isRtl,
    suggestionChips: suggestionChips ?? this.suggestionChips,
    systemContext: systemContext ?? this.systemContext,
  );

  // Convenience getters
  bool get hasRecommendation => recommendation != null;
  bool get isProcessing => status == AdvisorStatus.processing;

  AssessmentProgress? get progress => lastResult?.assessmentProgress;
  ConversationStage? get phase => lastResult?.currentPhase;
  double get confidence =>
      lastResult?.assessmentProgress.overallConfidence ?? 0;
}
