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
import 'package:shohojpath/l10n/app_language.dart';
import 'package:shohojpath/widgets/change_password_sheet.dart';

/// Change password is a bottom sheet rather than a centred dialog: three
/// stacked fields plus the keyboard does not fit in an AlertDialog on a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> posts;
  late int status;

  setUp(() {
    posts = [];
    status = 200;

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

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        posts.add(request);
        if (status >= 400) {
          return http.Response(
            jsonEncode({'detail': 'Current password is incorrect.'}),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('', 204);
      }),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageState()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: ShohojpathApi(client)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showChangePasswordSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String current = 'oldpassword1',
    String next = 'newpassword1',
    String confirm = 'newpassword1',
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), current);
    await tester.enterText(fields.at(1), next);
    await tester.enterText(fields.at(2), confirm);
    await tester.pump();
  }

  testWidgets('opens as a bottom sheet, not a dialog', (tester) async {
    await openSheet(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('পাসওয়ার্ড বদলান'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('it sits at the bottom of the screen', (tester) async {
    await openSheet(tester);

    final sheet = tester.getRect(find.byType(BottomSheet));
    final screen = tester.getRect(find.byType(MaterialApp));
    expect(
      sheet.bottom,
      moreOrLessEquals(screen.bottom, epsilon: 1),
      reason: 'a sheet is anchored to the bottom edge',
    );
  });

  testWidgets('saves and reports success', (tester) async {
    await openSheet(tester);
    await fill(tester);

    await tester.tap(find.text('পাসওয়ার্ড বদলান').last);
    await tester.pumpAndSettle();

    expect(posts, hasLength(1));
    final body = jsonDecode(posts.single.body) as Map<String, dynamic>;
    expect(body['current_password'], 'oldpassword1');
    expect(body['new_password'], 'newpassword1');

    expect(find.byType(BottomSheet), findsNothing, reason: 'it closes');
    expect(find.text('পাসওয়ার্ড বদলে গেছে।'), findsOneWidget);
  });

  testWidgets('a mismatch is caught before the request', (tester) async {
    await openSheet(tester);
    await fill(tester, confirm: 'differentpass1');

    await tester.tap(find.text('পাসওয়ার্ড বদলান').last);
    await tester.pumpAndSettle();

    // Mistyping the new password would lock someone out of the account they
    // need in order to fix it, so this never reaches the server.
    expect(posts, isEmpty);
    expect(find.text('দুটি নতুন পাসওয়ার্ড মিলছে না।'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('a short password is caught before the request', (tester) async {
    await openSheet(tester);
    await fill(tester, next: 'short', confirm: 'short');

    await tester.tap(find.text('পাসওয়ার্ড বদলান').last);
    await tester.pumpAndSettle();

    expect(posts, isEmpty);
    expect(find.text('অন্তত ৮টি অক্ষর ব্যবহার করুন।'), findsOneWidget);
  });

  testWidgets('a server rejection stays open and says why', (tester) async {
    status = 400;
    await openSheet(tester);
    await fill(tester);

    await tester.tap(find.text('পাসওয়ার্ড বদলান').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Current password is incorrect.'), findsOneWidget);
  });

  testWidgets('Cancel closes it without saving', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('বাতিল'));
    await tester.pumpAndSettle();

    expect(posts, isEmpty);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a tap outside does not discard a half-typed password',
      (tester) async {
    await openSheet(tester);
    await fill(tester);

    // The scrim is dismissible by default; here it must not be, or a stray
    // tap throws away what was typed.
    await tester.tapAt(const Offset(300, 40));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
