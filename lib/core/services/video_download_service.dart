import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_encryption_service.dart';

/// خدمة التحميل الآمن للفيديوهات التعليمية
/// تستخدم Dio للتحميل الموثوق وتُمرر البيانات مباشرة لخدمة التشفير
/// لا تُكتب ملفات .mp4 أبداً على القرص
class VideoDownloadService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  // ======== التحقق من الحالة ========

  /// يُعيد true إذا كان الفيديو محمّلاً ومشفراً بالفعل
  static Future<bool> isDownloaded(String videoId) async {
    final path = await VideoEncryptionService.getEncFilePath(videoId);
    return File(path).exists();
  }

  // ======== حفظ بيانات التحميل (Metadata) ========

  static const String _downloadsPrefsKey = 'downloaded_videos_meta';

  /// استرجاع قائمة الفيديوهات المحمّلة
  static Future<List<Map<String, dynamic>>> getDownloadedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_downloadsPrefsKey);
    if (data == null) return [];
    
    final List<dynamic> decoded = jsonDecode(data);
    final List<Map<String, dynamic>> videos = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    
    // التحقق الفعلي من وجود الملفات
    List<Map<String, dynamic>> validVideos = [];
    bool listChanged = false;
    for (var video in videos) {
      if (await isDownloaded(video['videoId'])) {
        validVideos.add(video);
      } else {
        listChanged = true;
      }
    }
    
    if (listChanged) {
      await prefs.setString(_downloadsPrefsKey, jsonEncode(validVideos));
    }
    
    return validVideos;
  }

  /// استرجاع مجموعات الدورات (مجلدات) — كل مجلد يحتوي بيانات الدورة وعدد الفيديوهات
  static Future<List<Map<String, dynamic>>> getCourseGroups() async {
    final videos = await getDownloadedVideos();
    final Map<String, Map<String, dynamic>> groups = {};

    for (var video in videos) {
      final courseId = video['courseId'] as String? ?? 'unknown';
      if (!groups.containsKey(courseId)) {
        groups[courseId] = {
          'courseId': courseId,
          'courseName': video['courseName'] ?? 'دورة غير معروفة',
          'coverImage': video['coverImage'] ?? '',
          'videoCount': 0,
        };
      }
      groups[courseId]!['videoCount'] = (groups[courseId]!['videoCount'] as int) + 1;
    }

    return groups.values.toList();
  }

  /// استرجاع فيديوهات دورة محددة
  static Future<List<Map<String, dynamic>>> getVideosByCourse(String courseId) async {
    final videos = await getDownloadedVideos();
    return videos.where((v) => (v['courseId'] ?? 'unknown') == courseId).toList();
  }

  /// إجمالي المساحة المستهلكة بالبايت
  static Future<int> getTotalDownloadSizeBytes() async {
    final videos = await getDownloadedVideos();
    int totalBytes = 0;
    for (var video in videos) {
      try {
        final path = await VideoEncryptionService.getEncFilePath(video['videoId']);
        final file = File(path);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      } catch (_) {}
    }
    return totalBytes;
  }

  /// إجمالي المساحة المستهلكة — نص قابل للعرض (MB / GB)
  static Future<String> getTotalDownloadSizeFormatted() async {
    final totalBytes = await getTotalDownloadSizeBytes();
    if (totalBytes == 0) return '0 MB';
    final sizeMB = totalBytes / (1024 * 1024);
    if (sizeMB >= 1024) {
      return '${(sizeMB / 1024).toStringAsFixed(2)} GB';
    }
    return '${sizeMB.toStringAsFixed(1)} MB';
  }

  /// مساحة فيديوهات دورة محددة
  static Future<String> getCourseTotalSize(String courseId) async {
    final videos = await getVideosByCourse(courseId);
    int totalBytes = 0;
    for (var video in videos) {
      try {
        final path = await VideoEncryptionService.getEncFilePath(video['videoId']);
        final file = File(path);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      } catch (_) {}
    }
    if (totalBytes == 0) return '0 MB';
    final sizeMB = totalBytes / (1024 * 1024);
    if (sizeMB >= 1024) {
      return '${(sizeMB / 1024).toStringAsFixed(2)} GB';
    }
    return '${sizeMB.toStringAsFixed(1)} MB';
  }

  /// حفظ فيديو جديد في القائمة
  static Future<void> _saveVideoMetadata({
    required String videoId,
    required String title,
    required String url,
    required String courseId,
    required String courseName,
    required String coverImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> videos = await getDownloadedVideos();
    
    // التأكد من عدم التكرار
    videos.removeWhere((v) => v['videoId'] == videoId);
    
    videos.add({
      'videoId': videoId,
      'title': title,
      'url': url,
      'courseId': courseId,
      'courseName': courseName,
      'coverImage': coverImage,
      'downloadDate': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_downloadsPrefsKey, jsonEncode(videos));
  }

  /// إزالة فيديو من القائمة
  static Future<void> _removeVideoMetadata(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> videos = await getDownloadedVideos();
    
    videos.removeWhere((v) => v['videoId'] == videoId);
    await prefs.setString(_downloadsPrefsKey, jsonEncode(videos));
  }

  // ======== التحميل والتشفير ========

  /// تحميل الفيديو من Archive.org وتشفيره مباشرة دون حفظ .mp4
  ///
  /// [videoId]      معرف الفيديو (e.g. "flutter_lecture_01")
  /// [url]          الرابط المباشر للملف على Archive.org
  /// [title]        عنوان الفيديو
  /// [courseId]     معرف الدورة التي ينتمي إليها الفيديو
  /// [courseName]   اسم الدورة
  /// [coverImage]   رابط صورة غلاف الدورة
  /// [onProgress]   callback لتحديث شريط التقدم (0.0 → 1.0)
  /// يُعيد مسار الملف المشفر .enc عند الاكتمال
  static Future<String> downloadAndEncrypt({
    required String videoId,
    required String url,
    required String title,
    String courseId = '',
    String courseName = '',
    String coverImage = '',
    void Function(double progress)? onProgress,
  }) async {
    final encPath = await VideoEncryptionService.getEncFilePath(videoId);

    // التحميل كـ bytes مباشرة في الذاكرة (لا يُحفظ .mp4)
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    if (response.data == null) {
      throw Exception('فشل التحميل: البيانات فارغة');
    }

    final videoBytes = Uint8List.fromList(response.data!);

    // التشفير الفوري وحفظ .enc فقط
    await VideoEncryptionService.encryptAndSave(
      videoBytes: videoBytes,
      encFilePath: encPath,
    );
    
    // حفظ البيانات الوصفية لظهورها في شاشة التنزيلات
    await _saveVideoMetadata(
      videoId: videoId,
      title: title,
      url: url,
      courseId: courseId,
      courseName: courseName,
      coverImage: coverImage,
    );

    return encPath;
  }

  // ======== حذف التحميل ========

  /// حذف الملف المشفر من القرص (لتحرير المساحة)
  static Future<void> deleteDownload(String videoId) async {
    final path = await VideoEncryptionService.getEncFilePath(videoId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await _removeVideoMetadata(videoId);
  }

  // ======== حجم الملف المشفر ========

  /// حجم الملف المشفر بالميغابايت (للعرض في الواجهة)
  static Future<String> getFileSizeMB(String videoId) async {
    try {
      final path = await VideoEncryptionService.getEncFilePath(videoId);
      final file = File(path);
      if (!await file.exists()) return '0 MB';
      final sizeBytes = await file.length();
      final sizeMB = sizeBytes / (1024 * 1024);
      return '${sizeMB.toStringAsFixed(1)} MB';
    } catch (_) {
      return '? MB';
    }
  }
}
