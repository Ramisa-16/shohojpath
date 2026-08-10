import 'dart:io';

import 'package:flutter/foundation.dart';

/// Where the Django backend lives.
///
/// Override at build time when neither default is right — a second server, or
/// testing a release build against a laptop:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8002
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// The port the local backend runs on in development. 8000 is taken by
  /// another project on this machine, so Shohojpath uses 8002 — start it with
  /// `python manage.py runserver 0.0.0.0:8002`.
  static const int devPort = 8002;

  /// The deployed study backend.
  static const String production = 'https://shohojpath.pythonanywhere.com';

  /// Release builds talk to the server, debug builds talk to the laptop.
  ///
  /// Keyed on the build mode rather than left to a `--dart-define` on every
  /// release: an APK is what goes on a study device, and one built without
  /// the flag would silently point at a development machine that is not
  /// there. Forgetting a flag should not be able to produce an app that
  /// looks fine and records nothing.
  ///
  /// The Android emulator cannot reach the host machine on `localhost` — that
  /// resolves to the emulator itself. 10.0.2.2 is the loopback alias the
  /// emulator maps to the host, and getting this wrong is the single most
  /// common reason a local backend "doesn't work" from the app.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return production;
    if (kIsWeb) return 'http://127.0.0.1:8002';
    if (Platform.isAndroid) return 'http://10.0.2.2:8002';
    return 'http://127.0.0.1:8002';
  }

  static Uri url(String path, [Map<String, dynamic>? query]) {
    final normalised = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalised');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null) entry.key: '${entry.value}',
      },
    );
  }

  /// Long enough for a free-tier host waking from sleep, which can take the
  /// better part of a minute on the first request of the day.
  static const Duration timeout = Duration(seconds: 60);

  /// Short probe used before syncing, so a sleeping server does not block the
  /// UI for a minute just to discover it is asleep.
  static const Duration healthTimeout = Duration(seconds: 8);
}
