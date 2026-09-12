import 'package:flutter/material.dart';

import '../models/challenge_type.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../utils/page_transition.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/gradient_background.dart';
import 'pack_select_screen.dart';

/// اختيار التحديات وترتيبها.
///
/// الترتيب يتحدد حسب ترتيب الضغط — أول تحدي تضغط عليه بيكون الأول.
class ChallengeSelectScreen extends StatefulWidget {
  const ChallengeSelectScreen({required this.teamNames, super.key});

  final List<String> teamNames;

  @override
  State<ChallengeSelectScreen> createState() => _ChallengeSelectScreenState();
}

class _ChallengeSelectScreenState extends State<ChallengeSelectScreen> {
  /// مرتّبة حسب الاختيار — هي نفسها ترتيب اللعب.
  final List<ChallengeType> _order = [];

  void _toggle(ChallengeType type) {
    setState(() {
      _order.contains(type) ? _order.remove(type) : _order.add(type);
    });
  }

  void _selectAll() {
    setState(() {
      _order
        ..clear()
        ..addAll(ChallengeType.values);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _order.isNotEmpty;

    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'التحديات',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: T.s16),
            child: Text(
              'اضغطوا على التحديات بالترتيب اللي بدكم تلعبوا فيه.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .8),
              ),
            ),
          ),
          const SizedBox(height: T.s16),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: T.s16),
              crossAxisCount: 2,
              crossAxisSpacing: T.s12,
              mainAxisSpacing: T.s12,
              childAspectRatio: .86,
              children: [
                for (var i = 0; i < ChallengeType.values.length; i++)
                  FadeInUp(
                    delay: Duration(milliseconds: 60 * i),
                    child: _ChallengeCard(
                      type: ChallengeType.values[i],
                      orderIndex: _order.indexOf(ChallengeType.values[i]),
                      onTap: () => _toggle(ChallengeType.values[i]),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s16, T.s16, T.s16),
            child: Row(
              children: [
                Expanded(
                  child: ChunkyButton(
                    label: 'اختيار الكل',
                    icon: Icons.done_all_rounded,
                    color: Colors.white.withValues(alpha: .18),
                    foreground: Colors.white,
                    fontSize: 16,
                    onPressed: _selectAll,
                  ),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  flex: 2,
                  child: ChunkyButton(
                    label: canProceed
                        ? 'التالي (${_order.length})'
                        : 'اختاروا تحدي على الأقل',
                    icon: canProceed ? Icons.arrow_back_rounded : null,
                    fontSize: 17,
                    depth: 9,
                    onPressed: canProceed
                        ? () => context.pushFade(
                              PackSelectScreen(
                                teamNames: widget.teamNames,
                                order: List.of(_order),
                              ),
                            )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.type,
    required this.orderIndex,
    required this.onTap,
  });

  final ChallengeType type;

  /// موقع التحدي في ترتيب اللعب، أو -1 إذا مش مختار.
  final int orderIndex;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeTheme.of(type);
    final selected = orderIndex >= 0;

    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '${type.title}، مختار، الترتيب ${orderIndex + 1}'
          : type.title,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: T.quick,
          curve: T.smooth,
          scale: selected ? 1 : .96,
          child: AnimatedContainer(
            duration: T.quick,
            curve: T.smooth,
            padding: const EdgeInsets.all(T.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rLg),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? theme.gradient.sublist(1)
                    : [
                        Colors.white.withValues(alpha: .10),
                        Colors.white.withValues(alpha: .06),
                      ],
              ),
              border: Border.all(
                color: selected
                    ? theme.accent
                    : Colors.white.withValues(alpha: .18),
                width: selected ? 2.4 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .3),
                  offset: const Offset(0, 8),
                  blurRadius: 18,
                  spreadRadius: -6,
                ),
                if (selected)
                  BoxShadow(
                    color: theme.glow.withValues(alpha: .4),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      theme.icon,
                      size: 40,
                      color: selected
                          ? theme.accent
                          : Colors.white.withValues(alpha: .55),
                    ),
                    const Spacer(),
                    Text(
                      type.title,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: T.s4),
                    Text(
                      type.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: .72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                // شارة الترتيب في الزاوية.
                if (selected)
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accent,
                        boxShadow: [
                          BoxShadow(
                            color: Color.lerp(theme.accent, Colors.black, .4)!,
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${orderIndex + 1}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.onAccent,
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
    );
  }
}
