import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/feedback_service.dart';
import '../theme/challenge_theme.dart';

/// يتحكّم بـ [CircularTimer] من الشاشة الأب (تشغيل، إيقاف، تمديد).
class CountdownController {
  _CircularTimerState? _state;

  void _attach(_CircularTimerState state) => _state = state;

  void _detach(_CircularTimerState state) {
    if (identical(_state, state)) _state = null;
  }

  /// يبدأ العد من الأول بالمدة الأصلية.
  void start() => _state?._start();

  void stop() => _state?._stop();

  /// يرجّع العدّاد لبدايته بدون تشغيل.
  void reset() => _state?._reset();

  /// يضيف وقت إضافي (زر "تمديد ٥ ث").
  void extend(Duration extra) => _state?._extend(extra);

  bool get isRunning => _state?._isRunning ?? false;

  bool get isFinished => _state?._isFinished ?? false;

  int get secondsLeft => _state?._secondsLeft ?? 0;
}

/// عدّاد تنازلي دائري كبير مع رنّة تنبيه واضحة عند انتهاء الوقت.
class CircularTimer extends StatefulWidget {
  const CircularTimer({
    required this.duration,
    required this.controller,
    this.onFinished,
    this.size = 190,
    this.autoStart = false,
    super.key,
  });

  final Duration duration;
  final CountdownController controller;

  /// يُستدعى مرة وحدة عند وصول العدّاد للصفر.
  final VoidCallback? onFinished;

  final double size;
  final bool autoStart;

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late int _totalMs;

  /// وقت التنبيه الصوتي — حتى ما يرن أكثر من مرة للجولة الواحدة.
  bool _alerted = false;

  /// آخر ثانية شغّلنا لها تكّة — لمنع تكرارها داخل الثانية نفسها.
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    _totalMs = widget.duration.inMilliseconds;
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onStatus)
      ..addListener(_onFrame);
    widget.controller._attach(this);
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _c.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_alerted) {
      _alerted = true;
      FeedbackService.instance.timeUp();
      widget.onFinished?.call();
    }
  }

  /// تكّة مسموعة كل ثانية في آخر خمس ثوانٍ لرفع التوتّر.
  void _onFrame() {
    if (!_c.isAnimating) return;
    final left = _secondsLeft;
    if (left == _lastTickSecond) return;
    _lastTickSecond = left;
    if (left > 0 && left <= 5) {
      FeedbackService.instance.countdownTick();
    }
  }

  bool get _isRunning => _c.isAnimating;

  bool get _isFinished => _c.status == AnimationStatus.completed;

  int get _secondsLeft => ((1 - _c.value) * _totalMs / 1000).ceil();

  void _start() {
    if (!mounted) return;
    _alerted = false;
    _lastTickSecond = -1;
    _totalMs = widget.duration.inMilliseconds;
    _c.duration = widget.duration;
    _c.forward(from: 0);
    FeedbackService.instance.countdownStart();
  }

  void _stop() => _c.stop();

  void _reset() {
    _alerted = false;
    _lastTickSecond = -1;
    _totalMs = widget.duration.inMilliseconds;
    _c
      ..duration = widget.duration
      ..value = 0;
  }

  void _extend(Duration extra) {
    if (!mounted) return;
    final wasRunningOrDone = _c.isAnimating || _isFinished;
    // نحافظ على الوقت المنقضي كما هو ونزيد الإجمالي.
    final elapsedMs = _c.value * _totalMs;
    _totalMs += extra.inMilliseconds;
    _c.duration = Duration(milliseconds: _totalMs);
    _c.value = (elapsedMs / _totalMs).clamp(0.0, 1.0);
    _alerted = false;
    _lastTickSecond = -1;
    if (wasRunningOrDone) _c.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final left = _secondsLeft;
          final urgent = left <= 5 && left > 0 && _c.isAnimating;
          final done = _isFinished;

          final ringColor = done
              ? const Color(0xFFEF4444)
              : urgent
                  ? const Color(0xFFFBBF24)
                  : theme.accent;

          // نبضة خفيفة في آخر ٥ ثواني.
          final elapsedMs = _c.lastElapsedDuration?.inMilliseconds ?? 0;
          final pulse = urgent ? 1 + 0.05 * math.sin(elapsedMs / 90) : 1.0;

          return Transform.scale(
            scale: pulse,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: 1 - _c.value,
                  color: ringColor,
                  track: Colors.black.withValues(alpha: .28),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        done ? 'انتهى' : '$left',
                        style: TextStyle(
                          fontSize: done ? widget.size * .19 : widget.size * .34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      if (!done)
                        Text(
                          'ثانية',
                          style: TextStyle(
                            fontSize: widget.size * .09,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: .7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  /// النسبة المتبقية من الوقت (١ = كامل، ٠ = انتهى).
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .085;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(stroke / 2 + 2);
    final center = rect.center;

    // قرص داخلي معتم يعطي عمق.
    canvas.drawCircle(
      center,
      rect.width / 2 - stroke / 2,
      Paint()..color = Colors.black.withValues(alpha: .22),
    );

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      -2 * math.pi * progress, // عكس عقارب الساعة، مناسب للاتجاه من اليمين لليسار
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color, Color.lerp(color, Colors.white, .5)!, color],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
