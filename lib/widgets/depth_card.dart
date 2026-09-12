import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';

/// بطاقة زجاجية: سطح شبه شفاف مع ضباب خفيف، حدّ معدني رفيع،
/// وظل ناعم عميق. الأساس البصري لكل محتوى التطبيق.
class DepthCard extends StatelessWidget {
  const DepthCard({
    required this.child,
    this.padding = const EdgeInsets.all(T.s20),
    this.color,
    this.borderColor,
    this.radius = T.rLg,
    this.glow,
    this.onTap,
    this.margin,
    this.blur = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// هالة خافتة حول البطاقة — لإبراز البطاقة المختارة.
  final Color? glow;

  final VoidCallback? onTap;

  /// الضباب مكلف بصريًا؛ أوقفه داخل القوائم الطويلة.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);
    final fill = color ?? theme.glass;
    final border = borderColor ?? Colors.white.withValues(alpha: .10);
    final shape = BorderRadius.circular(radius);

    Widget surface = AnimatedContainer(
      duration: T.quick,
      curve: T.smooth,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.lerp(fill, Colors.white, .045)!,
            fill,
          ],
        ),
        border: Border.all(color: border, width: T.hairline),
      ),
      child: child,
    );

    if (blur) {
      surface = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: surface,
        ),
      );
    }

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          splashColor: theme.accent.withValues(alpha: .10),
          highlightColor: theme.accent.withValues(alpha: .05),
          child: surface,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          ...T.softShadow(),
          if (glow != null) ...T.halo(glow!, strength: 1.4),
        ],
      ),
      child: ClipRRect(borderRadius: shape, child: surface),
    );
  }
}
