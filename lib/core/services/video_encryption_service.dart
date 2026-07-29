import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as aes_lib;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التشفير وفك التشفير لملفات الفيديو التعليمية
/// تعتمد على خوارزمية AES-256-CBC
class VideoEncryptionService {
  static const String _keyPrefKey = 'venc_aes_key_b64';
  static const String _ivPrefKey = 'venc_aes_iv_b64';

  // ======== توليد / استرجاع المفتاح والـ IV ========

  /// استرجاع مفتاح AES-256 (32 بايت) من SharedPreferences
  /// إذا لم يوجد يُولِّد مفتاحاً جديداً ويحفظه
  static Future<aes_lib.Key> _getOrCreateKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPrefKey);
    if (stored != null) {
      return aes_lib.Key(base64Decode(stored));
    }
    // توليد مفتاح عشوائي 32 بايت (256 بت)
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    await prefs.setString(_keyPrefKey, base64Encode(keyBytes));
    return aes_lib.Key(keyBytes);
  }

  /// استرجاع IV ثابت (16 بايت) من SharedPreferences
  /// إذا لم يوجد يُولِّد IV جديداً ويحفظه
  static Future<aes_lib.IV> _getOrCreateIV() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_ivPrefKey);
    if (stored != null) {
      return aes_lib.IV(base64Decode(stored));
    }
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
    await prefs.setString(_ivPrefKey, base64Encode(ivBytes));
    return aes_lib.IV(ivBytes);
  }

  // ======== التشفير ========

  /// تشفير البيانات الثنائية للفيديو وحفظها كملف .enc
  /// [videoBytes]  البيانات الخام المحمّلة من الإنترنت
  /// [encFilePath] مسار الحفظ النهائي داخل ApplicationDocumentsDirectory
  static Future<void> encryptAndSave({
    required Uint8List videoBytes,
    required String encFilePath,
  }) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = aes_lib.Encrypter(
      aes_lib.AES(key, mode: aes_lib.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(videoBytes, iv: iv);
    final file = File(encFilePath);
    await file.writeAsBytes(encrypted.bytes, flush: true);
  }

  // ======== فك التشفير إلى ملف مؤقت ========

  /// قراءة الملف المشفر .enc وفك تشفيره إلى مسار مؤقت
  /// [encFilePath] مسار الملف المشفر
  /// [videoId]     معرف الفيديو (لتسمية الملف المؤقت)
  /// يُعيد مسار الملف المؤقت المفكوك جاهزاً للتشغيل
  static Future<String> decryptToTemp({
    required String encFilePath,
    required String videoId,
  }) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = aes_lib.Encrypter(
      aes_lib.AES(key, mode: aes_lib.AESMode.cbc),
    );

    final encFile = File(encFilePath);
    final encryptedBytes = await encFile.readAsBytes();
    final decryptedBytes = encrypter.decryptBytes(
      aes_lib.Encrypted(encryptedBytes),
      iv: iv,
    );

    // حفظ الملف المؤقت في TempDirectory فقط
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/tmp_$videoId.mp4';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(decryptedBytes, flush: true);
    return tempPath;
  }

  // ======== الإتلاف التلقائي ========

  /// مسح الملف المؤقت المفكوك — يُستدعى دائماً في dispose()
  static Future<void> deleteTemp(String tempPath) async {
    try {
      final file = File(tempPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // لا نرمي خطأ حتى لو فشل المسح (الملف قد لا يوجد)
    }
  }

  // ======== مساعد: مسار ملف التشفير ========

  /// يُعيد المسار الكامل لملف .enc داخل sandbox التطبيق
  static Future<String> getEncFilePath(String videoId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${docDir.path}/stustep_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return '${videoDir.path}/$videoId.enc';
  }
}
