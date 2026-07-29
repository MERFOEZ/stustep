import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/services/video_download_service.dart';
import '../../core/theme/app_theme.dart';
import '../video_player/secure_video_player_screen.dart';

/// شاشة فيديوهات الدورة المحملة — مع حذف فردي وأنميشن سينمائي
class CourseDownloadsScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String coverImage;
  final String heroTag;

  const CourseDownloadsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.coverImage,
    required this.heroTag,
  });

  @override
  State<CourseDownloadsScreen> createState() => _CourseDownloadsScreenState();
}

class _CourseDownloadsScreenState extends State<CourseDownloadsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  String _courseSize = '0 MB';

  // Animation controllers for pulse effect on play buttons
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadVideos();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    final videos = await VideoDownloadService.getVideosByCourse(widget.courseId);
    final size = await VideoDownloadService.getCourseTotalSize(widget.courseId);
    if (mounted) {
      setState(() {
        _videos = videos;
        _courseSize = size;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVideo(String videoId, int index) async {
    // Show glass confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _buildDeleteDialog(context),
    );

    if (confirmed == true) {
      await VideoDownloadService.deleteDownload(videoId);
      if (mounted) {
        setState(() {
          _videos.removeAt(index);
        });
        _refreshSize();

        // If all videos deleted, go back
        if (_videos.isEmpty) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _refreshSize() async {
    final size = await VideoDownloadService.getCourseTotalSize(widget.courseId);
    if (mounted) {
      setState(() {
        _courseSize = size;
      });
    }
  }

  Widget _buildDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade900.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade400,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'حذف الفيديو؟',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم حذف هذا الفيديو من جهازك نهائياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'حذف',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(isDark),
          if (!_isLoading)
            _buildSizeInfoBar(isDark),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _videos.isEmpty
                    ? _buildEmptyState()
                    : _buildVideoList(isDark),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Hero Header ─────────────────────────────

  Widget _buildHeader(bool isDark) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero cover image
          Hero(
            tag: widget.heroTag,
            child: widget.coverImage.isNotEmpty
                ? Image.network(
                    widget.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient(ctx) as LinearGradient,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient(context) as LinearGradient,
                    ),
                  ),
          ),
          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: FadeInLeft(
              duration: const Duration(milliseconds: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          // Course title at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_videos.length} فيديو محمّل',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Size Info Bar ───────────────────────────

  Widget _buildSizeInfoBar(bool isDark) {
    return FadeInDown(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'حجم المجلد: $_courseSize',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── Empty State ─────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد فيديوهات محملة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Video List ──────────────────────────────

  Widget _buildVideoList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final videoId = video['videoId'] as String;
        final title = video['title'] as String? ?? 'فيديو';
        final downloadDate = video['downloadDate'] as String?;
        final url = video['url'] as String? ?? '';

        return FadeInUp(
          delay: Duration(milliseconds: 80 * index),
          duration: const Duration(milliseconds: 600),
          child: Dismissible(
            key: Key(videoId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                barrierColor: Colors.black54,
                builder: (context) => _buildDeleteDialog(context),
              );
            },
            onDismissed: (direction) async {
              setState(() {
                _videos.removeAt(index);
              });
              await VideoDownloadService.deleteDownload(videoId);
              _refreshSize();
              if (_videos.isEmpty && mounted) {
                Navigator.pop(context);
              }
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: AlignmentDirectional.centerEnd,
              padding: const EdgeInsetsDirectional.only(end: 24),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            child: _buildVideoCard(
              videoId: videoId,
              title: title,
              url: url,
              downloadDate: downloadDate,
              index: index,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────── Video Card ──────────────────────────────

  Widget _buildVideoCard({
    required String videoId,
    required String title,
    required String url,
    required String? downloadDate,
    required int index,
    required bool isDark,
  }) {

    // Gradients for cards
    final List<LinearGradient> gradients = [
      const LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF9C27B0)]),
      const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
      const LinearGradient(colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)]),
      const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5252)]),
      const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)]),
      const LinearGradient(colors: [Color(0xFF304FFE), Color(0xFF448AFF)]),
    ];
    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SecureVideoPlayerScreen(
              videoTitle: title,
              videoId: videoId,
              onlineUrl: url,
              gradient: gradient,
            ),
          ),
        ).then((_) => _loadVideos());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glassmorphism overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Pulsing play button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  // Title and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // File size
                            FutureBuilder<String>(
                              future: VideoDownloadService.getFileSizeMB(videoId),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? '...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                );
                              },
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            // Download date
                            Text(
                              _formatDate(downloadDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Swipe hint / delete button
                  IconButton(
                    onPressed: () => _deleteVideo(videoId, index),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
