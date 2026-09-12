import 'package:flutter/material.dart';

import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';

/// الزر الأساسي في التطبيق: سطح متدرّج هادئ، حدّ معدني رفيع،
/// وظل ناعم منتشر. الضغط يخفض الحجم والظل قليلًا بلا قفزات.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foreground,
    this.depth = 1,
    this.expand = true,
    this.fontSize = 16,
    this.padding,
    this.borderRadius,
    this.playSound = true,
    this.shine = false,
    super.key,
  });

  final String label;

  /// إذا كانت null يصير الزر معطّلًا (باهت ولا ينضغط).
  final VoidCallback? onPressed;

  final IconData? icon;

  /// لون السطح — الافتراضي هو اللمسة المعدنية للثيم الحالي.
  final Color? color;

  final Color? foreground;

  /// قوة الارتفاع: ١ عادي، وأكبر منها للأزرار الرئيسية.
  final double depth;

  final bool expand;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  /// أوقفه للأزرار التي لها صوتها الخاص.
  final bool playSound;

  /// لمعة قطرية تمر ببطء عبر الزر — للأزرار الرئيسية وحدها.
  final bool shine;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _shine;

  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    if (widget.shine) {
      _shine = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _shine?.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ChallengeThemeScope.of(context);
    final baseColor = widget.color ?? challenge.accent;
    final radius = widget.borderRadius ?? T.rMd;

    // المعطّل يفقد تشبّعه بدل أن يتحول إلى رمادي ميت.
    final color = _enabled
        ? baseColor
        : Color.lerp(baseColor, const Color(0xFF2A313C), .72)!;
    final fg = _enabled
        ? (widget.foreground ?? challenge.onAccent)
        : AppTheme.inkMuted;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled
            ? () {
                if (widget.playSound) FeedbackService.instance.tap();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          duration: T.press,
          curve: T.smooth,
          scale: _pressed ? .982 : 1,
          child: AnimatedContainer(
            duration: T.press,
            curve: T.smooth,
            width: widget.expand ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: T.minTouch),
            padding: widget.padding ??
                const EdgeInsets.symmetric(
                    horizontal: T.s20, vertical: T.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, .12)!,
                  color,
                  Color.lerp(color, Colors.black, .14)!,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: _enabled ? .22 : .08),
                width: T.hairline,
              ),
              boxShadow: [
                ...T.softShadow(strength: _pressed ? .45 : widget.depth),
                if (_enabled)
                  ...T.halo(color, strength: _pressed ? .4 : widget.depth * .8),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize:
                        widget.expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            color: fg, size: widget.fontSize + 5),
                        const SizedBox(width: T.s8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fg,
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_shine != null && _enabled)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _shine!,
                            builder: (context, _) => _ShineBand(
                              progress: _shine!.value,
                            ),
                          ),
                        ),
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
}

/// شريط ضوء قطري يعبر الزر ببطء ثم يختفي فترة قبل أن يعود.
class _ShineBand extends StatelessWidget {
  const _ShineBand({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    // اللمعة تظهر في أول ثلث الدورة فقط حتى تبقى لمسة خفيفة لا وميضًا دائمًا.
    if (progress > .34) return const SizedBox.shrink();
    final t = Curves.easeInOut.transform(progress / .34);
    final x = -1.4 + 2.8 * t;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(x, -1),
          end: Alignment(x + .5, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .16),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// زر أيقونة دائري بمظهر زجاجي وحدّ معدني رفيع.
class ChunkyIconButton extends StatefulWidget {
  const ChunkyIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.foreground,
    this.size = 46,
    this.iconSize = 22,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// وصف الزر لقارئ الشاشة — إلزامي لأنه زر بلا نص.
  final String tooltip;

  final Color? color;
  final Color? foreground;
  final double size;
  final double iconSize;

  @override
  State<ChunkyIconButton> createState() => _ChunkyIconButtonState();
}

class _ChunkyIconButtonState extends State<ChunkyIconButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ChallengeThemeScope.of(context);
    final fill = widget.color ?? challenge.glass;
    final fg = widget.foreground ??
        (_enabled ? AppTheme.ink : AppTheme.inkMuted.withValues(alpha: .5));

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _enabled
              ? () {
                  FeedbackService.instance.tap();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            duration: T.press,
            curve: T.smooth,
            scale: _pressed ? .94 : 1,
            child: AnimatedContainer(
              duration: T.press,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: _enabled
                      ? challenge.hairline
                      : Colors.white.withValues(alpha: .07),
                  width: T.hairline,
                ),
                boxShadow: _pressed ? null : T.softShadow(strength: .5),
              ),
              child: Icon(widget.icon, color: fg, size: widget.iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
