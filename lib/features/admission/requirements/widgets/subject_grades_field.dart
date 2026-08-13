import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../models/subject_catalog.dart';

// ⚠️ `dart:ui` باسم مستعار: حزمة easy_localization تصدّر تعداداً آخر اسمه
// `TextDirection` أيضاً، فنكتب `ui.TextDirection.ltr` صراحةً لفض التعارض.

/// حقول إدخال درجات المواد بالنسبة المئوية.
///
/// اختيارية للطالب، لكنها ضرورية للتحقق الدقيق: كلية الطب لا تشترط المعدل
/// العام فقط بل 85% في الأحياء تحديداً. إن تُركت فارغة، يُبلغ محرّك الأهلية
/// الطالب بأن الدرجة **غير مُدخلة** بدل أن يرفضه بلا سبب واضح.
class SubjectGradesField extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const SubjectGradesField({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admission.certificate.subjects_hint'.tr(),
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        ...SubjectCatalog.all.map((subject) {
          final controller = controllers[subject.code];
          if (controller == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    subject.icon,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    subject.labelKey.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textDirection: ui.TextDirection.ltr,
                    textAlign: TextAlign.center,
                    validator: _validateGrade,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '—',
                      suffixText: '%',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// الحقل اختياري، فالفراغ صالح. أما القيمة المُدخلة فيجب أن تكون نسبة
  /// مئوية معقولة.
  String? _validateGrade(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'admission.certificate.invalid_number'.tr();
    if (parsed < 0 || parsed > 100) {
      return 'admission.certificate.invalid_percentage'.tr();
    }
    return null;
  }

  /// بناء خريطة الدرجات من المتحكمات، متجاهلةً الحقول الفارغة.
  static Map<String, double> collect(
    Map<String, TextEditingController> controllers,
  ) {
    final grades = <String, double>{};
    controllers.forEach((code, controller) {
      final parsed = double.tryParse(controller.text.trim());
      if (parsed != null) grades[code] = parsed;
    });
    return grades;
  }
}
