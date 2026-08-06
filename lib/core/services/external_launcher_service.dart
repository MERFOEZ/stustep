import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// فتح التطبيقات الخارجية: الاتصال، واتساب، والخرائط.
///
/// **لماذا خدمة وسيطة بدل استدعاء `url_launcher` من الشاشات؟**
/// لأن بناء الروابط منطق قابل للخطأ (تنسيق الأرقام، ترميز الإحداثيات)،
/// وتجميعه هنا يجعله قابلاً للاختبار ويمنع تكراره في ثلاث شاشات.
///
/// **لماذا روابط `https` بدل مخططات مخصصة؟**
/// المخططات المخصصة مثل `whatsapp://` تتطلب تعريفاً في `Info.plist` على
/// iOS وفي المانفست على أندرويد. رابط `wa.me` القياسي يعمل على المنصتين
/// بلا أي إعداد إضافي — قرار يوفّر تعديل ملفين حساسين.
class ExternalLauncherService {
  static final ExternalLauncherService _instance =
      ExternalLauncherService._internal();

  factory ExternalLauncherService() => _instance;

  ExternalLauncherService._internal();

  /// فتح تطبيق الاتصال برقم السكن.
  Future<bool> call(String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return false;
    return _launch(Uri.parse('tel:$normalized'));
  }

  /// فتح محادثة واتساب عبر الرابط القياسي.
  Future<bool> whatsapp(String phone, {String? message}) async {
    final normalized = normalizePhone(phone).replaceAll('+', '');
    if (normalized.isEmpty) return false;

    final uri = Uri.https('wa.me', '/$normalized', {
      if (message != null && message.isNotEmpty) 'text': message,
    });
    return _launch(uri);
  }

  /// فتح الموقع في تطبيق الخرائط الخارجي.
  Future<bool> openMap(GeoPoint location) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${location.latitude},${location.longitude}',
    });
    return _launch(uri);
  }

  Future<bool> openUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Future.value(false);
    return _launch(uri);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('ExternalLauncherService: failed to launch $uri: $e');
      return false;
    }
  }

  /// تنظيف رقم الهاتف من المسافات والرموز مع الإبقاء على مفتاح الدولة.
  static String normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return hasPlus ? '+$digits' : digits;
  }

  /// استخراج الإحداثيات من رابط خرائط جوجل ملصوق.
  ///
  /// يتيح لصاحب السكن مشاركة موقعه بلصق رابط بدل إدخال الإحداثيات يدوياً،
  /// وهو ما يوفّر إضافة حزمة خرائط كاملة بمفتاح API وإعدادات منصّية.
  /// يدعم الصيغ: `@15.36,44.19` و`q=15.36,44.19` و`query=15.36,44.19`.
  static GeoPoint? parseCoordinates(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final patterns = [
      RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)'),
      RegExp(r'[?&](?:q|query|ll)=(-?\d+\.?\d*),(-?\d+\.?\d*)'),
      RegExp(r'^\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat == null || lng == null) continue;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) continue;
      return GeoPoint(lat, lng);
    }
    return null;
  }
}
