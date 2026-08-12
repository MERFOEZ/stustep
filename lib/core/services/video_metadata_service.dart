import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'video_encryption_service.dart';

/// خدمة استخراج وتخزين البيانات الوصفية الحقيقية للفيديو
///
/// تستخرج: المدة الحقيقية، حجم الملف الفعلي، الدقة الديناميكية
/// وتخزنها في ذاكرة مؤقتة (SharedPreferences) لتجنب إعادة الحساب
class VideoMetadataService {
  static const String _cacheKey = 'video_metadata_cache';

  // ═══════════════════ التخزين المؤقت ═══════════════════

  /// جلب البيانات المخزنة مؤقتاً
  static Future<Map<String, dynamic>?> getCachedMetadata(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    final Map<String, dynamic> all = jsonDecode(raw);
    if (!all.containsKey(videoId)) return null;
    return Map<String, dynamic>.from(all[videoId]);
  }

  /// حفظ البيانات في الذاكرة المؤقتة
  static Future<void> _cacheMetadata(
    String videoId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    final Map<String, dynamic> all = raw != null ? jsonDecode(raw) : {};
    all[videoId] = data;
    await prefs.setString(_cacheKey, jsonEncode(all));
  }

  /// حذف ذاكرة فيديو محدد
  static Future<void> clearCache(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return;
    final Map<String, dynamic> all = jsonDecode(raw);
    all.remove(videoId);
    await prefs.setString(_cacheKey, jsonEncode(all));
  }

  // ═══════════════════ حجم الملف الحقيقي ═══════════════════

  /// إرجاع حجم الملف الفعلي بتنسيق مقروء (MB / GB)
  static Future<String> getRealFileSize(
    String videoId, {
    String courseId = '',
  }) async {
    try {
      final path = await VideoEncryptionService.resolveFilePath(
        videoId,
        courseId: courseId,
      );
      final file = File(path);
      if (!await file.exists()) return '';
      final bytes = await file.length();
      return _formatBytes(bytes);
    } catch (_) {
      return '';
    }
  }

  /// تحويل البايتات إلى نص مقروء
  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  // ═══════════════════ الدقة الديناميكية (Resolution Parser) ═══════════════════

  /// استخراج الدقة من اسم الفيديو أو URL
  /// يبحث عن أنماط: 1080p, 720p, 480p, 360p, 4K, FHD, HD
  static String parseResolution(String videoUrl, {String? title}) {
    final combined = '${videoUrl.toLowerCase()} ${(title ?? '').toLowerCase()}';

    // ترتيب البحث من الأعلى للأدنى
    if (combined.contains('2160') || combined.contains('4k') || combined.contains('uhd')) {
      return '4K';
    }
    if (combined.contains('1080') || combined.contains('fhd') || combined.contains('full_hd') || combined.contains('fullhd')) {
      return '1080p';
    }
    if (combined.contains('720') || combined.contains('hd')) {
      return '720p';
    }
    if (combined.contains('480') || combined.contains('sd')) {
      return '480p';
    }
    if (combined.contains('360')) {
      return '360p';
    }
    if (combined.contains('240')) {
      return '240p';
    }

    return ''; // غير معروفة — ستُستخرج لاحقاً عند التشغيل
  }

  // ═══════════════════ المدة الحقيقية (من ملف محلي) ═══════════════════

  /// استخراج المدة الحقيقية من ملف فيديو مفكوك التشفير
  /// يُستخدم بعد فك التشفير المؤقت أو عند أول تشغيل
  static Future<Duration?> extractDuration({
    required String videoId,
    String courseId = '',
  }) async {
    // محاولة من الكاش أولاً
    final cached = await getCachedMetadata(videoId);
    if (cached != null && cached['durationMs'] != null) {
      return Duration(milliseconds: cached['durationMs']);
    }

    try {
      // فك التشفير لملف مؤقت → قراءة المدة → حذف المؤقت
      final encPath = await VideoEncryptionService.resolveFilePath(
        videoId,
        courseId: courseId,
      );
      final encFile = File(encPath);
      if (!await encFile.exists()) return null;

      final tempPath = await VideoEncryptionService.decryptToTemp(
        encFilePath: encPath,
        videoId: videoId,
      );

      final controller = VideoPlayerController.file(File(tempPath));
      await controller.initialize();
      final duration = controller.value.duration;
      final width = controller.value.size.width.toInt();
      final height = controller.value.size.height.toInt();
      await controller.dispose();

      // حذف الملف المؤقت فوراً
      await VideoEncryptionService.deleteTemp(tempPath);

      // تحديد الدقة الحقيقية من أبعاد الفيديو
      final realRes = _resolutionFromDimensions(width, height);

      // حفظ في الكاش
      await _cacheMetadata(videoId, {
        'durationMs': duration.inMilliseconds,
        'width': width,
        'height': height,
        'resolution': realRes,
      });

      return duration;
    } catch (e) {
      debugPrint('⚠️ [VideoMetadata] فشل استخراج المدة لـ $videoId: $e');
      return null;
    }
  }

  /// تحويل Duration إلى نص قابل للعرض
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// تحديد الدقة من أبعاد الفيديو الحقيقية
  static String _resolutionFromDimensions(int width, int height) {
    final maxDim = width > height ? width : height;
    if (maxDim >= 3840) return '4K';
    if (maxDim >= 1920) return '1080p';
    if (maxDim >= 1280) return '720p';
    if (maxDim >= 854) return '480p';
    if (maxDim >= 640) return '360p';
    return '${height}p';
  }

  // ═══════════════════ جلب كل البيانات دفعة واحدة ═══════════════════

  /// جلب جميع البيانات الوصفية لفيديو محمل (حجم + مدة + دقة)
  /// يستخدم الكاش أولاً، ثم يستخرج من الملف إذا لزم الأمر
  static Future<VideoMeta> getFullMetadata(
    String videoId, {
    String courseId = '',
    String? videoUrl,
    String? title,
  }) async {
    // ═══ الحجم الفعلي ═══
    final fileSize = await getRealFileSize(videoId, courseId: courseId);

    // ═══ الدقة: كاش → parse من الاسم ═══
    final cached = await getCachedMetadata(videoId);
    String resolution = cached?['resolution'] ?? '';
    if (resolution.isEmpty && videoUrl != null) {
      resolution = parseResolution(videoUrl, title: title);
    }

    // ═══ المدة: كاش ═══
    String duration = '';
    if (cached?['durationMs'] != null) {
      duration = formatDuration(Duration(milliseconds: cached!['durationMs']));
    }

    return VideoMeta(
      duration: duration,
      fileSize: fileSize,
      resolution: resolution,
    );
  }

  /// حفظ المدة والدقة بعد أول تشغيل ناجح
  /// يُستدعى من المشغل عند اكتمال التهيئة
  static Future<void> cacheFromController(
    String videoId,
    VideoPlayerController controller,
  ) async {
    if (!controller.value.isInitialized) return;
    final duration = controller.value.duration;
    final width = controller.value.size.width.toInt();
    final height = controller.value.size.height.toInt();
    final resolution = _resolutionFromDimensions(width, height);

    await _cacheMetadata(videoId, {
      'durationMs': duration.inMilliseconds,
      'width': width,
      'height': height,
      'resolution': resolution,
    });
  }
}

/// كائن بيانات وصفية للفيديو
class VideoMeta {
  final String duration;
  final String fileSize;
  final String resolution;

  const VideoMeta({
    this.duration = '',
    this.fileSize = '',
    this.resolution = '',
  });
}
