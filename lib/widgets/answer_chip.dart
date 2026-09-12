import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';

/// شريحة إجابة مقترحة يعلّم عليها الحكم حين يذكرها الفريق.
///
/// الشرائح للحكم وحده — اللاعبون لا يرون الشاشة.
class AnswerChip extends StatelessWidget {
  const AnswerChip({
    required this.text,
    required this.marked,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool marked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);

    return Semantics(
      button: true,
      selected: marked,
      label: '$text${marked ? '، معلّمة' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: T.quick,
          curve: T.smooth,
          constraints: const BoxConstraints(minHeight: T.minTouch),
          padding: const EdgeInsets.symmetric(
              horizontal: T.s12, vertical: T.s8),
          decoration: BoxDecoration(
            color: marked
                ? theme.accent.withValues(alpha: .16)
                : Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(T.rSm),
            border: Border.all(
              color: marked
                  ? theme.accent.withValues(alpha: .75)
                  : Colors.white.withValues(alpha: .10),
              width: T.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (marked) ...[
                Icon(Icons.check_rounded, size: 16, color: theme.accent),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: marked ? FontWeight.w700 : FontWeight.w400,
                    color: marked ? AppTheme.ink : AppTheme.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريحة لتسجيل إجابة صحيحة **لم ترد** في قائمة الإجابات.
///
/// قوائم الإجابات مهما طالت لا تحيط بكل صواب ممكن (خاصةً في أسئلة
/// «اذكر ما استطعت»)، فهذه الشريحة تجعل الحكم يحتسب أي إجابة صحيحة:
/// ضغطة تزيد واحدة، وضغطة مطوّلة تُنقص واحدة.
class ExtraAnswerChip extends StatelessWidget {
  const ExtraAnswerChip({
    required this.count,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final int count;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);
    final active = count > 0;

    return Semantics(
      button: true,
      label: 'إجابة صحيحة غير مذكورة',
      value: '$count',
      child: GestureDetector(
        onTap: onAdd,
        onLongPress: count > 0 ? onRemove : null,
        child: AnimatedContainer(
          duration: T.quick,
          curve: T.smooth,
          constraints: const BoxConstraints(minHeight: T.minTouch),
          padding: const EdgeInsets.symmetric(
              horizontal: T.s12, vertical: T.s8),
          decoration: BoxDecoration(
            color: active
                ? theme.accent.withValues(alpha: .16)
                : Colors.white.withValues(alpha: .02),
            borderRadius: BorderRadius.circular(T.rSm),
            border: Border.all(
              color: active
                  ? theme.accent.withValues(alpha: .75)
                  : theme.accent.withValues(alpha: .40),
              width: T.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: theme.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  active ? 'إجابة صحيحة أخرى ($count)' : 'إجابة صحيحة أخرى',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppTheme.ink : theme.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عدّاد الإجابات المعلّمة.
class AnswerCounter extends StatelessWidget {
  const AnswerCounter({
    required this.marked,
    required this.total,
    this.target,
    super.key,
  });

  final int marked;
  final int total;

  /// الهدف المطلوب (رقم المزايدة في تحدي «مين يزوّد»).
  final int? target;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);
    final reached = target != null && marked >= target!;
    const success = Color(0xFF6FA88C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s8),
      decoration: BoxDecoration(
        color: reached
            ? success.withValues(alpha: .14)
            : Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(
          color: reached
              ? success.withValues(alpha: .7)
              : Colors.white.withValues(alpha: .10),
          width: T.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reached ? Icons.verified_rounded : Icons.checklist_rounded,
            size: 18,
            color: reached ? success : theme.accent,
          ),
          const SizedBox(width: T.s8),
          // الشرطة المائلة محايدة اتجاهيًا، فلو تُركت داخل فقرة RTL
          // انعكس ترتيب الرقمين («1 / 5» تظهر «5 / 1»). نعزلها بـ LTR.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              target == null ? '$marked / $total' : '$marked / $target',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
                color: AppTheme.ink,
              ),
            ),
          ),
          if (target != null) ...[
            const SizedBox(width: T.s8),
            Text(
              '(المتاح $total)',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppTheme.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
