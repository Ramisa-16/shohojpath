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
import 'package:shohojpath/l10n/app_language.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/screens/home_shell.dart';
import 'package:shohojpath/services/passage_repository.dart';
import 'package:shohojpath/widgets/bottom_tab_bar.dart';

/// Home's search field is a shortcut: tapping it switches to Library, where
/// the real search lives. It used to land there with the keyboard down, so the
/// reader had to tap search twice to search once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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

  late AppNavState nav;

  /// The bottom bar's own label — "Library" and "Home" also appear as tiles
  /// on the Home page.
  Finder tab(String label) => find.descendant(
        of: find.byType(BottomTabBar),
        matching: find.text(label),
      );

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        final Map<String, Object?> body;
        if (path.endsWith('/api/me/progress/')) {
          body = {
            'minutes_today': 0,
            'pages_today': 0,
            'sessions_total': 0,
            'current_passage': null,
            'week': const [],
          };
        } else if (path.endsWith('/api/passages/categories/')) {
          body = {'categories': const ['All']};
        } else {
          body = {'results': const []};
        }
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final participant = ParticipantState()
      ..signInAsReader('P-7DFF', displayName: 'Mitu');
    final api = ShohojpathApi(client);
    nav = AppNavState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ReadingSettings()),
          ChangeNotifierProvider.value(value: participant),
          ChangeNotifierProvider.value(value: nav),
          ChangeNotifierProvider(create: (_) => LanguageState()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: api),
          Provider<PassageRepository>(create: (_) => PassageRepository(api)),
          ChangeNotifierProvider(
            create: (_) => AuthState(api: api, participant: participant),
          ),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Library's search box is the only real text field in the shell — Home's
  /// is a tappable look-alike that does nothing but hand over to this one.
  bool librarySearchHasFocus(WidgetTester tester) {
    // skipOffstage: false — IndexedStack keeps the unselected tabs in the
    // tree but offstage, and finders skip those by default.
    final fields = find.byType(TextField, skipOffstage: false);
    expect(fields, findsOneWidget);
    return tester.widget<TextField>(fields).focusNode?.hasFocus ?? false;
  }

  testWidgets('tapping Home search opens Library with the cursor in the field',
      (tester) async {
    await pumpShell(tester);
    expect(nav.tab, AppTab.home);
    expect(librarySearchHasFocus(tester), isFalse);

    await tester.tap(find.text('Search passages…'));
    await tester.pumpAndSettle();

    expect(nav.tab, AppTab.library);
    expect(
      librarySearchHasFocus(tester),
      isTrue,
      reason: 'the reader asked to search, so let them type',
    );
  });

  testWidgets('reaching Library by the tab bar does not force the keyboard up',
      (tester) async {
    await pumpShell(tester);

    // Browsing the library is not searching it; a keyboard would just cover
    // the passage list.
    await tester.tap(tab('পাঠাগার'));
    await tester.pumpAndSettle();

    expect(nav.tab, AppTab.library);
    expect(librarySearchHasFocus(tester), isFalse);
  });

  testWidgets('the request is consumed, not repeated', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Search passages…'));
    await tester.pumpAndSettle();
    expect(librarySearchHasFocus(tester), isTrue);

    // Leave, come back the ordinary way: the earlier request must not still
    // be sitting there waiting to fire.
    await tester.tap(tab('হোম'));
    await tester.pumpAndSettle();
    await tester.tap(tab('পাঠাগার'));
    await tester.pumpAndSettle();

    expect(librarySearchHasFocus(tester), isFalse);
  });

  test('takeSearchFocusRequest clears itself', () {
    final state = AppNavState();
    expect(state.takeSearchFocusRequest(), isFalse);

    state.openLibrarySearch();
    expect(state.tab, AppTab.library);
    expect(state.takeSearchFocusRequest(), isTrue);
    expect(state.takeSearchFocusRequest(), isFalse);
  });
}
