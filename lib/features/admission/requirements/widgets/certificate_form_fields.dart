import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// حقول نموذج إدخال الشهادة، مفصولة عن الشاشة لإبقائها تحت السقف المتفق
// عليه ولإعادة استخدامها في مساعد اختيار التخصص في المرحلة 7.
//
// ⚠️ ملاحظة مهمة: نستورد `dart:ui` باسم مستعار `ui` ونكتب `ui.TextDirection`
// صراحةً. السبب أن حزمة easy_localization تصدّر تعداداً آخر بنفس الاسم
// (`TextDirection` من حزمة intl) وقيمه `LTR` و`RTL` بحروف كبيرة، فيتعارض
// الاسمان ويفشل البناء عند كتابة `TextDirection.ltr` مجرّدة.

/// عنوان حقل داخل النموذج.
class FormFieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const FormFieldLabel({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// مجموعة اختيار واحد من عدة خيارات، معروضة كرقائق.
///
/// نستخدمها بدل `DropdownButton` لأن عدد الخيارات صغير، ورؤيتها كلها
/// دفعة واحدة أوضح للطالب من قائمة منسدلة تخفي البدائل.
class ChoiceChipsGroup<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onSelected;

  const ChoiceChipsGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.15)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? primary
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check_rounded, size: 15, color: primary),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labelBuilder(option),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? primary : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// حقل رقمي للمعدل مع عرض الحد الأقصى المسموح حسب السلّم المختار.
class GpaNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? helperText;
  final String? Function(String?)? validator;

  const GpaNumberField({
    super.key,
    required this.controller,
    required this.hint,
    this.helperText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: ui.TextDirection.ltr,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.grade_rounded),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

/// قائمة منسدلة لسنة التخرج.
class GraduationYearField extends StatelessWidget {
  final List<int> years;
  final int selected;
  final ValueChanged<int> onChanged;

  const GraduationYearField({
    super.key,
    required this.years,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: years.contains(selected) ? selected : years.first,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.event_rounded),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      items: years
          .map(
            (year) => DropdownMenuItem<int>(
              value: year,
              child: Text('$year', textDirection: ui.TextDirection.ltr),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

/// مفتاح تأكيد توفّر معادلة وزارة التربية.
class EquivalencySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const EquivalencySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        title: Text(
          'admission.certificate.has_equivalency'.tr(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        activeTrackColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
