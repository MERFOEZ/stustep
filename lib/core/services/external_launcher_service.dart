import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// فتح التطبيقات الخارجية: الاتصال، واتساب، والخرائط.
///
/// **لماذا خريطة خارجية بدل خريطة مدمجة؟**
/// الخريطة المدمجة (`google_maps_flutter`) تتطلب مفتاح API وتعديل
/// `build.gradle` و`Info.plist` — وكلها ملفات مصنّفة حساسة في هذا المشروع
/// ويملكها زملاء آخرون. فتح تطبيق الخرائط المثبَّت على الجهاز يعطي الطالب
/// تجربة أفضل فعلياً (اتجاهات حقيقية وملاحة صوتية) بصفر تعديل على ملفات
/// المنصات وصفر مفاتيح مكشوفة.
class ExternalLauncherService {
  static final ExternalLauncherService _instance =
      ExternalLauncherService._internal();

  factory ExternalLauncherService() => _instance;

  ExternalLauncherService._internal();

  /// إجراء اتصال هاتفي.
  Future<bool> call(String phone) {
    final digits = _normalizePhone(phone);
    if (digits.isEmpty) return Future.value(false);
    return _launch(Uri(scheme: 'tel', path: digits));
  }

  /// فتح محادثة واتساب.
  ///
  /// نستخدم `wa.me` لا مخطط `whatsapp://` لأن الأول يعمل حتى لو لم يكن
  /// التطبيق مثبَّتاً (يفتح في المتصفح)، بينما الثاني يفشل صامتاً.
  Future<bool> whatsapp(String phone, {String? message}) {
    final digits = _normalizePhone(phone);
    if (digits.isEmpty) return Future.value(false);

    return _launch(
      Uri.parse(
        'https://wa.me/$digits'
        '${message == null ? '' : '?text=${Uri.encodeComponent(message)}'}',
      ),
    );
  }

  /// فتح موقع على تطبيق الخرائط.
  Future<bool> openMap(String url) => _launch(Uri.parse(url));

  /// فتح رابط عام (يُستخدم لتنزيل ملفات نماذج الاختبارات).
  Future<bool> openUrl(String url) => _launch(Uri.parse(url));

  Future<bool> _launch(Uri uri) async {
    try {
      // `externalApplication` تُجبر النظام على تسليم الرابط للتطبيق المختص
      // بدل فتحه في متصفح داخلي، وهو المطلوب للاتصال والخرائط.
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('ExternalLauncherService: failed to launch $uri: $e');
      return false;
    }
  }

  /// تنظيف رقم الهاتف من المسافات والرموز.
  ///
  /// دالة خالصة ومكشوفة للاختبار: أرقام الهواتف تُدخَل بصيغ متعددة
  /// (‏+967 77 123 4567 · 00967-771234567 · 771234567) ويجب أن تعمل كلها.
  @visibleForTesting
  static String normalizePhone(String phone) => _normalizePhone(phone);

  static String _normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return '';

    // `00` بادئة دولية بديلة عن `+` — نوحّدها لأن `wa.me` لا يقبل إلا
    // الأرقام المجرّدة بلا رموز.
    if (cleaned.startsWith('00')) return cleaned.substring(2);
    if (cleaned.startsWith('+')) return cleaned.substring(1);
    return cleaned;
  }
}
