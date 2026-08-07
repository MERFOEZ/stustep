import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admission/models/exam_paper_model.dart';
import 'auth_service.dart';

/// التخزين المحلي لنماذج الاختبارات المحمَّلة.
///
/// **فُصلت عن `ExamPapersService` عمداً.** تلك تتعامل مع Firestore وهذه
/// تتعامل مع نظام الملفات وذاكرة الجهاز — مسؤوليتان مختلفتان تماماً،
/// وفصلهما يسمح باختبار كل منهما وتغيير أيهما بلا مساس بالآخر.
///
/// 🔴 **مفتاح البيانات الوصفية مرتبط بمعرّف المستخدم.**
/// هذا تصحيح متعمَّد لخطأ رُصد في مرحلة التحليل: نظام تنزيل الفيديو القائم
/// يستخدم مفتاحاً عالمياً واحداً (`downloaded_videos_meta`)، فتظهر تنزيلات
/// مستخدم لمستخدم آخر عند تبديل الحساب على الجهاز نفسه.
class PaperDownloadsService {
  static final PaperDownloadsService _instance =
      PaperDownloadsService._internal();

  factory PaperDownloadsService() => _instance;

  PaperDownloadsService._internal();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  static const String _keyPrefix = 'exam_papers_meta';
  static const String _folderName = 'stustep_papers';

  String get _storageKey {
    final uid = AuthService().currentUser?.uid ?? 'guest';
    return '${_keyPrefix}_$uid';
  }

  // ===================== المسارات =====================

  Future<String> _filePathFor(ExamPaperModel paper) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}/$_folderName');
    if (!await folder.exists()) await folder.create(recursive: true);
    return '${folder.path}/${paper.localFileName}';
  }

  Future<bool> isDownloaded(ExamPaperModel paper) async {
    try {
      return File(await _filePathFor(paper)).exists();
    } catch (e) {
      debugPrint('PaperDownloadsService: exists check failed: $e');
      return false;
    }
  }

  // ===================== التنزيل =====================

  /// تنزيل الملف وحفظه محلياً، وإرجاع مساره.
  Future<String?> download(
    ExamPaperModel paper, {
    void Function(double progress)? onProgress,
  }) async {
    if (paper.fileUrl.isEmpty) return null;

    try {
      final path = await _filePathFor(paper);
      await _dio.download(
        paper.fileUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      await _saveMetadata(paper);
      return path;
    } catch (e) {
      debugPrint('PaperDownloadsService: download failed ${paper.id}: $e');
      return null;
    }
  }

  /// فتح الملف المحمَّل بالتطبيق الافتراضي للجهاز.
  Future<bool> open(ExamPaperModel paper) async {
    try {
      final path = await _filePathFor(paper);
      if (!await File(path).exists()) return false;
      final result = await OpenFilex.open(path);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('PaperDownloadsService: open failed ${paper.id}: $e');
      return false;
    }
  }

  /// حذف الملف المحمَّل لتحرير المساحة.
  Future<void> deleteLocal(ExamPaperModel paper) async {
    try {
      final file = File(await _filePathFor(paper));
      if (await file.exists()) await file.delete();
      await _removeMetadata(paper.id);
    } catch (e) {
      debugPrint('PaperDownloadsService: delete failed ${paper.id}: $e');
    }
  }

  // ===================== البيانات الوصفية =====================

  /// قائمة النماذج المحمَّلة، منقّاة من أي ملف حُذف من خارج التطبيق.
  Future<List<Map<String, dynamic>>> getDownloaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = (json.decode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final documents = await getApplicationDocumentsDirectory();
      final valid = <Map<String, dynamic>>[];
      for (final item in decoded) {
        final path = '${documents.path}/$_folderName/paper_${item['id']}.pdf';
        if (await File(path).exists()) valid.add(item);
      }

      if (valid.length != decoded.length) {
        await prefs.setString(_storageKey, json.encode(valid));
      }
      return valid;
    } catch (e) {
      debugPrint('PaperDownloadsService: metadata read failed: $e');
      return [];
    }
  }

  Future<int> totalSizeBytes() async {
    var total = 0;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final folder = Directory('${documents.path}/$_folderName');
      if (!await folder.exists()) return 0;
      await for (final entity in folder.list()) {
        if (entity is File) total += await entity.length();
      }
    } catch (e) {
      debugPrint('PaperDownloadsService: size scan failed: $e');
    }
    return total;
  }

  Future<void> _saveMetadata(ExamPaperModel paper) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getDownloaded()
      ..removeWhere((item) => item['id'] == paper.id);

    items.add({
      'id': paper.id,
      'title': paper.title,
      'collegeId': paper.collegeId,
      'year': paper.year,
      'type': paper.type.code,
      'downloadedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_storageKey, json.encode(items));
  }

  Future<void> _removeMetadata(String paperId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getDownloaded()
      ..removeWhere((item) => item['id'] == paperId);
    await prefs.setString(_storageKey, json.encode(items));
  }
}
