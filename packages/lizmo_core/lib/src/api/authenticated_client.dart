// prefer_initializing_formals does not apply here: named parameters cannot
// begin with an underscore, so `this._inner` is not expressible.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:http/http.dart';

/// Refreshes an expired access token and replays the request, once.
///
/// Access tokens live an hour. Without this, an app left open past that point
/// fails every request until it is restarted — the session is still valid, but
/// nothing exchanges the refresh token for a new access token mid-flight.
///
/// Wraps the generated client's inner [Client], since the generated code offers
/// no interceptor hook of its own.
class AuthenticatedClient extends BaseClient {
  AuthenticatedClient({
    required Client inner,
    required Future<String?> Function() onUnauthorized,
  })  : _inner = inner,
        _onUnauthorized = onUnauthorized;

  final Client _inner;

  /// Obtains a fresh access token, or null if the session is truly over.
  final Future<String?> Function() _onUnauthorized;

  /// Shared so that several requests failing at once trigger one refresh rather
  /// than a stampede — and so the losers wait for the winner's token instead of
  /// racing to rotate it, which would revoke each other's.
  Future<String?>? _inFlightRefresh;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // Captured before sending: a request's body stream can only be read once,
    // so a replay needs its own copy.
    final bodyBytes = request is Request ? request.bodyBytes : null;

    final response = await _inner.send(request);

    if (response.statusCode != 401 || !_isReplayable(request)) {
      return response;
    }

    // Buffered so the original response can still be returned intact if the
    // refresh fails.
    final originalBody = await response.stream.toBytes();

    final token = await _refreshOnce();
    if (token == null || token.isEmpty) {
      return StreamedResponse(
        Stream.value(originalBody),
        response.statusCode,
        request: request,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
      );
    }

    final replay = Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..headers['Authorization'] = 'Bearer $token'
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;

    if (bodyBytes != null && bodyBytes.isNotEmpty) {
      replay.bodyBytes = bodyBytes;
    }

    return _inner.send(replay);
  }

  Future<String?> _refreshOnce() {
    return _inFlightRefresh ??= _onUnauthorized().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  /// Only plain requests are replayed.
  ///
  /// Streamed and multipart bodies (file uploads) cannot be rewound, so they
  /// are returned as-is rather than replayed with an empty body — a silent
  /// corruption that would be far worse than the 401.
  ///
  /// The auth endpoints are excluded too: a 401 from login or refresh is a real
  /// answer, and refreshing in response would recurse.
  bool _isReplayable(BaseRequest request) {
    if (request is! Request) return false;
    return !request.url.path.contains('/api/v1/auth/');
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
