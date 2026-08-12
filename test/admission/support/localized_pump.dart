import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مُهيّئ اختبارات الودجت مع **ملفات الترجمة الحقيقية**.
///
/// **لماذا لا نكتفي باختبارات المنطق الخالص؟**
/// الموديول يحتوي 65 ملف واجهة، وكل نص فيها يأتي من `easy_localization`.
/// اختبار المنطق وحده لا يكشف صنفاً كاملاً من الأعطال: مفتاح ترجمة كُتب
/// خطأً فيظهر للطالب مفتاحاً خاماً مثل `admission.housing.price`، أو ودجت
/// ترمي استثناء عند أول رسم لأن قيمة مطلوبة كانت `null`.
///
/// ولأن تشغيل التطبيق كاملاً يتطلب تهيئة Firebase غير المتاحة في بيئة
/// الاختبار، نرسم **الودجت وحدها** داخل غلاف الترجمة الحقيقي. هذا أقرب ما
/// يمكن الوصول إليه آلياً من «شغّل التطبيق وانظر إلى الشاشة».
Future<void> initLocalizationForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// رسم ودجت داخل التطبيق مع تحميل ترجمات العربية فعلياً من `assets`.
///
/// [locale] تسمح باختبار اللغتين على نفس الودجت، وهو ما يكشف النصوص
/// المكتوبة داخل الكود: النص المكتوب لا يتغيّر بتغيّر اللغة.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ar'),
}) async {
  final app = EasyLocalization(
    supportedLocales: const [Locale('ar'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar'),
    startLocale: locale,
    child: Builder(
      builder: (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  // `runAsync` ضرورية لا تجميلية: تحميل ملف الترجمة قراءة **حقيقية** من
  // `assets`، والزمن المزيَّف الذي يستخدمه `pump` لا يُكمل هذه القراءة —
  // فتبقى الشجرة فارغة ويمرّ الاختبار على لا شيء وهو أخطر من فشله.
  await tester.runAsync(() async {
    await tester.pumpWidget(app);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });

  // `pumpAndSettle` غير صالح هنا: ودجت الموديول تستخدم `animate_do`، وانتظار
  // استقرار كل حركاتها يستهلك وقت الاختبار بلا فائدة. نبضتان تكفيان لإتمام
  // بناء الشجرة بعد وصول الترجمة.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// هل ظهر أي مفتاح ترجمة خام على الشاشة بدل نصه؟
///
/// أهم فحص في هذا الملف: المفتاح غير المترجَم لا يُسقط التطبيق، بل يظهر
/// للطالب كنص تقني مبهم — وهو عطل يمرّ من التحليل ومن اختبارات المنطق معاً.
void expectNoRawTranslationKeys() {
  final texts = find.byType(Text).evaluate().map((element) {
    final data = (element.widget as Text).data;
    return data ?? '';
  });

  for (final text in texts) {
    expect(
      text.startsWith('admission.'),
      isFalse,
      reason: 'ظهر مفتاح ترجمة خام على الشاشة: $text',
    );
  }
}
