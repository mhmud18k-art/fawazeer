import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge_type.dart';
import '../models/team.dart';
import '../providers/app_providers.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/confetti.dart';
import '../widgets/depth_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/score_bar.dart';

/// شاشة النتيجة النهائية: الفائز، النقاط، وإحصائيات بسيطة.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final ConfettiController _confetti = ConfettiController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FeedbackService.instance.win();
      _confetti.fire();
      // دفعة ثانية بعد شوي حتى يستمر الاحتفال.
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) _confetti.fire();
      });
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _newGame() {
    ref.read(gameProvider.notifier).reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    if (session == null) return const SizedBox.shrink();

    final winners = session.winners;
    final ranked = [...session.teams]
      ..sort((a, b) => b.score.compareTo(a.score));

    // التحديات اللي انلعبت فعليًا — لعرض الإحصائيات.
    final playedTypes = <ChallengeType>[
      for (final c in session.challenges) c.type,
    ];

    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'النتيجة النهائية',
      showBack: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
            children: [
              FadeInUp(
                child: _WinnerBanner(
                  winners: winners,
                  isDraw: session.isDraw,
                  teams: session.teams,
                ),
              ),
              const SizedBox(height: T.s24),
              for (var rank = 0; rank < ranked.length; rank++)
                FadeInUp(
                  delay: Duration(milliseconds: 90 * (rank + 1)),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: T.s12),
                    child: _TeamResultCard(
                      team: ranked[rank],
                      rank: rank + 1,
                      color: TeamColors.of(session.teams.indexOf(ranked[rank])),
                      playedTypes: playedTypes,
                    ),
                  ),
                ),
              const SizedBox(height: T.s16),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: ChunkyButton(
                  label: 'لعبة جديدة',
                  icon: Icons.replay_rounded,
                  fontSize: 20,
                  depth: 9,
                  padding: const EdgeInsets.symmetric(
                      horizontal: T.s20, vertical: T.s18),
                  onPressed: _newGame,
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: ConfettiOverlay(controller: _confetti, pieces: 110),
          ),
        ],
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({
    required this.winners,
    required this.isDraw,
    required this.teams,
  });

  final List<Team> winners;
  final bool isDraw;
  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final names = winners.map((t) => t.name).join(' و ');

    return Column(
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          size: 96,
          color: Color(0xFFFBBF24),
          shadows: [
            Shadow(color: Color(0xFF7C2D12), offset: Offset(0, 6)),
            Shadow(color: Color(0x88FBBF24), blurRadius: 30),
          ],
        ),
        const SizedBox(height: T.s12),
        Text(
          isDraw ? 'تعادل!' : 'الفائز',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: .8),
          ),
        ),
        const SizedBox(height: T.s4),
        DisplayTitle(names, fontSize: 30),
        const SizedBox(height: T.s8),
        Text(
          isDraw
              ? 'نفس عدد النقاط — لعبة متكافئة!'
              : 'مبروك 🎉 بـ ${winners.first.score} نقطة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: .88),
          ),
        ),
      ],
    );
  }
}

class _TeamResultCard extends StatelessWidget {
  const _TeamResultCard({
    required this.team,
    required this.rank,
    required this.color,
    required this.playedTypes,
  });

  final Team team;
  final int rank;
  final Color color;
  final List<ChallengeType> playedTypes;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      color: color.withValues(alpha: .15),
      borderColor: color.withValues(alpha: rank == 1 ? .9 : .4),
      glow: rank == 1 ? color : null,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: .3),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .25)),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              ScoreBadge(value: team.score, color: color, size: 54),
            ],
          ),
          const SizedBox(height: T.s12),
          Divider(color: Colors.white.withValues(alpha: .14), height: 1),
          const SizedBox(height: T.s12),
          // توزيع النقاط على التحديات.
          Row(
            children: [
              for (final type in playedTypes)
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        ChallengeTheme.of(type).icon,
                        size: 20,
                        color: ChallengeTheme.of(type).accent,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team.pointsByChallenge[type] ?? 0}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        type.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
