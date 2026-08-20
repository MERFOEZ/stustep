// SAIE — ConversationView Widget
//
// Scrollable list of chat messages + typing indicator + suggestion chips.
// Reads state from Riverpod providers. No AI logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stustep/features/saie/presentation/providers/ai_provider.dart';
import 'package:stustep/features/saie/presentation/widgets/chat_message.dart';
import 'package:stustep/features/saie/presentation/widgets/suggestion_chip.dart';
import 'package:stustep/features/saie/presentation/widgets/typing_indicator.dart';

class ConversationView extends ConsumerStatefulWidget {
  /// Called when the user taps a suggestion chip.
  final void Function(String text) onSuggestionSelected;

  const ConversationView({
    super.key,
    required this.onSuggestionSelected,
  });

  @override
  ConsumerState<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<ConversationView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isTyping = ref.watch(isTypingProvider);
    final chips = ref.watch(suggestionChipsProvider);
    final isRtl = ref.watch(isRtlProvider);

    // Auto-scroll when messages change.
    ref.listen(chatMessagesProvider, (prev, next) => _scrollToBottom());
    ref.listen(isTypingProvider, (_, v) {
      if (v) _scrollToBottom();
    });

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length + (isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length && isTyping) {
                return _AssistantTypingBubble(isRtl: isRtl);
              }
              return ChatMessageWidget(message: messages[index]);
            },
          ),
        ),
        if (chips.isNotEmpty)
          SuggestionChipRow(
            suggestions: chips,
            onSelected: widget.onSuggestionSelected,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Wraps the TypingIndicator inside an assistant-styled bubble.
class _AssistantTypingBubble extends StatelessWidget {
  final bool isRtl;

  const _AssistantTypingBubble({required this.isRtl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: const TypingIndicator(),
        ),
      ),
    );
  }
}
