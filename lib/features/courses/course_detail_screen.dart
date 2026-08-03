import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/services/video_download_service.dart';
import '../../core/services/video_encryption_service.dart';

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
  
  // Track download states: 'downloaded', 'not_downloaded', or double representing progress
  final Map<String, dynamic> _downloadStatus = {};
  String? _currentTempFile;

  @override
  void initState() {
    super.initState();
    _checkInitialDownloadStatus();
  }

  Future<void> _checkInitialDownloadStatus() async {
    for (int i = 0; i < widget.lectures.length; i++) {
      final videoId = _getVideoId(i);
      final isDownloaded = await VideoDownloadService.isDownloaded(videoId);
      if (mounted) {
        setState(() {
          _downloadStatus[videoId] = isDownloaded ? 'downloaded' : 'not_downloaded';
        });
      }
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

    print('=== VIDEO_URL_DEBUG: $videoUrl ===');

    if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
      if (mounted) {
        _showCinematicSnackBar('رابط الفيديو غير متوفر أو غير صالح', isError: true);
      }
      return;
    }

    try {
      final isDownloaded = await VideoDownloadService.isDownloaded(videoId);
      if (isDownloaded) {
        final encPath = await VideoEncryptionService.getEncFilePath(videoId);
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
      print('=== VIDEO_INIT_ERROR: $e ===');
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

    print('=== START DOWNLOADING: $downloadUrl ===');

    if (downloadUrl.isEmpty) {
      _showCinematicSnackBar('رابط الفيديو غير متوفر للتحميل', isError: true);
      return;
    }

    setState(() {
      _downloadStatus[videoId] = 0.0;
    });

    // إشعار سينمائي فوري عند بدء التنزيل
    _showCinematicSnackBar('تم إضافة الفيديو إلى قائمة التنزيلات 🍿');

    try {
      final String fullTitle = '${widget.title} - $downloadTitle';
      await VideoDownloadService.downloadAndEncrypt(
        videoId: videoId,
        url: downloadUrl,
        title: fullTitle,
        courseId: widget.courseId,
        courseName: widget.title,
        coverImage: widget.coverImage,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadStatus[videoId] = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadStatus[videoId] = 'downloaded';
        });
        _showCinematicSnackBar('تم تحميل الدرس بنجاح ✨');
      }
    } catch (e) {
      print('=== DOWNLOAD ERROR: $e ===');
      if (mounted) {
        setState(() {
          _downloadStatus[videoId] = 'not_downloaded';
        });
        _showCinematicSnackBar('فشل تحميل الدرس، يرجى المحاولة لاحقاً', isError: true);
      }
    }
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
        final videoId = _getVideoId(index);
        final status = _downloadStatus[videoId] ?? 'not_downloaded';
        final isSelected = _selectedLectureIndex == index;

        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 50),
          child: _buildLectureCard(
            index: index,
            title: lessonTitle,
            videoUrl: videoUrl,
            status: status,
            isSelected: isSelected,
          ),
        );
      },
    );
  }

  Widget _buildLectureCard({
    required int index,
    required String title,
    required String videoUrl,
    required dynamic status,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return GestureDetector(
      onTap: () => _playVideo(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : theme.cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? primary.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Play Icon / Number
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primary : primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.pause : Icons.play_arrow,
                color: isSelected ? Colors.white : primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الدرس ${(index + 1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Download Action
            _buildDownloadAction(index, title, videoUrl, status),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadAction(int index, String title, String videoUrl, dynamic status) {
    if (status == 'downloaded') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
      );
    } else if (status is double) {
      // Downloading
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: status,
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    } else {
      // not_downloaded
      return IconButton(
        icon: const Icon(Icons.download_rounded, color: Colors.grey),
        onPressed: () => _downloadVideo(index),
      );
    }
  }
}
