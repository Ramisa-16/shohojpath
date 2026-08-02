import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/passages.dart';
import 'models/reading_settings.dart';
import 'screens/reading_screen.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ShohojpathApp());
}

class ShohojpathApp extends StatelessWidget {
  const ShohojpathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // Starts in the evidence-based condition; the researcher switches
          // condition per participant from the Reading Settings screen.
          create: (_) => ReadingSettings(),
        ),
        ChangeNotifierProvider(create: (_) => TtsService()..init()),
      ],
      child: MaterialApp(
        title: 'সহজপাঠ · Shohojpath',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // The system font scale must not silently change an independent
        // variable — font size is controlled inside the app and logged.
        builder: (context, child) => MediaQuery.withNoTextScaling(
          child: child ?? const SizedBox.shrink(),
        ),
        // STEP 2: the Reading Interface is the entry point while the passage
        // renderer is being evaluated. Splash / Login / Home come later.
        home: ReadingScreen(passage: Passages.bristirDineMitu),
      ),
    );
  }
}
