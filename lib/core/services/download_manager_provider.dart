import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'video_download_service.dart';

/// حالة التحميل لكل فيديو
enum DownloadStatus {
  /// جاهز للتحميل
  idle,

  /// قيد التحميل حالياً
  downloading,

  /// اكتمل التحميل والتشفير
  completed,

  /// فشل التحميل
  failed,
}

/// يمثل مهمة تحميل فيديو واحد مع جميع بياناتها الوصفية
class DownloadTask {
  final String videoId;
  final String courseId;
  final String courseName;
  final String title;
  final String url;
  final String coverImage;
  double progress;
  DownloadStatus status;
  String? errorMessage;
  CancelToken? _cancelToken;

  DownloadTask({
    required this.videoId,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.url,
    required this.coverImage,
    this.progress = 0.0,
    this.status = DownloadStatus.idle,
    this.errorMessage,
  });

  /// هل يمكن إلغاء هذا التحميل؟
  bool get isCancellable => status == DownloadStatus.downloading;
}

/// مزود إدارة التحميلات المركزي
///
/// يُدير حالة التحميلات في الوقت الفعلي ويمرر التحديثات
/// لجميع الشاشات التي تستمع إليه عبر Provider.
///
/// يمكن لـ [CourseDetailScreen] و [DownloadsScreen] الوصول لنفس
/// الحالة في الوقت الفعلي دون أي ربط يدوي.
class DownloadManagerProvider extends ChangeNotifier {
  /// خريطة المهام النشطة: videoId → DownloadTask
  final Map<String, DownloadTask> _tasks = {};

  /// الحد الأقصى للتحميلات المتزامنة
  static const int maxConcurrent = 3;

  /// قائمة الانتظار
  final List<DownloadTask> _queue = [];

  /// عدّاد اكتمال التحميلات — يزداد عند كل تحميل ناجح
  /// تستخدمه DownloadsScreen لمعرفة متى يجب إعادة جلب المجلدات
  int _completedCount = 0;
  int get completedCount => _completedCount;

  // ══════════════════════ الاستعلام (Queries) ══════════════════════

  /// استرجاع مهمة تحميل محددة بواسطة videoId
  DownloadTask? getTask(String videoId) => _tasks[videoId];

  /// حالة تحميل فيديو محدد
  DownloadStatus getStatus(String videoId) {
    return _tasks[videoId]?.status ?? DownloadStatus.idle;
  }

  /// نسبة تقدم تحميل فيديو محدد (0.0 → 1.0)
  double getProgress(String videoId) {
    return _tasks[videoId]?.progress ?? 0.0;
  }

  /// قائمة التحميلات النشطة (قيد التحميل فقط)
  List<DownloadTask> get activeDownloads {
    return _tasks.values
        .where((t) => t.status == DownloadStatus.downloading)
        .toList();
  }

  /// قائمة جميع المهام (نشطة + مكتملة + فاشلة)
  List<DownloadTask> get allTasks => _tasks.values.toList();

  /// عدد التحميلات النشطة حالياً
  int get activeCount =>
      _tasks.values.where((t) => t.status == DownloadStatus.downloading).length;

  /// هل توجد تحميلات نشطة؟
  bool get hasActiveDownloads => activeCount > 0;

  // ══════════════════════ التحقق السريع ══════════════════════

  /// التحقق من أن الفيديو محمّل مسبقاً (ملف .stustep موجود على القرص)
  Future<bool> isVideoDownloaded(String videoId, {String courseId = ''}) async {
    // أولاً: تحقق من الحالة المحلية
    final task = _tasks[videoId];
    if (task != null && task.status == DownloadStatus.completed) return true;

    // ثانياً: تحقق فعلي من الملف — مع courseId للبحث في المجلد الصحيح
    return await VideoDownloadService.isDownloaded(videoId, courseId: courseId);
  }

  // ══════════════════════ التهيئة الأولية ══════════════════════

  /// تحميل حالة الفيديوهات المحملة مسبقاً (تُستدعى مرة واحدة عند بدء التطبيق)
  Future<void> initializeDownloadedStatus(List<Map<String, String>> videoEntries) async {
    for (final entry in videoEntries) {
      final id = entry['videoId'] ?? '';
      final courseId = entry['courseId'] ?? '';
      if (id.isEmpty) continue;
      final isDownloaded = await VideoDownloadService.isDownloaded(id, courseId: courseId);
      if (isDownloaded && !_tasks.containsKey(id)) {
        _tasks[id] = DownloadTask(
          videoId: id,
          courseId: courseId,
          courseName: entry['courseName'] ?? '',
          title: entry['title'] ?? '',
          url: '',
          coverImage: '',
          status: DownloadStatus.completed,
          progress: 1.0,
        );
      }
    }
    notifyListeners();
  }

  /// تحديث حالة فيديو واحد (مثلاً عند فتح شاشة الدورة)
  Future<void> checkAndMarkDownloaded(String videoId, {String courseId = ''}) async {
    if (_tasks.containsKey(videoId)) return;
    final isDownloaded = await VideoDownloadService.isDownloaded(videoId, courseId: courseId);
    if (isDownloaded) {
      _tasks[videoId] = DownloadTask(
        videoId: videoId,
        courseId: courseId,
        courseName: '',
        title: '',
        url: '',
        coverImage: '',
        status: DownloadStatus.completed,
        progress: 1.0,
      );
      notifyListeners();
    }
  }

  // ══════════════════════ بدء التحميل ══════════════════════

  /// بدء تحميل فيديو جديد
  ///
  /// إذا تجاوز عدد التحميلات النشطة [maxConcurrent]،
  /// يوضع الفيديو في قائمة الانتظار تلقائياً.
  Future<void> startDownload({
    required String videoId,
    required String courseId,
    required String courseName,
    required String title,
    required String url,
    required String coverImage,
  }) async {
    // تجنب التحميل المكرر
    if (_tasks.containsKey(videoId)) {
      final existing = _tasks[videoId]!;
      if (existing.status == DownloadStatus.downloading ||
          existing.status == DownloadStatus.completed) {
        return;
      }
    }

    final task = DownloadTask(
      videoId: videoId,
      courseId: courseId,
      courseName: courseName,
      title: title,
      url: url,
      coverImage: coverImage,
      status: DownloadStatus.downloading,
    );

    _tasks[videoId] = task;
    notifyListeners();

    // التحقق من الحد الأقصى
    if (activeCount > maxConcurrent) {
      _queue.add(task);
      return;
    }

    await _executeDownload(task);
  }

  /// تنفيذ التحميل الفعلي
  Future<void> _executeDownload(DownloadTask task) async {
    final cancelToken = CancelToken();
    task._cancelToken = cancelToken;

    try {
      await VideoDownloadService.downloadAndEncrypt(
        videoId: task.videoId,
        url: task.url,
        title: task.title,
        courseId: task.courseId,
        courseName: task.courseName,
        coverImage: task.coverImage,
        cancelToken: cancelToken,
        onProgress: (progress) {
          task.progress = progress;
          notifyListeners();
        },
      );

      // اكتمال التحميل بنجاح
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task._cancelToken = null;
      _completedCount++; // إشعار DownloadsScreen بضرورة إعادة تحميل المجلدات
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // تم إلغاء التحميل — لا نعتبره خطأ
        task.status = DownloadStatus.idle;
        task.progress = 0.0;
      } else {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.message ?? 'خطأ في الشبكة';
      }
      task._cancelToken = null;
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      task._cancelToken = null;
    }

    notifyListeners();

    // معالجة قائمة الانتظار
    _processQueue();
  }

  /// معالجة المهمة التالية في قائمة الانتظار
  void _processQueue() {
    if (_queue.isEmpty) return;
    if (activeCount >= maxConcurrent) return;

    final nextTask = _queue.removeAt(0);
    if (nextTask.status == DownloadStatus.downloading) {
      _executeDownload(nextTask);
    }
  }

  // ══════════════════════ الإلغاء ══════════════════════

  /// إلغاء تحميل نشط
  void cancelDownload(String videoId) {
    final task = _tasks[videoId];
    if (task == null) return;

    // إلغاء من قائمة الانتظار
    _queue.removeWhere((t) => t.videoId == videoId);

    // إلغاء التحميل النشط
    if (task._cancelToken != null && !task._cancelToken!.isCancelled) {
      task._cancelToken!.cancel('ألغى المستخدم التحميل');
    }

    task.status = DownloadStatus.idle;
    task.progress = 0.0;
    task._cancelToken = null;
    _tasks.remove(videoId);
    notifyListeners();
  }

  // ══════════════════════ الحذف ══════════════════════

  /// حذف فيديو محمّل (من القرص والحالة)
  Future<void> deleteDownload(String videoId) async {
    cancelDownload(videoId);
    await VideoDownloadService.deleteDownload(videoId);
    _tasks.remove(videoId);
    notifyListeners();
  }

  // ══════════════════════ إعادة المحاولة ══════════════════════

  /// إعادة محاولة تحميل فاشل
  Future<void> retryDownload(String videoId) async {
    final task = _tasks[videoId];
    if (task == null || task.status != DownloadStatus.failed) return;

    task.status = DownloadStatus.downloading;
    task.progress = 0.0;
    task.errorMessage = null;
    notifyListeners();

    await _executeDownload(task);
  }

  // ══════════════════════ التنظيف ══════════════════════

  /// إزالة المهام المكتملة والفاشلة من القائمة (لا يحذف الملفات)
  void clearCompletedTasks() {
    _tasks.removeWhere(
      (_, task) =>
          task.status == DownloadStatus.completed ||
          task.status == DownloadStatus.failed,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    // إلغاء جميع التحميلات النشطة
    for (final task in _tasks.values) {
      if (task._cancelToken != null && !task._cancelToken!.isCancelled) {
        task._cancelToken!.cancel('تم إغلاق التطبيق');
      }
    }
    super.dispose();
  }
}
