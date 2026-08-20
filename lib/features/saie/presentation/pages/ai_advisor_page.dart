// SAIE — AiAdvisorPage
//
// The complete AI Advisor screen.
// Accepts a Conversation + AssessmentResult from the assessment pages.
// Restores previous messages and builds layered AI context.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stustep/features/saie_core/models/assessment_result.dart';
import 'package:stustep/features/saie_core/models/chat_message_model.dart';
import 'package:stustep/features/saie_core/models/conversation.dart';
import 'package:stustep/features/saie_core/services/ai_context_builder.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/presentation/providers/ai_provider.dart';
import 'package:stustep/features/saie/presentation/viewmodels/advisor_ui_state.dart';
import 'package:stustep/features/saie/presentation/viewmodels/ai_advisor_viewmodel.dart';
import 'package:stustep/features/saie/presentation/widgets/assessment_progress_card.dart';
import 'package:stustep/features/saie/presentation/widgets/confidence_card.dart';
import 'package:stustep/features/saie/presentation/widgets/conversation_view.dart';
import 'package:stustep/features/saie/presentation/widgets/loading_overlay.dart';
import 'package:stustep/features/saie/presentation/widgets/message_input.dart';
import 'package:stustep/features/saie/presentation/widgets/recommendation_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AiAdvisorPage
// ─────────────────────────────────────────────────────────────────────────────

/// The main AI Advisor screen.
///
/// Must be opened with a [Conversation] (for history) and an
/// [AssessmentResult] (for AI context). Both come from the assessment pages.
class AiAdvisorPage extends ConsumerStatefulWidget {
  const AiAdvisorPage({
    super.key,
    required this.conversation,
    required this.assessment,
    this.roleIntroMessage,
  });

  final Conversation conversation;
  final AssessmentResult assessment;

  /// Optional custom intro message (used by RIASEC student path).
  final String? roleIntroMessage;

  @override
  ConsumerState<AiAdvisorPage> createState() => _AiAdvisorPageState();
}

class _AiAdvisorPageState extends ConsumerState<AiAdvisorPage>
    with WidgetsBindingObserver {
  bool _showSidePanel = false;
  late final AiContextBuilder _contextBuilder;

  AiAdvisorViewModel? _notifier;

  @override
  void initState() {
    super.initState();
    _contextBuilder = const AiContextBuilder();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier = ref.read(aiAdvisorProvider.notifier);

      // Restore previous messages from the persisted conversation.
      for (final m in widget.conversation.messages) {
        _notifier!.injectStoredMessage(
          m.text,
          m.sender == MessageSender.assistant
              ? ChatSender.assistant
              : ChatSender.user,
        );
      }

      // Build layered system context (Base + Role + Assessment).
      final systemPrompt = _contextBuilder.buildSystemPrompt(
        role: widget.assessment.role,
        assessment: widget.assessment,
      );
      _notifier!.setSystemContext(systemPrompt);

      // Inject role intro if this is a fresh conversation.
      if (widget.conversation.isEmpty) {
        final intro = widget.roleIntroMessage
            ?? widget.assessment.role.introAr;
        _notifier!.injectRoleIntro(intro);
      }

      // All roles now use the direct AI path.
      // markAsReady() transitions from 'initialising' → 'ready'
      // so the chat input unlocks immediately.
      _notifier!.markAsReady();

      // For fresh conversations: trigger the AI to open with
      // a personalised analysis of the assessment results.
      if (widget.conversation.isEmpty &&
          ref.read(aiAdvisorProvider).systemContext.isNotEmpty) {
        _notifier!.startWithAnalysis();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Safe: _notifier is null if the page was disposed before first frame.
    _notifier?.saveSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(aiAdvisorProvider.notifier).saveSession();
    }
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  void _onSend(String text) {
    final vm = ref.read(aiAdvisorProvider.notifier);
    final phase = ref.read(aiAdvisorProvider).phase;
    if (phase == ConversationStage.postRecommendation) {
      vm.continueDiscussion(text);
    } else {
      vm.sendMessage(text);
    }
  }

  void _onSuggestion(String chip) => _onSend(chip);

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(aiAdvisorProvider);
    final isRtl = ref.watch(isRtlProvider);
    final status = ref.watch(advisorStatusProvider);
    final error = ref.watch(errorMessageProvider);
    final isWide = MediaQuery.of(context).size.width >= 720;

    final isInitialising = status == AdvisorStatus.initialising;

    return LoadingOverlay(
        isLoading: isInitialising,
        message: isRtl ? 'جارٍ الاتصال بسيرا...' : 'Connecting...',
        isRtl: isRtl,
        child: Scaffold(
          appBar: _buildAppBar(context, uiState, isRtl, isWide),
          body: Column(
            children: [
              // Error banner
              if (error != null)
                ErrorBanner(
                  message: error,
                  onDismiss: () =>
                      ref.read(aiAdvisorProvider.notifier).dismissError(),
                ),
              Expanded(
                child: isWide
                    ? _WideLayout(
                        uiState: uiState,
                        isRtl: isRtl,
                        onSend: _onSend,
                        onSuggestion: _onSuggestion,
                      )
                    : _NarrowLayout(
                        uiState: uiState,
                        isRtl: isRtl,
                        showPanel: _showSidePanel,
                        onSend: _onSend,
                        onSuggestion: _onSuggestion,
                      ),
              ),
            ],
          ),
        ),
      );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AdvisorUiState state,
    bool isRtl,
    bool isWide,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final phase = state.phase;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'المستشار الأكاديمي' : 'Academic Advisor',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (phase != null)
            Text(
              _phaseLabel(phase, isRtl),
              style: TextStyle(
                color: scheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (!isWide)
          IconButton(
            icon: Icon(
              _showSidePanel ? Icons.chat_bubble_outline : Icons.analytics_outlined,
            ),
            tooltip: isRtl ? 'عرض الإحصائيات' : 'Show Stats',
            onPressed: () => setState(() => _showSidePanel = !_showSidePanel),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: isRtl ? 'إعادة التعيين' : 'Reset',
          onPressed: () => ref.read(aiAdvisorProvider.notifier).reset(),
        ),
      ],
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }

  String _phaseLabel(ConversationStage stage, bool rtl) => switch (stage) {
    ConversationStage.introduction =>
      rtl ? 'التعارف' : 'Introduction',
    ConversationStage.assessment =>
      rtl ? 'جلسة التقييم' : 'Assessment in Progress',
    ConversationStage.paused =>
      rtl ? 'تقييم متوقف' : 'Assessment Paused',
    ConversationStage.recommendation =>
      rtl ? 'التوصية جاهزة' : 'Recommendation Ready',
    ConversationStage.postRecommendation =>
      rtl ? 'استكشاف الخيارات' : 'Exploring Options',
    ConversationStage.closing =>
      rtl ? 'اختتام الجلسة' : 'Session Closing',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide layout (tablets / desktop)
// ─────────────────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final AdvisorUiState uiState;
  final bool isRtl;
  final void Function(String) onSend;
  final void Function(String) onSuggestion;

  const _WideLayout({
    required this.uiState,
    required this.isRtl,
    required this.onSend,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Chat column
        Expanded(
          flex: 6,
          child: _ChatColumn(
            uiState: uiState,
            isRtl: isRtl,
            onSend: onSend,
            onSuggestion: onSuggestion,
          ),
        ),
        // Stats panel
        SizedBox(
          width: 300,
          child: _StatsPanel(uiState: uiState, isRtl: isRtl),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Narrow layout (phone)
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final AdvisorUiState uiState;
  final bool isRtl;
  final bool showPanel;
  final void Function(String) onSend;
  final void Function(String) onSuggestion;

  const _NarrowLayout({
    required this.uiState,
    required this.isRtl,
    required this.showPanel,
    required this.onSend,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    if (showPanel) {
      return _StatsPanel(uiState: uiState, isRtl: isRtl);
    }
    return SizedBox.expand(
      child: _ChatColumn(
        uiState: uiState,
        isRtl: isRtl,
        onSend: onSend,
        onSuggestion: onSuggestion,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat column
// ─────────────────────────────────────────────────────────────────────────────

class _ChatColumn extends StatelessWidget {
  final AdvisorUiState uiState;
  final bool isRtl;
  final void Function(String) onSend;
  final void Function(String) onSuggestion;

  const _ChatColumn({
    required this.uiState,
    required this.isRtl,
    required this.onSend,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ConversationView(onSuggestionSelected: onSuggestion),
        ),
        MessageInput(
          enabled: !uiState.isProcessing,
          isRtl: isRtl,
          onSend: onSend,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats / info panel
// ─────────────────────────────────────────────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  final AdvisorUiState uiState;
  final bool isRtl;

  const _StatsPanel({required this.uiState, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = uiState.progress;
    final recommendation = uiState.recommendation;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Confidence
          ConfidenceCard(
            confidence: uiState.confidence,
            isRtl: isRtl,
          ),
          const SizedBox(height: 10),
          // Assessment progress
          if (progress != null) ...[
            AssessmentProgressCard(progress: progress, isRtl: isRtl),
            const SizedBox(height: 10),
          ],
          // Top recommendation(s)
          if (recommendation != null &&
              recommendation.recommendations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                right: 4,
                bottom: 6,
                top: 4,
              ),
              child: Text(
                isRtl ? 'التوصيات' : 'Recommendations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...recommendation.recommendations.take(3).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RecommendationCard(rec: r, isRtl: isRtl),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
