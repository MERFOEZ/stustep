import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/video_encryption_service.dart';
import '../../core/services/video_download_service.dart';

/// مشغّل الفيديو الآمن المتكامل
/// يدمج:
///   • البث المباشر (Online) عبر URL
///   • التشغيل الأوفلاين من ملف .enc مفكوك لحظياً
///   • التحميل المشفر AES-256 بدون أي .mp4 على القرص
///   • الإتلاف التلقائي للملف المؤقت عند dispose()
class SecureVideoPlayerScreen extends StatefulWidget {
  final String videoTitle;

  /// معرف فريد للفيديو — يُستخدم لتسمية الملف المشفر (.enc)
  final String videoId;

  /// الرابط المباشر من Archive.org
  final String onlineUrl;

  /// تدرج ألوان يُستخدم في شريط العنوان
  final Gradient? gradient;

  /// معرف الدورة للبحث في المجلد الصحيح
  final String courseId;

  const SecureVideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.videoId,
    required this.onlineUrl,
    this.gradient,
    this.courseId = '',
  });

  @override
  State<SecureVideoPlayerScreen> createState() =>
      _SecureVideoPlayerScreenState();
}

class _SecureVideoPlayerScreenState extends State<SecureVideoPlayerScreen>
    with TickerProviderStateMixin {
  // ─── Video Controller ───────────────────────────────────────────────────
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;

  // ─── State Flags ────────────────────────────────────────────────────────
  bool _isOfflineAvailable = false;
  bool _isDownloading = false;
  bool _isDecrypting = false;
  bool _isFullscreen = false;
  bool _hasError = false;
  String _errorMessage = '';

  // ─── Download Progress ──────────────────────────────────────────────────
  double _downloadProgress = 0.0;

  // ─── Temp File Path ─────────────────────────────────────────────────────
  String? _tempFilePath; // يُحذف في dispose()

  // ─── Position / Duration ────────────────────────────────────────────────
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // ─── Animations ─────────────────────────────────────────────────────────
  late AnimationController _controlsFadeController;
  late AnimationController _playPulseController;
  late Animation<double> _playPulseAnim;

  @override
  void initState() {
    super.initState();
    _controlsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _playPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _playPulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _playPulseController, curve: Curves.easeOut),
    );
    _initialize();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  التهيئة: تحديد حالة Online/Offline وتحميل المشغّل
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _initialize() async {
    final offline = await VideoDownloadService.isDownloaded(widget.videoId, courseId: widget.courseId);
    if (mounted) {
      setState(() => _isOfflineAvailable = offline);
    }
    await _initPlayer(offline);
  }

  Future<void> _initPlayer(bool useOffline) async {
    try {
      await _controller?.dispose();
      _controller = null;
      setState(() {
        _isInitialized = false;
        _hasError = false;
      });

      VideoPlayerController controller;

      if (useOffline) {
        // ── وضع أوفلاين: فك التشفير اللحظي ──────────────────────────────
        setState(() => _isDecrypting = true);

        // ═══ استخدام resolveFilePath بدلاً من getEncFilePath ═══
        // يبحث في المجلد الصحيح: stustep_videos/{courseId}/{videoId}.stustep
        // مع fallback للمسار القديم المسطح للتوافق
        final encPath = await VideoEncryptionService.resolveFilePath(
          widget.videoId,
          courseId: widget.courseId,
        );
        final tempPath = await VideoEncryptionService.decryptToTemp(
          encFilePath: encPath,
          videoId: widget.videoId,
        );

        _tempFilePath = tempPath;
        setState(() => _isDecrypting = false);

        controller = VideoPlayerController.file(File(tempPath));
      } else {
        // ── وضع أونلاين: بث مباشر من Archive.org ─────────────────────────
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.onlineUrl),
        );
      }

      _controller = controller;
      await controller.initialize();

      controller.addListener(_onVideoProgress);

      setState(() {
        _isInitialized = true;
        _duration = controller.value.duration;
      });

      // تشغيل تلقائي
      await controller.play();
      setState(() => _isPlaying = true);
      _scheduleHideControls();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isDecrypting = false;
        _errorMessage = 'تعذّر تحميل الفيديو: ${e.toString()}';
      });
    }
  }

  void _onVideoProgress() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    setState(() {
      _position = value.position;
      _duration = value.duration;
      _isPlaying = value.isPlaying;
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  التحكم في التشغيل
  // ════════════════════════════════════════════════════════════════════════

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    _playPulseController.forward().then((_) => _playPulseController.reverse());
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      _scheduleHideControls();
    }
  }

  void _onSliderChanged(double value) {
    if (_controller == null) return;
    _controller!.seekTo(
      Duration(milliseconds: (value * _duration.inMilliseconds).round()),
    );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _skip(int seconds) {
    if (_controller == null) return;
    final newPos = _position + Duration(seconds: seconds);
    _controller!.seekTo(
      newPos.isNegative
          ? Duration.zero
          : newPos > _duration
          ? _duration
          : newPos,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  منطق التحميل المشفر
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      await VideoDownloadService.downloadAndEncrypt(
        videoId: widget.videoId,
        url: widget.onlineUrl,
        title: widget.videoTitle,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isOfflineAvailable = true;
          _downloadProgress = 1.0;
        });
        _showSnack('✅ تم الحفظ بتشفير AES-256 — متاح أوفلاين');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        _showSnack('❌ فشل التحميل: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteDownload() async {
    await VideoDownloadService.deleteDownload(widget.videoId);
    // إعادة التشغيل أونلاين بعد حذف التحميل
    setState(() => _isOfflineAvailable = false);
    await _initPlayer(false);
    if (mounted) _showSnack('🗑 تم حذف النسخة المحفوظة');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  dispose: الإتلاف التلقائي للملف المؤقت
  // ════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.pause();
    _controller?.dispose();
    _controlsFadeController.dispose();
    _playPulseController.dispose();

    // ← الإتلاف التلقائي: مسح الملف المؤقت المفكوك فوراً
    if (_tempFilePath != null) {
      VideoEncryptionService.deleteTemp(_tempFilePath!);
    }

    // إعادة الاتجاه الطبيعي للجهاز
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  Build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── شريط العنوان ─────────────────────────────────────────────
            if (!_isFullscreen) _buildAppBar(isDark, primaryColor),

            // ── منطقة الفيديو ─────────────────────────────────────────────
            Expanded(
              flex: _isFullscreen ? 1 : 0,
              child: AspectRatio(
                aspectRatio:
                    _isInitialized && _controller != null
                        ? _controller!.value.aspectRatio
                        : 16 / 9,
                child: GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTapDown: (details) {
                    final width = MediaQuery.of(context).size.width;
                    if (details.localPosition.dx < width / 2) {
                      _skip(-10);
                    } else {
                      _skip(10);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // الفيديو
                      _buildVideoLayer(),
                      // Overlay التحكم
                      if (_showControls) _buildControlsOverlay(primaryColor),
                      // مؤشر فك التشفير
                      if (_isDecrypting) _buildDecryptingIndicator(),
                      // شارة الحالة
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildStatusBadge(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── لوحة المعلومات والتحكم (أوفلاين/حذف/حجم) ────────────────
            if (!_isFullscreen) ...[
              Expanded(child: _buildInfoPanel(isDark, primaryColor)),
            ],
          ],
        ),
      ),
    );
  }

  // ────────────────────────────── Widgets ──────────────────────────────────

  Widget _buildAppBar(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient:
            widget.gradient ??
            LinearGradient(
              colors: [primaryColor, primaryColor.withAlpha(180)],
            ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.videoTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // زر حذف التحميل
          if (_isOfflineAvailable)
            IconButton(
              tooltip: 'حذف التحميل',
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _initPlayer(_isOfflineAvailable),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'جاري التحميل...',
                style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
      );
    }

    return VideoPlayer(_controller!);
  }

  Widget _buildControlsOverlay(Color primaryColor) {
    final progress =
        _duration.inMilliseconds > 0
            ? _position.inMilliseconds / _duration.inMilliseconds
            : 0.0;

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xCC000000),
              Color(0x00000000),
              Color(0x00000000),
              Color(0xCC000000),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── صف علوي ────────────────────────────────────────────────
            const SizedBox(height: 8),

            // ── أزرار التحكم الوسطى ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlBtn(
                  icon: Icons.replay_10,
                  onTap: () => _skip(-10),
                ),
                const SizedBox(width: 32),
                // زر Play/Pause مع animation
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: ScaleTransition(
                    scale: _playPulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withAlpha(120),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                _controlBtn(
                  icon: Icons.forward_10,
                  onTap: () => _skip(10),
                ),
              ],
            ),

            // ── شريط التقدم والوقت ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                      overlayColor: primaryColor.withAlpha(60),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: _isInitialized ? _onSliderChanged : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleFullscreen,
                              child: Icon(
                                _isFullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _controlBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isOffline = _isOfflineAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOffline ? Colors.green.shade700 : Colors.blue.shade700,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOffline ? Colors.green : Colors.blue).withAlpha(80),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.lock_rounded : Icons.wifi_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isOffline ? 'أوفلاين مشفّر' : 'بث مباشر',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecryptingIndicator() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder:
                  (_, v, __) => CircularProgressIndicator(
                    value: null,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 3,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🔓 جاري فك التشفير...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AES-256-CBC',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF4F4F8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── عنوان الفيديو ───────────────────────────────────────────────
          Text(
            widget.videoTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 6),

          // ── شارة المصدر ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.cloud_rounded, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Archive.org • ${_isOfflineAvailable ? "محفوظ محلياً (مشفّر)" : "بث مباشر"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── زر التحميل / الحالة ─────────────────────────────────────────
          _buildDownloadSection(primaryColor),

          const SizedBox(height: 24),

          // ── بطاقة الأمان ────────────────────────────────────────────────
          _buildSecurityCard(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildDownloadSection(Color primaryColor) {
    if (_isOfflineAvailable) {
      return FutureBuilder<String>(
        future: VideoDownloadService.getFileSizeMB(widget.videoId, courseId: widget.courseId),
        builder: (_, snap) {
          final size = snap.data ?? '...';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withAlpha(60)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'متاح أوفلاين',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'ملف مشفّر • $size',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.lock_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  onPressed: null,
                  tooltip: 'محمي بـ AES-256',
                ),
              ],
            ),
          );
        },
      );
    }

    if (_isDownloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'جاري التحميل والتشفير...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🔐 يُشفَّر الملف تلقائياً بـ AES-256 — لا يُحفظ .mp4',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    // زر التحميل
    return GestureDetector(
      onTap: _startDownload,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha(180),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text(
              'تحميل للمشاهدة أوفلاين',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'AES-256',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(bool isDark, Color primaryColor) {
    final items = [
      ('🔐', 'تشفير AES-256-CBC', 'معيار عسكري لحماية البيانات'),
      ('📁', 'Sandbox التطبيق', 'محفوظ داخل بيئة التطبيق المعزولة فقط'),
      ('🔥', 'إتلاف تلقائي', 'الملف المؤقت يُمسح فور إغلاق المشغّل'),
      ('🚫', 'لا توجد ملفات .mp4', 'يستحيل تشغيله من أي مشغّل خارجي'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withAlpha(10)
                : primaryColor.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'طبقات الحماية النشطة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
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
    );
  }

  // ══════════════════════════════ Dialogs ══════════════════════════════════

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('حذف التحميل؟', style: TextStyle(fontFamily: 'Cairo')),
            content: const Text(
              'سيتم حذف الملف المشفّر وستحتاج إلى إعادة التحميل للمشاهدة أوفلاين.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteDownload();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
    );
  }

  // ══════════════════════════════ Helpers ══════════════════════════════════

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
