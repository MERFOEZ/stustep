import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/interest_tag.dart';

/// شبكة اختيار الاهتمامات — أربعة عشر وسماً باختيار متعدد.
///
/// لماذا رقائق ظاهرة كلها لا قائمة منسدلة؟ لأن الطالب في هذه اللحظة لا
/// يعرف ماذا يريد بالضبط، وهو يتعرّف على خياراته بالنظر إليها مجتمعة.
/// القائمة المنسدلة تخفي البدائل وتفترض أن المستخدم يعرف ما يبحث عنه.
class InterestChipGrid extends StatelessWidget {
  /// المعرّفات المختارة حالياً.
  final Set<String> selected;

  final ValueChanged<String> onToggle;

  /// أقصى عدد اهتمامات مسموح — يمنع اختيار كل شيء، لأن اختيار الكل يساوي
  /// عدم الاختيار: كل التخصصات تصبح متطابقة والترتيب يفقد معناه.
  final int maxSelection;

  const InterestChipGrid({
    super.key,
    required this.selected,
    required this.onToggle,
    this.maxSelection = 6,
  });

  bool get _reachedLimit => selected.length >= maxSelection;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: InterestCatalog.all.map((tag) {
        final isSelected = selected.contains(tag.id);
        // الوسم غير المختار يُعطَّل بصرياً عند بلوغ الحد، لكن المختار يبقى
        // قابلاً للنقر دائماً حتى يستطيع الطالب التراجع.
        final isDisabled = !isSelected && _reachedLimit;

        return Opacity(
          opacity: isDisabled ? 0.4 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isDisabled ? null : () => onToggle(tag.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.15)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 1.7 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tag.icon,
                      size: 18,
                      color: isSelected ? primary : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tag.labelKey.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? primary : null,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded, size: 15, color: primary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// عدّاد الاهتمامات المختارة مع تنبيه بلوغ الحد.
class InterestCounter extends StatelessWidget {
  final int selectedCount;
  final int maxSelection;
  final int minSelection;

  const InterestCounter({
    super.key,
    required this.selectedCount,
    required this.maxSelection,
    this.minSelection = 1,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isEnough = selectedCount >= minSelection;

    return Row(
      children: [
        Icon(
          isEnough ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 16,
          color: isEnough ? const Color(0xFF00A152) : primary,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'admission.matcher.selected_count'.tr(
              namedArgs: {
                'count': '$selectedCount',
                'max': '$maxSelection',
              },
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
