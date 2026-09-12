import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge_type.dart';
import '../models/pack.dart';
import '../models/question.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/challenge_theme.dart';
import '../widgets/animations.dart';
import '../widgets/chunky_button.dart';
import '../widgets/depth_card.dart';
import '../widgets/gradient_background.dart';

/// القيمة الخاصة في قائمة الفئات التي تفتح حقل إنشاء فئة جديدة.
const String _newPackValue = '__new_pack__';

/// إضافة أسئلة يدويًا — تُحفظ محليًا وتظهر مع بنك الأسئلة الجاهز.
///
/// يمكن كذلك إنشاء **فئة جديدة باسم من اختيارك** أثناء الإضافة،
/// وتظهر بعدها مع باقي الحزم في شاشة اختيار الحزم.
class AddQuestionScreen extends ConsumerStatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  ConsumerState<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends ConsumerState<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _newPackController = TextEditingController();
  List<TextEditingController> _answerControllers = [TextEditingController()];

  String _packId = Pack.builtIn.first.id;
  ChallengeType _type = ChallengeType.dawr;

  bool get _creatingPack => _packId == _newPackValue;

  /// الجرس و«من أنا» و«اسأل الحكم» إجابتهم واحدة محددة.
  bool get _singleAnswer => _type.hasSingleAnswer;

  @override
  void dispose() {
    _questionController.dispose();
    _newPackController.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(ChallengeType? type) {
    if (type == null) return;
    setState(() {
      _type = type;
      if (_singleAnswer && _answerControllers.length > 1) {
        for (final c in _answerControllers.skip(1)) {
          c.dispose();
        }
        _answerControllers = [_answerControllers.first];
      }
    });
  }

  void _addAnswerField() =>
      setState(() => _answerControllers.add(TextEditingController()));

  void _removeAnswerField(int index) =>
      setState(() => _answerControllers.removeAt(index).dispose());

  String _newId() =>
      'c_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // إنشاء الفئة الجديدة أولًا إن اختارها المستخدم.
    var packId = _packId;
    if (_creatingPack) {
      final pack = await ref
          .read(customPacksProvider.notifier)
          .add(_newPackController.text);
      packId = pack.id;
    }

    final answers = _answerControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    await ref.read(customQuestionsProvider.notifier).add(
          Question(
            id: _newId(),
            text: _questionController.text.trim(),
            answers: answers,
            packId: packId,
            type: _type,
            isCustom: true,
          ),
        );

    if (!mounted) return;

    _questionController.clear();
    _newPackController.clear();
    setState(() {
      // نبقى داخل الفئة التي أضفنا إليها لتسهيل إضافة أسئلة متتابعة.
      _packId = packId;
      for (final c in _answerControllers) {
        c.dispose();
      }
      _answerControllers = [TextEditingController()];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('أُضيف السؤال إلى «${Pack.byId(packId).name}»')),
    );
  }

  Future<void> _renamePack(Pack pack) async {
    final controller = TextEditingController(text: pack.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم الفئة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(customPacksProvider.notifier).rename(pack.id, name);
    }
  }

  Future<void> _deletePack(Pack pack) async {
    final count = ref
        .read(customQuestionsProvider)
        .where((q) => q.packId == pack.id)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف «${pack.name}»؟'),
        content: Text(
          count == 0
              ? 'ستُحذف هذه الفئة نهائيًا.'
              : 'ستُحذف الفئة و$count سؤالًا بداخلها نهائيًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(customQuestionsProvider.notifier).removeByPack(pack.id);
    await ref.read(customPacksProvider.notifier).remove(pack.id);

    if (!mounted) return;
    // لو كنا واقفين على الفئة المحذوفة نرجع لفئة صالحة.
    if (_packId == pack.id) {
      setState(() => _packId = Pack.builtIn.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final custom = ref.watch(customQuestionsProvider);
    final customPacks = ref.watch(customPacksProvider);
    const accent = ChallengeTheme.app;

    return GradientScaffold(
      theme: ChallengeTheme.app,
      title: 'إضافة أسئلة',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
          children: [
            FadeInUp(
              child: DepthCard(
                blur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('الفئة'),
                    _PackChips(
                      selected: _packId,
                      packs: Pack.all,
                      onSelected: (id) => setState(() => _packId = id),
                    ),
                    if (_creatingPack) ...[
                      const SizedBox(height: T.s12),
                      TextFormField(
                        controller: _newPackController,
                        maxLength: 30,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                        decoration: _fieldDecoration(
                          'اسم الفئة الجديدة — مثلًا: أسئلة العيلة',
                          counter: '',
                        ),
                        validator: (v) {
                          final name = (v ?? '').trim();
                          if (name.isEmpty) return 'اكتب اسمًا للفئة';
                          final taken = Pack.all.any((p) =>
                              p.name.trim() == name && p.id != _packId);
                          if (taken) return 'يوجد فئة بهذا الاسم';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: T.s16),
                    const _Label('نوع التحدي'),
                    _TypeDropdown(value: _type, onChanged: _onTypeChanged),
                    const SizedBox(height: T.s16),
                    _Label(_type == ChallengeType.askJudge
                        ? 'الأوصاف (سطر لكل وصف)'
                        : 'نص السؤال'),
                    TextFormField(
                      controller: _questionController,
                      maxLines: _type == ChallengeType.askJudge ? 6 : 3,
                      minLines: 2,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.ink,
                      ),
                      decoration: _fieldDecoration(switch (_type) {
                        ChallengeType.askJudge =>
                          'بلد\nيقع في شمال أفريقيا\nيمر عبره نهر النيل',
                        ChallengeType.whoAmI =>
                          'أنا سورة من سور القرآن… فمن أنا؟',
                        _ => 'اكتب نص السؤال هنا',
                      }),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اكتب نص السؤال'
                          : null,
                    ),
                    const SizedBox(height: T.s16),
                    _Label(_singleAnswer ? 'الإجابة' : 'الإجابات المقترحة'),
                    for (var i = 0; i < _answerControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: T.s8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _answerControllers[i],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.ink,
                                ),
                                decoration:
                                    _fieldDecoration('إجابة ${i + 1}'),
                                validator: i == 0
                                    ? (v) => (v == null || v.trim().isEmpty)
                                        ? 'اكتب إجابة واحدة على الأقل'
                                        : null
                                    : null,
                              ),
                            ),
                            if (_answerControllers.length > 1)
                              IconButton(
                                onPressed: () => _removeAnswerField(i),
                                icon: const Icon(
                                    Icons.remove_circle_outline_rounded),
                                color: const Color(0xFF9E4B52),
                                tooltip: 'حذف الإجابة',
                              ),
                          ],
                        ),
                      ),
                    if (!_singleAnswer)
                      TextButton.icon(
                        onPressed: _addAnswerField,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('إضافة إجابة'),
                        style: TextButton.styleFrom(
                          foregroundColor: accent.accent,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: T.s16),
            ChunkyButton(
              label: 'حفظ السؤال',
              icon: Icons.save_outlined,
              fontSize: 17,
              depth: 1.4,
              onPressed: _save,
            ),
            if (customPacks.isNotEmpty) ...[
              const SizedBox(height: T.s32),
              const _SectionTitle('فئاتي'),
              const SizedBox(height: T.s12),
              for (final pack in customPacks)
                Padding(
                  padding: const EdgeInsets.only(bottom: T.s8),
                  child: _CustomPackTile(
                    pack: pack,
                    count: custom.where((q) => q.packId == pack.id).length,
                    onRename: () => _renamePack(pack),
                    onDelete: () => _deletePack(pack),
                  ),
                ),
            ],
            if (custom.isNotEmpty) ...[
              const SizedBox(height: T.s32),
              _SectionTitle('أسئلتي (${custom.length})'),
              const SizedBox(height: T.s12),
              for (final q in custom.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: T.s8),
                  child: _CustomQuestionTile(
                    question: q,
                    onDelete: () => ref
                        .read(customQuestionsProvider.notifier)
                        .remove(q.id),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint, {String? counter}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B7684),
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      counterText: counter,
      filled: true,
      fillColor: Colors.black.withValues(alpha: .28),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s12),
      border: _border(Colors.white.withValues(alpha: .10)),
      enabledBorder: _border(Colors.white.withValues(alpha: .10)),
      focusedBorder: _border(ChallengeTheme.app.accent, width: 1.4),
      errorBorder: _border(const Color(0xFF9E4B52)),
      focusedErrorBorder: _border(const Color(0xFF9E4B52), width: 1.4),
    );

OutlineInputBorder _border(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(T.rSm),
      borderSide: BorderSide(color: color, width: width),
    );

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: T.s8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
            color: AppTheme.ink,
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
          color: AppTheme.ink,
        ),
      );
}

/// اختيار الفئة بشرائح ظاهرة كلها دفعةً واحدة.
///
/// أوضح من القائمة المنسدلة على الشاشات الصغيرة، ويتحدّث فورًا حين
/// تُنشأ فئة جديدة — بخلاف `DropdownButtonFormField` الذي يقرأ قيمته
/// الابتدائية مرة واحدة فقط.
class _PackChips extends StatelessWidget {
  const _PackChips({
    required this.selected,
    required this.packs,
    required this.onSelected,
  });

  final String selected;
  final List<Pack> packs;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = ChallengeTheme.app.accent;

    return Wrap(
      spacing: T.s8,
      runSpacing: T.s8,
      children: [
        for (final pack in packs)
          _Chip(
            label: pack.name,
            icon: pack.icon,
            color: pack.color,
            active: selected == pack.id,
            onTap: () => onSelected(pack.id),
          ),
        _Chip(
          label: 'فئة جديدة',
          icon: Icons.add_rounded,
          color: accent,
          active: selected == _newPackValue,
          onTap: () => onSelected(_newPackValue),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: T.quick,
          curve: T.smooth,
          constraints: const BoxConstraints(minHeight: T.minTouch),
          padding: const EdgeInsets.symmetric(
              horizontal: T.s12, vertical: T.s8),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: .18)
                : Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(T.rSm),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: .8)
                  : Colors.white.withValues(alpha: .10),
              width: T.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: active ? color : AppTheme.inkMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.ink : AppTheme.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final ChallengeType value;
  final ValueChanged<ChallengeType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ChallengeType>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF141A24),
      borderRadius: BorderRadius.circular(T.rSm),
      decoration: _fieldDecoration(''),
      style: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
      ),
      items: [
        for (final type in ChallengeType.values)
          DropdownMenuItem(
            value: type,
            child: Row(
              children: [
                Icon(
                  ChallengeTheme.of(type).icon,
                  size: 19,
                  color: ChallengeTheme.of(type).accent,
                ),
                const SizedBox(width: T.s8),
                Text(type.title),
              ],
            ),
          ),
      ],
    );
  }
}

class _CustomPackTile extends StatelessWidget {
  const _CustomPackTile({
    required this.pack,
    required this.count,
    required this.onRename,
    required this.onDelete,
  });

  final Pack pack;
  final int count;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s8),
      borderColor: pack.color.withValues(alpha: .4),
      child: Row(
        children: [
          Icon(pack.icon, color: pack.color, size: 22),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  '$count سؤال',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppTheme.inkMuted,
            tooltip: 'تعديل الاسم',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFF9E4B52),
            tooltip: 'حذف الفئة',
          ),
        ],
      ),
    );
  }
}

class _CustomQuestionTile extends StatelessWidget {
  const _CustomQuestionTile({required this.question, required this.onDelete});

  final Question question;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pack = Pack.byId(question.packId);
    // في «اسأل الحكم» نعرض أول سطر فقط في القائمة.
    final preview = question.text.split('\n').first.trim();

    return DepthCard(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s8),
      child: Row(
        children: [
          Icon(pack.icon, color: pack.color, size: 20),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pack.name} • ${question.type.title} • '
                  '${question.answers.length} إجابة',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFF9E4B52),
            tooltip: 'حذف السؤال',
          ),
        ],
      ),
    );
  }
}
