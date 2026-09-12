import 'package:flutter/foundation.dart';

import 'challenge_type.dart';

/// فريق مشارك. الفريق الثالث اختياري — كل الشاشات تتكيّف مع وجوده.
@immutable
class Team {
  const Team({
    required this.name,
    this.score = 0,
    this.pointsByChallenge = const {},
  });

  final String name;
  final int score;

  /// توزيع نقاط الفريق على التحديات — يظهر في شاشة النتيجة النهائية.
  final Map<ChallengeType, int> pointsByChallenge;

  Team copyWith({String? name, int? score, Map<ChallengeType, int>? points}) =>
      Team(
        name: name ?? this.name,
        score: score ?? this.score,
        pointsByChallenge: points ?? pointsByChallenge,
      );

  /// يرجّع نسخة جديدة بعد إضافة نقطة في التحدي المحدد.
  Team awarded(ChallengeType type, [int points = 1]) {
    final next = Map<ChallengeType, int>.from(pointsByChallenge);
    next[type] = (next[type] ?? 0) + points;
    return copyWith(score: score + points, points: next);
  }
}
