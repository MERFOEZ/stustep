import 'package:flutter/material.dart';

// طرق عرض المحتوى داخل بطاقات صفحة التخصص.
//
// فُصلت عن الشاشة لسببين: إبقاء ملف الشاشة تحت السقف المتفق عليه،
// وإتاحة إعادة استخدامها في شاشة الشروط في المرحلة 4.

/// عرض قائمة نصية على هيئة رقائق متجاورة — مناسب للمهارات والمواد القصيرة.
class GuideChipsWrap extends StatelessWidget {
  final List<String> items;
  final Color accentColor;
  final IconData? chipIcon;

  const GuideChipsWrap({
    super.key,
    required this.items,
    required this.accentColor,
    this.chipIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chipIcon != null) ...[
                Icon(chipIcon, size: 14, color: accentColor),
                const SizedBox(width: 6),
              ],
              Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// عرض قائمة مرقّمة عمودية — مناسب للمواد الأساسية ومجالات العمل.
class GuideNumberedList extends StatelessWidget {
  final List<String> items;
  final Color accentColor;
  final IconData? leadingIcon;

  const GuideNumberedList({
    super.key,
    required this.items,
    required this.accentColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: leadingIcon != null
                    ? Icon(leadingIcon, size: 13, color: accentColor)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[index],
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// سطر معلومة مختصرة (سنوات الدراسة، الدرجة الممنوحة).
class GuideInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const GuideInfoPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
