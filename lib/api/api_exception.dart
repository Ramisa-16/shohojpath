/// A failed API call, in a form the UI can show a participant.
///
/// DRF returns errors in several shapes — `{"detail": "..."}`, a field map,
/// or a bare list — so they are flattened here rather than in every screen
/// that happens to call an endpoint.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  /// The device could not reach the server at all.
  factory ApiException.offline() => ApiException(
        'No connection to the server. Your work is saved on this device and '
        'will sync when you are back online.',
      );

  factory ApiException.timeout() => ApiException(
        'The server took too long to respond. It may be waking up — try again '
        'in a moment.',
      );

  factory ApiException.fromResponse(int statusCode, dynamic body) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) {
        return ApiException(detail, statusCode: statusCode);
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
        );
      }
    }
    if (body is List && body.isNotEmpty) {
      return ApiException('${body.first}', statusCode: statusCode);
    }
    return ApiException(
      _defaultMessage(statusCode),
      statusCode: statusCode,
    );
  }

  final String message;
  final int? statusCode;

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

  @override
  String toString() => 'ApiException($statusCode): $message';
}
