import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/services/download_manager_provider.dart';
import '../../core/services/video_download_service.dart';
import '../../core/services/video_encryption_service.dart';
import '../../core/services/video_metadata_service.dart';
import '../../shared/widgets/download_state_button.dart';
import '../../shared/widgets/cinematic_lesson_badge.dart';
import '../video_player/secure_video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String title;
  final String coverImage;
  final Gradient gradient;
  final List<dynamic> lectures;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.coverImage,
    required this.gradient,
    required this.lectures,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int? _selectedLectureIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _currentTempFile;

  @override
  void initState() {
    super.initState();
    _checkInitialDownloadStatus();
  }

  Future<void> _checkInitialDownloadStatus() async {
    final provider = context.read<DownloadManagerProvider>();
    for (int i = 0; i < widget.lectures.length; i++) {
      final videoId = _getVideoId(i);
      await provider.checkAndMarkDownloaded(videoId, courseId: widget.courseId);
    }
  }

  String _getVideoId(int index) {
    // If the lecture object has an id, use it, else generate one.
    final lesson = widget.lectures[index] as Map<String, dynamic>?;
    if (lesson != null && lesson['id'] != null) {
      return lesson['id'].toString();
    }
    // Generate a unique ID based on course title and index if no ID provided
    return '${widget.title.hashCode}_vid_$index';
  }

  /// إشعار سينمائي عائم بخلفية زجاجية
  void _showCinematicSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError
                      ? [
                          Colors.red.shade900.withValues(alpha: 0.7),
                          Colors.red.shade700.withValues(alpha: 0.5),
                        ]
                      : [
                          const Color(0xFF6200EE).withValues(alpha: 0.7),
                          const Color(0xFF9C27B0).withValues(alpha: 0.5),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.movie_filter_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  Future<void> _playVideo(int index) async {
    if (_selectedLectureIndex == index) return;
    
    setState(() {
      _selectedLectureIndex = index;
    });

    await _cleanupPlayer();

    final lesson = widget.lectures[index] as Map<String, dynamic>;
    final videoUrl = lesson['url']?.toString() ?? '';
    final videoId = _getVideoId(index);

    debugPrint('=== VIDEO_URL_DEBUG: $videoUrl ===');

    if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
      if (mounted) {
        _showCinematicSnackBar('رابط الفيديو غير متوفر أو غير صالح', isError: true);
      }
      return;
    }

    try {
      final isDownloaded = await VideoDownloadService.isDownloaded(videoId, courseId: widget.courseId);
      if (isDownloaded) {
        final encPath = await VideoEncryptionService.resolveFilePath(
          videoId,
          courseId: widget.courseId,
        );
        _currentTempFile = await VideoEncryptionService.decryptToTemp(
          encFilePath: encPath, 
          videoId: videoId,
        );
        _videoPlayerController = VideoPlayerController.file(File(_currentTempFile!));
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
            'Connection': 'keep-alive',
            'Accept': '*/*',
          },
        );
      }

      await _videoPlayerController!.initialize();

      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            autoInitialize: true,
            allowedScreenSleep: false,
            looping: false,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          );
        });
      }
    } catch (e) {
      debugPrint('=== VIDEO_INIT_ERROR: $e ===');
      debugPrint("Error initializing video: $e");
    }
  }

  Future<void> _cleanupPlayer() async {
    _chewieController?.dispose();
    _chewieController = null;
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    if (_currentTempFile != null) {
      await VideoEncryptionService.deleteTemp(_currentTempFile!);
      _currentTempFile = null;
    }
  }

  Future<void> _downloadVideo(int index) async {
    final lesson = widget.lectures[index] as Map<String, dynamic>;
    final downloadUrl = lesson['url']?.toString() ?? '';
    final downloadTitle = lesson['title']?.toString() ?? lesson['name']?.toString() ?? '';
    final videoId = _getVideoId(index);

    debugPrint('=== START DOWNLOADING: $downloadUrl ===');

    if (downloadUrl.isEmpty) {
      _showCinematicSnackBar('رابط الفيديو غير متوفر للتحميل', isError: true);
      return;
    }

    final provider = context.read<DownloadManagerProvider>();

    // التحقق من الحد الأقصى للتحميلات المتزامنة
    if (provider.activeCount >= DownloadManagerProvider.maxConcurrent) {
      _showCinematicSnackBar('تمت إضافة الفيديو لقائمة الانتظار ⏳ (${provider.activeCount} تحميلات نشطة)');
    } else {
      _showCinematicSnackBar('تم إضافة الفيديو إلى قائمة التنزيلات 🍿');
    }

    // بدء التحميل عبر DownloadManagerProvider
    final String fullTitle = '${widget.title} - $downloadTitle';

    await provider.startDownload(
      videoId: videoId,
      courseId: widget.courseId,
      courseName: widget.title,
      title: fullTitle,
      url: downloadUrl,
      coverImage: widget.coverImage,
    );

    // التحقق من النتيجة
    if (mounted) {
      final status = provider.getStatus(videoId);
      if (status == DownloadStatus.completed) {
        _showCinematicSnackBar('تم تحميل الدرس بنجاح ✨');
      } else if (status == DownloadStatus.failed) {
        _showCinematicSnackBar('فشل تحميل الدرس، يرجى المحاولة لاحقاً', isError: true);
      }
    }
  }

  /// فتح المشغل السينمائي بقائمة التشغيل الكاملة
  void _openCinematicPlayer(int startIndex) {
    // بناء قائمة التشغيل من جميع الدروس
    final playlist = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.lectures.length; i++) {
      final lesson = widget.lectures[i] as Map<String, dynamic>;
      playlist.add({
        'videoId': _getVideoId(i),
        'title': lesson['title']?.toString() ?? lesson['name']?.toString() ?? 'الدرس ${i + 1}',
        'url': lesson['url']?.toString() ?? '',
      });
    }

    // تنظيف المشغل المدمج أولاً
    _cleanupPlayer();
    setState(() => _selectedLectureIndex = null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecureVideoPlayerScreen(
          playlist: playlist,
          initialIndex: startIndex,
          courseId: widget.courseId,
          gradient: widget.gradient,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cleanupPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildPlayerSection(),
          _buildCourseHeader(),
          Expanded(
            child: _buildCurriculumSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: widget.gradient,
        color: Colors.black,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_selectedLectureIndex == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: widget.coverImage.isEmpty
                          ? const Icon(Icons.video_library, size: 80, color: Colors.white)
                          : Image.network(
                              widget.coverImage,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.video_library, size: 80, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'اختر درساً للبدء',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
              Chewie(controller: _chewieController!)
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),
              
            // Back button overlay
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // زر فتح المشغل السينمائي الكامل
            if (_selectedLectureIndex != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, color: Colors.white),
                  tooltip: 'فتح المشغل السينمائي',
                  onPressed: () => _openCinematicPlayer(_selectedLectureIndex!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.lectures.length} دروس',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumSection() {
    if (widget.lectures.isEmpty) {
      return Center(
        child: Text(
          'لا توجد دروس حالياً',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: widget.lectures.length,
      itemBuilder: (context, index) {
        final lesson = widget.lectures[index] as Map<String, dynamic>;
        final lessonTitle = lesson['title']?.toString() ?? lesson['name']?.toString() ?? '';
        final videoUrl = lesson['url']?.toString() ?? '';
        final isSelected = _selectedLectureIndex == index;
        final videoId = _getVideoId(index);

        // الدقة الديناميكية: تحليل الاسم/URL أولاً
        final parsedResolution = VideoMetadataService.parseResolution(
          videoUrl,
          title: lessonTitle,
        );

        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: index * 100),
          child: FutureBuilder<VideoMeta>(
            future: VideoMetadataService.getFullMetadata(
              videoId,
              courseId: widget.courseId,
              videoUrl: videoUrl,
              title: lessonTitle,
            ),
            builder: (context, snapshot) {
              final meta = snapshot.data;
              return _buildLectureCard(
                index: index,
                title: lessonTitle,
                videoUrl: videoUrl,
                isSelected: isSelected,
                duration: meta?.duration ?? '',
                fileSize: meta?.fileSize ?? '',
                resolution: meta?.resolution ?? parsedResolution,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLectureCard({
    required int index,
    required String title,
    required String videoUrl,
    required bool isSelected,
    String duration = '',
    String fileSize = '',
    String resolution = '',
  }) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _playVideo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : theme.cardColor),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.5)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.12)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // ═══ Play Icon / Number ═══
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : primary.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isSelected ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isSelected ? Colors.white : primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            
            // ═══ Title + Badges ═══
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? primary : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // ═══ كبسولات البيانات الوصفية (Frosted Glass Badges) ═══
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // ترتيب الدرس
                      CinematicBadge(
                        icon: Icons.school_rounded,
                        label: 'الدرس ${index + 1}',
                        accentColor: isSelected ? primary : Colors.grey,
                        isDark: isDark,
                      ),
                      // المدة
                      CinematicBadge.duration(
                        duration: duration,
                        isDark: isDark,
                      ),
                      // الدقة
                      CinematicBadge.resolution(
                        resolution: resolution,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ═══ Download Button ═══
            DownloadStateButton(
              videoId: _getVideoId(index),
              accentColor: primary,
              onDownloadTap: () => _downloadVideo(index),
              onPlayTap: () => _playVideo(index),
            ),
          ],
        ),
      ),
    );
  }
}

