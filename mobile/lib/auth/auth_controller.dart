import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';

import '../api/api_config.dart';
import '../api/api_failure.dart';
import 'auth_state.dart';
import 'token_store.dart';

/// Held separately so the access token can be swapped without rebuilding the
/// client. The generated ApiClient takes its authentication once, at
/// construction, and exposes no setter.
final bearerAuthProvider = Provider<HttpBearerAuth>((ref) => HttpBearerAuth());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    basePath: ApiConfig.baseUrl,
    authentication: ref.watch(bearerAuthProvider),
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Owns the session: sign in, sign up, restore on launch, sign out.
///
/// Errors surface as thrown [ApiFailure]s rather than being folded into the
/// state, so a failed login leaves the state untouched and the screen decides
/// how to present it.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Restoring touches secure storage, so the first frame renders on
    // AuthUnknown and the splash shows until this resolves.
    Future.microtask(restore);
    return const AuthUnknown();
  }

  AuthApi get _api => ref.read(authApiProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  /// Exchanges a stored refresh token for a live session.
  ///
  /// The access token is not reused even when present: it may have expired
  /// while the app was closed, and refreshing is the only way to find out
  /// without a request that fails.
  Future<void> restore() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      state = const AuthSignedOut();
      return;
    }

    try {
      final response = await _api.refresh(RefreshRequest(refreshToken: refreshToken));
      if (response == null) {
        await _signOutLocally();
        return;
      }
      await _persist(response);
    } catch (error) {
      final failure = ApiFailure.from(error);
      // A network blip should not throw away a valid 30-day token — only a
      // token the server actually rejected.
      if (failure.isNetwork) {
        state = const AuthSignedOut();
        return;
      }
      await _signOutLocally();
    }
  }

  Future<void> login({required String identifier, required String password}) async {
    try {
      final response = await _api.login(
        LoginRequest(identifier: identifier.trim(), password: password),
      );
      if (response == null) {
        throw const ApiFailure(code: 'UNKNOWN', message: 'Sign in failed. Please try again.');
      }
      await _persist(response);
    } catch (error) {
      throw ApiFailure.from(error);
    }
  }

  Future<void> register({
    required String name,
    required String password,
    String? email,
    String? phone,
    bool asLandlord = false,
  }) async {
    try {
      final response = await _api.register(RegisterRequest(
        name: name.trim(),
        email: (email?.trim().isEmpty ?? true) ? null : email!.trim(),
        phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        password: password,
        asLandlord: asLandlord,
      ));
      if (response == null) {
        throw const ApiFailure(code: 'UNKNOWN', message: 'Sign up failed. Please try again.');
      }
      await _persist(response);
    } catch (error) {
      throw ApiFailure.from(error);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _api.logout(RefreshRequest(refreshToken: refreshToken));
      } catch (_) {
        // Revoking server-side is best effort. Failing to reach the server must
        // not trap the user in a session they asked to leave.
      }
    }
    await _signOutLocally();
  }

  Future<void> _persist(AuthResponse response) async {
    await _tokens.save(
      accessToken: response.accessToken ?? '',
      refreshToken: response.refreshToken ?? '',
    );
    _applyBearerToken(response.accessToken);
    state = AuthSignedIn(Session.fromResponse(response));
  }

  Future<void> _signOutLocally() async {
    await _tokens.clear();
    _applyBearerToken(null);
    state = const AuthSignedOut();
  }

  void _applyBearerToken(String? token) {
    ref.read(bearerAuthProvider).accessToken = token ?? '';
  }
}
