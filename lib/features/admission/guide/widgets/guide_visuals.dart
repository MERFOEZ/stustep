import 'package:flutter/material.dart';

/// العناصر البصرية المشتركة لشاشات الدليل: التدرجات وخريطة الأيقونات.
///
/// جُمعت هنا حتى لا تتكرر في ثلاث شاشات، ولتبقى تغييرات الهوية البصرية
/// في ملف واحد.
class GuideVisuals {
  const GuideVisuals._();

  /// تدرجات بطاقات الكليات — تُوزَّع دورياً حسب ترتيب العنصر.
  static const List<LinearGradient> gradients = [
    LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF9C27B0)]),
    LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
    LinearGradient(colors: [Color(0xFF304FFE), Color(0xFF448AFF)]),
    LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)]),
    LinearGradient(colors: [Color(0xFFC51162), Color(0xFFFF4081)]),
    LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF64FFDA)]),
    LinearGradient(colors: [Color(0xFFAA00FF), Color(0xFFD500F9)]),
    LinearGradient(colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)]),
  ];

  static LinearGradient gradientAt(int index) =>
      gradients[index % gradients.length];

  /// تحويل اسم الأيقونة النصي المخزَّن في حقل `icon` إلى أيقونة فعلية.
  ///
  /// نخزّن اسماً نصياً لا رمز أيقونة، لأن `IconData` كائن Dart لا يمكن
  /// تخزينه في قاعدة بيانات. القيم المدعومة موثّقة في ملف البذرة.
  static IconData collegeIcon(String? name) {
    switch (name) {
      case 'engineering':
        return Icons.engineering_rounded;
      case 'medical':
      case 'medicine':
        return Icons.local_hospital_rounded;
      case 'computer':
      case 'it':
        return Icons.computer_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'law':
        return Icons.gavel_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'arts':
        return Icons.palette_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'pharmacy':
        return Icons.medication_rounded;
      case 'agriculture':
        return Icons.eco_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }
}
