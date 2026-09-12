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
import '../../widgets/circular_timer.dart';
import '../../widgets/depth_card.dart';
import '../../widgets/stepper_control.dart';
import 'play_scaffold.dart';

/// مراحل الجولة: مزايدة ⇦ إجابة ضمن الوقت ⇦ حكم ⇦ نتيجة.
enum _Phase { bidding, answering, judging, done }

/// التحدي الثاني: **مين يزوّد** (المزاد).
///
/// اختيار الفريق الفائز بالمزايدة يبدأ عدّاد ثلاثين ثانية **فقط** ولا
/// يمنح أي نقطة. بعد انتهاء الوقت يحكم الحكم: «صح» فالنقطة للمزايد،
/// و«غلط» فالنقطة للفريق الآخر.
class AuctionScreen extends ConsumerStatefulWidget {
  const AuctionScreen({super.key});

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen>
    with ChallengeRunner<AuctionScreen> {
  static const Duration _roundDuration = Duration(seconds: 30);

  final CountdownController _timer = CountdownController();

  _Phase _phase = _Phase.bidding;
  int _bid = 1;
  int? _bidderIndex;
  final Set<int> _marked = {};

  /// إجابات صحيحة قالها الفريق ولم ترد في القائمة — تُحتسب ضمن المزايدة.
  int _extra = 0;

  /// نص نتيجة الجولة بعد الحكم.
  String? _outcome;
  Color _outcomeColor = AppTheme.inkMuted;

  @override
  ChallengeType get challengeType => ChallengeType.auction;

  int get _teamCount => session.teams.length;

  @override
  void onQuestionReady() {
    setState(() {
      _phase = _Phase.bidding;
      _bid = 1;
      _bidderIndex = null;
      _marked.clear();
      _extra = 0;
      _outcome = null;
    });
    _timer.reset();
  }

  /// اختيار الفريق الفائز بالمزايدة يبدأ العدّاد فورًا — بلا أي نقطة.
  void _selectBidder(int index) {
    setState(() {
      _bidderIndex = index;
      _phase = _Phase.answering;
    });
    // العدّاد لا يُبنى إلا في طور الإجابة، فنشغّله بعد انتهاء الإطار.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _timer.start();
    });
  }

  void _toggleAnswer(int index) {
    if (_phase != _Phase.answering) return;
    setState(() {
      if (_marked.remove(index)) return;
      _marked.add(index);
      FeedbackService.instance.correct();
    });
  }

  /// إجابة صحيحة خارج القائمة — تُحتسب للفريق المزايد مثل غيرها.
  void _addExtra() {
    if (_phase != _Phase.answering) return;
    setState(() => _extra++);
    FeedbackService.instance.correct();
  }

  void _removeExtra() {
    if (_phase != _Phase.answering || _extra == 0) return;
    setState(() => _extra--);
  }

  /// ينتقل لمرحلة الحكم — تلقائيًا عند انتهاء الوقت أو يدويًا.
  void _toJudging() {
    if (_phase != _Phase.answering) return;
    _timer.stop();
    setState(() => _phase = _Phase.judging);
  }

  /// «صح» ⇦ النقطة للفريق المزايد.
  void _judgeCorrect() {
    final bidder = _bidderIndex!;
    awardPoint(bidder);
    FeedbackService.instance.correct();
    setState(() {
      _phase = _Phase.done;
      _outcome = 'أصاب ${session.teams[bidder].name} — النقطة له';
      _outcomeColor = const Color(0xFF6FA88C);
    });
  }

  /// «غلط» ⇦ النقطة للفريق الآخر (تلقائيًا حين يكون هناك فريقان).
  void _judgeWrong() {
    FeedbackService.instance.strike();
    final bidder = _bidderIndex!;
    if (_teamCount == 2) {
      final other = (bidder + 1) % 2;
      awardPoint(other);
      setState(() {
        _phase = _Phase.done;
        _outcome = 'لم يوفَّق ${session.teams[bidder].name} — '
            'النقطة لـ ${session.teams[other].name}';
        _outcomeColor = const Color(0xFF9E4B52);
      });
      return;
    }
    // مع ثلاثة فرق يحدد الحكم من يأخذ النقطة.
    setState(() {
      _phase = _Phase.done;
      _outcome = null;
    });
  }

  void _awardOther(int index) {
    awardPoint(index);
    setState(() {
      _outcome = 'النقطة لـ ${session.teams[index].name}';
      _outcomeColor = const Color(0xFF6FA88C);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    if (session == null) return const SizedBox.shrink();

    final q = question;
    final theme = ChallengeTheme.of(challengeType);
    // مع ثلاثة فرق ننتظر قرار الحكم بمن يأخذ النقطة.
    final needsPicker =
        _phase == _Phase.done && _outcome == null && _bidderIndex != null;

    return PlayScaffold(
      type: challengeType,
      teams: session.teams,
      questionIndex: questionIndex,
      totalQuestions: totalQuestions,
      activeTeamIndex: _bidderIndex,
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
                      _QuestionCard(text: q.text, packId: q.packId),
                      const SizedBox(height: T.s16),
                      if (_phase == _Phase.bidding) ...[
                        StepperControl(
                          label: 'عدد الإجابات (المزايدة)',
                          icon: Icons.trending_up_rounded,
                          value: _bid,
                          min: 1,
                          max: q.answers.length,
                          onChanged: (v) => setState(() => _bid = v),
                        ),
                        const SizedBox(height: T.s16),
                        DepthCard(
                          blur: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'من صاحب أعلى مزايدة؟',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: T.s4),
                              const Text(
                                'باختيار الفريق يبدأ عدّاد ثلاثين ثانية فورًا، '
                                'ولا تُمنح أي نقطة قبل الحكم.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.inkMuted,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: T.s12),
                              for (var i = 0; i < session.teams.length; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: T.s8),
                                  child: ChunkyButton(
                                    label: session.teams[i].name,
                                    icon: Icons.gavel_rounded,
                                    color: TeamColors.of(i),
                                    foreground: TeamColors.on,
                                    onPressed: () => _selectBidder(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: CircularTimer(
                            duration: _roundDuration,
                            controller: _timer,
                            size: 160,
                            onFinished: _toJudging,
                          ),
                        ),
                        const SizedBox(height: T.s16),
                        Center(
                          child: AnswerCounter(
                            marked: _marked.length + _extra,
                            total: q.answers.length + _extra,
                            target: _bid,
                          ),
                        ),
                        const SizedBox(height: T.s16),
                        DepthCard(
                          blur: false,
                          padding: const EdgeInsets.all(T.s12),
                          child: Wrap(
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
                                onAdd: _addExtra,
                                onRemove: _removeExtra,
                              ),
                            ],
                          ),
                        ),
                        if (_outcome != null) ...[
                          const SizedBox(height: T.s16),
                          _OutcomeCard(
                              text: _outcome!, color: _outcomeColor),
                        ],
                        if (needsPicker) ...[
                          const SizedBox(height: T.s16),
                          DepthCard(
                            blur: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'من يأخذ النقطة؟',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: T.s12),
                                for (var i = 0;
                                    i < session.teams.length;
                                    i++)
                                  if (i != _bidderIndex)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: T.s8),
                                      child: ChunkyButton(
                                        label: session.teams[i].name,
                                        color: TeamColors.of(i),
                                        foreground: TeamColors.on,
                                        onPressed: () => _awardOther(i),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                _BottomBar(
                  phase: _phase,
                  accent: theme.accent,
                  bidderName: _bidderIndex == null
                      ? null
                      : session.teams[_bidderIndex!].name,
                  onEndEarly: _toJudging,
                  onCorrect: _judgeCorrect,
                  onWrong: _judgeWrong,
                  onNext: completeQuestion,
                  onSwap: swapQuestion,
                ),
              ],
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text, required this.packId});

  final String text;
  final String packId;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);
    final pack = Pack.byId(packId);

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
            text,
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

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      blur: false,
      color: color.withValues(alpha: .10),
      borderColor: color.withValues(alpha: .55),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: color, size: 24),
          const SizedBox(width: T.s12),
          Expanded(
            child: Text(
              text,
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
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.phase,
    required this.accent,
    required this.bidderName,
    required this.onEndEarly,
    required this.onCorrect,
    required this.onWrong,
    required this.onNext,
    required this.onSwap,
  });

  final _Phase phase;
  final Color accent;
  final String? bidderName;
  final VoidCallback onEndEarly;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
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
      child: switch (phase) {
        // مرحلة الحكم: صح / غلط.
        _Phase.judging => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هل أصاب ${bidderName ?? 'الفريق'} العدد الذي زايد عليه؟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.inkMuted,
                ),
              ),
              const SizedBox(height: T.s12),
              Row(
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
            ],
          ),
        _ => Row(
            children: [
              Expanded(
                child: switch (phase) {
                  _Phase.bidding => ChunkyButton(
                      label: 'اختر الفريق صاحب أعلى مزايدة',
                      color: Colors.white.withValues(alpha: .05),
                      foreground: AppTheme.inkMuted,
                      fontSize: 14,
                      onPressed: null,
                    ),
                  _Phase.answering => ChunkyButton(
                      label: 'إنهاء الوقت الآن',
                      icon: Icons.timer_off_outlined,
                      color: Colors.white.withValues(alpha: .06),
                      foreground: AppTheme.ink,
                      fontSize: 15,
                      onPressed: onEndEarly,
                    ),
                  _ => ChunkyButton(
                      label: 'السؤال التالي',
                      icon: Icons.arrow_back_rounded,
                      color: accent,
                      fontSize: 16,
                      onPressed: onNext,
                    ),
                },
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
      },
    );
  }
}
