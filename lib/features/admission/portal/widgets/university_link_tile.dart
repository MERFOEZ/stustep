import 'package:animate_do/animate_do.dart';
// `easy_localization` يُعيد تصدير `intl`، وفيها صنف `TextDirection` آخر
// يحجب صنف Flutter ويكسر `TextDirection.ltr`. نُخفيه هنا ونحتفظ بـ`tr()`.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../models/university_portal_link.dart';

/// بطاقة رابط رسمي واحد داخل شاشة بوابة الجامعة.
///
/// **لماذا أيقونة «مغادرة التطبيق» ظاهرة على كل بطاقة؟**
/// كل عناصر الموديول الأخرى تفتح شاشة داخلية، وهذه وحدها تسلّم الطالب
/// لمتصفح خارجي. بلا إشارة بصرية يفاجئه خروجه من التطبيق فيظنه تعطّل، ومع
/// الإشارة يصبح الخروج قراره هو.
class UniversityLinkTile extends StatelessWidget {
  final UniversityPortalLink link;
  final VoidCallback onTap;

  /// تأخير ظهور البطاقة — يُمرَّر من القائمة لينتج تتابعاً لا ظهوراً دفعة واحدة.
  final int delayMilliseconds;

  const UniversityLinkTile({
    super.key,
    required this.link,
    required this.onTap,
    this.delayMilliseconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delayMilliseconds),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    link.kind.icon,
                    color: theme.primaryColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(child: _buildTexts(context)),
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTexts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          link.kind.labelKey.tr(),
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          link.kind.descriptionKey.tr(),
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 5),
        // المضيف يُعرض حرفياً بلا ترجمة: هو بيانات لا نصّ واجهة، وأي تجميل
        // له يُفقده وظيفته — أن يرى الطالب الوجهة الحقيقية قبل مغادرته.
        Text(
          link.displayHost,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
