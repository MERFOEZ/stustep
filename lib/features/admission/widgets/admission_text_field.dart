import 'package:flutter/material.dart';

/// حقل نصي موحّد لكل نماذج الموديول.
///
/// نشأ في نموذج السكنات ثم احتاجته شاشة رفع النماذج، فنُقل إلى الودجت
/// المشتركة باسم محايد بدل استيراده من مجلد السكنات — الاستيراد المتقاطع
/// بين موديولين فرعيين يخلق ارتباطاً لا مبرر له.
class AdmissionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AdmissionTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
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
      ),
    );
  }
}
