import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/admission_enums.dart';

/// الهوية البصرية لمستويات الأهلية الثلاثة — لون وأيقونة موحّدان.
///
/// وُجدت هذه الودجت لأن مستوى الأهلية صار يُعرض في أربعة أماكن مختلفة:
/// لافتة نتيجة الفحص، بطاقة الاقتراح، ملخّص محاكي «ماذا لو؟»، وقائمة
/// الفرص المفتوحة. تكرار جدول الألوان في كل مكان يعني أن تغيير لون
/// «قريب من الشرط» يتطلب تعديل أربعة ملفات، وأن نسيان أحدها يُنتج واجهة
/// متناقضة يظنّها الطالب خطأً في النتيجة نفسها.
class EligibilityVisuals {
  const EligibilityVisuals._();

  /// اللون المعبّر عن المستوى: أخضر مؤهَّل · برتقالي قريب · أحمر غير مؤهَّل.
  static Color color(EligibilityLevel level) {
    switch (level) {
      case EligibilityLevel.eligible:
        return const Color(0xFF00A152);
      case EligibilityLevel.borderline:
        return const Color(0xFFEF6C00);
      case EligibilityLevel.notEligible:
        return const Color(0xFFD32F2F);
    }
  }

  static IconData icon(EligibilityLevel level) {
    switch (level) {
      case EligibilityLevel.eligible:
        return Icons.verified_rounded;
      case EligibilityLevel.borderline:
        return Icons.error_outline_rounded;
      case EligibilityLevel.notEligible:
        return Icons.cancel_outlined;
    }
  }
}

/// شارة صغيرة تعرض مستوى الأهلية بلونه وأيقونته.
///
/// تُعرض على **كل** بطاقة اقتراح بلا استثناء. هذا قرار تصميمي مقصود:
/// ترتيب الاقتراحات يعتمد على نتيجة مركّبة قد تضع تخصصاً غير مؤهَّل في
/// المقدمة لقوة تطابقه مع اهتمامات الطالب — فلو غابت الشارة لظنّ الطالب
/// أن كل ما في أعلى القائمة متاح له.
class EligibilityBadge extends StatelessWidget {
  final EligibilityLevel level;
  final bool dense;

  const EligibilityBadge({super.key, required this.level, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final color = EligibilityVisuals.color(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EligibilityVisuals.icon(level), size: dense ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Text(
            level.labelKey.tr(),
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
