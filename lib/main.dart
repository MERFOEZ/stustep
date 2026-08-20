import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // إعلانات AdMob لا تدعم الويب إطلاقاً، واستدعاء التهيئة هناك يرمي
  // MissingPluginException قبل runApp فتظهر صفحة بيضاء فارغة.
  // نتخطّاها على الويب وحده؛ سلوك أندرويد وiOS لم يتغيّر.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  await EasyLocalization.ensureInitialized();
  try {
    await Hive.initFlutter();
  } catch (e) {
    Hive.init(
      '.',
    ); // Fallback for Windows if documents directory is unavailable
  }

  runApp(
    // ProviderScope يغطّي التطبيق كاملاً حتى تعمل صفحات SAIE (Riverpod) من أي مكان
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: const StuStepApp(),
        ),
      ),
    ),
  );
}

class StuStepApp extends StatelessWidget {
  const StuStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: context.watch<ThemeProvider>().themeMode,
      home: const SplashScreen(),
    );
  }
}
