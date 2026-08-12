import 'package:flutter/material.dart';
import '../../features/quests/screens/quests_screen.dart';

/// تعريف المسارات المستقلة للتطبيق دون ربطها المباشر بواجهات قائمة.
class AppRoutes {
  static const String quests = '/quests';

  static Map<String, WidgetBuilder> get routes => {
        quests: (context) => const QuestsScreen(),
      };
}
