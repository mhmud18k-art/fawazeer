import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../widgets/animations.dart';
import '../widgets/depth_card.dart';
import '../widgets/gradient_background.dart';

/// تشغيل/إيقاف الصوت والاهتزاز.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'الإعدادات',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
        children: [
          FadeInUp(
            child: DepthCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: T.s16, vertical: T.s8),
              child: Column(
                children: [
                  _SettingSwitch(
                    icon: Icons.volume_up_rounded,
                    title: 'الأصوات',
                    subtitle: 'نقطة صحيحة، سترايك، انتهاء الوقت، والفوز',
                    value: settings.sound,
                    onChanged: (v) {
                      notifier.setSound(v);
                      // معاينة فورية للصوت لما ينفعّل.
                      if (v) FeedbackService.instance.correct();
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: .12), height: 1),
                  _SettingSwitch(
                    icon: Icons.vibration_rounded,
                    title: 'الاهتزاز',
                    subtitle: 'ردود فعل لمسية عند الضغط على الأزرار',
                    value: settings.haptics,
                    onChanged: (v) {
                      notifier.setHaptics(v);
                      if (v) FeedbackService.instance.tap();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: T.s20),
          const FadeInUp(
            delay: Duration(milliseconds: 80),
            child: DepthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عن التطبيق',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: T.s12),
                  _InfoRow(
                    icon: Icons.wifi_off_rounded,
                    text: 'يشتغل بدون إنترنت — كل الأسئلة محفوظة داخل التطبيق.',
                  ),
                  _InfoRow(
                    icon: Icons.volunteer_activism_rounded,
                    text: 'مجاني بالكامل: بدون إعلانات، بدون اشتراكات، وبدون حسابات.',
                  ),
                  _InfoRow(
                    icon: Icons.lock_open_rounded,
                    text: 'كل الحزم مفتوحة من أول لحظة — ما في محتوى مقفل.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ChallengeThemeScope.of(context);

    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.onAccent,
      activeTrackColor: theme.accent,
      contentPadding: const EdgeInsets.symmetric(vertical: T.s4),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.accent.withValues(alpha: .22),
        ),
        child: Icon(icon, color: theme.accent, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: .7),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: T.s12),
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
