import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/challenge_type.dart';
import '../../models/pack.dart';
import '../../providers/app_providers.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/challenge_theme.dart';
import '../../widgets/answer_chip.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/depth_card.dart';
import '../../widgets/strike_indicator.dart';
import 'play_scaffold.dart';

/// التحدي الأول: **الدور**.
///
/// الدور لفريق واحد في كل لحظة. كل إجابة خاطئة تُسجَّل سترايكًا على
/// صاحب الدور ثم ينتقل الدور فورًا للفريق التالي. السترايكات تتراكم
/// لكل فريق طوال السؤال ولا تُصفَّر عند عودة دوره، وحين يبلغ فريق
/// ثلاث سترايكات يخسر النقطة وننتقل لسؤال جديد بسترايكات مصفّرة.
class DawrScreen extends ConsumerStatefulWidget {
  const DawrScreen({super.key});

  @override
  ConsumerState<DawrScreen> createState() => _DawrScreenState();
}

class _DawrScreenState extends ConsumerState<DawrScreen>
    with ChallengeRunner<DawrScreen> {
  static const int _maxStrikes = 3;

  /// الإجابات التي علّم عليها الحكم في السؤال الحالي.
  final Set<int> _marked = {};

  /// إجابات صحيحة ذكرها اللاعبون ولم ترد في القائمة.
  int _extra = 0;

  /// سترايكات كل فريق في السؤال الحالي — تتراكم ولا تُصفَّر بعودة الدور.
  List<int> _strikes = const [];

  /// الفرق التي استهلكت تمريرتها في هذا التحدي.
  final Set<int> _passed = {};

  /// الفريق صاحب الدور الآن.
  int _turn = 0;

  /// الفريق الذي يبدأ السؤال التالي.
  int? _pendingStartTeam;

  /// يمنع ضغطات متكررة أثناء الانتقال للسؤال التالي.
  bool _resolving = false;

  @override
  ChallengeType get challengeType => ChallengeType.dawr;

  int get _teamCount => session.teams.length;

  @override
  void onQuestionReady() {
    setState(() {
      _marked.clear();
      _extra = 0;
      _strikes = List.filled(_teamCount, 0);
      // سؤال جديد ⇦ السترايكات تُصفَّر والدور يبدأ من الفريق المحدد.
      _turn = _pendingStartTeam ?? session.startingTeamIndex;
      _pendingStartTeam = null;
      _resolving = false;
    });
  }

  void _toggleAnswer(int index) {
    if (_resolving) return;
    setState(() {
      if (_marked.remove(index)) return;
      _marked.add(index);
      FeedbackService.instance.correct();
    });
  }

  /// إجابة صحيحة قالها الفريق لكنها ليست ضمن القائمة.
  void _addExtra() {
    if (_resolving) return;
    setState(() => _extra++);
    FeedbackService.instance.correct();
  }

  void _removeExtra() {
    if (_resolving || _extra == 0) return;
    setState(() => _extra--);
  }

  /// ينهي السؤال الحالي بعد مهلة قصيرة ليرى الحكم النتيجة.
  void _finishAfterPause(int nextStartTeam) {
    _pendingStartTeam = nextStartTeam % _teamCount;
    _resolving = true;
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) completeQuestion();
    });
  }

  void _addStrike() {
    if (_resolving) return;
    FeedbackService.instance.strike();

    final team = _turn;
    final next = List.of(_strikes);
    next[team]++;

    if (next[team] >= _maxStrikes) {
      setState(() => _strikes = next);

      // الفريق خسر النقطة، وتذهب لصاحب **أقل** سترايكات بين بقية
      // الفرق. وإذا تساوى أكثر من فريق في الأقل، يأخذها كلٌّ منهم.
      final others = [
        for (var i = 0; i < _teamCount; i++)
          if (i != team) i,
      ];
      final fewest = others.map((i) => next[i]).reduce(math.min);
      final winners = others.where((i) => next[i] == fewest).toList();
      for (final w in winners) {
        awardPoint(w);
      }
      FeedbackService.instance.correct();

      final names = winners.map((i) => session.teams[i].name).join(' و ');
      _banner('${session.teams[team].name}: ثلاث سترايكات — النقطة لـ $names');
      _finishAfterPause(team + 1);
      return;
    }

    // الدور ينتقل فورًا للفريق التالي بلا ضغطة إضافية.
    setState(() {
      _strikes = next;
      _turn = (team + 1) % _teamCount;
    });
  }

  /// التمريرة كبسة إنقاذ: تنقل الدور فقط.
  ///
  /// لا تضيف سترايكًا ولا تمسح سترايكًا مسجّلًا ولا تغيّر السؤال —
  /// السترايكات لا تُصفَّر إلا مع سؤال جديد.
  void _pass() {
    if (_resolving || _passed.contains(_turn)) return;
    final team = _turn;
    setState(() {
      _passed.add(team);
      _turn = (team + 1) % _teamCount;
    });
    _banner('تمريرة ${session.teams[team].name} — الدور ينتقل بلا سترايك');
  }

  void _complete() {
    if (_resolving) return;
    final team = _turn;
    awardPoint(team);
    FeedbackService.instance.correct();
    _finishAfterPause(team + 1);
  }

  /// يسلّم الدور لفريق يختاره الحكم مباشرةً.
  ///
  /// هذه هي الطريقة الأساسية لتبديل الدور: لا حاجة لتسجيل سترايك ولا
  /// لاستهلاك تمريرة لمجرّد نقل الدور لفريق آخر.
  void _giveTurnTo(int teamIndex) {
    if (_resolving || teamIndex == _turn) return;
    FeedbackService.instance.tap();
    setState(() => _turn = teamIndex);
  }

  void _banner(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    if (session == null) return const SizedBox.shrink();

    final q = question;
    final theme = ChallengeTheme.of(challengeType);
    // حماية أثناء أول إطار قبل تهيئة قائمة السترايكات.
    final strikes = _strikes.length == session.teams.length
        ? _strikes
        : List.filled(session.teams.length, 0);
    final hasPassed = _passed.contains(_turn);

    return PlayScaffold(
      type: challengeType,
      teams: session.teams,
      questionIndex: questionIndex,
      totalQuestions: totalQuestions,
      activeTeamIndex: _turn,
      confetti: confetti,
      reused: recycled,
      remaining: remainingInDeck,
      onQuit: () async {
        if (await confirmQuit()) endChallenge();
      },
      child: q == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(T.s32),
                child: Text(
                  'لا توجد أسئلة متاحة لهذا التحدي في الحزم المختارة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.ink),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        T.s16, T.s8, T.s16, T.s16),
                    children: [
                      _TurnSelector(
                        teams: [for (final t in session.teams) t.name],
                        current: _turn,
                        onSelect: _resolving ? null : _giveTurnTo,
                      ),
                      const SizedBox(height: T.s12),
                      DepthCard(
                        blur: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Pack.byId(q.packId).icon,
                                    size: 15, color: theme.accent),
                                const SizedBox(width: 6),
                                Text(
                                  Pack.byId(q.packId).name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: .3,
                                    color: theme.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: T.s16),
                            Text(
                              q.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.ink,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: T.s16),
                      // سترايكات كل الفرق ظاهرة معًا لأنها تتراكم.
                      DepthCard(
                        blur: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: T.s16, vertical: T.s12),
                        child: Column(
                          children: [
                            for (var i = 0; i < session.teams.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom:
                                        i == session.teams.length - 1 ? 0 : T.s8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        session.teams[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: i == _turn
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: i == _turn
                                              ? TeamColors.of(i)
                                              : AppTheme.inkMuted,
                                        ),
                                      ),
                                    ),
                                    StrikeIndicator(count: strikes[i]),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: T.s16),
                      Center(
                        child: AnswerCounter(
                          marked: _marked.length + _extra,
                          total: q.answers.length + _extra,
                        ),
                      ),
                      const SizedBox(height: T.s12),
                      DepthCard(
                        blur: false,
                        padding: const EdgeInsets.all(T.s12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الإجابات — علّم عليها حين يذكرها الفريق، '
                              'وأي إجابة صحيحة خارج القائمة سجّلها بـ '
                              '«إجابة صحيحة أخرى»',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.inkMuted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: T.s12),
                            Wrap(
                              spacing: T.s8,
                              runSpacing: T.s8,
                              children: [
                                for (var i = 0; i < q.answers.length; i++)
                                  AnswerChip(
                                    text: q.answers[i],
                                    marked: _marked.contains(i),
                                    onTap: () => _toggleAnswer(i),
                                  ),
                                ExtraAnswerChip(
                                  count: _extra,
                                  onAdd: _resolving ? null : _addExtra,
                                  onRemove: _resolving ? null : _removeExtra,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Controls(
                  onStrike: _resolving ? null : _addStrike,
                  onPass: (_resolving || hasPassed) ? null : _pass,
                  onComplete: _resolving ? null : _complete,
                  onSwap: _resolving ? null : swapQuestion,
                  passLabel:
                      hasPassed ? 'استُهلكت التمريرة' : 'تمريرة (PASS)',
                  accent: theme.accent,
                ),
              ],
            ),
    );
  }
}

/// يبيّن صاحب الدور، ويتيح للحكم تسليم الدور لأي فريق بضغطة واحدة.
///
/// هذا يغني عن استخدام «سترايك» أو «تمريرة» لمجرّد نقل الدور.
class _TurnSelector extends StatelessWidget {
  const _TurnSelector({
    required this.teams,
    required this.current,
    required this.onSelect,
  });

  final List<String> teams;
  final int current;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final color = TeamColors.of(current);

    return AnimatedContainer(
      duration: T.quick,
      curve: T.smooth,
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(
            color: color.withValues(alpha: .65), width: T.hairline),
        boxShadow: T.halo(color, strength: .7),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_outlined, color: color, size: 19),
              const SizedBox(width: T.s8),
              Flexible(
                child: Text(
                  'الدور على ${teams[current]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: T.s12),
          Row(
            children: [
              for (var i = 0; i < teams.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _TurnChip(
                      name: teams[i],
                      color: TeamColors.of(i),
                      active: i == current,
                      onTap: onSelect == null ? null : () => onSelect!(i),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: T.s4),
          const Text(
            'اضغط على فريق لتسليمه الدور',
            style: TextStyle(fontSize: 11.5, color: AppTheme.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _TurnChip extends StatelessWidget {
  const _TurnChip({
    required this.name,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'تسليم الدور لـ $name',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: T.quick,
          curve: T.smooth,
          constraints: const BoxConstraints(minHeight: T.minTouch),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
              horizontal: T.s8, vertical: T.s8),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: .22)
                : Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(T.rSm),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: .85)
                  : Colors.white.withValues(alpha: .10),
              width: T.hairline,
            ),
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppTheme.ink : AppTheme.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.onStrike,
    required this.onPass,
    required this.onComplete,
    required this.onSwap,
    required this.passLabel,
    required this.accent,
  });

  final VoidCallback? onStrike;
  final VoidCallback? onPass;
  final VoidCallback? onComplete;
  final VoidCallback? onSwap;
  final String passLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s16, T.s16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .30),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .07)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: 'سترايك',
                  icon: Icons.close_rounded,
                  color: const Color(0xFF9E4B52),
                  foreground: const Color(0xFFF3DCDE),
                  fontSize: 15,
                  onPressed: onStrike,
                  playSound: false,
                ),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: ChunkyButton(
                  label: passLabel,
                  icon: Icons.skip_next_rounded,
                  color: Colors.white.withValues(alpha: .06),
                  foreground: AppTheme.inkMuted,
                  fontSize: 14,
                  onPressed: onPass,
                ),
              ),
              const SizedBox(width: T.s12),
              ChunkyIconButton(
                icon: Icons.autorenew_rounded,
                tooltip: 'تبديل السؤال',
                size: 48,
                onPressed: onSwap,
              ),
            ],
          ),
          const SizedBox(height: T.s12),
          ChunkyButton(
            label: 'اكتملت الإجابات',
            icon: Icons.check_rounded,
            color: accent,
            fontSize: 16,
            depth: 1.4,
            onPressed: onComplete,
            playSound: false,
          ),
        ],
      ),
    );
  }
}
