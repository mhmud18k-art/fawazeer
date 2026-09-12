import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/question_repository.dart';
import 'models/pack.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'services/feedback_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storage = await StorageService.create();
  // نسجّل الفئات المخصصة قبل بناء الواجهة حتى يتعرّف عليها Pack.byId
  // من أول إطار، حتى لو لم يُقرأ مزوّدها بعد.
  Pack.setCustom(storage.loadCustomPacks());

  final repository = QuestionRepository();
  await repository.loadAssets();

  // الإعدادات المحفوظة تسري على الصوت والاهتزاز من أول إقلاع.
  FeedbackService.instance
    ..soundEnabled = storage.soundEnabled
    ..hapticsEnabled = storage.hapticsEnabled;
  await FeedbackService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        questionRepositoryProvider.overrideWithValue(repository),
      ],
      child: const FawazeerApp(),
    ),
  );
}

class FawazeerApp extends StatelessWidget {
  const FawazeerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لعبة الفوازير',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // التطبيق عربي بالكامل — كل الشاشات RTL.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeScreen(),
    );
  }
}
