import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// شريط علوي متدرّج موحّد لكل شاشات الموديول.
///
/// يستدعي `AppTheme.primaryGradient` القائم ولا يعيد تعريف ألوان خاصة، حتى
/// يتبع الموديول أي تغيير مستقبلي في هوية التطبيق البصرية تلقائياً.
class AdmissionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final PreferredSizeWidget? bottom;

  const AdmissionAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient(context)),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }
}
