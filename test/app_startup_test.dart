import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/main.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/app/participant_state.dart';
import 'package:shohojpath/services/session_logger.dart';
import 'package:shohojpath/services/settings_repository.dart';

/// Boots the real ShohojpathApp.
///
/// Every other widget test builds its own provider tree, which is exactly why
/// they all passed while the app crashed on its first frame:
/// `MaterialApp(locale: context.watch<LanguageState>()...)` read from build()'s
/// own context, which sits ABOVE the MultiProvider that same method creates.
/// ProviderNotFoundException, every launch, release and debug alike.
///
/// Only pumping the widget the app actually runs can catch that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final keystore = <String, String>{};
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? const {};
        switch (call.method) {
          case 'write':
            keystore['${args['key']}'] = '${args['value']}';
            return null;
          case 'read':
            return keystore['${args['key']}'];
          case 'readAll':
            return Map<String, String>.from(keystore);
          case 'deleteAll':
            keystore.clear();
            return null;
          default:
            return null;
        }
      },
    );

    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );

    // sqflite: the settings and session stores open a database on startup.
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async {
        switch (call.method) {
          case 'getDatabasesPath':
            return '.';
          case 'openDatabase':
            return 1;
          case 'query':
            return <Map<String, Object?>>[];
          default:
            return null;
        }
      },
    );

    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['none'],
    );
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      null,
    );
  });

  testWidgets('the app boots without a provider lookup failing',
      (tester) async {
    await tester.pumpWidget(
      ShohojpathApp(
        settings: ReadingSettings(),
        logger: SessionLogger(),
        participant: ParticipantState(),
        settingsRepository: SettingsRepository(),
      ),
    );
    await tester.pump();

    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason: 'the first frame threw: $error',
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MaterialApp reads its locale from below the providers',
      (tester) async {
    await tester.pumpWidget(
      ShohojpathApp(
        settings: ReadingSettings(),
        logger: SessionLogger(),
        participant: ParticipantState(),
        settingsRepository: SettingsRepository(),
      ),
    );
    await tester.pump();

    // Bangla is the default, and the app must reach the first frame holding
    // it — this is the value whose lookup was throwing.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale?.languageCode, 'bn');
    expect(
      app.supportedLocales.map((l) => l.languageCode),
      containsAll(['bn', 'en']),
    );
  });
}
