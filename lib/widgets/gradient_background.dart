import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';

/// خلفية متدرّجة تنتقل لونيًا بشكل متحرك لما يتغيّر ثيم التحدي.
///
/// بتنشر الثيم (بعد المزج) عبر [ChallengeThemeScope] حتى كل الودجت
/// تحتها تاخد الألوان الصحيحة أثناء الانتقال.
class AnimatedChallengeBackground extends StatefulWidget {
  const AnimatedChallengeBackground({
    required this.theme,
    required this.child,
    this.showBubbles = true,
    super.key,
  });

  final ChallengeTheme theme;
  final Widget child;
  final bool showBubbles;

  @override
  State<AnimatedChallengeBackground> createState() =>
      _AnimatedChallengeBackgroundState();
}

class _AnimatedChallengeBackgroundState
    extends State<AnimatedChallengeBackground> with TickerProviderStateMixin {
  late final AnimationController _fade;
  late final AnimationController _drift;
  late ChallengeTheme _from;
  late ChallengeTheme _to;

  @override
  void initState() {
    super.initState();
    _from = widget.theme;
    _to = widget.theme;
    _fade = AnimationController(vsync: this, duration: T.slow, value: 1);
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedChallengeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != _to) {
      // ننطلق من اللون الحالي (حتى لو الانتقال السابق ما خلص).
      _from = ChallengeTheme.lerp(_from, _to, _fade.value);
      _to = widget.theme;
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_fade.value);
        final theme = ChallengeTheme.lerp(_from, _to, t);
        return ChallengeThemeScope(
          theme: theme,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.gradient,
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                if (widget.showBubbles)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _drift,
                          builder: (context, _) => CustomPaint(
                            painter: _BubblesPainter(
                              progress: _drift.value,
                              color: theme.glow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(child: child ?? const SizedBox.shrink()),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// فقاعات شفافة خفيفة تطوف ببطء بالخلفية.
class _BubblesPainter extends CustomPainter {
  _BubblesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  // مواقع وأحجام ثابتة (نسبية) حتى تكون الحركة متوقّعة وهادية.
  static const List<({double x, double y, double r, double speed})> _bubbles = [
    (x: .12, y: .18, r: .30, speed: 1.0),
    (x: .84, y: .10, r: .22, speed: -0.7),
    (x: .72, y: .62, r: .34, speed: 0.55),
    (x: .18, y: .78, r: .26, speed: -0.85),
    (x: .50, y: .40, r: .18, speed: 0.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // هالات خافتة جدًا تعطي عمقًا للخلفية بلا ضجيج بصري.
    for (final b in _bubbles) {
      final angle = progress * 2 * math.pi * b.speed;
      final dx = math.cos(angle) * size.width * .04;
      final dy = math.sin(angle) * size.height * .03;
      final center = Offset(b.x * size.width + dx, b.y * size.height + dy);
      final radius = b.r * size.width * .75;
      paint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: .075),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // تعتيم لطيف عند الأطراف يركّز النظر على المنتصف.
    final vignette = Paint()
      ..shader = RadialGradient(
        radius: .95,
        colors: [
          const Color(0x00000000),
          Colors.black.withValues(alpha: .32),
        ],
        stops: const [.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(_BubblesPainter old) =>
      old.progress != progress || old.color != color;
}

/// Scaffold موحّد: خلفية متدرّجة + شريط علوي بسيط + محتوى داخل SafeArea.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    required this.child,
    this.theme,
    this.title,
    this.showBack = true,
    this.actions = const [],
    this.top,
    this.showBubbles = true,
    super.key,
  });

  final Widget child;

  /// ثيم التحدي — إذا null بنستخدم الثيم الموروث من الأعلى.
  final ChallengeTheme? theme;

  final String? title;
  final bool showBack;
  final List<Widget> actions;

  /// ودجت ثابتة أعلى المحتوى (شريط النقاط مثلًا).
  final Widget? top;

  final bool showBubbles;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? ChallengeThemeScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AnimatedChallengeBackground(
        theme: resolved,
        showBubbles: showBubbles,
        child: SafeArea(
          child: Column(
            children: [
              if (title != null || showBack || actions.isNotEmpty)
                _Header(title: title, showBack: showBack, actions: actions),
              ?top,
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.showBack,
    required this.actions,
  });

  final String? title;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s12, T.s8, T.s12, T.s4),
      child: Row(
        children: [
          if (showBack && canPop)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_forward_rounded),
              color: Colors.white,
              iconSize: 28,
              tooltip: 'رجوع',
            )
          else
            const SizedBox(width: T.s48),
          Expanded(
            child: Text(
              title ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (actions.isEmpty)
            const SizedBox(width: T.s48)
          else
            Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}
