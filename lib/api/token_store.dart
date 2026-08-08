import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the JWT pair lives between app launches.
///
/// The Android keystore rather than SharedPreferences: these tokens grant
/// access to children's names, schools and reading-performance data, and a
/// study device is handed between people.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _accessKey = 'shohojpath.access';
  static const _refreshKey = 'shohojpath.refresh';
  static const _roleKey = 'shohojpath.role';
  static const _participantKey = 'shohojpath.participant_id';
  static const _emailKey = 'shohojpath.email';
  static const _nameKey = 'shohojpath.full_name';

  final FlutterSecureStorage _storage;

  // Cached after the first read so every request does not hit the keystore,
  // which is a platform channel round trip.
  String? _access;
  String? _refresh;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _access = await _storage.read(key: _accessKey);
    _refresh = await _storage.read(key: _refreshKey);
    _loaded = true;
  }

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  bool get hasSession => (_refresh ?? '').isNotEmpty;

  Future<void> save({
    required String access,
    required String refresh,
    String? role,
    String? participantId,
    String? email,
    String? fullName,
  }) async {
    _access = access;
    _refresh = refresh;
    _loaded = true;
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
      if (role != null) _storage.write(key: _roleKey, value: role),
      if (participantId != null)
        _storage.write(key: _participantKey, value: participantId),
      if (email != null) _storage.write(key: _emailKey, value: email),
      if (fullName != null) _storage.write(key: _nameKey, value: fullName),
    ]);
  }

  /// Replaces only the access token, after a refresh.
  Future<void> updateAccess(String access) async {
    _access = access;
    await _storage.write(key: _accessKey, value: access);
  }

  Future<Map<String, String?>> readProfile() async => {
        'role': await _storage.read(key: _roleKey),
        'participant_id': await _storage.read(key: _participantKey),
        'email': await _storage.read(key: _emailKey),
        'full_name': await _storage.read(key: _nameKey),
      };

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await _storage.deleteAll();
  }
}
