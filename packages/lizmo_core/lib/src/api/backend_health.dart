import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Whether the backend can be reached at all.
///
/// Nothing in Lizmo works offline — there is no local cache, and every screen
/// is a view onto the API — so an unreachable backend is worth saying plainly
/// at launch rather than letting the user discover it by finding that login
/// fails, or worse, that their portfolio appears empty.
enum BackendReachability { checking, reachable, unreachable }

/// Probes the API with a short timeout.
///
/// Any HTTP answer counts as reachable, including 401 or 503: the question is
/// whether the server is on the other end, not whether this particular request
/// succeeded. Only a socket error or a timeout means genuinely out of contact.
class BackendHealth extends Notifier<BackendReachability> {
  static const timeout = Duration(seconds: 5);

  http.Client _client = http.Client();

  /// Swapped in tests, which must not touch a real socket.
  // ignore: use_setters_to_change_properties
  void useClient(http.Client client) => _client = client;

  @override
  BackendReachability build() {
    ref.onDispose(() => _client.close());
    Future.microtask(check);
    return BackendReachability.checking;
  }

  Future<void> check() async {
    state = BackendReachability.checking;
    try {
      await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/actuator/health'))
          .timeout(timeout);
      state = BackendReachability.reachable;
    } on Object {
      // Deliberately broad: SocketException, ClientException, TimeoutException
      // and the web equivalents all mean the same thing to the person holding
      // the phone.
      state = BackendReachability.unreachable;
    }
  }
}

final backendHealthProvider =
    NotifierProvider<BackendHealth, BackendReachability>(BackendHealth.new);
