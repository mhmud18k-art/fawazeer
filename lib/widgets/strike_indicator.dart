import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// مؤشّر السترايكات لفريق واحد في تحدي «الدور».
///
/// ثلاث سترايكات تعني خسارة النقطة والانتقال لسؤال جديد.
class StrikeIndicator extends StatelessWidget {
  const StrikeIndicator({
    required this.count,
    this.max = 3,
    this.size = 26,
    this.label,
    super.key,
  });

  final int count;
  final int max;
  final double size;

  /// اسم الفريق — يظهر بجانب المؤشّر حين نعرض أكثر من فريق.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${label ?? ''} $count من $max سترايكات',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.inkMuted,
              ),
            ),
            const SizedBox(width: T.s8),
          ],
          for (var i = 0; i < max; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: _Mark(active: i < count, size: size),
            ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.active, required this.size});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    // قرمزي خافت بدل الأحمر الفاقع.
    const strike = Color(0xFF9E4B52);

    return AnimatedContainer(
      duration: T.quick,
      curve: T.smooth,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? strike.withValues(alpha: .30)
            : Colors.white.withValues(alpha: .04),
        border: Border.all(
          color: active
              ? strike.withValues(alpha: .85)
              : Colors.white.withValues(alpha: .10),
          width: T.hairline,
        ),
        boxShadow: active ? T.halo(strike, strength: .8) : null,
      ),
      child: Icon(
        Icons.close_rounded,
        size: size * .58,
        color: active
            ? const Color(0xFFE0A0A4)
            : Colors.white.withValues(alpha: .18),
      ),
    );
  }
}
