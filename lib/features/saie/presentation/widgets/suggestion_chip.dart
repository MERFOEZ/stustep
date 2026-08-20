// SAIE — SuggestionChip Widget
//
// Displays a row of quick-reply suggestion chips.

import 'package:flutter/material.dart';

class SuggestionChipRow extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSelected;

  const SuggestionChipRow({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(chip),
                labelStyle: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => onSelected(chip),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
