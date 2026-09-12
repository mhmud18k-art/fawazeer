import 'dart:math' as math;

import 'package:flutter/material.dart';

/// يشغّل الاحتفال من الشاشة الأب.
class ConfettiController extends ChangeNotifier {
  int _fires = 0;
  int get fires => _fires;

  /// دفعة احتفال جديدة — عند تسجيل نقطة أو عند الفوز.
  void fire() {
    _fires++;
    notifyListeners();
  }
}

/// احتفال أنيق: ذرّات ذهبية خفيفة تتصاعد ببطء ثم تتلاشى.
///
/// مرسوم بالكامل بـ CustomPainter بلا حزم خارجية، ومقصود أن يكون
/// هادئًا وفخمًا لا صاخبًا.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    required this.controller,
    this.pieces = 42,
    this.duration = const Duration(milliseconds: 2800),
    super.key,
  });

  final ConfettiController controller;
  final int pieces;
  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  List<_Mote> _motes = const [];

  /// نغمات معدنية فقط — ذهبي، شامبانيا، برونزي، وبريق أبيض خافت.
  static const List<Color> _palette = [
    Color(0xFFC9A961),
    Color(0xFFD9C27E),
    Color(0xFFE8DCB5),
    Color(0xFFB87333),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    widget.controller.addListener(_onFire);
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onFire);
      widget.controller.addListener(_onFire);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFire);
    _c.dispose();
    super.dispose();
  }

  void _onFire() {
    if (!mounted) return;
    final rnd = math.Random();
    _motes = List.generate(widget.pieces, (_) {
      return _Mote(
        x: rnd.nextDouble(),
        rise: .28 + rnd.nextDouble() * .42,
        sway: (rnd.nextDouble() - .5) * .12,
        swayPhase: rnd.nextDouble() * math.pi * 2,
        size: 2.5 + rnd.nextDouble() * 4.5,
        color: _palette[rnd.nextInt(_palette.length)],
        delay: rnd.nextDouble() * .35,
        sliver: rnd.nextDouble() < .3,
      );
    });
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (_c.isDismissed || _motes.isEmpty) {
              return const SizedBox.expand();
            }
            return CustomPaint(
              size: Size.infinite,
              painter: _MotesPainter(motes: _motes, progress: _c.value),
            );
          },
        ),
      ),
    );
  }
}

class _Mote {
  const _Mote({
    required this.x,
    required this.rise,
    required this.sway,
    required this.swayPhase,
    required this.size,
    required this.color,
    required this.delay,
    required this.sliver,
  });

  /// الموقع الأفقي الابتدائي (٠..١ من عرض الشاشة).
  final double x;

  /// مسافة الصعود كنسبة من ارتفاع الشاشة.
  final double rise;

  final double sway;
  final double swayPhase;
  final double size;
  final Color color;
  final double delay;

  /// شظية رفيعة بدل الذرّة الدائرية.
  final bool sliver;
}

class _MotesPainter extends CustomPainter {
  _MotesPainter({required this.motes, required this.progress});

  final List<_Mote> motes;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final m in motes) {
      final t = ((progress - m.delay) / (1 - m.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // صعود يتباطأ تدريجيًا (ease-out) مع تمايل أفقي لطيف.
      final eased = 1 - math.pow(1 - t, 2.2).toDouble();
      final dy = size.height * (.94 - m.rise * eased);
      final dx = (m.x + m.sway * math.sin(m.swayPhase + t * math.pi * 2)) *
          size.width;

      // تظهر بسرعة ثم تتلاشى في الثلثين الأخيرين.
      final opacity = t < .18 ? t / .18 : (1 - (t - .18) / .82).clamp(0.0, 1.0);
      paint.color = m.color.withValues(alpha: opacity * .85);

      if (m.sliver) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(m.swayPhase + t * 1.4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: m.size * .5, height: m.size * 3),
            Radius.circular(m.size * .25),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(dx, dy), m.size * .5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MotesPainter old) =>
      old.progress != progress || old.motes != motes;
}
