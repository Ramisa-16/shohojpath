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
import 'package:shohojpath/app/app_nav_state.dart';
import 'package:shohojpath/app/auth_state.dart';
import 'package:shohojpath/app/participant_state.dart';
import 'package:shohojpath/app/route_observer.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/screens/home_screen.dart';
import 'package:shohojpath/services/passage_repository.dart';
import 'package:shohojpath/widgets/app_header.dart';

/// Home reads its four tile captions once, in initState. A reader who
/// bookmarked a page and came back saw "0 saved" until they pulled to refresh
/// — the server was right and the screen was stale. These tests cover the
/// reload-on-return that fixes it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int bookmarkCount;
  late int bookmarkFetches;

  setUp(() {
    bookmarkCount = 0;
    bookmarkFetches = 0;

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

  http.Response jsonResponse(Object body) => http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        final path = request.url.path;

        if (path.endsWith('/api/bookmarks/')) {
          bookmarkFetches++;
          return jsonResponse({
            'results': [
              for (var i = 0; i < bookmarkCount; i++)
                {
                  'id': i + 1,
                  'passage_id': 'aesop_4026',
                  'passage_title': 'অদৃষ্টের পরিহাস',
                  'page_index': i,
                  'excerpt': '',
                },
            ],
          });
        }
        if (path.endsWith('/api/me/progress/')) {
          return jsonResponse({
            'minutes_today': 0,
            'pages_today': 0,
            'sessions_total': 0,
            'current_passage': null,
            'week': const [],
          });
        }
        return jsonResponse({'results': const []});
      }),
    );

    final participant = ParticipantState()
      ..signInAsReader('P-7DFF', displayName: 'Mitu');
    final api = ShohojpathApi(client);
    final auth = AuthState(api: api, participant: participant);
    await client.tokens.save(
      access: 'a',
      refresh: 'r',
      role: 'reader',
      participantId: 'P-7DFF',
      email: 'mitu@example.com',
      fullName: 'Mitu',
    );
    await auth.restore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ReadingSettings()),
          ChangeNotifierProvider.value(value: participant),
          ChangeNotifierProvider(create: (_) => AppNavState()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: api),
          Provider<PassageRepository>(create: (_) => PassageRepository(api)),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(
          navigatorObservers: [appRouteObserver],
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Stands in for Reading / Bookmarks: any route pushed over Home that
  /// changes what the tiles should say.
  Future<void> pushAndPopARoute(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('reading')),
      ),
    );
    await tester.pumpAndSettle();
    // The reader saves a bookmark while they are in there.
    bookmarkCount = 1;
    navigator.pop();
    await tester.pumpAndSettle();
  }

  testWidgets('the bookmark tile updates after returning from a route',
      (tester) async {
    await pumpHome(tester);
    expect(find.text('0 saved'), findsOneWidget);

    await pushAndPopARoute(tester);

    expect(
      find.text('1 saved'),
      findsOneWidget,
      reason: 'Home must re-read its counts once it is uncovered',
    );
    expect(find.text('0 saved'), findsNothing);
  });

  testWidgets('it refetches rather than reusing the first result',
      (tester) async {
    await pumpHome(tester);
    expect(bookmarkFetches, 1);

    await pushAndPopARoute(tester);
    expect(bookmarkFetches, 2);
  });

  testWidgets('it does not refetch while nothing has been popped',
      (tester) async {
    await pumpHome(tester);
    await tester.pump(const Duration(seconds: 2));

    // Sitting on Home must not poll the server in a loop.
    expect(bookmarkFetches, 1);
  });

  testWidgets('the greeting sits in the header, left of the bell',
      (tester) async {
    await pumpHome(tester);

    final greeting = find.textContaining('Good ');
    expect(greeting, findsOneWidget);

    // Inside the navy bar rather than the scrolling page below it.
    expect(
      find.ancestor(of: greeting, matching: find.byType(AppHeader)),
      findsOneWidget,
    );

    final name = tester.getRect(find.text('Mitu'));
    final bell = tester.getRect(find.byIcon(Icons.notifications_rounded));
    expect(name.left, lessThan(bell.left), reason: 'name on the left');
    // Same row, not stacked.
    expect(name.center.dy, moreOrLessEquals(bell.center.dy, epsilon: 20));
  });
}
