import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

/// بطاقة متدرّجة اللون — الودجت الأساسي المتكرر في كل شاشات الموديول.
///
/// تحاكي نمط بطاقات الخدمات في الشاشة الرئيسية للمشروع (تدرّج + أيقونة
/// شفافة في الخلفية + ظل ملوّن + دخول متحرك) حتى يبدو الموديول جزءاً
/// أصيلاً من التطبيق لا إضافة غريبة عليه.
class AdmissionGradientCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final int delayMilliseconds;
  final Widget? trailing;

  const AdmissionGradientCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.subtitle,
    this.delayMilliseconds = 0,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = gradient is LinearGradient
        ? (gradient as LinearGradient).colors.first
        : Theme.of(context).primaryColor;

    return ElasticIn(
      delay: Duration(milliseconds: delayMilliseconds),
      duration: const Duration(milliseconds: 1100),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -24,
                  top: -24,
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(icon, size: 120, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: Colors.white, size: 34),
                      const SizedBox(height: 10),
                      _buildTexts(),
                      if (trailing != null) ...[
                        const SizedBox(height: 8),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
