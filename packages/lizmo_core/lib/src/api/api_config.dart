import 'package:flutter/foundation.dart';

/// Where the API lives.
///
/// Override for a real device or a deployed environment:
///   flutter run --dart-define=LIZMO_API_BASE_URL=https://lizmo-api-xxxx.run.app
///
/// Uses [defaultTargetPlatform] rather than `dart:io`'s Platform, which is not
/// available on web — dart2js substitutes a stub that throws, so the guard
/// would compile and then fail at runtime in the admin console.
abstract final class ApiConfig {
  static const _override = String.fromEnvironment('LIZMO_API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches the host machine through 10.0.2.2; localhost
    // there refers to the emulator itself. A physical device needs the LAN
    // address passed via --dart-define.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      //return 'http://10.0.2.2:8082';
      return 'http://192.168.18.7:8082';
    }

    // Host port 8082, not 8080 — see the README on port collisions.
    return 'http://localhost:8082';
  }
}
