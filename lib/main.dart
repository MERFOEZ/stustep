import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/points/services/points_service.dart';
import 'features/points/providers/points_provider.dart';
import 'features/leaderboard/services/leaderboard_service.dart';
import 'features/leaderboard/providers/leaderboard_provider.dart';
import 'features/referral/services/referral_service.dart';
import 'features/referral/providers/referral_provider.dart';
import 'features/quests/services/quests_service.dart';
import 'features/quests/providers/quests_provider.dart';
import 'core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();
  try {
    await Hive.initFlutter();
  } catch (e) {
    Hive.init(
      '.',
    ); // Fallback for Windows if documents directory is unavailable
  }

  // Initialize Hive boxes for offline caching
  await PointsService.initHive();
  await LeaderboardService.initHive();
  await ReferralService.initHive();
  await QuestsService.initHive();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => PointsProvider()),
          ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
          ChangeNotifierProvider(create: (_) => ReferralProvider()),
          ChangeNotifierProvider(create: (_) => QuestsProvider()),
        ],
        child: const StuStepApp(),
      ),
    ),
  );
}

class StuStepApp extends StatelessWidget {
  const StuStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: context.watch<ThemeProvider>().themeMode,
      routes: AppRoutes.routes,
      home: const SplashScreen(),
    );
  }
}
