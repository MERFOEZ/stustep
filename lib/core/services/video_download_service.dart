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
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Connection': 'keep-alive',
        'Accept': '*/*',
      },
    ),
  );

  // ======== التحقق من الحالة ========

  /// يُعيد true إذا كان الفيديو محمّلاً ومشفراً بالفعل
  /// يجب تمرير [courseId] للبحث في المجلد الصحيح
  static Future<bool> isDownloaded(String videoId, {String courseId = ''}) async {
    return await VideoEncryptionService.fileExistsForVideo(videoId, courseId: courseId);
  }

  // ======== حفظ بيانات التحميل (Metadata) ========

  static const String _downloadsPrefsKey = 'downloaded_videos_meta';

  /// استرجاع قائمة الفيديوهات المحمّلة
  static Future<List<Map<String, dynamic>>> getDownloadedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_downloadsPrefsKey);
    if (data == null) {
      print('📦 [Downloads] لا توجد بيانات metadata في SharedPreferences');
      return [];
    }
    
    final List<dynamic> decoded = jsonDecode(data);
    final List<Map<String, dynamic>> videos = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    print('📦 [Downloads] عدد السجلات في metadata: ${videos.length}');
    
    // التحقق الفعلي من وجود الملفات — مع تمرير courseId!
    List<Map<String, dynamic>> validVideos = [];
    bool listChanged = false;
    for (var video in videos) {
      final videoId = video['videoId'] as String? ?? '';
      final courseId = video['courseId'] as String? ?? '';
      final exists = await isDownloaded(videoId, courseId: courseId);
      print('📦 [Downloads] فحص: $videoId (course: $courseId) → exists=$exists');
      if (exists) {
        validVideos.add(video);
      } else {
        listChanged = true;
        print('⚠️ [Downloads] ملف غير موجود فعلياً — سيتم حذفه من metadata: $videoId');
      }
    }
    
    if (listChanged) {
      await prefs.setString(_downloadsPrefsKey, jsonEncode(validVideos));
    }
    
    print('📦 [Downloads] عدد الفيديوهات الصالحة: ${validVideos.length}');
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

    print('📂 [Downloads] عدد المجلدات (الدورات): ${groups.length}');
    for (var g in groups.values) {
      print('📂 [Downloads]   → ${g['courseName']} (${g['courseId']}): ${g['videoCount']} فيديو');
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
        final path = await VideoEncryptionService.resolveFilePath(
          video['videoId'],
          courseId: video['courseId'] ?? '',
        );
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
        final path = await VideoEncryptionService.resolveFilePath(
          video['videoId'],
          courseId: video['courseId'] ?? '',
        );
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
    
    // جلب القائمة الخام بدون فحص الملفات (لتجنب الدورة اللانهائية)
    final String? rawData = prefs.getString(_downloadsPrefsKey);
    final List<Map<String, dynamic>> videos = rawData != null
        ? (jsonDecode(rawData) as List).map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
    
    // التأكد من عدم التكرار
    videos.removeWhere((v) => v['videoId'] == videoId);
    
    final entry = {
      'videoId': videoId,
      'title': title,
      'url': url,
      'courseId': courseId,
      'courseName': courseName,
      'coverImage': coverImage,
      'downloadDate': DateTime.now().toIso8601String(),
    };
    videos.add(entry);
    
    await prefs.setString(_downloadsPrefsKey, jsonEncode(videos));
    print('✅ [Metadata] تم حفظ: $videoId | course=$courseId ($courseName) | total=${videos.length}');
  }

  /// إزالة فيديو من القائمة
  static Future<void> _removeVideoMetadata(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> videos = await getDownloadedVideos();
    
    videos.removeWhere((v) => v['videoId'] == videoId);
    await prefs.setString(_downloadsPrefsKey, jsonEncode(videos));
  }

  // ======== التحميل والتشفير ========

  /// تحميل الفيديو من الإنترنت وتشفيره مباشرة دون حفظ .mp4
  ///
  /// [videoId]      معرف الفيديو (e.g. "flutter_lecture_01")
  /// [url]          الرابط المباشر للملف
  /// [title]        عنوان الفيديو
  /// [courseId]     معرف الدورة التي ينتمي إليها الفيديو
  /// [courseName]   اسم الدورة
  /// [coverImage]   رابط صورة غلاف الدورة
  /// [cancelToken]  للإلغاء من DownloadManagerProvider
  /// [onProgress]   callback لتحديث شريط التقدم (0.0 → 1.0)
  /// يُعيد مسار الملف المشفر .stustep عند الاكتمال
  static Future<String> downloadAndEncrypt({
    required String videoId,
    required String url,
    required String title,
    String courseId = '',
    String courseName = '',
    String coverImage = '',
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final encPath = await VideoEncryptionService.getEncFilePath(
      videoId,
      courseId: courseId,
    );

    // التحميل كـ bytes مباشرة في الذاكرة (لا يُحفظ .mp4)
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
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

    // التشفير الفوري وحفظ .stustep فقط
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
    // البحث في metadata لاسترجاع courseId
    final videos = await getDownloadedVideos();
    String courseId = '';
    for (final v in videos) {
      if (v['videoId'] == videoId) {
        courseId = v['courseId'] ?? '';
        break;
      }
    }

    // حذف الملف — البحث في جميع المسارات الممكنة
    final path = await VideoEncryptionService.resolveFilePath(
      videoId,
      courseId: courseId,
    );
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await _removeVideoMetadata(videoId);

    // حذف مجلد الدورة إذا أصبح فارغاً
    if (courseId.isNotEmpty) {
      try {
        final dir = file.parent;
        if (await dir.exists()) {
          final remaining = await dir.list().length;
          if (remaining == 0) {
            await dir.delete();
          }
        }
      } catch (_) {}
    }
  }

  // ======== حجم الملف المشفر ========

  /// حجم الملف المشفر بالميغابايت (للعرض في الواجهة)
  static Future<String> getFileSizeMB(String videoId, {String courseId = ''}) async {
    try {
      final path = await VideoEncryptionService.resolveFilePath(videoId, courseId: courseId);
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
