import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_repository.dart';
import '../models/challenge_type.dart';
import '../models/game_session.dart';
import '../models/pack.dart';
import '../models/question.dart';
import '../models/team.dart';
import '../services/feedback_service.dart';
import '../services/storage_service.dart';

/// يُستبدل في `main()` بعد تهيئة SharedPreferences.
final storageProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageProvider لازم يُستبدل في main()'),
);

/// يُستبدل في `main()` بعد قراءة ملفات الأسئلة.
final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => throw UnimplementedError('questionRepositoryProvider لازم يُستبدل'),
);

// --- الإعدادات --------------------------------------------------------------

class Settings {
  const Settings({required this.sound, required this.haptics});

  final bool sound;
  final bool haptics;

  Settings copyWith({bool? sound, bool? haptics}) =>
      Settings(sound: sound ?? this.sound, haptics: haptics ?? this.haptics);
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier(this._storage)
      : super(Settings(
          sound: _storage.soundEnabled,
          haptics: _storage.hapticsEnabled,
        )) {
    _sync();
  }

  final StorageService _storage;

  /// نمرّر الإعدادات لخدمة الصوت حتى تحترمها كل الودجت.
  void _sync() {
    FeedbackService.instance
      ..soundEnabled = state.sound
      ..hapticsEnabled = state.haptics;
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(sound: value);
    _sync();
    await _storage.setSoundEnabled(value);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(haptics: value);
    _sync();
    await _storage.setHapticsEnabled(value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>(
  (ref) => SettingsNotifier(ref.watch(storageProvider)),
);

// --- الأسئلة المخصصة --------------------------------------------------------

class CustomQuestionsNotifier extends StateNotifier<List<Question>> {
  CustomQuestionsNotifier(this._storage, this._repo)
      : super(_storage.loadCustomQuestions()) {
    _repo.setCustomQuestions(state);
  }

  final StorageService _storage;
  final QuestionRepository _repo;

  Future<void> add(Question question) async {
    state = [...state, question];
    _repo.setCustomQuestions(state);
    await _storage.saveCustomQuestions(state);
  }

  Future<void> remove(String id) async {
    state = state.where((q) => q.id != id).toList();
    _repo.setCustomQuestions(state);
    await _storage.saveCustomQuestions(state);
  }

  /// تُستدعى عند حذف فئة مخصصة — أسئلتها تُحذف معها.
  Future<void> removeByPack(String packId) async {
    state = state.where((q) => q.packId != packId).toList();
    _repo.setCustomQuestions(state);
    await _storage.saveCustomQuestions(state);
  }
}

final customQuestionsProvider =
    StateNotifierProvider<CustomQuestionsNotifier, List<Question>>(
  (ref) => CustomQuestionsNotifier(
    ref.watch(storageProvider),
    ref.watch(questionRepositoryProvider),
  ),
);

// --- الفئات المخصصة ----------------------------------------------------------

/// الحزم التي ينشئها المستخدم بأسماء من اختياره.
///
/// تُحفظ محليًا وتظهر مع الحزم المدمجة في كل شاشات الاختيار.
class CustomPacksNotifier extends StateNotifier<List<Pack>> {
  CustomPacksNotifier(this._storage) : super(_storage.loadCustomPacks()) {
    Pack.setCustom(state);
  }

  final StorageService _storage;

  Future<void> _commit(List<Pack> next) async {
    state = next;
    Pack.setCustom(next);
    await _storage.saveCustomPacks(next);
  }

  /// ينشئ فئة جديدة ويرجّع معرّفها.
  Future<Pack> add(String name) async {
    final pack = Pack.custom(
      id: 'pack_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
    );
    await _commit([...state, pack]);
    return pack;
  }

  Future<void> rename(String id, String name) => _commit([
        for (final p in state)
          if (p.id == id) p.copyWith(name: name.trim()) else p,
      ]);

  Future<void> remove(String id) =>
      _commit(state.where((p) => p.id != id).toList());
}

final customPacksProvider =
    StateNotifierProvider<CustomPacksNotifier, List<Pack>>(
  (ref) => CustomPacksNotifier(ref.watch(storageProvider)),
);

// --- الأسئلة المستخدَمة -------------------------------------------------------

/// معرّفات الأسئلة التي عُرضت أو استُبدلت — محفوظة بين الجلسات.
///
/// هي مرجع الحقيقة الوحيد لمنع التكرار، ولا تُمسح إلا عند نفاد أسئلة
/// حزمة معيّنة فيُعاد تدويرها.
class UsedQuestionsNotifier extends StateNotifier<Set<String>> {
  UsedQuestionsNotifier(this._storage) : super(_storage.loadUsedQuestionIds());

  final StorageService _storage;

  Future<void> addAll(Set<String> ids) async {
    if (ids.every(state.contains)) return;
    state = {...state, ...ids};
    await _storage.saveUsedQuestionIds(state);
  }

  /// تُستدعى عند إعادة تدوير أسئلة نفدت، فتعود صالحة للعرض.
  Future<void> removeAll(Iterable<String> ids) async {
    final next = {...state}..removeAll(ids);
    state = next;
    await _storage.saveUsedQuestionIds(next);
  }

  Future<void> clear() async {
    state = const {};
    await _storage.saveUsedQuestionIds(const {});
  }
}

final usedQuestionsProvider =
    StateNotifierProvider<UsedQuestionsNotifier, Set<String>>(
  (ref) => UsedQuestionsNotifier(ref.watch(storageProvider)),
);

// --- الجلسة ------------------------------------------------------------------

class GameNotifier extends StateNotifier<GameSession?> {
  GameNotifier() : super(null);

  /// يبدأ جلسة جديدة. [order] هو ترتيب التحديات كما اختاره اللاعب.
  void start({
    required List<String> teamNames,
    required List<ChallengeType> order,
    required Set<String> packIds,
    int questionCount = ChallengeConfig.defaultQuestionCount,
  }) {
    state = GameSession(
      teams: [for (final name in teamNames) Team(name: name)],
      challenges: [
        for (final type in order)
          ChallengeConfig(
            type: type,
            packIds: {...packIds},
            questionCount: questionCount,
          ),
      ],
    );
  }

  void awardPoint(int teamIndex) {
    final s = state;
    if (s == null || s.isFinished) return;
    state = s.awardPoint(teamIndex, s.currentChallenge.type);
  }


  /// تعديل إعدادات التحدي الحالي من شاشة التمهيد.
  void updateCurrentChallenge({Set<String>? packIds, int? questionCount}) {
    final s = state;
    if (s == null || s.isFinished) return;
    final next = [...s.challenges];
    next[s.currentChallengeIndex] = next[s.currentChallengeIndex]
        .copyWith(packIds: packIds, questionCount: questionCount);
    state = s.copyWith(challenges: next);
  }

  void nextChallenge() {
    final s = state;
    if (s == null) return;
    state = s.advanceChallenge();
  }

  void reset() => state = null;
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameSession?>((ref) => GameNotifier());

/// عدد الأسئلة في كل حزمة — يظهر في شاشة اختيار الحزم.
final packCountsProvider = Provider<Map<String, int>>((ref) {
  final repo = ref.watch(questionRepositoryProvider);
  // نراقب الأسئلة والفئات المخصصة حتى تتحدّث الأعداد والقائمة معًا.
  ref.watch(customQuestionsProvider);
  ref.watch(customPacksProvider);
  return {
    for (final pack in Pack.all) pack.id: repo.countForPack(pack.id),
  };
});
