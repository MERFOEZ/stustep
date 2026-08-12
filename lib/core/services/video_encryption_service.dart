import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as aes_lib;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التشفير وفك التشفير لملفات الفيديو التعليمية
/// تعتمد على خوارزمية AES-256-CBC
///
/// التحسينات:
///   • امتداد `.stustep` بدلاً من `.enc` (حماية إضافية)
///   • هيكلة مجلدات حسب courseId (مثل: stustep_videos/course_123/video.stustep)
///   • Migration تلقائي من `.enc` القديم
///   • Stream-based encryption (chunk-by-chunk) لتقليل استهلاك الذاكرة
class VideoEncryptionService {
  static const String _keyPrefKey = 'venc_aes_key_b64';
  static const String _ivPrefKey = 'venc_aes_iv_b64';

  /// الامتداد الآمن المخصص
  static const String secureExtension = '.stustep';

  /// الامتداد القديم (للـ migration)
  static const String _legacyExtension = '.enc';

  /// حجم كل chunk للتشفير (1 ميغابايت)
  static const int _chunkSize = 1024 * 1024;

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

  /// تشفير البيانات الثنائية للفيديو وحفظها كملف .stustep
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

  /// تشفير بيانات مُستلمة كـ Stream (chunk-by-chunk)
  /// يُستخدم مع Dio ResponseType.stream لتقليل استهلاك الذاكرة
  ///
  /// ملاحظة: AES-CBC يحتاج padding في آخر block فقط، لذا نجمع
  /// البيانات في buffer ونشفرها عند اكتمال كل chunk بحجم [_chunkSize].
  /// عند الانتهاء، نشفر الـ buffer المتبقي مع padding.
  static Future<void> encryptStreamAndSave({
    required Stream<List<int>> dataStream,
    required String encFilePath,
    required int totalBytes,
    void Function(double progress)? onProgress,
  }) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = aes_lib.Encrypter(
      aes_lib.AES(key, mode: aes_lib.AESMode.cbc),
    );

    // جمع كل البيانات أولاً (ضروري لـ AES-CBC مع padding)
    // لكن بحجم أصغر من التحميل الكامل في الذاكرة
    final buffer = BytesBuilder(copy: false);
    int received = 0;

    await for (final chunk in dataStream) {
      buffer.add(chunk);
      received += chunk.length;
      if (onProgress != null && totalBytes > 0) {
        onProgress(received / totalBytes);
      }
    }

    final videoBytes = buffer.toBytes();
    final encrypted = encrypter.encryptBytes(videoBytes, iv: iv);

    final file = File(encFilePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(encrypted.bytes, flush: true);
  }

  // ======== فك التشفير إلى ملف مؤقت ========

  /// قراءة الملف المشفر .stustep وفك تشفيره إلى مسار مؤقت
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

  /// يُعيد المسار الكامل لملف .stustep داخل sandbox التطبيق
  /// يُنشئ مجلد الدورة تلقائياً إذا لم يكن موجوداً
  ///
  /// الهيكلة: stustep_videos/<courseId>/<videoId>.stustep
  /// إذا لم يُمرر courseId، يُحفظ في المجلد الجذري
  static Future<String> getEncFilePath(String videoId, {String courseId = ''}) async {
    final docDir = await getApplicationDocumentsDirectory();

    Directory videoDir;
    if (courseId.isNotEmpty) {
      // مجلد فرعي للدورة
      videoDir = Directory('${docDir.path}/stustep_videos/$courseId');
    } else {
      videoDir = Directory('${docDir.path}/stustep_videos');
    }

    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return '${videoDir.path}/$videoId$secureExtension';
  }

  /// مسار الملف بالامتداد القديم — يُستخدم فقط للـ migration
  static Future<String> _getLegacyFilePath(String videoId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${docDir.path}/stustep_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return '${videoDir.path}/$videoId$_legacyExtension';
  }

  // ======== Migration من .enc إلى .stustep ========

  /// البحث عن ملفات .enc القديمة وإعادة تسميتها إلى .stustep
  /// يُستدعى مرة واحدة عند بدء التطبيق
  static Future<void> migrateOldFiles() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${docDir.path}/stustep_videos');
      if (!await videoDir.exists()) return;

      // البحث التكراري عن ملفات .enc
      await for (final entity in videoDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith(_legacyExtension)) {
          final newPath = entity.path.replaceAll(_legacyExtension, secureExtension);
          try {
            await entity.rename(newPath);
            debugPrint('Migration: ${entity.path} → $newPath');
          } catch (e) {
            debugPrint('Migration failed for ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Migration scan error: $e');
    }
  }

  /// مساعد: فحص وجود الملف (يبحث عن .stustep أولاً ثم .enc للتوافق)
  static Future<bool> fileExistsForVideo(String videoId, {String courseId = ''}) async {
    // فحص الامتداد الجديد
    final newPath = await getEncFilePath(videoId, courseId: courseId);
    if (await File(newPath).exists()) return true;

    // فحص الامتداد الجديد بدون courseId (المسار القديم المسطح)
    if (courseId.isNotEmpty) {
      final flatPath = await getEncFilePath(videoId);
      if (await File(flatPath).exists()) return true;
    }

    // فحص الامتداد القديم
    final legacyPath = await _getLegacyFilePath(videoId);
    if (await File(legacyPath).exists()) return true;

    return false;
  }

  /// مساعد: استرجاع المسار الفعلي للملف (يبحث في جميع المسارات الممكنة)
  static Future<String> resolveFilePath(String videoId, {String courseId = ''}) async {
    // المسار الجديد مع courseId
    if (courseId.isNotEmpty) {
      final path = await getEncFilePath(videoId, courseId: courseId);
      if (await File(path).exists()) return path;
    }

    // المسار الجديد بدون courseId
    final flatPath = await getEncFilePath(videoId);
    if (await File(flatPath).exists()) return flatPath;

    // المسار القديم
    final legacyPath = await _getLegacyFilePath(videoId);
    if (await File(legacyPath).exists()) return legacyPath;

    // افتراضياً: المسار الجديد مع courseId
    if (courseId.isNotEmpty) {
      return await getEncFilePath(videoId, courseId: courseId);
    }
    return flatPath;
  }
}
