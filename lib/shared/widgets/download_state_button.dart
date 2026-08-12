import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/download_manager_provider.dart';

/// زر التحميل السينمائي ثلاثي الحالات
///
/// يتبدل تلقائياً بين:
///   • **Idle**: أيقونة تنزيل عادية مع توهج خفيف
///   • **Downloading**: دائرة تقدم مع النسبة المئوية + shimmer + إمكانية الإلغاء
///   • **Completed**: أيقونة "تم" مع نبض خفيف (pulse) وتوهج متدرج
///   • **Failed**: أيقونة إعادة مع تأثير اهتزاز
///
/// يستمع تلقائياً لـ [DownloadManagerProvider] ويتحدث في الوقت الفعلي.
class DownloadStateButton extends StatefulWidget {
  /// معرف الفيديو للاستعلام من Provider
  final String videoId;

  /// يُستدعى عند الضغط في حالة Idle (لبدء التحميل)
  final VoidCallback? onDownloadTap;

  /// يُستدعى عند الضغط في حالة Completed (للتشغيل)
  final VoidCallback? onPlayTap;

  /// حجم الأيقونة
  final double size;

  /// لون رئيسي مخصص (اختياري)
  final Color? accentColor;

  const DownloadStateButton({
    super.key,
    required this.videoId,
    this.onDownloadTap,
    this.onPlayTap,
    this.size = 44,
    this.accentColor,
  });

  @override
  State<DownloadStateButton> createState() => _DownloadStateButtonState();
}

class _DownloadStateButtonState extends State<DownloadStateButton>
    with TickerProviderStateMixin {
  // ─── أنميشن النبض لحالة Completed ──────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ─── أنميشن التوهج لحالة Idle ─────────────────────────────────────
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // ─── أنميشن الدوران للـ Shimmer أثناء التحميل ──────────────────────
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // ─── أنميشن الاهتزاز لحالة Failed ─────────────────────────────────
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse — يعمل فقط عند Completed
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow — دائم خفيف لحالة Idle
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Shimmer — دوران مستمر أثناء التحميل
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Shake — اهتزاز سريع عند الفشل
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// إدارة حالة الأنيميشن بناءً على حالة التحميل
  void _syncAnimations(DownloadStatus status) {
    // Pulse: فقط عند Completed
    if (status == DownloadStatus.completed) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Shimmer: فقط عند Downloading
    if (status == DownloadStatus.downloading) {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    } else {
      if (_shimmerController.isAnimating) {
        _shimmerController.stop();
        _shimmerController.reset();
      }
    }

    // Shake: trigger واحد عند Failed
    if (status == DownloadStatus.failed) {
      if (!_shakeController.isAnimating) {
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloadManagerProvider>();
    final task = provider.getTask(widget.videoId);
    final status = task?.status ?? DownloadStatus.idle;
    final progress = task?.progress ?? 0.0;

    _syncAnimations(status);

    final accent = widget.accentColor ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: _buildState(status, progress, accent),
      ),
    );
  }

  /// بناء الحالة المناسبة
  Widget _buildState(DownloadStatus status, double progress, Color accent) {
    switch (status) {
      case DownloadStatus.idle:
        return _buildIdleState(accent);
      case DownloadStatus.downloading:
        return _buildDownloadingState(progress, accent);
      case DownloadStatus.completed:
        return _buildCompletedState(accent);
      case DownloadStatus.failed:
        return _buildFailedState(accent);
    }
  }

  // ══════════════════════ حالة الخمول (Idle) ══════════════════════

  Widget _buildIdleState(Color accent) {
    return AnimatedBuilder(
      key: const ValueKey('idle'),
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onDownloadTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.08 + 0.04 * _glowAnimation.value),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12 * _glowAnimation.value),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.download_rounded,
                color: accent.withValues(alpha: 0.75),
                size: widget.size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════ حالة التحميل (Downloading) ══════════════════════

  Widget _buildDownloadingState(double progress, Color accent) {
    final percent = (progress * 100).toInt();

    return AnimatedBuilder(
      key: const ValueKey('downloading'),
      animation: _shimmerAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // إلغاء التحميل عند الضغط
            context.read<DownloadManagerProvider>().cancelDownload(widget.videoId);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Shimmer glow يدور حول الزر
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2 + 0.15 * math.sin(_shimmerAnimation.value * 2 * math.pi)),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // الدائرة الخلفية الدوارة (shimmer ring)
                SizedBox(
                  width: widget.size - 2,
                  height: widget.size - 2,
                  child: Transform.rotate(
                    angle: _shimmerAnimation.value * 2 * math.pi,
                    child: CircularProgressIndicator(
                      value: null,
                      strokeWidth: 1.5,
                      color: accent.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // دائرة التقدم الحقيقية
                SizedBox(
                  width: widget.size - 2,
                  height: widget.size - 2,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return CustomPaint(
                        painter: _ProgressArcPainter(
                          progress: value,
                          color: accent,
                          strokeWidth: 3.0,
                          glowIntensity: 0.3 + 0.2 * math.sin(_shimmerAnimation.value * 2 * math.pi),
                        ),
                      );
                    },
                  ),
                ),
                // النسبة المئوية في المنتصف مع تأثير fade
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.size * 0.22,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: -0.5,
                  ),
                  child: Text('$percent%'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════ حالة الاكتمال (Completed) ══════════════════════

  Widget _buildCompletedState(Color accent) {
    return AnimatedBuilder(
      key: const ValueKey('completed'),
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.onPlayTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  // Glow خارجي متدرج ينبض مع الزر
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25 + 0.2 * (_pulseAnimation.value - 0.92) / 0.16),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  // توهج داخلي خفيف
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════ حالة الفشل (Failed) ══════════════════════

  Widget _buildFailedState(Color accent) {
    return AnimatedBuilder(
      key: const ValueKey('failed'),
      animation: _shakeAnimation,
      builder: (context, child) {
        // اهتزاز أفقي خفيف
        final offset = math.sin(_shakeAnimation.value * math.pi * 4) * 3;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: GestureDetector(
            onTap: () {
              // إعادة المحاولة
              context.read<DownloadManagerProvider>().retryDownload(widget.videoId);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
                border: Border.all(
                  color: Colors.red.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.refresh_rounded,
                  color: Colors.red.shade400,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════ Custom Painter — دائرة التقدم ══════════════════════

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double glowIntensity;

  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.glowIntensity = 0.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // الخلفية
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // قوس التقدم مع glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final sweepAngle = 2 * math.pi * progress;

    // رسم الـ glow أولاً
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // قوس التقدم الحقيقي
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // البدء من الأعلى
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
