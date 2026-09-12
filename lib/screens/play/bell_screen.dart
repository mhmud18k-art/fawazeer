import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/challenge_type.dart';
import '../../models/pack.dart';
import '../../models/question.dart';
import '../../providers/app_providers.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/challenge_theme.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/depth_card.dart';
import 'play_scaffold.dart';

/// مراحل الجولة:
/// اطّلاع الحكم ⇦ انتظار الضغط ⇦ إبراز الضاغط ⇦ حكم ⇦ نتيجة.
enum _Phase { reveal, buzzing, pressed, judging, done }

/// التحدي الثالث: **الجرس** (السرعة).
///
/// بعد أن يخفي الحكم السؤال ويضع الجهاز بين الفرق، يضغط أسرع فريق زره
/// فتُضيء بطاقته وتخفت البقية **دون أن تظهر الإجابة**. وحين يقرر الحكم
/// يضغط «إظهار السؤال» ثم يحكم بصح أو غلط.
class BellScreen extends ConsumerStatefulWidget {
  const BellScreen({super.key});

  @override
  ConsumerState<BellScreen> createState() => _BellScreenState();
}

class _BellScreenState extends ConsumerState<BellScreen>
    with ChallengeRunner<BellScreen> {
  _Phase _phase = _Phase.reveal;

  /// الفريق صاحب حق الإجابة الآن.
  int? _current;

  /// الفرق التي أخطأت في هذا السؤال.
  final Set<int> _eliminated = {};

  String? _outcome;
  Color _outcomeColor = AppTheme.inkMuted;

  @override
  ChallengeType get challengeType => ChallengeType.bell;

  int get _teamCount => session.teams.length;

  @override
  void onQuestionReady() {
    setState(() {
      _phase = _Phase.reveal;
      _current = null;
      _eliminated.clear();
      _outcome = null;
    });
  }

  void _hideQuestion() => setState(() => _phase = _Phase.buzzing);

  void _buzz(int teamIndex) {
    if (_phase != _Phase.buzzing || _eliminated.contains(teamIndex)) return;
    FeedbackService.instance.buzz();
    setState(() {
      _current = teamIndex;
      _phase = _Phase.pressed;
    });
  }

  /// الحكم وحده يقرر متى يرى السؤال والإجابة.
  void _showQuestion() => setState(() => _phase = _Phase.judging);

  void _correct() {
    final team = _current!;
    awardPoint(team);
    FeedbackService.instance.correct();
    setState(() {
      _phase = _Phase.done;
      _outcome = 'أصاب ${session.teams[team].name} — النقطة له';
      _outcomeColor = const Color(0xFF6FA88C);
    });
  }

  /// إجابة خاطئة ⇦ تنتقل الفرصة للفريق التالي غير المستبعَد.
  void _wrong() {
    FeedbackService.instance.strike();
    final team = _current!;
    _eliminated.add(team);

    // نبحث دورانيًا عن الفريق التالي الذي لم يخطئ بعد.
    int? next;
    for (var step = 1; step < _teamCount; step++) {
      final candidate = (team + step) % _teamCount;
      if (!_eliminated.contains(candidate)) {
        next = candidate;
        break;
      }
    }

    setState(() {
      if (next == null) {
        _phase = _Phase.done;
        _current = null;
        _outcome = 'أخطأت جميع الفرق — لا نقطة لهذا السؤال';
        _outcomeColor = AppTheme.inkMuted;
      } else {
        _current = next;
        // تبقى المرحلة «حكم» ليجيب الفريق التالي شفهيًا.
        _phase = _Phase.judging;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    if (session == null) return const SizedBox.shrink();

    final q = question;
    final theme = ChallengeTheme.of(challengeType);

    return PlayScaffold(
      type: challengeType,
      teams: session.teams,
      questionIndex: questionIndex,
      totalQuestions: totalQuestions,
      activeTeamIndex: _current,
      confetti: confetti,
      reused: recycled,
      remaining: remainingInDeck,
      onQuit: () async {
        if (await confirmQuit()) endChallenge();
      },
      child: q == null
          ? const Center(
              child: Text(
                'لا توجد أسئلة متاحة لهذا التحدي.',
                style: TextStyle(fontSize: 16, color: AppTheme.ink),
              ),
            )
          : switch (_phase) {
              _Phase.reveal => _RevealView(
                  question: q,
                  onHide: _hideQuestion,
                  onSwap: swapQuestion,
                ),
              _Phase.buzzing || _Phase.pressed => _BuzzView(
                  teams: [for (final t in session.teams) t.name],
                  eliminated: _eliminated,
                  winner: _current,
                  waiting: _phase == _Phase.buzzing,
                  onBuzz: _buzz,
                  onShowQuestion: _showQuestion,
                ),
              _Phase.judging || _Phase.done => _JudgeView(
                  question: q,
                  teamName:
                      _current == null ? null : session.teams[_current!].name,
                  teamColor:
                      _current == null ? null : TeamColors.of(_current!),
                  accent: theme.accent,
                  finished: _phase == _Phase.done,
                  outcome: _outcome,
                  outcomeColor: _outcomeColor,
                  onCorrect: _correct,
                  onWrong: _wrong,
                  onNext: completeQuestion,
                  onSwap: swapQuestion,
                ),
            },
    );
  }
}

/// المرحلة ١: الحكم يطّلع على السؤال والإجابة ويحفظهما.
class _RevealView extends StatelessWidget {
  const _RevealView({
    required this.question,
    required this.onHide,
    required this.onSwap,
  });

  final Question question;
  final VoidCallback onHide;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s16),
            children: [
              const _Hint(
                icon: Icons.visibility_outlined,
                text: 'اقرأ السؤال والإجابة واحفظهما، ثم أخفِ السؤال '
                    'وضع الجهاز بين الفرق.',
              ),
              const SizedBox(height: T.s12),
              _QuestionCard(question: question),
              const SizedBox(height: T.s12),
              _AnswerCard(answers: question.answers),
            ],
          ),
        ),
        _Bar(
          child: Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: 'إخفاء السؤال',
                  icon: Icons.visibility_off_outlined,
                  color: theme.accent,
                  fontSize: 16,
                  depth: 1.4,
                  onPressed: onHide,
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
        ),
      ],
    );
  }
}

/// المرحلتان ٢ و٣: أزرار الضغط، ثم إبراز الضاغط وتعتيم البقية.
class _BuzzView extends StatelessWidget {
  const _BuzzView({
    required this.teams,
    required this.eliminated,
    required this.winner,
    required this.waiting,
    required this.onBuzz,
    required this.onShowQuestion,
  });

  final List<String> teams;
  final Set<int> eliminated;

  /// الفريق الذي ضغط أولًا — null أثناء الانتظار.
  final int? winner;

  final bool waiting;
  final ValueChanged<int> onBuzz;
  final VoidCallback onShowQuestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < teams.length; i++)
          Expanded(
            child: _BuzzPad(
              name: teams[i],
              color: TeamColors.of(i),
              disabled: eliminated.contains(i),
              // قبل الضغط: الجميع متساوون. بعده: الضاغط مضيء والبقية خافتة.
              state: winner == null
                  ? _PadState.idle
                  : (winner == i ? _PadState.winner : _PadState.dimmed),
              onPressed: () => onBuzz(i),
            ),
          ),
        _Bar(
          child: waiting
              ? const Text(
                  'يضع الحكم الجهاز بين اللاعبين ويقرأ السؤال غيبًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.inkMuted,
                    height: 1.6,
                  ),
                )
              : ChunkyButton(
                  label: 'إظهار السؤال للحكم',
                  icon: Icons.visibility_outlined,
                  fontSize: 16,
                  depth: 1.4,
                  onPressed: onShowQuestion,
                ),
        ),
      ],
    );
  }
}

enum _PadState { idle, winner, dimmed }

class _BuzzPad extends StatefulWidget {
  const _BuzzPad({
    required this.name,
    required this.color,
    required this.disabled,
    required this.state,
    required this.onPressed,
  });

  final String name;
  final Color color;
  final bool disabled;
  final _PadState state;
  final VoidCallback onPressed;

  @override
  State<_BuzzPad> createState() => _BuzzPadState();
}

class _BuzzPadState extends State<_BuzzPad> {
  bool _pressed = false;

  bool get _tappable => !widget.disabled && widget.state == _PadState.idle;

  @override
  Widget build(BuildContext context) {
    final isWinner = widget.state == _PadState.winner;
    final isDimmed = widget.state == _PadState.dimmed || widget.disabled;

    final color = isDimmed
        ? Color.lerp(widget.color, const Color(0xFF11151C), .82)!
        : widget.color;

    return Semantics(
      button: true,
      enabled: _tappable,
      label: 'زر ${widget.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _tappable ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _tappable ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _tappable ? () => setState(() => _pressed = false) : null,
        onTap: _tappable ? widget.onPressed : null,
        child: AnimatedScale(
          duration: T.press,
          curve: T.smooth,
          scale: _pressed ? .985 : 1,
          child: AnimatedContainer(
            duration: T.quick,
            curve: T.smooth,
            margin: const EdgeInsets.symmetric(
                horizontal: T.s12, vertical: T.s4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rLg),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isWinner
                    ? [
                        Color.lerp(color, Colors.white, .28)!,
                        color,
                      ]
                    : [
                        color.withValues(alpha: isDimmed ? .16 : .22),
                        color.withValues(alpha: isDimmed ? .08 : .12),
                      ],
              ),
              border: Border.all(
                color: isWinner
                    ? Colors.white.withValues(alpha: .55)
                    : color.withValues(alpha: isDimmed ? .18 : .5),
                width: isWinner ? 2 : T.hairline,
              ),
              boxShadow: isWinner
                  ? T.halo(widget.color, strength: 2.2)
                  : (isDimmed ? null : T.softShadow(strength: .6)),
            ),
            child: Center(
              // لا تدوير للنص — يظهر الاسم بشكل صحيح دائمًا.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.disabled
                        ? Icons.block_rounded
                        : isWinner
                            ? Icons.bolt_rounded
                            : Icons.touch_app_outlined,
                    size: 34,
                    color: isWinner
                        ? TeamColors.on
                        : color.withValues(alpha: isDimmed ? .4 : .85),
                  ),
                  const SizedBox(height: T.s8),
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: isWinner
                          ? TeamColors.on
                          : (isDimmed ? AppTheme.inkMuted : AppTheme.ink),
                    ),
                  ),
                  if (widget.disabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'أجاب خطأً',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    )
                  else if (isWinner)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'ضغط أولًا',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TeamColors.on,
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

/// المرحلة ٤: الحكم يرى السؤال والإجابة ويحكم بصح أو غلط.
class _JudgeView extends StatelessWidget {
  const _JudgeView({
    required this.question,
    required this.teamName,
    required this.teamColor,
    required this.accent,
    required this.finished,
    required this.outcome,
    required this.outcomeColor,
    required this.onCorrect,
    required this.onWrong,
    required this.onNext,
    required this.onSwap,
  });

  final Question question;
  final String? teamName;
  final Color? teamColor;
  final Color accent;
  final bool finished;
  final String? outcome;
  final Color outcomeColor;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onNext;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s16),
            children: [
              if (!finished && teamName != null)
                DepthCard(
                  blur: false,
                  color: teamColor!.withValues(alpha: .12),
                  borderColor: teamColor!.withValues(alpha: .65),
                  child: Row(
                    children: [
                      Icon(Icons.pan_tool_alt_outlined,
                          color: teamColor, size: 26),
                      const SizedBox(width: T.s12),
                      Expanded(
                        child: Text(
                          'حق الإجابة الآن لـ $teamName',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (outcome != null)
                DepthCard(
                  blur: false,
                  color: outcomeColor.withValues(alpha: .10),
                  borderColor: outcomeColor.withValues(alpha: .55),
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: outcomeColor, size: 24),
                      const SizedBox(width: T.s12),
                      Expanded(
                        child: Text(
                          outcome!,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: T.s12),
              _QuestionCard(question: question),
              const SizedBox(height: T.s12),
              _AnswerCard(answers: question.answers),
            ],
          ),
        ),
        _Bar(
          child: finished
              ? Row(
                  children: [
                    Expanded(
                      child: ChunkyButton(
                        label: 'السؤال التالي',
                        icon: Icons.arrow_back_rounded,
                        color: accent,
                        fontSize: 16,
                        onPressed: onNext,
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
                )
              : Row(
                  children: [
                    Expanded(
                      child: ChunkyButton(
                        label: 'صح',
                        icon: Icons.check_rounded,
                        color: const Color(0xFF4E7F68),
                        foreground: const Color(0xFFE6F2EC),
                        fontSize: 16,
                        onPressed: onCorrect,
                        playSound: false,
                      ),
                    ),
                    const SizedBox(width: T.s12),
                    Expanded(
                      child: ChunkyButton(
                        label: 'غلط',
                        icon: Icons.close_rounded,
                        color: const Color(0xFF9E4B52),
                        foreground: const Color(0xFFF3DCDE),
                        fontSize: 16,
                        onPressed: onWrong,
                        playSound: false,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);
    final pack = Pack.byId(question.packId);

    return DepthCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(pack.icon, size: 15, color: theme.accent),
              const SizedBox(width: 6),
              Text(
                pack.name,
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
            question.text,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answers});

  final List<String> answers;

  @override
  Widget build(BuildContext context) {
    const success = Color(0xFF6FA88C);

    return DepthCard(
      blur: false,
      color: success.withValues(alpha: .10),
      borderColor: success.withValues(alpha: .55),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: success.withValues(alpha: .22),
              border: Border.all(
                  color: success.withValues(alpha: .8), width: T.hairline),
            ),
            child: const Icon(Icons.check_rounded, size: 20, color: success),
          ),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإجابة',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                    color: success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  answers.join('  •  '),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    height: 1.4,
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

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(T.s12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.inkMuted, size: 20),
          const SizedBox(width: T.s12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppTheme.inkMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// الشريط السفلي الموحّد لشاشات الجرس.
class _Bar extends StatelessWidget {
  const _Bar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s16, T.s16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .30),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .07)),
        ),
      ),
      child: child,
    );
  }
}
