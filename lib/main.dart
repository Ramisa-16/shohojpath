import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app_nav_state.dart';
import 'app/participant_state.dart';
import 'models/reading_settings.dart';
import 'screens/splash_screen.dart';
import 'services/app_config_repository.dart';
import 'services/reader_repository.dart';
import 'services/session_logger.dart';
import 'services/settings_repository.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final repository = SettingsRepository();
  final settings = ReadingSettings();
  final participant = ParticipantState();

  // Nobody is signed in yet at launch, so there is no participant row to
  // load from or save to — Splash/Login render with the plain constructor
  // default until sign-in calls loadReaderProfile for whoever it is.
  //
  // Debounced so dragging a slider doesn't queue a database write per frame
  // — only the value the reader settles on gets persisted, keyed to
  // whichever participant is currently signed in.
  Timer? saveDebounce;
  settings.addListener(() {
    final id = participant.participantId;
    // A therapist-locked condition (Default/Recommended) is forced onto the
    // shared settings instance for this session only — it must never
    // overwrite the reader's own saved preferences for next time.
    if (id.isEmpty || participant.isSettingsLocked) return;
    saveDebounce?.cancel();
    saveDebounce = Timer(
      const Duration(milliseconds: 400),
      () => repository.save(id, settings.toMap()),
    );
  });

  // Registered once, permanently, so a settings change made from the Library
  // or the Settings screen — outside any reading session — still gets
  // logged, not just the ones made while a ReadingScreen is on-screen.
  // SessionLogger.logSettingsChange itself attributes each change to
  // whichever session id is currently active (or none).
  final logger = SessionLogger();
  settings.addChangeObserver(logger.logSettingsChange);

  runApp(ShohojpathApp(
    settings: settings,
    logger: logger,
    participant: participant,
    settingsRepository: repository,
  ));
}

/// Material's default overscroll effect wraps every scrollable in an
/// `ImageFiltered` stretch shader. On some emulator/GPU driver combinations
/// running the Impeller backend that filter renders as fully transparent —
/// the scrollable's own layout is untouched (correct sizes throughout), but
/// nothing under it paints. Turning the decorative indicator off avoids the
/// broken code path entirely rather than working around a driver bug.
class _NoOverscrollIndicator extends MaterialScrollBehavior {
  const _NoOverscrollIndicator();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class ShohojpathApp extends StatelessWidget {
  const ShohojpathApp({
    super.key,
    required this.settings,
    required this.logger,
    required this.participant,
    required this.settingsRepository,
  });

  final ReadingSettings settings;
  final SessionLogger logger;
  final ParticipantState participant;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => TtsService()..init()),
        ChangeNotifierProvider(create: (_) => AppNavState()),
        ChangeNotifierProvider.value(value: participant),
        Provider.value(value: logger),
        Provider.value(value: settingsRepository),
        Provider(create: (_) => ReaderRepository()),
        Provider(create: (_) => AppConfigRepository()),
      ],
      child: MaterialApp(
        title: 'সহজপাঠ · Shohojpath',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        scrollBehavior: const _NoOverscrollIndicator(),
        // The font size setting is a whole-app independent variable, not
        // just a passage style — it has to scale every reader screen's
        // text, not only the passage itself. The OS's own accessibility
        // text scale is deliberately overridden rather than combined with,
        // so the study's condition is exactly what was configured in-app
        // and logged, never silently modified by a setting outside it.
        //
        // The therapist's own screens are exempt: they're clinical/roster
        // UI, not part of any reading condition, and must not inherit
        // whatever size a reader configured for themselves (including a
        // leftover value from the reader session that was just supervised).
        builder: (context, child) {
          final isTherapist = context.watch<ParticipantState>().isTherapist;
          final fontSize = context.watch<ReadingSettings>().fontSize;
          final effectiveFontSize = isTherapist ? 16.0 : fontSize;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(effectiveFontSize / 16.0),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
