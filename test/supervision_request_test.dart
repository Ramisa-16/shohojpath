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
import 'package:shohojpath/screens/notifications_screen.dart';

/// A therapist asking to supervise a reader is a request, not a claim. The
/// reader answers it on the notification itself, and nothing changes until
/// they do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late String requestStatus;
  late int respondStatus;

  setUp(() {
    requests = [];
    requestStatus = 'pending';
    respondStatus = 200;

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

  http.Response json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<void> pumpNotifications(WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = ApiClient(
      tokens: TokenStore(),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;

        if (path.endsWith('/api/notifications/')) {
          return json({
            'results': [
              {
                'id': 1,
                'kind': 'supervision_requested',
                'title': 'A therapist wants to add you',
                'body': 'Dr Karim would like to add you as their reader.',
                'created_at': '2026-08-10T09:00:00Z',
                'read_at': null,
                'is_read': false,
                'supervision_request': 7,
                'supervision_status': requestStatus,
              },
            ],
          });
        }
        if (path.contains('/api/supervision-requests/')) {
          if (respondStatus >= 400) {
            return json({'detail': 'This request has already been answered.'},
                respondStatus);
          }
          return json({
            'id': 7,
            'status': 'accepted',
            'therapist_name': 'Dr Karim',
          });
        }
        return json({'results': const []});
      }),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageState()),
          Provider<ApiClient>.value(value: client),
          Provider<ShohojpathApi>.value(value: ShohojpathApi(client)),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a pending request offers Accept and Decline', (tester) async {
    await pumpNotifications(tester);

    expect(find.text('রাজি'), findsOneWidget);
    expect(find.text('না'), findsOneWidget);
  });

  testWidgets('accepting posts accept:true', (tester) async {
    await pumpNotifications(tester);

    await tester.tap(find.text('রাজি'));
    await tester.pumpAndSettle();

    final posted = requests.firstWhere(
      (r) => r.url.path.contains('/supervision-requests/'),
    );
    expect(posted.method, 'POST');
    expect(posted.url.path, contains('/7/respond/'));
    expect(jsonDecode(posted.body)['accept'], isTrue);
  });

  testWidgets('declining posts accept:false', (tester) async {
    await pumpNotifications(tester);

    await tester.tap(find.text('না'));
    await tester.pumpAndSettle();

    final posted = requests.firstWhere(
      (r) => r.url.path.contains('/supervision-requests/'),
    );
    expect(jsonDecode(posted.body)['accept'], isFalse);
  });

  testWidgets('an already-answered request offers no buttons', (tester) async {
    // Answered on another device, or superseded because they accepted someone
    // else. Offering the buttons would only produce a 409.
    requestStatus = 'accepted';
    await pumpNotifications(tester);

    expect(find.text('রাজি'), findsNothing);
    expect(find.text('না'), findsNothing);
    expect(find.text('A therapist wants to add you'), findsOneWidget);
  });

  testWidgets('a conflict tells the reader rather than failing silently',
      (tester) async {
    respondStatus = 409;
    await pumpNotifications(tester);

    await tester.tap(find.text('রাজি'));
    await tester.pumpAndSettle();

    expect(find.text('এই অনুরোধের উত্তর আগেই দেওয়া হয়েছে।'), findsOneWidget);
  });

  testWidgets('an ordinary notification has no buttons', (tester) async {
    requestStatus = 'none';
    await pumpNotifications(tester);
    expect(find.text('রাজি'), findsNothing);
  });
}
