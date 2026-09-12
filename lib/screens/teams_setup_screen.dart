import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../utils/page_transition.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/depth_card.dart';
import '../widgets/gradient_background.dart';
import 'challenge_select_screen.dart';

/// إعداد الفرق — فريقين أساسيين وفريق ثالث اختياري.
class TeamsSetupScreen extends ConsumerStatefulWidget {
  const TeamsSetupScreen({super.key});

  @override
  ConsumerState<TeamsSetupScreen> createState() => _TeamsSetupScreenState();
}

class _TeamsSetupScreenState extends ConsumerState<TeamsSetupScreen> {
  static const int _minTeams = 2;
  static const int _maxTeams = 3;

  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(storageProvider).savedTeamNames;
    _controllers = [
      for (var i = 0; i < _maxTeams; i++)
        TextEditingController(
          text: i < saved.length && saved[i].trim().isNotEmpty
              ? saved[i]
              : 'اللاعب ${i + 1}',
        ),
    ];
    // نبدأ بفريقين — الثالث بينضاف بالزر.
    _teamCount = saved.length.clamp(_minTeams, _maxTeams);
  }

  late int _teamCount;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _names => [
        for (var i = 0; i < _teamCount; i++)
          _controllers[i].text.trim().isEmpty
              ? 'اللاعب ${i + 1}'
              : _controllers[i].text.trim(),
      ];

  void _next() {
    final names = _names;
    ref.read(storageProvider).setSavedTeamNames(names);
    context.pushFade(ChallengeSelectScreen(teamNames: names));
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'الفرق',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s16),
              children: [
                FadeInUp(
                  child: Text(
                    'اكتبوا أسماء الفرق، أو خلّوها زي ما هي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ),
                ),
                const SizedBox(height: T.s20),
                for (var i = 0; i < _teamCount; i++)
                  FadeInUp(
                    delay: Duration(milliseconds: 60 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: T.s16),
                      child: _TeamField(
                        controller: _controllers[i],
                        color: TeamColors.of(i),
                        index: i,
                        // الفريق الثالث فقط يمكن حذفه.
                        onRemove: i >= _minTeams
                            ? () => setState(() => _teamCount--)
                            : null,
                      ),
                    ),
                  ),
                if (_teamCount < _maxTeams)
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: ChunkyButton(
                      label: 'إضافة فريق ثالث',
                      icon: Icons.group_add_rounded,
                      color: Colors.white.withValues(alpha: .18),
                      foreground: Colors.white,
                      onPressed: () => setState(() => _teamCount++),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(T.s16, 0, T.s16, T.s16),
            child: ChunkyButton(
              label: 'التالي',
              icon: Icons.arrow_back_rounded,
              fontSize: 20,
              depth: 9,
              padding: const EdgeInsets.symmetric(
                  horizontal: T.s20, vertical: T.s18),
              onPressed: _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamField extends StatelessWidget {
  const _TeamField({
    required this.controller,
    required this.color,
    required this.index,
    required this.onRemove,
  });

  final TextEditingController controller;
  final Color color;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      padding: const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s12),
      borderColor: color.withValues(alpha: .6),
      color: color.withValues(alpha: .13),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(color, Colors.white, .4)!, color],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(color, Colors.black, .4)!,
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: TeamColors.on,
                ),
              ),
            ),
          ),
          const SizedBox(width: T.s12),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              maxLength: 16,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'اسم الفريق ${index + 1}',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: .7),
                  fontWeight: FontWeight.w600,
                ),
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
              color: Colors.white70,
              tooltip: 'حذف الفريق الثالث',
            ),
        ],
      ),
    );
  }
}
