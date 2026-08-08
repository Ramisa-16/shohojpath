import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// The single door to the Django backend.
///
/// Every call goes through here so three things happen in exactly one place:
/// the bearer token is attached, a 401 triggers one refresh-and-retry, and a
/// dead network becomes an [ApiException] rather than a raw socket error
/// surfacing in the UI.
class ApiClient {
  ApiClient({http.Client? httpClient, TokenStore? tokens})
      : _http = httpClient ?? http.Client(),
        tokens = tokens ?? TokenStore();

  final http.Client _http;
  final TokenStore tokens;

  /// Called when the refresh token itself is rejected — the session is over
  /// and the app must return to Login. Set by AuthState.
  VoidCallback? onSessionExpired;

  /// Guards against a burst of parallel 401s each firing its own refresh.
  Future<bool>? _refreshInFlight;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// True when the server answers at all. Probed with a short timeout so a
  /// sleeping free-tier host does not stall the UI for a minute.
  Future<bool> isReachable() async {
    try {
      final response = await _http
          .get(ApiConfig.url('/api/health/'))
          .timeout(ApiConfig.healthTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
    bool isRetry = false,
  }) async {
    await tokens.load();

    final request = http.Request(method, ApiConfig.url(path, query))
      ..headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final access = tokens.accessToken;
    if (authenticated && access != null && access.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $access';
    }

    http.Response response;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.offline();
    } on http.ClientException {
      throw ApiException.offline();
    }

    // One refresh-and-retry, never a loop: if the refreshed token is also
    // rejected the session is genuinely over.
    if (response.statusCode == 401 && authenticated && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _send(
          method,
          path,
          body: body,
          query: query,
          authenticated: authenticated,
          isRetry: true,
        );
      }
      onSessionExpired?.call();
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final hasBody = response.body.isNotEmpty;
    dynamic decoded;
    if (hasBody) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException.fromResponse(response.statusCode, decoded);
  }

  Future<bool> _refreshAccessToken() {
    // Share one in-flight refresh between every caller that hit a 401 at the
    // same moment, or the first success would be immediately overwritten by
    // the others rotating the refresh token again.
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refresh = tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _http
          .post(
            ApiConfig.url('/api/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) return false;
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

      final access = data['access'] as String?;
      if (access == null) return false;

      // ROTATE_REFRESH_TOKENS is on server-side, so a new refresh token comes
      // back with the access token and must replace the stored one.
      final newRefresh = data['refresh'] as String?;
      if (newRefresh != null) {
        await tokens.save(access: access, refresh: newRefresh);
      } else {
        await tokens.updateAccess(access);
      }
      return true;
    } catch (_) {
      // A network failure is not an expired session — keep the tokens so the
      // reader is not signed out simply for being offline.
      return false;
    }
  }

  void close() => _http.close();
}
