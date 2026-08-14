import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the token pair in platform-backed secure storage — Keychain on iOS,
/// EncryptedSharedPreferences on Android.
///
/// Deliberately not SharedPreferences: a refresh token is a 30-day credential,
/// and plaintext preferences are readable on a rooted or jailbroken device.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'lizmo.access_token';
  static const _refreshKey = 'lizmo.refresh_token';

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
