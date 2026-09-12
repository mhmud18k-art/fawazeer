import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge_type.dart';
import '../models/pack.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../utils/page_transition.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/gradient_background.dart';
import 'challenge_intro_screen.dart';

/// اختيار الحزم قبل بداية اللعبة. كل الحزم مجانية ومفتوحة.
class PackSelectScreen extends ConsumerStatefulWidget {
  const PackSelectScreen({
    required this.teamNames,
    required this.order,
    super.key,
  });

  final List<String> teamNames;
  final List<ChallengeType> order;

  @override
  ConsumerState<PackSelectScreen> createState() => _PackSelectScreenState();
}

class _PackSelectScreenState extends ConsumerState<PackSelectScreen> {
  // بنبدأ بكل الحزم مختارة — أسهل للاعب.
  late Set<String> _selected = {for (final p in Pack.all) p.id};

  void _start() {
    ref.read(gameProvider.notifier).start(
          teamNames: widget.teamNames,
          order: widget.order,
          packIds: _selected,
        );
    context.pushFade(const ChallengeIntroScreen());
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(packCountsProvider);
    final canProceed = _selected.isNotEmpty;

    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'الحزم',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: T.s16),
            child: Text(
              'اختاروا الحزم اللي بدكم الأسئلة تجي منها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .8),
              ),
            ),
          ),
          const SizedBox(height: T.s12),
          Expanded(
            child: PackPickerList(
              selected: _selected,
              counts: counts,
              onChanged: (next) => setState(() => _selected = next),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s16),
            child: ChunkyButton(
              label: canProceed ? 'تم' : 'اختاروا حزمة على الأقل',
              icon: canProceed ? Icons.check_rounded : null,
              fontSize: 20,
              depth: 9,
              padding: const EdgeInsets.symmetric(
                  horizontal: T.s20, vertical: T.s18),
              onPressed: canProceed ? _start : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة اختيار الحزم — مشتركة بين شاشة الحزم وشاشة تمهيد كل تحدي.
class PackPickerList extends StatelessWidget {
  const PackPickerList({
    required this.selected,
    required this.counts,
    required this.onChanged,
    this.availability,
    this.shrinkWrap = false,
    super.key,
  });

  final Set<String> selected;
  final Map<String, int> counts;
  final ValueChanged<Set<String>> onChanged;

  /// عدد أسئلة كل حزمة ضمن نوع تحدي محدد — لما يكون مهم نبيّن التوفّر.
  final Map<String, int>? availability;

  final bool shrinkWrap;

  void _toggle(String id) {
    final next = {...selected};
    next.contains(id) ? next.remove(id) : next.add(id);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(T.s16, T.s4, T.s16, T.s8),
      itemCount: Pack.all.length,
      separatorBuilder: (_, _) => const SizedBox(height: T.s12),
      itemBuilder: (context, i) {
        final pack = Pack.all[i];
        final available = availability?[pack.id];
        return FadeInUp(
          delay: Duration(milliseconds: 45 * i),
          child: _PackTile(
            pack: pack,
            count: counts[pack.id] ?? 0,
            availableForType: available,
            selected: selected.contains(pack.id),
            onTap: () => _toggle(pack.id),
          ),
        );
      },
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.availableForType,
  });

  final Pack pack;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final int? availableForType;

  @override
  Widget build(BuildContext context) {
    // لو الحزمة ما فيها أسئلة من نوع التحدي الحالي، منبيّن ذلك بدل ما نخفيها.
    final emptyForType = availableForType != null && availableForType == 0;

    return Semantics(
      button: true,
      selected: selected,
      label: '${pack.name}، $count سؤال',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: T.quick,
          curve: T.smooth,
          padding: const EdgeInsets.all(T.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rLg),
            color: selected
                ? pack.color.withValues(alpha: .20)
                : Colors.white.withValues(alpha: .07),
            border: Border.all(
              color: selected
                  ? pack.color
                  : Colors.white.withValues(alpha: .16),
              width: selected ? 2.2 : 1.3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: pack.color.withValues(alpha: .3),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(T.rSm),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(pack.color, Colors.white, .35)!,
                      pack.color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(pack.color, Colors.black, .42)!,
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(pack.icon, color: const Color(0xFF10231A), size: 28),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pack.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: .72),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: T.s8),
                    Row(
                      children: [
                        _Pill(text: '$count سؤال', color: pack.color),
                        if (emptyForType) ...[
                          const SizedBox(width: T.s8),
                          const _Pill(
                            text: 'ما في أسئلة لهالتحدي',
                            color: Color(0xFFF87171),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: T.s8),
              AnimatedScale(
                duration: T.quick,
                curve: T.smooth,
                scale: selected ? 1 : .6,
                child: AnimatedOpacity(
                  duration: T.quick,
                  opacity: selected ? 1 : .25,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? pack.color : Colors.white,
                    size: 30,
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
