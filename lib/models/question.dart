import 'challenge_type.dart';

/// درجة صعوبة السؤال.
enum QuestionDifficulty {
  medium('medium', 'متوسط'),
  hard('hard', 'صعب'),
  veryHard('very_hard', 'صعب جدًا'),
  extreme('extreme', 'شبه مستحيل');

  const QuestionDifficulty(this.id, this.label);

  final String id;
  final String label;

  static QuestionDifficulty fromId(String? id) {
    for (final d in QuestionDifficulty.values) {
      if (d.id == id) return d;
    }
    return QuestionDifficulty.medium;
  }
}

/// سؤال واحد في بنك الأسئلة.
///
/// [answers] تحمل إجابة واحدة (الجرس / من أنا / اسأل الحكم) أو عدة
/// إجابات مقترحة (الدور / مين يزوّد).
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.packId,
    required this.type,
    this.options = const [],
    this.difficulty = QuestionDifficulty.medium,
    this.isCustom = false,
  });

  final String id;

  /// نص السؤال أو اللغز. في «اسأل الحكم» أسطر متتابعة يفصلها `\n`.
  final String text;

  final List<String> answers;

  final String packId;

  final ChallengeType type;

  /// الخيارات المعروضة في أسئلة الاختيار من متعدد (فقرة «المستحيل»).
  ///
  /// الإجابة الصحيحة من بينها موجودة في [answers] الأولى.
  final List<String> options;

  final QuestionDifficulty difficulty;

  /// مضاف يدويًا من المستخدم (يظهر بشارة «سؤالك»).
  final bool isCustom;

  factory Question.fromJson(Map<String, dynamic> json, {String? packId}) {
    final typeId = json['type'] as String?;
    final type = ChallengeType.fromId(typeId ?? '');
    if (type == null) {
      throw FormatException('نوع تحدي غير معروف: $typeId');
    }
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      answers: (json['answers'] as List).map((e) => e as String).toList(),
      packId: (json['packId'] as String?) ?? packId ?? 'misc',
      type: type,
      options: (json['options'] as List?)?.map((e) => e as String).toList() ??
          const [],
      difficulty: QuestionDifficulty.fromId(json['difficulty'] as String?),
      isCustom: (json['isCustom'] as bool?) ?? false,
    );
  }

  /// موقع الإجابة الصحيحة بين [options]، أو -1 إن لم تُوجد.
  int get correctOptionIndex =>
      answers.isEmpty ? -1 : options.indexOf(answers.first);

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'answers': answers,
        'packId': packId,
        'type': type.id,
        if (options.isNotEmpty) 'options': options,
        'difficulty': difficulty.id,
        'isCustom': isCustom,
      };
}
