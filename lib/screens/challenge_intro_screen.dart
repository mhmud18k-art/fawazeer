import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge_type.dart';
import '../models/game_session.dart';
import '../models/pack.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../utils/page_transition.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/depth_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/stepper_control.dart';
import 'how_to_play_screen.dart';
import 'pack_select_screen.dart';
import 'play/auction_screen.dart';
import 'play/bell_screen.dart';
import 'play/clue_challenge_screen.dart';
import 'play/dawr_screen.dart';
import 'play/impossible_screen.dart';
import 'results_screen.dart';

/// شاشة تمهيد التحدي: اسمه، حزمه، عدد أسئلته، وزر البدء.
class ChallengeIntroScreen extends ConsumerWidget {
  const ChallengeIntroScreen({super.key});

  /// يفتح شاشة اللعب المناسبة لنوع التحدي.
  ///
  /// «من أنا» و«اسأل الحكم» يتشاركان الشاشة نفسها لأن منطقهما واحد.
  static Widget playScreenFor(ChallengeType type) => switch (type) {
        ChallengeType.dawr => const DawrScreen(),
        ChallengeType.auction => const AuctionScreen(),
        ChallengeType.bell => const BellScreen(),
        ChallengeType.whoAmI ||
        ChallengeType.askJudge =>
          ClueChallengeScreen(type: type),
        ChallengeType.impossible => const ImpossibleScreen(),
      };

  Future<void> _editPacks(
    BuildContext context,
    WidgetRef ref,
    ChallengeConfig config,
  ) async {
    final repo = ref.read(questionRepositoryProvider);
    final counts = ref.read(packCountsProvider);
    final availability = {
      for (final p in Pack.all)
        p.id: repo.countForPackAndType(p.id, config.type),
    };

    var selected = {...config.packIds};

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241046),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(T.rXl)),
      ),
      builder: (context) => ChallengeThemeScope(
        theme: ChallengeTheme.of(config.type),
        child: StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: T.s12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: T.s12),
                const Text(
                  'حزم هذا التحدي',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: T.s8),
                Flexible(
                  child: PackPickerList(
                    selected: selected,
                    counts: counts,
                    availability: availability,
                    onChanged: (next) =>
                        setSheetState(() => selected = next),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(T.s16),
                  child: ChunkyButton(
                    label: 'تم',
                    icon: Icons.check_rounded,
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            ref
                                .read(gameProvider.notifier)
                                .updateCurrentChallenge(packIds: selected);
                            Navigator.of(context).pop();
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider);

    // حماية: إذا ما في جلسة أو خلصت التحديات، بنروح لشاشة النتيجة.
    if (session == null) return const SizedBox.shrink();
    if (session.isFinished) return const ResultsScreen();

    final config = session.currentChallenge;
    final type = config.type;
    final theme = ChallengeTheme.of(type);
    final repo = ref.watch(questionRepositoryProvider);
    final available =
        repo.questionsIn(packIds: config.packIds, type: type).length;

    return GradientScaffold(
      theme: theme,
      title: 'التحدي ${session.currentChallengeIndex + 1} '
          'من ${session.challenges.length}',
      actions: [
        ChunkyIconButton(
          icon: Icons.help_outline_rounded,
          tooltip: 'شرح التحدي',
          size: 46,
          iconSize: 24,
          onPressed: () => showChallengeRules(context, type),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s24),
        children: [
          FadeInUp(child: _ChallengeHero(type: type)),
          const SizedBox(height: T.s24),
          FadeInUp(
            delay: const Duration(milliseconds: 70),
            child: DepthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'الحزم المشمولة',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editPacks(context, ref, config),
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        label: const Text('تعديل'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.accent,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: T.s8),
                  Wrap(
                    spacing: T.s8,
                    runSpacing: T.s8,
                    children: [
                      for (final id in config.packIds)
                        _PackChip(
                          pack: Pack.byId(id),
                          onRemove: config.packIds.length > 1
                              ? () => ref
                                  .read(gameProvider.notifier)
                                  .updateCurrentChallenge(
                                    packIds: {...config.packIds}..remove(id),
                                  )
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: T.s12),
                  Text(
                    available > 0
                        ? 'متوفر $available سؤال لهذا التحدي.'
                        : 'ما في أسئلة من هذا النوع في الحزم المختارة — عدّلوا الحزم.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: available > 0
                          ? Colors.white.withValues(alpha: .72)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: T.s16),
          FadeInUp(
            delay: const Duration(milliseconds: 130),
            child: StepperControl(
              label: 'عدد أسئلة التحدي',
              icon: Icons.tag_rounded,
              value: config.questionCount,
              min: ChallengeConfig.minQuestionCount,
              max: ChallengeConfig.maxQuestionCount,
              onChanged: (v) => ref
                  .read(gameProvider.notifier)
                  .updateCurrentChallenge(questionCount: v),
            ),
          ),
          const SizedBox(height: T.s24),
          FadeInUp(
            delay: const Duration(milliseconds: 190),
            child: ChunkyButton(
              label: 'ابدأ',
              icon: Icons.play_arrow_rounded,
              shine: true,
              fontSize: 22,
              depth: 10,
              padding: const EdgeInsets.symmetric(
                  horizontal: T.s20, vertical: T.s20),
              onPressed: available > 0
                  ? () => context.replaceFade(playScreenFor(type))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({required this.type});

  final ChallengeType type;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeTheme.of(type);

    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(theme.accent, Colors.white, .35)!,
                theme.accent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(theme.accent, Colors.black, .45)!,
                offset: const Offset(0, 7),
                blurRadius: 0,
              ),
              BoxShadow(
                color: theme.glow.withValues(alpha: .5),
                blurRadius: 34,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(theme.icon, size: 54, color: theme.onAccent),
        ),
        const SizedBox(height: T.s16),
        DisplayTitle(type.title, fontSize: 32, glow: theme.accent),
        const SizedBox(height: T.s8),
        Text(
          type.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: .85),
          ),
        ),
      ],
    );
  }
}

class _PackChip extends StatelessWidget {
  const _PackChip({required this.pack, required this.onRemove});

  final Pack pack;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: T.s12,
        end: onRemove == null ? T.s12 : T.s4,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: pack.color.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(T.rSm),
        border: Border.all(color: pack.color.withValues(alpha: .6), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pack.icon, size: 17, color: pack.color),
          const SizedBox(width: 6),
          Text(
            pack.name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 16),
              color: Colors.white70,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              tooltip: 'إزالة ${pack.name}',
            ),
        ],
      ),
    );
  }
}
