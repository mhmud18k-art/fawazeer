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

/// الفقرة الخامسة: **المستحيل**.
///
/// أسئلة اختيار من متعدد بأصعب مستوى في اللعبة. الحكم يقرأ السؤال
/// وخياراته الأربعة على الفرق، والإجابة الصحيحة **معلّمة أمامه وحده**،
/// ثم يضغط على اسم الفريق الذي أصاب.
class ImpossibleScreen extends ConsumerStatefulWidget {
  const ImpossibleScreen({super.key});

  @override
  ConsumerState<ImpossibleScreen> createState() => _ImpossibleScreenState();
}

class _ImpossibleScreenState extends ConsumerState<ImpossibleScreen>
    with ChallengeRunner<ImpossibleScreen> {
  /// الفريق الذي أصاب — بعد اختياره تُمنح النقطة.
  int? _answeredBy;

  /// صحيح حين يقرر الحكم أن أحدًا لم يُصب.
  bool _closed = false;

  @override
  ChallengeType get challengeType => ChallengeType.impossible;

  @override
  void onQuestionReady() {
    setState(() {
      _answeredBy = null;
      _closed = false;
    });
  }

  bool get _resolved => _answeredBy != null || _closed;

  void _answered(int teamIndex) {
    if (_resolved) return;
    setState(() => _answeredBy = teamIndex);
    awardPoint(teamIndex);
    FeedbackService.instance.correct();
  }

  void _noOne() {
    if (_resolved) return;
    FeedbackService.instance.strike();
    setState(() => _closed = true);
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
                      _QuestionCard(question: q),
                      const SizedBox(height: T.s16),
                      const _JudgeHint(),
                      const SizedBox(height: T.s12),
                      _Options(question: q),
                      const SizedBox(height: T.s20),
                      if (_answeredBy != null)
                        _Outcome(
                          text: 'النقطة لـ ${session.teams[_answeredBy!].name}',
                          color: TeamColors.of(_answeredBy!),
                          icon: Icons.emoji_events_rounded,
                        )
                      else if (_closed)
                        const _Outcome(
                          text: 'لم يُصب أحد — لا نقطة لهذا السؤال',
                          color: AppTheme.inkMuted,
                          icon: Icons.remove_circle_outline_rounded,
                        )
                      else
                        DepthCard(
                          blur: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'من أصاب الإجابة الصحيحة؟',
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
                                    icon: Icons.check_rounded,
                                    color: TeamColors.of(i),
                                    foreground: TeamColors.on,
                                    onPressed: () => _answered(i),
                                    playSound: false,
                                  ),
                                ),
                              ChunkyButton(
                                label: 'لم يُصب أحد',
                                icon: Icons.close_rounded,
                                color: Colors.white.withValues(alpha: .06),
                                foreground: AppTheme.inkMuted,
                                fontSize: 15,
                                onPressed: _noOne,
                                playSound: false,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      T.s16, T.s12, T.s16, T.s16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .35),
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: .07)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          label: 'السؤال التالي',
                          icon: Icons.arrow_back_rounded,
                          color: theme.accent,
                          fontSize: 16,
                          onPressed: completeQuestion,
                        ),
                      ),
                      const SizedBox(width: T.s12),
                      ChunkyIconButton(
                        icon: Icons.autorenew_rounded,
                        tooltip: 'تبديل السؤال',
                        size: 48,
                        onPressed: swapQuestion,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: T.s8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E2A47).withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF8E2A47).withValues(alpha: .7)),
                ),
                child: Text(
                  question.difficulty.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0A8B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: T.s16),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// الخيارات الأربعة، والإجابة الصحيحة معلّمة للحكم وحده.
class _Options extends StatelessWidget {
  const _Options({required this.question});

  final Question question;

  /// حروف الترقيم العربية للخيارات.
  static const List<String> _letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];

  @override
  Widget build(BuildContext context) {
    const success = Color(0xFF6FA88C);
    final correct = question.correctOptionIndex;

    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: T.s8),
            child: DepthCard(
              blur: false,
              padding: const EdgeInsets.symmetric(
                  horizontal: T.s12, vertical: T.s12),
              color: i == correct
                  ? success.withValues(alpha: .14)
                  : Colors.white.withValues(alpha: .04),
              borderColor: i == correct
                  ? success.withValues(alpha: .75)
                  : Colors.white.withValues(alpha: .08),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == correct
                          ? success.withValues(alpha: .25)
                          : Colors.white.withValues(alpha: .06),
                      border: Border.all(
                        color: i == correct
                            ? success
                            : Colors.white.withValues(alpha: .14),
                        width: T.hairline,
                      ),
                    ),
                    child: Text(
                      i < _letters.length ? _letters[i] : '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: i == correct ? success : AppTheme.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: T.s12),
                  Expanded(
                    child: Text(
                      question.options[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            i == correct ? FontWeight.w700 : FontWeight.w400,
                        color:
                            i == correct ? AppTheme.ink : AppTheme.inkMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (i == correct)
                    const Icon(Icons.check_circle_rounded,
                        size: 22, color: success),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _JudgeHint extends StatelessWidget {
  const _JudgeHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(T.s12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: AppTheme.inkMuted, size: 19),
          SizedBox(width: T.s12),
          Expanded(
            child: Text(
              'اقرأ الخيارات على الفرق دون أن تريهم الشاشة — '
              'الإجابة الصحيحة معلّمة لك بالأخضر.',
              style: TextStyle(
                fontSize: 13,
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

class _Outcome extends StatelessWidget {
  const _Outcome({
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
