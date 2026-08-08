import 'dart:io';

import 'package:flutter/foundation.dart';

/// Where the Django backend lives.
///
/// Override at build time so a device build never has to be edited by hand:
///
///   flutter run --dart-define=API_BASE_URL=https://shohojpath.onrender.com
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// The Android emulator cannot reach the host machine on `localhost` — that
  /// resolves to the emulator itself. 10.0.2.2 is the loopback alias the
  /// emulator maps to the host, and getting this wrong is the single most
  /// common reason a local backend "doesn't work" from the app.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
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
