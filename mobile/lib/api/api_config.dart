import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the API lives.
///
/// Override for a real device or a deployed environment:
///   flutter run --dart-define=LIZMO_API_BASE_URL=https://lizmo-api-xxxx.run.app
abstract final class ApiConfig {
  static const _override = String.fromEnvironment('LIZMO_API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches the host machine through 10.0.2.2; localhost
    // there refers to the emulator itself.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8082';
    }

    // Host port 8082, not 8080 — see the README on port collisions.
    return 'http://localhost:8082';
  }
}
