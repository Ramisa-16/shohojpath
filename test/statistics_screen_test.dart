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
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/screens/statistics_screen.dart';

/// Pumps the real Statistics screen against a faked API.
///
/// This exists because the screen shipped a crash: three Rows used
/// CrossAxisAlignment.stretch inside a ListView. A Row there has unbounded
/// height, so "stretch" resolves to infinity and layout throws. Analyze cannot
/// see that — only building the widget can.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const statsJson = {
    'sessions_logged': 12,
    'words_this_week': 1840,
    'words_delta_vs_last_week': 260,
    'words_per_minute': 62.4,
    'comprehension_percent': 78.0,
    'read_aloud_percent': 41.0,
    'passages_finished': 5,
    'average_session_seconds': 512.0,
    'most_changed_settings': [
      {'key': 'font_size', 'changes': 9},
      {'key': 'line_height', 'changes': 4},
    ],
  };

  setUp(() {
    // The keystore is a platform channel. Without a stand-in the token read
    // never returns, ApiData sits on its spinner and pumpAndSettle times out
    // — the screen never gets far enough to lay anything out.
    final keystore = <String, String>{};
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

  /// The default 800x600 test viewport cannot fit the whole list, and a
  /// ListView does not build off-screen children — a card would look "missing"
  /// for a reason unrelated to the code under test.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpStatistics(
    WidgetTester tester, {
    Map<String, dynamic>? stats,
  }) async {
    useTallSurface(tester);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/api/me/statistics/')) {
          return http.Response(
            jsonEncode(stats ?? statsJson),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      }),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ReadingSettings()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: ShohojpathApi(client)),
        ],
        child: const MaterialApp(home: StatisticsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders without a layout exception', (tester) async {
    await pumpStatistics(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the paired metric cards', (tester) async {
    await pumpStatistics(tester);

    // The two Rows that threw: metric cards, then the small-stat pairs.
    expect(find.text('Reading speed'), findsOneWidget);
    expect(find.text('Comprehension'), findsOneWidget);
    expect(find.text('Average session'), findsOneWidget);
    expect(find.text('Sessions logged'), findsOneWidget);
    expect(find.text('Passages read'), findsOneWidget);
    expect(find.text('Words per minute'), findsOneWidget);
  });

  testWidgets('renders the empty state without a crash', (tester) async {
    // Nothing synced yet — the stretch Rows are skipped entirely, so this
    // path passed even while the populated one threw.
    await pumpStatistics(tester, stats: {'sessions_logged': 0});

    expect(tester.takeException(), isNull);
    expect(find.text('No statistics yet'), findsOneWidget);
  });

  testWidgets('survives a large font scale', (tester) async {
    // A reader at 48px pushes the two cards to different natural heights,
    // which is exactly what stretch is there to reconcile.
    useTallSurface(tester);
    tester.view.physicalSize = const Size(400, 2400);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((_) async => http.Response(
            jsonEncode(statsJson),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ReadingSettings()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: ShohojpathApi(client)),
        ],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(home: StatisticsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
