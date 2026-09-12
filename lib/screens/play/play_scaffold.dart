import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/challenge_type.dart';
import '../../models/game_session.dart';
import '../../models/question.dart';
import '../../models/team.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/challenge_theme.dart';
import '../../utils/page_transition.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/confetti.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/score_bar.dart';
import '../challenge_intro_screen.dart';
import '../how_to_play_screen.dart';
import '../results_screen.dart';

/// المنطق المشترك بين شاشات التحديات الأربعة:
/// سحب الأسئلة بدون تكرار، التبديل، التقدّم، وإنهاء التحدي.
mixin ChallengeRunner<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  Question? question;
  int questionIndex = 0;

  final ConfettiController confetti = ConfettiController();

  /// الأسئلة التي سحبناها في هذه الشاشة.
  ///
  /// نحتفظ بها محليًا لأن تسجيلها في المزوّد ممنوع أثناء بناء شجرة
  /// الودجت، فيتأجّل لأول لحظة آمنة.
  final Set<String> _picked = {};

  /// رزمة أسئلة مخلوطة مرة واحدة تُستهلك بالتسلسل.
  ///
  /// هذا ما يضمن ألّا يعيد زر «تبديل» سؤالًا سبق عرضه أو استبداله.
  List<Question> _deck = const [];
  int _cursor = 0;

  /// صحيح بعد إعادة تدوير حزمة نفدت أسئلتها.
  bool recycled = false;

  ChallengeType get challengeType;

  GameSession get session => ref.read(gameProvider)!;

  int get totalQuestions => session.currentChallenge.questionCount;

  /// الفريق صاحب الدور — يتناوب مع كل سؤال.
  int get currentTeamIndex =>
      (session.startingTeamIndex + questionIndex) % session.teams.length;

  int get nextTeamIndex =>
      (currentTeamIndex + 1) % session.teams.length;

  @override
  void initState() {
    super.initState();
    // _select ما بيلمس أي provider — بس بيقرأ.
    _select();
    // initState بيصير ضمن بناء شجرة الودجت، وتعديل provider هون ممنوع،
    // فمنأجّل تسجيل السؤال (و setState) لبعد ما يخلص أول إطار.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _flushPicked();
      onQuestionReady();
    });
  }

  @override
  void dispose() {
    confetti.dispose();
    super.dispose();
  }

  /// يبني رزمة جديدة من كل الأسئلة غير المستخدَمة، مخلوطة مرة واحدة.
  void _buildDeck() {
    final config = ref.read(gameProvider)!.currentChallenge;
    final repo = ref.read(questionRepositoryProvider);
    final used = {...ref.read(usedQuestionsProvider), ..._picked};

    var deck = repo.deck(
      packIds: config.packIds,
      type: challengeType,
      exclude: used,
    );

    if (deck.isEmpty) {
      // نفدت أسئلة هذه الحزم لهذا التحدي ⇦ نعيد تدويرها من جديد.
      deck = repo.deck(packIds: config.packIds, type: challengeType);
      if (deck.isNotEmpty) {
        recycled = true;
        _picked.clear();
        // نرفع علامة الاستخدام عن هذه الأسئلة تحديدًا فقط.
        final ids = deck.map((q) => q.id);
        Future.microtask(
          () => ref.read(usedQuestionsProvider.notifier).removeAll(ids),
        );
      }
    }

    _deck = deck;
    _cursor = 0;
  }

  /// يسحب السؤال التالي من الرزمة. قراءة فقط — لا يلمس أي مزوّد.
  void _select() {
    if (_cursor >= _deck.length) _buildDeck();
    if (_deck.isEmpty) {
      question = null;
      return;
    }
    final q = _deck[_cursor++];
    question = q;
    _picked.add(q.id);
  }

  /// يسجّل الأسئلة المسحوبة كمستخدَمة (محفوظة بين الجلسات).
  ///
  /// يجب أن تُستدعى من مكان آمن (ضغطة زر أو بعد انتهاء الإطار) لا من
  /// دورة حياة الودجت.
  void _flushPicked() {
    if (_picked.isEmpty) return;
    ref.read(usedQuestionsProvider.notifier).addAll({..._picked});
  }

  /// كم سؤالًا ما زال متاحًا في الرزمة الحالية.
  int get remainingInDeck => (_deck.length - _cursor).clamp(0, _deck.length);

  /// تُستدعى بعد كل سؤال جديد — أعِد ضبط الحالة الخاصة بالتحدي هون.
  void onQuestionReady() {}

  /// تبديل السؤال الحالي بدون احتساب سؤال جديد.
  void swapQuestion() {
    setState(_select);
    _flushPicked();
    onQuestionReady();
  }

  /// إنهاء السؤال الحالي والانتقال للتالي (أو إنهاء التحدي).
  void completeQuestion() {
    if (questionIndex + 1 >= totalQuestions) {
      endChallenge();
      return;
    }
    setState(() {
      questionIndex++;
      _select();
    });
    _flushPicked();
    onQuestionReady();
  }

  void awardPoint(int teamIndex) {
    ref.read(gameProvider.notifier).awardPoint(teamIndex);
    confetti.fire();
  }

  void endChallenge() {
    // ممكن تنستدعى بعد await (تأكيد الخروج)، فمنتأكد إن الشاشة لسا موجودة.
    if (!mounted) return;
    // نتأكد إن كل أسئلة هالتحدي انسجّلت قبل ما ننتقل للتحدي التالي.
    _flushPicked();
    ref.read(gameProvider.notifier).nextChallenge();
    final s = ref.read(gameProvider)!;
    context.replaceFade(
      s.isFinished ? const ResultsScreen() : const ChallengeIntroScreen(),
    );
  }

  /// يسأل الحكم إذا متأكد قبل الخروج من التحدي.
  Future<bool> confirmQuit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء التحدي؟'),
        content: const Text('راح ينتهي هذا التحدي وتنتقلوا لللي بعده.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// الهيكل الموحّد لشاشات اللعب: خلفية الثيم + شريط النقاط + الاحتفال.
class PlayScaffold extends StatelessWidget {
  const PlayScaffold({
    required this.type,
    required this.teams,
    required this.questionIndex,
    required this.totalQuestions,
    required this.confetti,
    required this.child,
    this.activeTeamIndex,
    this.onQuit,
    this.reused = false,
    this.remaining = 0,
    super.key,
  });

  final ChallengeType type;
  final List<Team> teams;
  final int questionIndex;
  final int totalQuestions;
  final ConfettiController confetti;
  final Widget child;
  final int? activeTeamIndex;
  final VoidCallback? onQuit;
  final bool reused;

  /// عدد الأسئلة التي ما زالت في الرزمة — مفيد ليعرف الحكم ما تبقّى.
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeTheme.of(type);

    return GradientScaffold(
      theme: theme,
      title: type.title,
      showBack: false,
      actions: [
        ChunkyIconButton(
          icon: Icons.help_outline_rounded,
          tooltip: 'شرح التحدي',
          size: 44,
          iconSize: 22,
          onPressed: () => showChallengeRules(context, type),
        ),
        const SizedBox(width: T.s8),
        ChunkyIconButton(
          icon: Icons.exit_to_app_rounded,
          tooltip: 'إنهاء التحدي',
          size: 44,
          iconSize: 22,
          onPressed: onQuit,
        ),
      ],
      top: ScoreBar(
        teams: teams,
        activeTeamIndex: activeTeamIndex,
        label: 'السؤال ${questionIndex + 1} من $totalQuestions'
            '${remaining > 0 ? '  •  بقي $remaining في الحزمة' : ''}'
            '${reused ? '  •  أُعيد تدوير أسئلة الحزمة' : ''}',
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned.fill(child: ConfettiOverlay(controller: confetti)),
        ],
      ),
    );
  }
}
