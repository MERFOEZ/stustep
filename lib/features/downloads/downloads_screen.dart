import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/services/download_manager_provider.dart';
import '../../core/services/video_download_service.dart';
import 'course_downloads_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _courseGroups = [];
  bool _isLoading = true;
  String _totalSize = '0 MB';
  late AnimationController _shimmerController;

  /// آخر قيمة معروفة لعدّاد الاكتمال — لمراقبة التغيير التفاعلي
  int _lastCompletedCount = -1;

  // Curated cinematic gradients
  static const List<List<Color>> _gradientPairs = [
    [Color(0xFF6200EE), Color(0xFF9C27B0)],
    [Color(0xFF00C853), Color(0xFF00E676)],
    [Color(0xFFD500F9), Color(0xFFE040FB)],
    [Color(0xFFFF1744), Color(0xFFFF5252)],
    [Color(0xFFFFAB00), Color(0xFFFFD54F)],
    [Color(0xFF00BCD4), Color(0xFF00E5FF)],
    [Color(0xFF304FFE), Color(0xFF448AFF)],
    [Color(0xFFC51162), Color(0xFFFF4081)],
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadCourseGroups();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseGroups() async {
    print('🖥️ [DownloadsScreen] _loadCourseGroups() — جاري جلب المجلدات...');
    final groups = await VideoDownloadService.getCourseGroups();
    final size = await VideoDownloadService.getTotalDownloadSizeFormatted();
    print('🖥️ [DownloadsScreen] النتيجة: ${groups.length} مجلد | الحجم: $size');
    if (mounted) {
      setState(() {
        _courseGroups = groups;
        _totalSize = size;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // الاستماع للتحميلات النشطة في الوقت الفعلي
    final downloadProvider = context.watch<DownloadManagerProvider>();
    final activeDownloads = downloadProvider.activeDownloads;
    final hasActive = activeDownloads.isNotEmpty;

    // ═══ التحديث التفاعلي: هل اكتمل تحميل جديد؟ ═══
    // context.watch يعيد البناء عند كل notifyListeners()
    // نتحقق: هل تغيّر عدّاد الاكتمال؟ → أعد جلب المجلدات من SharedPreferences
    final currentCompleted = downloadProvider.completedCount;
    if (_lastCompletedCount != -1 && currentCompleted != _lastCompletedCount) {
      // ScheduleMicrotask لتجنب setState أثناء build
      Future.microtask(() => _loadCourseGroups());
    }
    _lastCompletedCount = currentCompleted;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF6200EE).withValues(alpha: 0.03),
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : (!hasActive && _courseGroups.isEmpty)
                ? _buildEmptyState(isDark)
                : _buildContent(isDark, activeDownloads),
      ),
    );
  }

  // ──────────────────────────── Loading ─────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── Empty ───────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cinematic empty icon with glow
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6200EE).withValues(alpha: 0.15),
                    const Color(0xFF9C27B0).withValues(alpha: 0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6200EE).withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.movie_filter_outlined,
                size: 64,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_downloads'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بتحميل الدروس من صفحة الدورة لمشاهدتها بدون إنترنت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── Content ─────────────────────────────

  Widget _buildContent(bool isDark, List<DownloadTask> activeDownloads) {
    return CustomScrollView(
      slivers: [
        // Storage bar at top
        SliverToBoxAdapter(
          child: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: _buildStorageBar(isDark),
          ),
        ),

        // ═══════════════ قسم التحميلات النشطة (Active Downloads) ═══════════════
        if (activeDownloads.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: FadeInDown(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    // أيقونة متحركة
                    _AnimatedDownloadIcon(controller: _shimmerController),
                    const SizedBox(width: 10),
                    Text(
                      'جاري التحميل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge عدد التحميلات
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6200EE).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeDownloads.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6200EE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = activeDownloads[index];
                  return FadeInDown(
                    delay: Duration(milliseconds: 80 * index),
                    duration: const Duration(milliseconds: 500),
                    child: _buildActiveDownloadCard(task, isDark),
                  );
                },
                childCount: activeDownloads.length,
              ),
            ),
          ),
        ],

        // ═══════════════ عنوان المجلدات المحملة ═══════════════
        if (_courseGroups.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: FadeInDown(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 600),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6200EE), Color(0xFFE91E63)],
                  ).createShader(bounds),
                  child: Text(
                    'downloads'.tr(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
          ),
          // Course folders grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = _courseGroups[index];
                  final colors = _gradientPairs[index % _gradientPairs.length];

                  return FadeInUp(
                    delay: Duration(milliseconds: 120 * index),
                    duration: const Duration(milliseconds: 800),
                    child: _buildCourseFolderCard(
                      context,
                      group: group,
                      gradientColors: colors,
                      isDark: isDark,
                    ),
                  );
                },
                childCount: _courseGroups.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────── Active Download Card (YouTube-style) ─────────

  Widget _buildActiveDownloadCard(DownloadTask task, bool isDark) {
    final percent = (task.progress * 100).toInt();
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الفيديو + زر إلغاء
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                // أيقونة الدورة مع gradient
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // عنوان الفيديو والدورة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title.isNotEmpty ? task.title : 'فيديو قيد التحميل',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.courseName.isNotEmpty ? task.courseName : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // نسبة التقدم
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                // زر الإلغاء
                IconButton(
                  onPressed: () {
                    context.read<DownloadManagerProvider>().cancelDownload(task.videoId);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // ═══ شريط التقدم الخطي (YouTube-style) ═══
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: task.progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    // الخلفية
                    Container(
                      height: 4,
                      width: double.infinity,
                      color: primaryColor.withValues(alpha: 0.08),
                    ),
                    // شريط التقدم مع gradient
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              const Color(0xFFE91E63),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Storage Bar ─────────────────────────────

  Widget _buildStorageBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6200EE).withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Storage icon with glow
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6200EE).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المساحة المستهلكة',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _totalSize,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF311B92),
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated neon line indicator
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF6200EE)
                                .withValues(alpha: 0.3 + 0.7 * _shimmerController.value),
                            const Color(0xFFE91E63)
                                .withValues(alpha: 0.7 - 0.4 * _shimmerController.value),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6200EE)
                                .withValues(alpha: 0.3 * _shimmerController.value),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────── Course Folder Card ──────────────────────────

  Widget _buildCourseFolderCard(
    BuildContext context, {
    required Map<String, dynamic> group,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    final courseId = group['courseId'] as String;
    final courseName = group['courseName'] as String;
    final coverImage = group['coverImage'] as String;
    final videoCount = group['videoCount'] as int;
    final heroTag = 'course_cover_$courseId';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) =>
                CourseDownloadsScreen(
              courseId: courseId,
              courseName: courseName,
              coverImage: coverImage,
              heroTag: heroTag,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
        // Refresh after returning
        _loadCourseGroups();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: cover image or gradient
              Hero(
                tag: heroTag,
                child: coverImage.isNotEmpty
                    ? Image.network(
                        coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.movie_rounded, size: 48, color: Colors.white54),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.movie_rounded, size: 48, color: Colors.white54),
                        ),
                      ),
              ),
              // Dark gradient overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Glassmorphism overlay at top-left
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Video count badge — glassy
              Positioned(
                top: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '$videoCount دروس',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Course name at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Small accent line
                      Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════ أيقونة التحميل المتحركة ═══════════════

class _AnimatedDownloadIcon extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDownloadIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6200EE).withValues(
              alpha: 0.1 + 0.08 * controller.value,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6200EE).withValues(
                  alpha: 0.15 * controller.value,
                ),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.downloading_rounded,
            color: const Color(0xFF6200EE).withValues(
              alpha: 0.7 + 0.3 * controller.value,
            ),
            size: 20,
          ),
        );
      },
    );
  }
}
