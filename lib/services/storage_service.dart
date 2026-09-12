import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pack.dart';
import '../models/question.dart';

/// التخزين المحلي: الإعدادات + الأسئلة اللي يضيفها المستخدم.
///
/// أوفلاين بالكامل — ما في أي اتصال بسيرفر ولا حسابات.
class StorageService {
  StorageService(this._prefs);

  static const String _kSound = 'sound_enabled';
  static const String _kHaptics = 'haptics_enabled';
  static const String _kCustomQuestions = 'custom_questions';
  static const String _kCustomPacks = 'custom_packs';
  static const String _kUsedQuestions = 'used_question_ids';
  static const String _kTeamNames = 'team_names';

  final SharedPreferences _prefs;

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  // --- الإعدادات ------------------------------------------------------------

  bool get soundEnabled => _prefs.getBool(_kSound) ?? true;
  Future<void> setSoundEnabled(bool v) => _prefs.setBool(_kSound, v);

  bool get hapticsEnabled => _prefs.getBool(_kHaptics) ?? true;
  Future<void> setHapticsEnabled(bool v) => _prefs.setBool(_kHaptics, v);

  /// آخر أسماء فرق استخدمها اللاعب — لتوفير إعادة الكتابة كل مرة.
  List<String> get savedTeamNames => _prefs.getStringList(_kTeamNames) ?? const [];
  Future<void> setSavedTeamNames(List<String> names) =>
      _prefs.setStringList(_kTeamNames, names);

  // --- الأسئلة المخصصة ------------------------------------------------------

  List<Question> loadCustomQuestions() {
    final raw = _prefs.getString(_kCustomQuestions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('تعذّر قراءة الأسئلة المخصصة: $e');
      return [];
    }
  }

  Future<void> saveCustomQuestions(List<Question> questions) {
    final raw = jsonEncode(questions.map((q) => q.toJson()).toList());
    return _prefs.setString(_kCustomQuestions, raw);
  }

  // --- الفئات المخصصة -------------------------------------------------------

  List<Pack> loadCustomPacks() {
    final raw = _prefs.getString(_kCustomPacks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Pack.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('تعذّر قراءة الفئات المخصصة: $e');
      return [];
    }
  }

  Future<void> saveCustomPacks(List<Pack> packs) {
    final raw = jsonEncode(packs.map((p) => p.toJson()).toList());
    return _prefs.setString(_kCustomPacks, raw);
  }

  // --- الأسئلة المستخدَمة ---------------------------------------------------

  /// معرّفات الأسئلة التي عُرضت أو استُبدلت سابقًا.
  ///
  /// تُحفظ بين الجلسات حتى لا يعود السؤال نفسه في كل مرة تُفتح اللعبة.
  Set<String> loadUsedQuestionIds() =>
      (_prefs.getStringList(_kUsedQuestions) ?? const []).toSet();

  Future<void> saveUsedQuestionIds(Set<String> ids) =>
      _prefs.setStringList(_kUsedQuestions, ids.toList());
}
