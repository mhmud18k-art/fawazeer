import 'package:flutter/foundation.dart';

import 'challenge_type.dart';
import 'team.dart';

/// إعدادات تحدي واحد ضمن الجلسة: الحزم المشمولة وعدد الأسئلة.
///
/// اللاعب يقدر يعدّلها من شاشة تمهيد التحدي قبل ما يبدأ.
@immutable
class ChallengeConfig {
  const ChallengeConfig({
    required this.type,
    required this.packIds,
    this.questionCount = defaultQuestionCount,
  });

  static const int defaultQuestionCount = 5;
  static const int minQuestionCount = 1;
  static const int maxQuestionCount = 20;

  final ChallengeType type;
  final Set<String> packIds;
  final int questionCount;

  ChallengeConfig copyWith({Set<String>? packIds, int? questionCount}) =>
      ChallengeConfig(
        type: type,
        packIds: packIds ?? this.packIds,
        questionCount: questionCount ?? this.questionCount,
      );
}

/// حالة الجلسة الكاملة: الفرق، التحديات بالترتيب، والتقدّم الحالي.
@immutable
class GameSession {
  const GameSession({
    required this.teams,
    required this.challenges,
    this.currentChallengeIndex = 0,
    this.startingTeamIndex = 0,
  });

  final List<Team> teams;
  final List<ChallengeConfig> challenges;

  /// موقع التحدي الحالي ضمن [challenges].
  final int currentChallengeIndex;

  /// الفريق الذي يبدأ التحدي الحالي — يتناوب بين التحديات.
  final int startingTeamIndex;

  bool get isFinished => currentChallengeIndex >= challenges.length;

  ChallengeConfig get currentChallenge => challenges[currentChallengeIndex];

  int get teamCount => teams.length;

  /// أعلى نتيجة — قد يشاركها أكثر من فريق في حالة التعادل.
  int get topScore =>
      teams.map((t) => t.score).fold(0, (a, b) => a > b ? a : b);

  /// الفرق الفائزة (أكثر من فريق إذا في تعادل).
  List<Team> get winners =>
      teams.where((t) => t.score == topScore).toList(growable: false);

  bool get isDraw => winners.length > 1;

  GameSession copyWith({
    List<Team>? teams,
    List<ChallengeConfig>? challenges,
    int? currentChallengeIndex,
    int? startingTeamIndex,
  }) =>
      GameSession(
        teams: teams ?? this.teams,
        challenges: challenges ?? this.challenges,
        currentChallengeIndex:
            currentChallengeIndex ?? this.currentChallengeIndex,
        startingTeamIndex: startingTeamIndex ?? this.startingTeamIndex,
      );

  /// إضافة نقطة لفريق ضمن التحدي المحدد.
  GameSession awardPoint(int teamIndex, ChallengeType type) {
    final next = [...teams];
    next[teamIndex] = next[teamIndex].awarded(type);
    return copyWith(teams: next);
  }

  /// الانتقال للتحدي التالي مع تدوير الفريق الذي يبدأ.
  GameSession advanceChallenge() => copyWith(
        currentChallengeIndex: currentChallengeIndex + 1,
        startingTeamIndex: (startingTeamIndex + 1) % teams.length,
      );
}
