import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admission/models/high_school_certificate.dart';
import 'auth_service.dart';

/// حفظ شهادة الطالب محلياً حتى لا يُعيد إدخالها في كل مرة.
///
/// **مفتاح التخزين مرتبط بمعرّف المستخدم.**
/// هذا تصحيح متعمَّد لخطأ رُصد في مرحلة التحليل: نظام تنزيل الفيديو القائم
/// يستخدم مفتاحاً عالمياً واحداً غير مرتبط بالمستخدم، فتظهر بيانات مستخدم
/// لمستخدم آخر عند تبديل الحساب على الجهاز نفسه.
///
/// لماذا محلياً لا في Firestore؟
/// لأن الشهادة بيانات شخصية يستخدمها الطالب في جهازه فقط، ولا تحتاج
/// مزامنة. تخزينها في السحابة يعني بيانات حساسة بلا فائدة تشغيلية.
class CertificateStorageService {
  static final CertificateStorageService _instance =
      CertificateStorageService._internal();

  factory CertificateStorageService() => _instance;

  CertificateStorageService._internal();

  static const String _keyPrefix = 'admission_certificate';

  String get _storageKey {
    final uid = AuthService().currentUser?.uid ?? 'guest';
    return '${_keyPrefix}_$uid';
  }

  /// حفظ الشهادة للمستخدم الحالي.
  Future<bool> save(HighSchoolCertificate certificate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
        _storageKey,
        json.encode(certificate.toMap()),
      );
    } catch (e) {
      debugPrint('CertificateStorageService: failed to save: $e');
      return false;
    }
  }

  /// استرجاع الشهادة المحفوظة — `null` إذا لم يسبق إدخالها.
  Future<HighSchoolCertificate?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      return HighSchoolCertificate.fromMap(map);
    } catch (e) {
      debugPrint('CertificateStorageService: failed to load: $e');
      return null;
    }
  }

  Future<bool> hasSavedCertificate() async => await load() != null;

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('CertificateStorageService: failed to clear: $e');
    }
  }
}
