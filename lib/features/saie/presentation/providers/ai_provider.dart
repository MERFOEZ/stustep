// SAIE — AiProvider
//
// Riverpod providers for the AI Advisor screen.
// The UI imports ONLY these providers — never internal engines.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stustep/features/saie/presentation/viewmodels/advisor_ui_state.dart';
import 'package:stustep/features/saie/presentation/viewmodels/ai_advisor_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primary provider
// ─────────────────────────────────────────────────────────────────────────────

/// The main provider for the AI Advisor ViewModel.
///
/// Widgets watch this provider to receive [AdvisorUiState] updates.
final aiAdvisorProvider =
    NotifierProvider<AiAdvisorViewModel, AdvisorUiState>(
  AiAdvisorViewModel.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Derived providers (select — no unnecessary rebuilds)
// ─────────────────────────────────────────────────────────────────────────────

/// Current chat messages.
final chatMessagesProvider = Provider<List<UiChatMessage>>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.messages));
});

/// Whether the assistant is currently typing.
final isTypingProvider = Provider<bool>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.isTyping));
});

/// Current error message (null if none).
final errorMessageProvider = Provider<String?>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.errorMessage));
});

/// Whether a recommendation is ready.
final hasRecommendationProvider = Provider<bool>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.hasRecommendation));
});

/// The current recommendation report.
final recommendationProvider = Provider((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.recommendation));
});

/// Assessment progress snapshot.
final assessmentProgressProvider = Provider((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.progress));
});

/// Current advisor status.
final advisorStatusProvider = Provider<AdvisorStatus>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.status));
});

/// Current suggestion chips.
final suggestionChipsProvider = Provider<List<String>>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.suggestionChips));
});

/// Whether the UI should be RTL.
final isRtlProvider = Provider<bool>((ref) {
  return ref.watch(aiAdvisorProvider.select((s) => s.isRtl));
});
