import '../l10n/app_strings.dart';

/// A failed API call, in a form the UI can show a participant.
///
/// DRF returns errors in several shapes — `{"detail": "..."}`, a field map,
/// or a bare list — so they are flattened here rather than in every screen
/// that happens to call an endpoint.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
    this.kind = ApiErrorKind.server,
  });

  /// The device could not reach the server at all.
  factory ApiException.offline() => ApiException(
        'No connection to the server. Your work is saved on this device and '
        'will sync when you are back online.',
        kind: ApiErrorKind.offline,
      );

  factory ApiException.timeout() => ApiException(
        'The server took too long to respond. It may be waking up — try again '
        'in a moment.',
        kind: ApiErrorKind.timeout,
      );

  factory ApiException.fromResponse(int statusCode, dynamic body) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) {
        return ApiException(
          detail,
          statusCode: statusCode,
          kind: ApiErrorKind.fromServer,
        );
      }

      // Field errors: {"email": ["already exists"], "password": [...]}
      final fields = <String, String>{};
      for (final entry in body.entries) {
        final value = entry.value;
        final text = value is List
            ? value.map((v) => '$v').join(' ')
            : '$value';
        fields['${entry.key}'] = text;
      }
      if (fields.isNotEmpty) {
        return ApiException(
          fields.values.first,
          statusCode: statusCode,
          fieldErrors: fields,
          kind: ApiErrorKind.fromServer,
        );
      }
    }
    if (body is List && body.isNotEmpty) {
      return ApiException(
        '${body.first}',
        statusCode: statusCode,
        kind: ApiErrorKind.fromServer,
      );
    }
    return ApiException(
      _defaultMessage(statusCode),
      statusCode: statusCode,
    );
  }

  /// English, and only English. Kept for logs, tests and the exported study
  /// data, where a message that changes with the reader's language setting
  /// would be worse than useless. Screens show [messageFor] instead.
  final String message;

  final int? statusCode;

  /// What went wrong, independent of wording — this is what [messageFor]
  /// translates. A message built by string comparison would break the moment
  /// anyone edited the English.
  final ApiErrorKind kind;

  /// Per-field messages, so a form can mark the field that was wrong instead
  /// of dumping one string above the whole thing.
  final Map<String, String> fieldErrors;

  bool get isUnauthorised => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;

  static String _defaultMessage(int status) => switch (status) {
        400 => 'That request was not valid.',
        401 => 'Please sign in again.',
        403 => 'You do not have permission to do that.',
        404 => 'Not found.',
        409 => 'That has already been done by someone else.',
        >= 500 => 'The server had a problem. Try again shortly.',
        _ => 'Something went wrong (HTTP $status).',
      };

  /// The same failure in the reader's language.
  ///
  /// Anything the server said in words — a field error, a `detail` — is passed
  /// through untranslated: it is more specific than any category here, and
  /// inventing a vaguer local sentence in its place would lose information the
  /// reader needs. Only our own generic categories are translated.
  String messageFor(AppStrings t) => switch (kind) {
        ApiErrorKind.offline => t.offlineBanner,
        ApiErrorKind.timeout => t.errorTimeout,
        ApiErrorKind.fromServer => message,
        ApiErrorKind.server => switch (statusCode) {
            400 => t.errorBadRequest,
            401 => t.errorSignInAgain,
            403 => t.errorForbidden,
            404 => t.errorNotFound,
            409 => t.errorConflict,
            _ => t.errorServer,
          },
      };

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Why a call failed, so the wording can be chosen at display time.
enum ApiErrorKind {
  /// No route to the server.
  offline,

  /// Reached it, waited too long.
  timeout,

  /// The server explained itself in words; show those rather than a category.
  fromServer,

  /// A bare status code with nothing useful in the body.
  server,
}
