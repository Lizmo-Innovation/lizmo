import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the token pair lives between requests.
///
/// Two implementations, because the two apps face different threats:
/// [SecureTokenStore] for mobile, [InMemoryTokenStore] for the admin console.
abstract interface class TokenStore {
  Future<void> save({required String accessToken, required String refreshToken});

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> clear();
}

/// Platform-backed storage — Keychain on iOS, EncryptedSharedPreferences on
/// Android.
///
/// Deliberately not SharedPreferences: a refresh token is a 30-day credential,
/// and plaintext preferences are readable on a rooted or jailbroken device.
///
/// Not suitable for web. There the package encrypts into localStorage but keeps
/// the key in localStorage too, so any XSS on the origin can lift the refresh
/// token — see [InMemoryTokenStore].
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'lizmo.access_token';
  static const _refreshKey = 'lizmo.refresh_token';

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}

/// Holds tokens in memory only, so they never reach browser storage.
///
/// Used by the admin console. Without a backend that issues an httpOnly refresh
/// cookie, anything persisted on web is readable by script, and this is the one
/// console where a stolen session can confirm payments to Lizmo.
///
/// The cost is real and intended: closing the tab ends the session, so admins
/// sign in again rather than staying logged in indefinitely.
class InMemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
