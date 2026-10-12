import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/push/push_channel.dart';
import 'package:lizmo/push/push_providers.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Which phone the server pushes to: told after signing in, told again when
/// Firebase replaces the token, and untold on the way out.
///
/// Firebase itself is not here -- only what the app does with the token it
/// hands over.
void main() {
  late List<String> events;
  late _FakeChannel channel;
  late _FakeDevices devices;

  setUp(() {
    events = [];
    channel = _FakeChannel(events, token: 'phone-1');
    devices = _FakeDevices(events);
  });

  ProviderContainer containerFor(AuthState initial) {
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(() => _FakeAuth(initial, events)),
      pushChannelProvider.overrideWithValue(channel),
      devicesApiProvider.overrideWithValue(devices),
    ]);
    addTearDown(container.dispose);
    container.listen(pushRegistrationProvider, (_, __) {});
    return container;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('registering', () {
    test('a phone signed in on is registered', () async {
      containerFor(_signedIn('ana'));
      await settle();

      expect(devices.registered, ['phone-1']);
      expect(devices.platforms.single, RegisterDevicePlatformEnum.ANDROID);
    });

    test('a phone nobody is signed in on is not', () async {
      containerFor(const AuthSignedOut());
      await settle();

      expect(devices.registered, isEmpty);
    });

    test('signing in registers it then', () async {
      final container = containerFor(const AuthSignedOut());
      await settle();

      container.read(authControllerProvider.notifier).state = _signedIn('ana');
      await settle();

      expect(devices.registered, ['phone-1']);
    });

    test('a token Firebase replaces is registered in its place', () async {
      containerFor(_signedIn('ana'));
      await settle();

      channel.refreshes.add('phone-1b');
      await settle();

      expect(devices.registered, ['phone-1', 'phone-1b']);
    });

    /// An access token refreshed every few minutes is the same person.
    test('a refreshed session does not register it again', () async {
      final container = containerFor(_signedIn('ana'));
      await settle();

      container.read(authControllerProvider.notifier).state =
          _signedIn('ana', accessToken: 'newer');
      await settle();

      expect(devices.registered, ['phone-1']);
    });

    test('somebody else signing in moves it to them', () async {
      final container = containerFor(_signedIn('ana'));
      await settle();

      container.read(authControllerProvider.notifier).state = _signedIn('bea');
      await settle();

      expect(devices.registered, ['phone-1', 'phone-1']);
    });

    test('a phone with no push registers nothing', () async {
      channel = _FakeChannel(events, token: null);
      containerFor(_signedIn('ana'));
      await settle();

      expect(devices.registered, isEmpty);
    });

    test('a server it cannot reach is no error', () async {
      devices.failing = true;
      containerFor(_signedIn('ana'));
      await settle();

      expect(devices.registered, isEmpty);
    });

    test('after signing out, a new token is nobody\'s', () async {
      final container = containerFor(_signedIn('ana'));
      await settle();
      container.read(authControllerProvider.notifier).state =
          const AuthSignedOut();
      await settle();

      channel.refreshes.add('phone-1b');
      await settle();

      expect(devices.registered, ['phone-1']);
    });
  });

  group('signing out', () {
    /// Forgotten while the session can still say whose phone it is; the token
    /// thrown away only after, so a replacement is not registered straight
    /// back to the person leaving.
    test('forgets the phone, signs out, then throws the token away', () async {
      final container = containerFor(_signedIn('ana'));
      await settle();
      events.clear();

      await container.read(signOutProvider)();

      expect(events, ['forget phone-1', 'logout', 'delete token']);
      expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    });

    test('a server it cannot reach still signs them out', () async {
      final container = containerFor(_signedIn('ana'));
      await settle();
      devices.failing = true;
      events.clear();

      await container.read(signOutProvider)();

      expect(events, ['logout', 'delete token']);
      expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    });

    test('with no push, it is only signing out', () async {
      channel = _FakeChannel(events, token: null);
      final container = containerFor(_signedIn('ana'));
      await settle();
      events.clear();

      await container.read(signOutProvider)();

      expect(events, ['logout', 'delete token']);
    });

    /// The server forgot every phone with the account, and refuses the session.
    test('after closing the account, the server is not asked', () async {
      final container = containerFor(_signedIn('ana'));
      await settle();
      events.clear();

      await container.read(signOutProvider).afterClosingTheAccount();

      expect(events, ['logout', 'delete token']);
    });
  });
}

AuthSignedIn _signedIn(String userId, {String accessToken = 'token'}) =>
    AuthSignedIn(Session(
      userId: userId,
      name: userId,
      profiles: const {LizmoProfile.tenant},
      accessToken: accessToken,
    ));

class _FakeAuth extends AuthController {
  _FakeAuth(this._initial, this._events);

  final AuthState _initial;
  final List<String> _events;

  @override
  AuthState build() => _initial;

  @override
  Future<void> logout() async {
    _events.add('logout');
    state = const AuthSignedOut();
  }
}

class _FakeChannel implements PushChannel {
  _FakeChannel(this._events, {required String? token}) : _token = token;

  final List<String> _events;
  final String? _token;
  final refreshes = StreamController<String>.broadcast();

  @override
  Future<String?> token() async => _token;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Future<void> deleteToken() async => _events.add('delete token');
}

class _FakeDevices extends DevicesApi {
  _FakeDevices(this._events);

  final List<String> _events;
  final registered = <String>[];
  final platforms = <RegisterDevicePlatformEnum>[];
  bool failing = false;

  @override
  Future<void> registerDevice(RegisterDevice registerDevice,
      {Future<void>? abortTrigger}) async {
    if (failing) throw ApiException(503, 'unreachable');
    registered.add(registerDevice.token);
    platforms.add(registerDevice.platform);
  }

  @override
  Future<void> forgetDevice(String token, {Future<void>? abortTrigger}) async {
    if (failing) throw ApiException(503, 'unreachable');
    _events.add('forget $token');
  }
}
