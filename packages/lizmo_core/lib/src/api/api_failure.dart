import 'dart:convert';

import 'package:lizmo_api/api.dart';

/// A backend error translated into something the UI can act on.
///
/// The generated client throws [ApiException] with the raw body, so this is
/// where the shared error contract is parsed exactly once. Screens branch on
/// [code] — never on [message], which is free to change wording.
class ApiFailure implements Exception {
  const ApiFailure({required this.code, required this.message, this.fields = const {}});

  /// Stable machine-readable code, e.g. INVALID_CREDENTIALS.
  final String code;

  /// Safe to show to the user.
  final String message;

  /// Per-field validation messages, keyed by field name.
  final Map<String, String> fields;

  static const _network = ApiFailure(
    code: 'NETWORK_UNAVAILABLE',
    message: "Can't reach Lizmo. Check your connection and try again.",
  );

  static const _unknown = ApiFailure(
    code: 'UNKNOWN',
    message: 'Something went wrong. Please try again.',
  );

  /// Normalises anything thrown by the generated client into an [ApiFailure].
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;

    if (error is ApiException) {
      // The generated client wraps transport failures (socket, TLS, IO, client)
      // with ApiException.withInner, so a non-null innerException means the
      // request never reached us. Checked by presence rather than by type:
      // SocketException lives in dart:io and would not compile for web.
      if (error.innerException != null) return _network;

      final body = error.message;
      if (body == null || body.isEmpty) return _unknown;

      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['code'] is String) {
          return ApiFailure(
            code: decoded['code'] as String,
            message: decoded['message'] as String? ?? _unknown.message,
            fields: (decoded['fields'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, v.toString())),
          );
        }
      } on FormatException {
        // Not our error shape — a proxy or gateway error page, most likely.
      }
      return _unknown;
    }

    // SocketException, TimeoutException, HandshakeException and friends. Worth
    // distinguishing: the user can act on "no connection", not on "unknown".
    return _network;
  }

  bool get isNetwork => code == _network.code;

  @override
  String toString() => 'ApiFailure($code): $message';
}
