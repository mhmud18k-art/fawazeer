import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// أصوات اللعبة. كلها مولّدة محليًا ومرفقة مع التطبيق (أوفلاين بالكامل).
///
/// الصيغة WAV بترميز PCM ١٦-بت، وهي أكثر صيغة يتعامل معها
/// `audioplayers` بثبات على أندرويد و iOS معًا.
enum Sfx {
  /// ضغطة زر عامة.
  tap('sounds/tap.wav'),

  /// إجابة صحيحة أو تسجيل نقطة.
  correct('sounds/correct.wav'),

  /// سترايك أو إجابة خاطئة.
  strike('sounds/strike.wav'),

  /// بداية العدّاد التنازلي.
  start('sounds/start.wav'),

  /// تكّة في آخر خمس ثوانٍ.
  tick('sounds/tick.wav'),

  /// انتهاء الوقت — جرس واضح وقوي.
  timeUp('sounds/timeup.wav'),

  /// الفوز في نهاية اللعبة.
  win('sounds/win.wav'),

  /// ضغط زر الجرس.
  buzz('sounds/buzz.wav');

  const Sfx(this.asset);

  /// المسار نسبةً إلى مجلد `assets/` — هكذا يتوقّعه `AssetSource`.
  final String asset;
}

/// خدمة موحّدة للصوت والاهتزاز.
///
/// singleton حتى تستطيع أي ودجت مناداتها دون تمرير providers عبر الشجرة.
/// شاشة الإعدادات تحدّث [soundEnabled] و[hapticsEnabled].
class FeedbackService {
  FeedbackService._();

  static final FeedbackService instance = FeedbackService._();

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  /// مشغّل مستقل لكل صوت حتى لا يقطع صوتٌ آخر (التكّة مع الرنّة مثلًا).
  final Map<Sfx, AudioPlayer> _players = {};
  bool _ready = false;

  /// تهيئة سياق الصوت وتحميل الملفات مسبقًا.
  ///
  /// السياق مضبوط على **وسائط** (media/music) حتى يخرج الصوت من مستوى
  /// صوت الوسائط ويعمل حتى لو كان الجرس صامتًا.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            // لا نطلب تركيز الصوت: المؤثرات قصيرة ولا يجب أن تُخفض
            // صوت أي تطبيق آخر، والطلب نفسه يضيف تأخيرًا محسوسًا.
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('تعذّر ضبط سياق الصوت: $e');
    }

    // نسخ ملفات الأصول إلى الذاكرة المؤقتة مرة واحدة حتى لا يتأخر
    // أول تشغيل لكل صوت.
    try {
      await AudioCache.instance.loadAll([for (final s in Sfx.values) s.asset]);
    } catch (e) {
      debugPrint('تعذّر التحميل المسبق للأصوات: $e');
    }

    for (final sfx in Sfx.values) {
      try {
        final player = AudioPlayer(playerId: sfx.name);
        // mediaPlayer أكثر موثوقية من lowLatency على أندرويد؛
        // الأخير يستخدم SoundPool وقد يفشل بصمت.
        await player.setPlayerMode(PlayerMode.mediaPlayer);
        await player.setReleaseMode(ReleaseMode.stop);
        _players[sfx] = player;
      } catch (e) {
        // الصوت ليس ضروريًا للّعب — نكمل بدونه.
        debugPrint('تعذّر تهيئة المشغّل ${sfx.asset}: $e');
      }
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!soundEnabled) return;
    final player = _players[sfx];
    if (player == null) return;
    try {
      // إعادة التشغيل من الصفر حتى لو كان الصوت السابق ما زال شغّالًا.
      await player.stop();
      await player.play(AssetSource(sfx.asset));
    } catch (e) {
      debugPrint('تعذّر تشغيل الصوت ${sfx.asset}: $e');
    }
  }

  // --- ردود الفعل المركّبة (صوت + اهتزاز) ---------------------------------

  void tap() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    play(Sfx.tap);
  }

  void correct() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
    play(Sfx.correct);
  }

  void strike() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    play(Sfx.strike);
  }

  /// بداية العدّاد التنازلي.
  void countdownStart() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
    play(Sfx.start);
  }

  /// تكّة كل ثانية في آخر خمس ثوانٍ — بلا اهتزاز حتى لا تزعج.
  void countdownTick() => play(Sfx.tick);

  /// انتهاء الوقت — تنبيه صوتي واضح.
  void timeUp() {
    if (hapticsEnabled) HapticFeedback.vibrate();
    play(Sfx.timeUp);
  }

  void win() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    play(Sfx.win);
  }

  void buzz() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
    play(Sfx.buzz);
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    _ready = false;
  }
}
