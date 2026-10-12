import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

import 'push_channel.dart';

/// No push unless `main` found Firebase and said so.
final pushChannelProvider = Provider<PushChannel>((ref) {
  return const NoPushChannel();
});

final devicesApiProvider = Provider<DevicesApi>((ref) {
  return DevicesApi(ref.watch(apiClientProvider));
});

/// Tells the server which phone to push to, for as long as somebody is
/// signed in on it.
///
/// Watched by the app. Keyed on who is signed in rather than on the whole
/// auth state, so refreshing an access token does not register the phone
/// all over again; signing in as somebody else does, and moves the phone to
/// them.
final pushRegistrationProvider = Provider<void>((ref) {
  final userId = ref.watch(authControllerProvider
      .select((auth) => auth is AuthSignedIn ? auth.session.userId : null));
  if (userId == null) return;

  final channel = ref.watch(pushChannelProvider);
  final devices = ref.watch(devicesApiProvider);

  Future<void> register(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await devices.registerDevice(
        RegisterDevice(token: token, platform: _thisPlatform),
      );
    } catch (_) {
      // Tried again on the next start. A phone that is not registered misses
      // pushes; the bell still has everything.
    }
  }

  unawaited(channel.token().then(register, onError: (_) {}));
  final refreshes = channel.tokenRefreshes.listen(register, onError: (_) {});
  ref.onDispose(refreshes.cancel);
});

RegisterDevicePlatformEnum get _thisPlatform =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? RegisterDevicePlatformEnum.IOS
        : RegisterDevicePlatformEnum.ANDROID;

/// Signing out, including of this phone's pushes.
///
/// The phone is forgotten while the session can still say whose it is, then
/// the session ends, then the token is thrown away -- in that order, because
/// a token replaced while still signed in would be registered straight back
/// to the person leaving. None of it can keep anybody signed in: each step
/// is best effort, and bounded.
class SignOut {
  SignOut(this._ref);

  final Ref _ref;

  static const _patience = Duration(seconds: 5);

  Future<void> call() async {
    final channel = _ref.read(pushChannelProvider);
    final token = await _quietly(channel.token);
    if (token != null && token.isNotEmpty) {
      await _quietly(() => _ref.read(devicesApiProvider).forgetDevice(token));
    }
    await _ref.read(authControllerProvider.notifier).logout();
    await _quietly(channel.deleteToken);
  }

  /// After the account is closed: the server has already forgotten every
  /// phone, and no longer accepts this session to ask it to.
  Future<void> afterClosingTheAccount() async {
    await _ref.read(authControllerProvider.notifier).logout();
    await _quietly(_ref.read(pushChannelProvider).deleteToken);
  }

  static Future<T?> _quietly<T>(Future<T> Function() step) async {
    try {
      return await step().timeout(_patience);
    } catch (_) {
      return null;
    }
  }
}

final signOutProvider = Provider<SignOut>((ref) => SignOut(ref));
