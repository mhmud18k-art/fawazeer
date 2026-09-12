import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import 'chunky_button.dart';

/// عدّاد بأزرار + و − — لعدد أسئلة التحدي وعدد المزايدة.
class StepperControl extends StatelessWidget {
  const StepperControl({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.icon,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.accent, size: 22),
            const SizedBox(width: T.s8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          ChunkyIconButton(
            icon: Icons.remove_rounded,
            tooltip: 'إنقاص',
            size: 44,
            iconSize: 24,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 56,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          ChunkyIconButton(
            icon: Icons.add_rounded,
            tooltip: 'زيادة',
            size: 44,
            iconSize: 24,
            color: theme.accent.withValues(alpha: .35),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
