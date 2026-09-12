import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ظهور متدرّج من الأسفل مع تلاشٍ — لتتابع (stagger) العناصر.
///
/// مرّر [delay] متزايدًا للعناصر المتتالية لتظهر موجة هادئة.
class FadeInUp extends StatelessWidget {
  const FadeInUp({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
    this.duration = T.medium,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // احترام تفضيل تقليل الحركة.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: T.smooth,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// عنوان رئيسي أنيق: وزن عريض، تباعد أحرف مدروس، وهالة خافتة
/// بدل الظلال الصلبة الكرتونية.
class DisplayTitle extends StatelessWidget {
  const DisplayTitle(
    this.text, {
    this.fontSize = 34,
    this.color = AppTheme.ink,
    this.glow,
    super.key,
  });

  final String text;
  final double fontSize;
  final Color color;

  /// لون الهالة الخافتة خلف النص.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final halo = glow ?? const Color(0xFFC9A961);

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
        color: color,
        height: 1.3,
        shadows: [
          Shadow(color: halo.withValues(alpha: .28), blurRadius: 24),
          const Shadow(color: Color(0x66000000), blurRadius: 12),
        ],
      ),
    );
  }
}

/// فاصل رفيع بلمسة معدنية — يفصل الأقسام بهدوء.
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({this.color, this.width = 64, super.key});

  final Color? color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFC9A961);
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.withValues(alpha: 0),
            c.withValues(alpha: .55),
            c.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
