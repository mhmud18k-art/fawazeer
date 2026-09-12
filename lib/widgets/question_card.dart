import 'package:flutter/material.dart';

import '../models/pack.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'depth_card.dart';

/// بطاقة السؤال الرئيسية — نص كبير وواضح حتى يقرأه الحكم بسهولة.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    this.fontSize = 23,
    this.trailing,
    super.key,
  });

  final Question question;
  final double fontSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final pack = Pack.byId(question.packId);

    return DepthCard(
      padding: const EdgeInsets.all(T.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Badge(
                icon: pack.icon,
                label: pack.name,
                color: pack.color,
              ),
              if (question.isCustom) ...[
                const SizedBox(width: T.s8),
                const _Badge(
                  icon: Icons.edit_note_rounded,
                  label: 'سؤالك',
                  color: Color(0xFFA78BFA),
                ),
              ],
            ],
          ),
          const SizedBox(height: T.s16),
          Text(
            question.text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.55,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: T.s16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(T.rSm),
        border: Border.all(color: color.withValues(alpha: .55), width: 1.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
