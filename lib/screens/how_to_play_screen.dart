import 'package:flutter/material.dart';

import '../models/challenge_type.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../widgets/animations.dart';
import '../widgets/depth_card.dart';
import '../widgets/gradient_background.dart';

/// شرح عام للّعبة + قواعد كل تحدي.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'كيف تلعب',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
        children: [
          const FadeInUp(child: _Intro()),
          const SizedBox(height: T.s20),
          for (var i = 0; i < ChallengeType.values.length; i++) ...[
            FadeInUp(
              delay: Duration(milliseconds: 70 * (i + 1)),
              child: _ChallengeRules(type: ChallengeType.values[i]),
            ),
            const SizedBox(height: T.s16),
          ],
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفكرة باختصار',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: T.s12),
          _Bullet('اللعبة بتنلعب على جهاز واحد، وجهًا لوجه بين فريقين أو ثلاثة.'),
          _Bullet(
              'واحد منكم بيكون الحكم: هو اللي ماسك الموبايل، يشوف الأسئلة والإجابات ويقرأها بصوته.'),
          _Bullet('اللاعبون ما بيشوفوا الشاشة — إلا في تحدي الجرس.'),
          _Bullet(
              'قبل ما تبدأوا بتختاروا التحديات وترتيبها، والحزم، وعدد الأسئلة بكل تحدي.'),
          _Bullet('الفريق صاحب أعلى نقاط في النهاية هو الفائز.'),
        ],
      ),
    );
  }
}

class _ChallengeRules extends StatelessWidget {
  const _ChallengeRules({required this.type});

  final ChallengeType type;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeTheme.of(type);

    return DepthCard(
      color: theme.primary.withValues(alpha: .22),
      borderColor: theme.accent.withValues(alpha: .45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(theme.accent, Colors.white, .3)!,
                      theme.accent,
                    ],
                  ),
                ),
                child: Icon(theme.icon, color: theme.onAccent, size: 26),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      type.tagline,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: .75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: T.s12),
          for (final rule in type.rules) _Bullet(rule),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: T.s8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نافذة شرح سريعة تُفتح من زر "شرح" ❓ في شاشة تمهيد التحدي.
Future<void> showChallengeRules(BuildContext context, ChallengeType type) {
  final theme = ChallengeTheme.of(type);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(T.s20),
      child: ChallengeThemeScope(
        theme: theme,
        child: DepthCard(
          color: const Color(0xFF241046),
          borderColor: theme.accent.withValues(alpha: .5),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(theme.icon, color: theme.accent, size: 28),
                    const SizedBox(width: T.s8),
                    Expanded(
                      child: Text(
                        'شرح تحدي ${type.title}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white70,
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
                const SizedBox(height: T.s8),
                for (final rule in type.rules) _Bullet(rule),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
