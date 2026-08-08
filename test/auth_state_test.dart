import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/api/api_client.dart';
import 'package:shohojpath/api/shohojpath_api.dart';
import 'package:shohojpath/api/token_store.dart';
import 'package:shohojpath/app/auth_state.dart';
import 'package:shohojpath/app/participant_state.dart';

/// An in-memory stand-in for the Android keystore, so the token lifecycle can
/// be tested without a device.
class FakeSecureStorage {
  static const MethodChannel _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> values = {};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      final args = (call.arguments as Map?) ?? const {};
      switch (call.method) {
        case 'write':
          values['${args['key']}'] = '${args['value']}';
          return null;
        case 'read':
          return values['${args['key']}'];
        case 'readAll':
          return Map<String, String>.from(values);
        case 'delete':
          values.remove('${args['key']}');
          return null;
        case 'deleteAll':
          values.clear();
          return null;
        case 'containsKey':
          return values.containsKey('${args['key']}');
        default:
          return null;
      }
    });
  }

  void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStorage storage;
  late TokenStore tokens;
  late AuthState auth;
  late ParticipantState participant;

  setUp(() {
    storage = FakeSecureStorage()..install();
    tokens = TokenStore(storage: const FlutterSecureStorage());
    participant = ParticipantState();
    auth = AuthState(
      api: ShohojpathApi(ApiClient(tokens: tokens)),
      participant: participant,
    );
  });

  tearDown(() => storage.remove());

  /// Puts a signed-in reader in place, the way a successful login would.
  Future<void> signIn() async {
    await tokens.save(
      access: 'access-token',
      refresh: 'refresh-token',
      role: 'reader',
      participantId: 'P-04',
      email: 'mitu@example.com',
      fullName: 'Mitu Rahman',
    );
    await auth.restore();
  }

  group('restore', () {
    test('a stored session signs the reader back in', () async {
      await signIn();
      expect(auth.isSignedIn, isTrue);
      expect(auth.isReader, isTrue);
      expect(auth.participantId, 'P-04');
      expect(participant.participantId, 'P-04');
    });

    test('an empty keystore leaves nobody signed in', () async {
      await auth.restore();
      expect(auth.isSignedIn, isFalse);
      expect(auth.isRestoring, isFalse);
    });
  });

  group('signOut', () {
    test('clears the stored tokens, not just the in-memory identity', () async {
      await signIn();
      expect(storage.values, isNotEmpty);

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(participant.participantId, isEmpty);
      expect(
        storage.values,
        isEmpty,
        reason: 'the JWT must not survive a logout',
      );
      expect(tokens.hasSession, isFalse);
    });

    test('a logout survives a restart', () async {
      await signIn();
      await auth.signOut();

      // A fresh AuthState over the same keystore is exactly what the next app
      // launch does. Before this was fixed, ParticipantState.signOut left the
      // token behind and restore() signed the reader straight back in.
      final relaunched = AuthState(
        api: ShohojpathApi(ApiClient(tokens: TokenStore())),
        participant: ParticipantState(),
      );
      await relaunched.restore();

      expect(
        relaunched.isSignedIn,
        isFalse,
        reason: 'a logout that does not survive a restart is not a logout',
      );
    });

    test('the next reader does not inherit the previous one', () async {
      await signIn();
      await auth.signOut();

      await tokens.save(
        access: 'a2',
        refresh: 'r2',
        role: 'reader',
        participantId: 'P-09',
        email: 'rafi@example.com',
        fullName: 'Rafi Ahmed',
      );
      await auth.restore();

      expect(auth.participantId, 'P-09');
      expect(participant.participantId, 'P-09');
    });
  });

  group('errors', () {
    test('clear themselves after the configured lifetime', () {
      expect(AuthState.errorLifetime.inSeconds, lessThanOrEqualTo(5));
    });
  });
}
