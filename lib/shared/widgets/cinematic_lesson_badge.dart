import 'dart:ui';
import 'package:flutter/material.dart';

/// كبسولة معلومات سينمائية بتأثير الزجاج المضبب (Frosted Glass)
///
/// تعرض بيانات حقيقية فقط — لا يُعرض Badge إذا كان النص فارغاً
class CinematicBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;
  final bool isDark;

  const CinematicBadge({
    super.key,
    required this.icon,
    required this.label,
    this.accentColor,
    this.isDark = false,
  });

  /// يُخفي الكبسولة إذا لم تكن هناك بيانات حقيقية
  bool get _hasData => label.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasData) return const SizedBox.shrink();

    final color = accentColor ?? const Color(0xFF6200EE);
    final bgBase = isDark ? Colors.white : Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgBase.withValues(alpha: isDark ? 0.12 : 0.05),
                color.withValues(alpha: isDark ? 0.15 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: color.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════ Factory Constructors ═══════════════

  /// كبسولة المدة الزمنية — تُخفى إذا كانت المدة فارغة
  factory CinematicBadge.duration({
    required String duration,
    Color? accentColor,
    bool isDark = false,
  }) {
    return CinematicBadge(
      icon: Icons.access_time_rounded,
      label: duration, // فارغ = مخفي
      accentColor: accentColor ?? const Color(0xFF00BCD4),
      isDark: isDark,
    );
  }

  /// كبسولة حجم الملف — تُخفى إذا كان الحجم فارغاً
  factory CinematicBadge.fileSize({
    required String size,
    Color? accentColor,
    bool isDark = false,
  }) {
    return CinematicBadge(
      icon: Icons.sd_storage_rounded,
      label: size, // فارغ = مخفي
      accentColor: accentColor ?? const Color(0xFF6200EE),
      isDark: isDark,
    );
  }

  /// كبسولة الدقة — لون ذهبي لـ 4K/1080p، تُخفى إذا غير معروفة
  factory CinematicBadge.resolution({
    required String resolution,
    Color? accentColor,
    bool isDark = false,
  }) {
    final isHigh = resolution.contains('4K') || resolution.contains('1080');
    return CinematicBadge(
      icon: Icons.hd_rounded,
      label: resolution, // فارغ = مخفي
      accentColor: accentColor ?? (isHigh ? const Color(0xFFFFAB00) : const Color(0xFF9C27B0)),
      isDark: isDark,
    );
  }
}
