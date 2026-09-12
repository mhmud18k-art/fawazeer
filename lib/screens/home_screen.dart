import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../utils/page_transition.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/gradient_background.dart';
import 'add_question_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'teams_setup_screen.dart';

/// الشاشة الرئيسية — نقطة البداية لكل شي.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      theme: ChallengeTheme.app,
      showBack: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(T.s24, T.s16, T.s24, T.s32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FadeInUp(child: _Logo()),
                const SizedBox(height: T.s20),
                const FadeInUp(
                  delay: Duration(milliseconds: 60),
                  child: DisplayTitle('لعبة الفوازير', fontSize: 38),
                ),
                const SizedBox(height: T.s8),
                FadeInUp(
                  delay: const Duration(milliseconds: 110),
                  child: Text(
                    'أربع تحديات… فريقين أو ثلاثة… وموبايل واحد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .82),
                    ),
                  ),
                ),
                const SizedBox(height: T.s48),
                FadeInUp(
                  delay: const Duration(milliseconds: 170),
                  child: ChunkyButton(
                    label: 'ابدأ لعبة جديدة',
                    icon: Icons.play_arrow_rounded,
                    shine: true,
                    fontSize: 21,
                    depth: 9,
                    padding: const EdgeInsets.symmetric(
                        horizontal: T.s20, vertical: T.s20),
                    onPressed: () =>
                        context.pushFade(const TeamsSetupScreen()),
                  ),
                ),
                const SizedBox(height: T.s16),
                FadeInUp(
                  delay: const Duration(milliseconds: 220),
                  child: ChunkyButton(
                    label: 'إضافة أسئلة',
                    icon: Icons.add_circle_outline_rounded,
                    color: const Color(0xFF8B5CF6),
                    foreground: Colors.white,
                    onPressed: () =>
                        context.pushFade(const AddQuestionScreen()),
                  ),
                ),
                const SizedBox(height: T.s16),
                FadeInUp(
                  delay: const Duration(milliseconds: 270),
                  child: ChunkyButton(
                    label: 'كيف تلعب',
                    icon: Icons.menu_book_rounded,
                    color: Colors.white.withValues(alpha: .18),
                    foreground: Colors.white,
                    onPressed: () =>
                        context.pushFade(const HowToPlayScreen()),
                  ),
                ),
                const SizedBox(height: T.s16),
                FadeInUp(
                  delay: const Duration(milliseconds: 320),
                  child: ChunkyButton(
                    label: 'الإعدادات',
                    icon: Icons.settings_rounded,
                    color: Colors.white.withValues(alpha: .18),
                    foreground: Colors.white,
                    onPressed: () => context.pushFade(const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: T.s24),
                FadeInUp(
                  delay: const Duration(milliseconds: 380),
                  child: Text(
                    'مجاني بالكامل • يشتغل بدون إنترنت',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شعار دائري بارز بأيقونة علامة استفهام ونجوم صغيرة حواليه.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 138,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDE68A), Color(0xFFFBBF24), Color(0xFFD97706)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C2D12).withValues(alpha: .9),
                  offset: const Offset(0, 8),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: .45),
                  blurRadius: 34,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              size: 62,
              color: Color(0xFF5A2600),
            ),
          ),
          const Positioned(
            top: 0,
            right: 6,
            child: Icon(Icons.star_rounded, size: 26, color: Color(0xFFE879F9)),
          ),
          const Positioned(
            bottom: 8,
            left: 0,
            child: Icon(Icons.star_rounded, size: 20, color: Color(0xFF67E8F9)),
          ),
        ],
      ),
    );
  }
}
