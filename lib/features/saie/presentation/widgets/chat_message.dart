// SAIE — ChatMessage Widget
//
// Renders a single chat message bubble.
// Supports Arabic RTL and English LTR automatically.
// Displays timestamp. No AI logic.

import 'package:flutter/material.dart';
import 'package:stustep/features/saie/presentation/viewmodels/advisor_ui_state.dart';

class ChatMessageWidget extends StatelessWidget {
  final UiChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bubbleColor = isUser
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final textColor = isUser
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = message.isRtl ? TextAlign.right : TextAlign.left;
    final textDir =
        message.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Directionality(
              textDirection: textDir,
              child: Text(
                message.text,
                style: textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.5,
                ),
                textAlign: textAlign,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _formatTime(message.timestamp),
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
