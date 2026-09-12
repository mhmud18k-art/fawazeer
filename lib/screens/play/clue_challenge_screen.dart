import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/challenge_type.dart';
import '../../models/pack.dart';
import '../../providers/app_providers.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/challenge_theme.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/circular_timer.dart';
import '../../widgets/depth_card.dart';
import 'play_scaffold.dart';

/// شاشة التحديات الوصفية: **من أنا** و**اسأل الحكم**.
///
/// التحديان يشتركان في المنطق: وصف يقرأه الحكم، والإجابة الصحيحة
/// ظاهرة له تحته مباشرة (الشاشة له وحده)، وعدّاد ثلاثين ثانية قابل
/// للتمديد، ثم يضغط الحكم على اسم الفريق الذي أصاب.
///
/// الفرق الوحيد في العرض: «اسأل الحكم» يعرض الأوصاف أسطرًا متتابعة،
/// و«من أنا» يعرض اللغز فقرةً واحدة.
class ClueChallengeScreen extends ConsumerStatefulWidget {
  const ClueChallengeScreen({required this.type, super.key});

  final ChallengeType type;

  @override
  ConsumerState<ClueChallengeScreen> createState() =>
      _ClueChallengeScreenState();
}

class _ClueChallengeScreenState extends ConsumerState<ClueChallengeScreen>
    with ChallengeRunner<ClueChallengeScreen> {
  static const Duration _roundDuration = Duration(seconds: 30);
  static const Duration _extension = Duration(seconds: 5);

  final CountdownController _timer = CountdownController();

  bool _started = false;

  /// الفريق الذي أصاب الجواب — بعد اختياره تُمنح النقطة.
  int? _answeredBy;

  /// صحيح حين يقرر الحكم أن أحدًا لم يعرف الجواب.
  bool _closed = false;

  @override
  ChallengeType get challengeType => widget.type;

  @override
  void onQuestionReady() {
    setState(() {
      _started = false;
      _answeredBy = null;
      _closed = false;
    });
    _timer.reset();
  }

  void _start() {
    setState(() => _started = true);
    _timer.start();
  }

  void _answered(int teamIndex) {
    if (_answeredBy != null || _closed) return;
    _timer.stop();
    setState(() => _answeredBy = teamIndex);
    awardPoint(teamIndex);
    FeedbackService.instance.correct();
  }

  void _noOne() {
    _timer.stop();
    setState(() => _closed = true);
  }

  bool get _resolved => _answeredBy != null || _closed;

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
      activeTeamIndex: _answeredBy,
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
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        T.s16, T.s8, T.s16, T.s16),
                    children: [
                      _ClueCard(
                        text: q.text,
                        packId: q.packId,
                        asLines: challengeType == ChallengeType.askJudge,
                      ),
                      const SizedBox(height: T.s12),
                      // الإجابة ظاهرة للحكم من البداية — الشاشة له وحده.
                      _AnswerCard(answers: q.answers),
                      const SizedBox(height: T.s20),
                      Center(
                        child: CircularTimer(
                          duration: _roundDuration,
                          controller: _timer,
                          size: 168,
                        ),
                      ),
                      if (_started && !_resolved) ...[
                        const SizedBox(height: T.s16),
                        Center(
                          child: ChunkyIconButton(
                            icon: Icons.more_time_rounded,
                            tooltip: 'تمديد خمس ثوانٍ',
                            size: 52,
                            iconSize: 24,
                            onPressed: () => _timer.extend(_extension),
                          ),
                        ),
                        const SizedBox(height: T.s4),
                        const Center(
                          child: Text(
                            'تمديد ٥ ثوانٍ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: T.s20),
                      if (_answeredBy != null)
                        _OutcomeBanner(
                          text: 'النقطة لـ ${session.teams[_answeredBy!].name}',
                          color: TeamColors.of(_answeredBy!),
                          icon: Icons.emoji_events_rounded,
                        )
                      else if (_closed)
                        const _OutcomeBanner(
                          text: 'لم يعرف أحد الجواب — لا نقطة لهذا السؤال',
                          color: AppTheme.inkMuted,
                          icon: Icons.remove_circle_outline_rounded,
                        )
                      else if (_started)
                        DepthCard(
                          blur: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'من أجاب إجابة صحيحة؟',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: T.s12),
                              for (var i = 0; i < session.teams.length; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: T.s8),
                                  child: ChunkyButton(
                                    label: session.teams[i].name,
                                    icon: Icons.pan_tool_alt_rounded,
                                    color: TeamColors.of(i),
                                    foreground: TeamColors.on,
                                    onPressed: () => _answered(i),
                                    playSound: false,
                                  ),
                                ),
                              ChunkyButton(
                                label: 'لم يعرف أحد',
                                icon: Icons.help_outline_rounded,
                                color: Colors.white.withValues(alpha: .06),
                                foreground: AppTheme.inkMuted,
                                fontSize: 15,
                                onPressed: _noOne,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _BottomBar(
                  accent: theme.accent,
                  started: _started,
                  onStart: _start,
                  onNext: completeQuestion,
                  onSwap: swapQuestion,
                ),
              ],
            ),
    );
  }
}

/// بطاقة الوصف: أسطر متتابعة في «اسأل الحكم»، وفقرة في «من أنا».
class _ClueCard extends StatelessWidget {
  const _ClueCard({
    required this.text,
    required this.packId,
    required this.asLines,
  });

  final String text;
  final String packId;
  final bool asLines;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);
    final pack = Pack.byId(packId);
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

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
          if (!asLines || lines.length == 1)
            Text(
              lines.join(' '),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.ink,
                height: 1.75,
              ),
            )
          else
            // الحكم يقرأ سطرًا بعد سطر حتى يعرف أحدهم.
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: EdgeInsets.only(
                    bottom: i == lines.length - 1 ? 0 : T.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.accent.withValues(alpha: .5),
                          width: T.hairline,
                        ),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: T.s12),
                    Expanded(
                      child: Text(
                        lines[i],
                        style: TextStyle(
                          // السطر الأول أعمّ، والأخير أقرب للجواب.
                          fontSize: 18,
                          fontWeight: i == lines.length - 1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppTheme.ink,
                          height: 1.6,
                        ),
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

/// الإجابة الصحيحة — للحكم وحده.
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

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      blur: false,
      color: color.withValues(alpha: .10),
      borderColor: color.withValues(alpha: .55),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: T.s12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.accent,
    required this.started,
    required this.onStart,
    required this.onNext,
    required this.onSwap,
  });

  final Color accent;
  final bool started;
  final VoidCallback onStart;
  final VoidCallback onNext;
  final VoidCallback onSwap;

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
      child: Row(
        children: [
          Expanded(
            child: started
                ? ChunkyButton(
                    label: 'السؤال التالي',
                    icon: Icons.arrow_back_rounded,
                    color: accent,
                    fontSize: 16,
                    onPressed: onNext,
                  )
                : ChunkyButton(
                    label: 'ابدأ العد (٣٠ ثانية)',
                    icon: Icons.timer_outlined,
                    color: accent,
                    fontSize: 16,
                    depth: 1.4,
                    onPressed: onStart,
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
    );
  }
}
