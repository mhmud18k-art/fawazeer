import 'package:flutter/material.dart';

import '../models/team.dart';
import '../theme/app_theme.dart';

/// شريط النقاط العلوي الثابت في كل شاشات اللعب.
///
/// كل فريق: اسمه ونقاطه داخل شارة دائرية بحلقة معدنية.
/// الفريق صاحب الدور يتميّز بحلقة أوضح وهالة خافتة.
class ScoreBar extends StatelessWidget {
  const ScoreBar({
    required this.teams,
    this.activeTeamIndex,
    this.label,
    super.key,
  });

  final List<Team> teams;

  /// الفريق صاحب الدور حاليًا — null إذا لا دور محدد.
  final int? activeTeamIndex;

  /// نص صغير أسفل الشريط (رقم السؤال مثلًا).
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s12, T.s4, T.s12, T.s12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < teams.length; i++)
                Expanded(
                  child: _TeamScore(
                    team: teams[i],
                    color: TeamColors.of(i),
                    isActive: activeTeamIndex == i,
                    compact: teams.length > 2,
                  ),
                ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: T.s8),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: .2,
                color: AppTheme.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.team,
    required this.color,
    required this.isActive,
    required this.compact,
  });

  final Team team;
  final Color color;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${team.name}: ${team.score} نقطة'
          '${isActive ? '، صاحب الدور' : ''}',
      child: AnimatedContainer(
        duration: T.quick,
        curve: T.smooth,
        padding: const EdgeInsets.symmetric(vertical: T.s12, horizontal: T.s4),
        margin: const EdgeInsets.symmetric(horizontal: T.s4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(T.rMd),
          color: isActive
              ? color.withValues(alpha: .10)
              : Colors.white.withValues(alpha: .035),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: .70)
                : Colors.white.withValues(alpha: .07),
            width: T.hairline,
          ),
          boxShadow: isActive ? T.halo(color, strength: .9) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScoreBadge(
              value: team.score,
              color: color,
              size: compact ? 48 : 54,
              dim: !isActive,
            ),
            const SizedBox(height: T.s8),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 12 : 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: .2,
                color: isActive ? AppTheme.ink : AppTheme.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة نقاط أنيقة: قرص داكن بحلقة معدنية رفيعة والرقم في المنتصف.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.value,
    required this.color,
    this.size = 54,
    this.dim = false,
    super.key,
  });

  final int value;
  final Color color;
  final double size;

  /// يخفت الشارة حين لا يكون الفريق صاحب الدور.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final ring = dim ? color.withValues(alpha: .45) : color;

    return TweenAnimationBuilder<double>(
      // نبضة خفيفة عند تغيّر النقاط — بلا مبالغة.
      key: ValueKey(value),
      tween: Tween(begin: .92, end: 1),
      duration: T.medium,
      curve: T.smooth,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color.lerp(const Color(0xFF10151D), color, .16)!,
              const Color(0xFF0A0E14),
            ],
          ),
          border: Border.all(color: ring, width: 1.4),
          boxShadow: dim ? null : T.halo(color, strength: .7),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: size * .36,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            color: dim ? AppTheme.inkMuted : AppTheme.ink,
            height: 1,
          ),
        ),
      ),
    );
  }
}
