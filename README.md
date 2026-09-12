<div align="center">

# فوازير · Fawazeer

**An Arabic party quiz game for one shared phone. No accounts, no internet, no ads.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-4B6BFB)](https://riverpod.dev)
[![Offline](https://img.shields.io/badge/Offline-100%25-34D399)](#why-offline)
[![License: MIT](https://img.shields.io/badge/License-MIT-A78BFA)](LICENSE)

English · [العربية](#بالعربية)

</div>

---

## What this is

A quiz game built for the way people actually play in a living room: one phone, passed around, two teams shouting at each other. Not an online trivia app where everyone stares at their own screen.

It runs entirely offline. There is no backend, no account, no network call — the whole game, all thirty-odd question packs and every sound, ships inside the app.

## Game modes

Six different ways to play, each with its own rules, timing and scoring:

| Mode | الوضع | How it plays |
|---|---|---|
| **Bell** | الجرس | First team to buzz answers. Wrong answer passes the question. |
| **Clue** | التلميح | Clues are revealed one by one — the longer you wait, the fewer points. |
| **Auction** | المزاد | Teams bid on how many they can answer, then have to deliver. |
| **Dawr** | الدور | Turn-based rounds, each team answers in sequence. |
| **Impossible** | المستحيل | The hard pack. Strikes instead of points. |
| **Ask the judge** | اسأل الحكم | Disputed answers go to a human ruling. |

## Content

Thirty-plus curated question packs across football, geography, history, religion, series and general knowledge — including separate "impossible" tiers for each category. Teams can also add their own questions in-app; custom questions persist locally.

## Why offline

Every design decision here follows from one constraint: **it has to work when the internet doesn't.**

That rules out a backend, which rules out accounts, which rules out sign-up friction. The game opens and you are playing in under ten seconds. It also means the app keeps working in a car, on a roof, at a family gathering with bad reception — which is exactly where this kind of game gets played.

State lives in Riverpod during a session and in `shared_preferences` between them. Question packs are JSON assets read at launch.

## Built in Arabic

The interface is Arabic and right-to-left throughout, set in **Tajawal**. `flutter_localizations` provides the Material RTL behaviour, and the layout is composed right-to-left rather than mirrored from an English original.

## Project structure

```
lib/
├── models/        Team, GameSession, Question, Pack, ChallengeType
├── screens/       Home, teams setup, pack & challenge select, results, settings
│   └── play/      One screen per game mode — bell, clue, auction, dawr, impossible
├── widgets/       Timer, score bar, strike indicator, confetti, chunky button, cards
├── providers/     Riverpod state
├── services/      Local storage, haptic & sound feedback
├── theme/         App theme + per-mode theming
└── data/          Question repository

assets/
├── questions/     30+ JSON packs
├── sounds/        Buzz, tick, correct, strike, win, time-up
└── fonts/         Tajawal (SIL OFL, licence included)
```

## Running it

```bash
flutter pub get
flutter run
```

> Platform folders (`android/`, `ios/`, `web/`) are not committed — this repository holds the app code rather than generated scaffolding. Run `flutter create .` once to regenerate them before building for a device.

## License

[MIT](LICENSE) © Mohammad Almoslly. Tajawal is used under the SIL Open Font Licence — see `assets/fonts/OFL-Tajawal.txt`.

---

<div dir="rtl">

## بالعربية

**فوازير** — لعبة فوازير جماعية عربية، تُلعب على جهاز واحد. بلا حسابات، بلا إنترنت، وبلا إعلانات.

مبنية للطريقة اللي الناس فعلاً تلعب فيها: تلفون واحد يدور بين الجالسين، وفريقان يتنافسان. مو تطبيق أونلاين كل واحد فيه غارق بشاشته.

### أوضاع اللعب

ستة أوضاع، كل واحد بقوانينه وتوقيته وطريقة تسجيله: **الجرس** (أسرع فريق يضغط يجاوب)، و**التلميح** (التلميحات تنكشف واحداً واحداً، وكل ما تأخرت قلّت النقاط)، و**المزاد** (الفرق تزايد على عدد الأسئلة اللي تقدر تجاوبها، وبعدين لازم توفي)، و**الدور**، و**المستحيل** (الباقة الصعبة، بأخطاء بدل نقاط)، و**اسأل الحكم**.

### المحتوى

أكثر من ثلاثين باقة أسئلة في كرة القدم والجغرافيا والتاريخ والدين والمسلسلات والمعلومات العامة — ولكل تصنيف مستوى "مستحيل" منفصل. وتقدر الفرق تضيف أسئلتها الخاصة من داخل التطبيق، وتُحفظ محلياً.

### ليش أوفلاين

كل قرار في التطبيق نابع من شرط واحد: **لازم يشتغل لمّا الإنترنت ما يشتغل.**

وهذا يلغي الحاجة لخادم، واللي يلغي الحسابات، واللي يلغي احتكاك التسجيل. تفتح التطبيق وتكون تلعب خلال عشر ثوانٍ. ويعني كمان إنه يشتغل في السيارة، وعلى السطح، وفي عزيمة عيلة بتغطية ضعيفة — وهذي بالضبط المواقف اللي تُلعب فيها هذي اللعبة.

### التصميم

الواجهة عربية بالكامل وبالاتجاه من اليمين إلى اليسار، بخط **Tajawal**، والتخطيط مبني بهذا الاتجاه لا معكوساً عن نسخة إنجليزية.

### التشغيل

```bash
flutter pub get
flutter run
```

</div>
