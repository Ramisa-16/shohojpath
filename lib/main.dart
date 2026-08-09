import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/shohojpath_api.dart';
import 'app/app_nav_state.dart';
import 'app/auth_state.dart';
import 'app/participant_state.dart';
import 'app/route_observer.dart';
import 'l10n/app_language.dart';
import 'models/reading_settings.dart';
import 'screens/splash_screen.dart';
import 'services/app_config_repository.dart';
import 'services/reader_repository.dart';
import 'services/app_content.dart';
import 'services/passage_repository.dart';
import 'services/session_logger.dart';
import 'services/sync_service.dart';
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

  runApp(
    ShohojpathApp(
      settings: settings,
      logger: logger,
      participant: participant,
      settingsRepository: repository,
    ),
  );
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
        // Restored before anything is drawn would be nicer, but the sign-in
        // screen is the first thing shown and it has to be in the right
        // language: restore() notifies, so the first frame after the read
        // corrects itself.
        ChangeNotifierProvider(create: (_) => LanguageState()..restore()),
        ChangeNotifierProvider.value(value: participant),
        Provider.value(value: logger),
        Provider.value(value: settingsRepository),
        Provider(create: (_) => ReaderRepository()),
        Provider(create: (_) => AppConfigRepository()),

        // ---- Backend ----------------------------------------------------
        // One ApiClient for the whole app: it owns the token store and the
        // refresh-and-retry, and a second instance would refresh in parallel
        // and invalidate the first one's rotated refresh token.
        Provider(create: (_) => ApiClient(), dispose: (_, c) => c.close()),
        ProxyProvider<ApiClient, ShohojpathApi>(
          update: (context, client, previous) => ShohojpathApi(client),
        ),
        // Study material, fetched once and cached — so a reading session never
        // depends on the network being up at the moment it starts.
        ProxyProvider<ShohojpathApi, PassageRepository>(
          update: (context, api, previous) =>
              previous ?? PassageRepository(api),
        ),
        // Help/About copy, editable in the admin. Loaded once at startup with
        // the bundled strings standing in until it arrives.
        ChangeNotifierProxyProvider<ShohojpathApi, AppContent>(
          create: (context) =>
              AppContent(context.read<ShohojpathApi>())..load(),
          update: (context, api, existing) => existing!,
        ),
        ChangeNotifierProxyProvider<ShohojpathApi, AuthState>(
          create: (context) => AuthState(
            api: ShohojpathApi(context.read<ApiClient>()),
            participant: participant,
          )..restore(),
          update: (context, api, existing) => existing!,
        ),
        ChangeNotifierProxyProvider<ShohojpathApi, SyncService>(
          create: (context) =>
              SyncService(api: context.read<ShohojpathApi>())..start(),
          update: (context, api, existing) => existing!,
        ),
      ],
      // Builder so this context sits BELOW the providers above. build()'s own
      // context is the one this widget was created with, which is ABOVE the
      // MultiProvider it returns — reading LanguageState from it threw
      // ProviderNotFoundException on the very first frame.
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'সহজপাঠ · Shohojpath',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          scrollBehavior: const _NoOverscrollIndicator(),
          // Lets a screen reload its numbers when the route above it is popped
          // — see RefreshOnRouteReturn.
          navigatorObservers: [appRouteObserver],
          // Bangla is the default and the study language; English is here for
          // supervisors. Driven by the in-app setting rather than the phone's
          // locale, so a device left in English does not silently put an
          // eleven-year-old through an English interface.
          locale: context.watch<LanguageState>().locale,
          supportedLocales: [
            for (final language in AppLanguage.values) language.locale,
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
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

            // Clamped, and this matters: the *passage* is not scaled here at all
            // — BanglaPassage lays out with noScaling and an explicit fontSize,
            // so a reader still gets the exact size they chose where they are
            // actually reading. This scaler only grows the chrome (headers,
            // buttons, the settings panel itself). Unclamped it grew everything
            // by fontSize/16, which at the old 72 px maximum was 4.5x: the
            // Reading Settings title wrapped over three lines, the slider labels
            // overflowed, and there was no longer any way to reach the control
            // that would turn the size back down.
            final chromeScale = (effectiveFontSize / 16.0).clamp(1.0, 1.5);

            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(chromeScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
