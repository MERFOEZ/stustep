import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// خدمة رفع الملفات الخاصة بموديول القبول (صور السكنات وملفات النماذج).
///
/// ملاحظتان تصميميتان:
///
/// 1) هذه الخدمة تكرّر منطق الرفع الموجود في `ChatService.uploadFile` **عمداً**.
///    إعادة تصنيع تلك الدالة تعني تعديل أنشط ملف في المشروع (ملف زميل)،
///    وتكلفة التعارض أعلى بكثير من تكلفة تكرار اثني عشر سطراً.
///
/// 2) عزل الرفع خلف خدمة واحدة يجعل الانتقال مستقبلاً إلى Firebase Storage
///    تعديلاً في ملف واحد فقط، بلا مساس بأي شاشة.
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  static const String _cloudName = 'dwms0orf1';
  static const String _uploadPreset = 'h44lwdga';

  static const int maxImageCount = 6;

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

  /// رفع ملف واحد وإرجاع رابطه الآمن.
  Future<String> uploadFile(File file) async {
    final request = http.MultipartRequest('POST', _uploadUri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Upload failed: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null) {
      throw Exception('Upload succeeded but secure_url was missing');
    }
    return secureUrl;
  }

  Future<String> uploadImage(File file) => uploadFile(file);

  Future<String> uploadPdf(File file) => uploadFile(file);

  /// رفع عدة ملفات بالتسلسل مع تقرير التقدّم.
  ///
  /// اخترنا الرفع بالتسلسل لا بالتوازي لأن اتصال الطالب غالباً محدود،
  /// والرفع المتوازي لعدة صور يرفع نسبة الفشل الكلي.
  Future<List<String>> uploadMultiple(
    List<File> files, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (var index = 0; index < files.length; index++) {
      try {
        urls.add(await uploadFile(files[index]));
      } catch (e) {
        debugPrint('StorageService: failed to upload file $index: $e');
        rethrow;
      }
      onProgress?.call(index + 1, files.length);
    }
    return urls;
  }
}
