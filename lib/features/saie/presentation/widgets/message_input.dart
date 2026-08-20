// SAIE — MessageInput Widget
//
// RTL/LTR aware text field with send button.
// Calls onSend with the typed text. No AI logic.

import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final bool enabled;
  final bool isRtl;
  final void Function(String) onSend;

  const MessageInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.isRtl = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dir =
        widget.isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: dir,
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  maxLines: 4,
                  minLines: 1,
                  textDirection: dir,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: widget.isRtl
                        ? 'اكتب رسالتك هنا...'
                        : 'Type your message...',
                    hintTextDirection: dir,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                onPressed: _hasText && widget.enabled ? _send : null,
                backgroundColor:
                    _hasText && widget.enabled ? scheme.primary : scheme.outline,
                elevation: 0,
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
