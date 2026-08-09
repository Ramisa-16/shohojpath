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
import 'package:shohojpath/models/passage.dart';
import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/screens/reading_screen.dart';
import 'package:shohojpath/services/session_logger.dart';
import 'package:shohojpath/services/tts_service.dart';

/// The bookmark control on the Reading screen used to be
/// `setState(() => _bookmarked = !_bookmarked)` — a local flag that never
/// reached the server. It looked right and saved nothing. These tests drive
/// the real screen and assert on the HTTP the button produces.
class _NoDbLogger extends SessionLogger {
  // The real logger writes through sqflite, which has no implementation in a
  // widget test. Reading is not what is under test here.
  @override
  Future<void> startSession({
    required String sessionId,
    required String participantId,
    required String passageId,
    required ReadingProfile profile,
  }) async {}

  @override
  Future<void> logPageTime(String sessionId, int pageIndex, Duration time) async {}

  @override
  Future<void> endActiveSession(String sessionId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final passage = Passage(
    id: 'aesop_4026',
    title: 'অদৃষ্টের পরিহাস',
    category: 'ইশপের গল্প',
    difficulty: PassageDifficulty.easy,
    estimatedMinutes: 3,
    pages: const [
      PassagePage(['এক দেশে এক কৃষক বাস করত।']),
      PassagePage(['কৃষকটি প্রতিদিন মাঠে কাজ করত।']),
    ],
  );

  late List<http.Request> requests;
  late List<Map<String, dynamic>> serverBookmarks;

  setUp(() {
    requests = [];
    serverBookmarks = [];

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

    // flutter_tts is constructed by TtsService but never driven here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
  });

  http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  /// Pumps the Reading screen against a faked bookmarks API that behaves like
  /// the real one: list, create returning an id, delete by id.
  Future<AuthState> pumpReading(
    WidgetTester tester, {
    bool signedIn = true,
    int createStatus = 201,
  }) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var nextId = 1;
    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;

        if (path.endsWith('/api/bookmarks/') && request.method == 'GET') {
          return jsonResponse({'results': serverBookmarks});
        }
        if (path.endsWith('/api/bookmarks/') && request.method == 'POST') {
          if (createStatus >= 400) {
            return jsonResponse({'detail': 'Could not save the bookmark.'}, createStatus);
          }
          final sent = jsonDecode(request.body) as Map<String, dynamic>;
          final row = {'id': nextId++, ...sent};
          serverBookmarks.add(row);
          return jsonResponse(row, 201);
        }
        if (RegExp(r'/api/bookmarks/\d+/$').hasMatch(path) &&
            request.method == 'DELETE') {
          final id = int.parse(RegExp(r'(\d+)/$').firstMatch(path)!.group(1)!);
          serverBookmarks.removeWhere((b) => b['id'] == id);
          return http.Response('', 204);
        }
        return jsonResponse(const {});
      }),
    );

    final participant = ParticipantState()
      ..signInAsReader('P-7DFF', displayName: 'Mitu');
    final api = ShohojpathApi(client);
    final auth = AuthState(api: api, participant: participant);

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
          ChangeNotifierProvider.value(value: participant),
          ChangeNotifierProvider(create: (_) => LanguageState()),
          ChangeNotifierProvider(create: (_) => TtsService()),
          Provider<SessionLogger>.value(value: _NoDbLogger()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: api),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(home: ReadingScreen(passage: passage)),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  Finder hollowBookmark() => find.byIcon(Icons.bookmark_border_rounded);
  Finder filledBookmark() => find.byIcon(Icons.bookmark_rounded);

  testWidgets('tapping bookmark POSTs the page to the server', (tester) async {
    await pumpReading(tester);

    expect(hollowBookmark(), findsOneWidget);
    await tester.tap(hollowBookmark());
    await tester.pumpAndSettle();

    final posts = requests.where((r) => r.method == 'POST').toList();
    expect(posts, hasLength(1), reason: 'the tap must reach the server');

    final body = jsonDecode(posts.single.body) as Map<String, dynamic>;
    expect(body['passage_id'], 'aesop_4026');
    expect(body['page_index'], 0);
    // The excerpt is what the Bookmarks list shows instead of a page number.
    expect(body['excerpt'], 'এক দেশে এক কৃষক বাস করত।');

    expect(filledBookmark(), findsOneWidget);
  });

  testWidgets('a saved bookmark survives reopening the passage',
      (tester) async {
    await pumpReading(tester);
    await tester.tap(hollowBookmark());
    await tester.pumpAndSettle();

    // Same server state, fresh screen: the icon must come back filled.
    await pumpReading(tester);
    expect(filledBookmark(), findsOneWidget);
    expect(hollowBookmark(), findsNothing);
  });

  testWidgets('tapping again deletes it', (tester) async {
    await pumpReading(tester);
    await tester.tap(hollowBookmark());
    await tester.pumpAndSettle();
    await tester.tap(filledBookmark());
    await tester.pumpAndSettle();

    expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(serverBookmarks, isEmpty);
    expect(hollowBookmark(), findsOneWidget);
  });

  testWidgets('the icon follows the page, not the passage', (tester) async {
    await pumpReading(tester);
    await tester.tap(hollowBookmark());
    await tester.pumpAndSettle();
    expect(filledBookmark(), findsOneWidget);

    // The confirmation snackbar sits over the Next button; let it go first.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Page 2 is a different bookmark and has not been saved.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(hollowBookmark(), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(filledBookmark(), findsOneWidget);
  });

  testWidgets('a failed save does not leave the icon lying', (tester) async {
    await pumpReading(tester, createStatus: 500);

    await tester.tap(hollowBookmark());
    await tester.pumpAndSettle();

    // Nothing was stored, so the icon must still read as unsaved — and the
    // reader has to be told, or the tap looks like it did nothing.
    expect(serverBookmarks, isEmpty);
    expect(hollowBookmark(), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('a guest is told to sign in rather than failing silently',
      (tester) async {
    await pumpReading(tester, signedIn: false);

    await tester.tap(hollowBookmark());
    await tester.pumpAndSettle();

    expect(requests.where((r) => r.method == 'POST'), isEmpty);
    expect(find.text('বুকমার্ক রাখতে সাইন ইন করুন।'), findsOneWidget);
  });
}
