import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:shohojpath/api/api_client.dart';
import 'package:shohojpath/api/shohojpath_api.dart';
import 'package:shohojpath/api/token_store.dart';
import 'package:shohojpath/app/auth_state.dart';
import 'package:shohojpath/app/participant_state.dart';
import 'package:shohojpath/l10n/app_language.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/screens/profile_screen.dart';

/// Pumps the real Profile screen against a faked API.
///
/// This exists because the screen shipped a crash — the details card used a
/// ListView inside the page's own scroll view, which has no bounded height and
/// throws "RenderBox was not laid out". Analyze cannot see that; only building
/// the widget can.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profileJson = {
    'participant_id': 'P-7DFF',
    'display_name': 'Mitu',
    'email': 'mitu@example.com',
    'age': 11,
    'class_grade': '',
    'school': '',
    'starting_profile': 'recommended',
    'therapist_name': null,
    'created_at': '2026-08-01T10:00:00Z',
  };

  late Map<String, String> keystore;

  setUp(() {
    // The keystore is a platform channel; an in-memory stand-in lets the test
    // put a real signed-in session in place.
    keystore = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
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
  });

  /// A tall surface: the default 800x600 test viewport cannot fit the whole
  /// Profile list, and a ListView does not build children that are off-screen
  /// — so a row would appear "missing" for a reason that has nothing to do
  /// with the code under test.
  void useTallSurface(WidgetTester tester) {
    // devicePixelRatio 1 so these are logical pixels: at 3.0 this is a 360x800
    // phone again and the bottom of the list stays unbuilt.
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    Map<String, dynamic>? profile,
    int status = 200,
    bool signedIn = true,
  }) async {
    useTallSurface(tester);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/api/me/profile/')) {
          return http.Response(
            jsonEncode(profile ?? profileJson),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      }),
    );

    final participant = ParticipantState()
      ..signInAsReader('P-7DFF', displayName: 'Mitu');

    final auth = AuthState(
      api: ShohojpathApi(client),
      participant: participant,
    );
    if (signedIn) {
      await client.tokens.save(
        access: 'a',
        refresh: 'r',
        role: 'reader',
        participantId: 'P-7DFF',
        email: 'mitu@example.com',
        fullName: 'Mitu',
      );
    }
    await auth.restore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ReadingSettings()),
          ChangeNotifierProvider(create: (_) => LanguageState()),
          ChangeNotifierProvider.value(value: participant),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: ShohojpathApi(client)),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders without a layout exception', (tester) async {
    await pumpProfile(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows every detail row, none clipped', (tester) async {
    await pumpProfile(tester);

    // Participant ID and Email were the two the fixed-height box hid.
    expect(find.text('অংশগ্রহণকারী আইডি'), findsOneWidget);
    expect(find.text('P-7DFF'), findsWidgets);
    expect(find.text('ইমেইল'), findsOneWidget);
    expect(find.text('mitu@example.com'), findsOneWidget);
    expect(find.text('বয়স'), findsOneWidget);
    expect(find.text('পড়ার ধরন'), findsOneWidget);
    expect(find.text('থেরাপিস্ট'), findsOneWidget);
    expect(find.text('এখনও দেওয়া হয়নি'), findsOneWidget);
  });

  testWidgets('offers Change password to a signed-in reader', (tester) async {
    await pumpProfile(tester);
    expect(find.text('পাসওয়ার্ড বদলান'), findsOneWidget);
    expect(find.text('লগ আউট'), findsOneWidget);
  });

  testWidgets('hides Change password from a guest', (tester) async {
    // A guest has no account, so the row would be a dead end.
    await pumpProfile(tester, signedIn: false, status: 404);
    expect(find.text('পাসওয়ার্ড বদলান'), findsNothing);
    expect(find.text('লগ আউট'), findsOneWidget);
  });

  testWidgets('a failed profile fetch does not break the screen',
      (tester) async {
    // A guest has no server profile, and neither does anyone offline. The
    // header already says who they are, so the card simply goes away.
    await pumpProfile(tester, status: 404);

    expect(tester.takeException(), isNull);
    expect(find.text('অংশগ্রহণকারী আইডি'), findsNothing);
    // The rest of the screen still works.
    expect(find.text('পড়ার ইতিহাস'), findsOneWidget);
    expect(find.text('লগ আউট'), findsOneWidget);
  });
}
