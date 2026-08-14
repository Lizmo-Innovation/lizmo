@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_api/api.dart';

/// Exercises the generated client against a running API.
///
/// Excluded from the default run because it needs the Docker stack up:
///   docker compose up -d
///   flutter test --tags live
///
/// Unit tests cover our own logic; this covers the seam between the generated
/// client, the wire format, and the error contract — the part that silently
/// breaks when the backend changes.
void main() {
  const baseUrl = String.fromEnvironment(
    'LIZMO_API_BASE_URL',
    defaultValue: 'http://localhost:8082',
  );

  late AuthApi api;

  setUp(() {
    api = AuthApi(ApiClient(basePath: baseUrl));
  });

  String uniqueEmail() => 'live${DateTime.now().microsecondsSinceEpoch}@lizmo.test';

  test('register issues tokens and a tenant profile', () async {
    final response = await api.register(RegisterRequest(
      name: 'Live Test',
      email: uniqueEmail(),
      password: 'correct-horse-battery',
    ));

    expect(response, isNotNull);
    expect(response!.accessToken, isNotEmpty);
    expect(response.refreshToken, isNotEmpty);
    expect(response.profiles, ['TENANT']);
    expect(response.expiresIn, 3600);

    // The mapping the app actually depends on.
    final session = Session.fromResponse(response);
    expect(session.isTenant, isTrue);
    expect(session.isLandlord, isFalse);
    expect(session.hasMultipleProfiles, isFalse);
  });

  test('landlord registration yields both profiles', () async {
    final response = await api.register(RegisterRequest(
      name: 'Live Landlord',
      email: uniqueEmail(),
      password: 'correct-horse-battery',
      asLandlord: true,
    ));

    final session = Session.fromResponse(response!);
    expect(session.isLandlord, isTrue);
    expect(session.hasMultipleProfiles, isTrue);
  });

  test('login then refresh rotates the refresh token', () async {
    final email = uniqueEmail();
    await api.register(RegisterRequest(
      name: 'Rotation',
      email: email,
      password: 'correct-horse-battery',
    ));

    final login = await api.login(
      LoginRequest(identifier: email, password: 'correct-horse-battery'),
    );
    final first = login!.refreshToken!;

    final refreshed = await api.refresh(RefreshRequest(refreshToken: first));
    expect(refreshed!.refreshToken, isNot(first));

    // The spent token must be rejected, not silently accepted again.
    await expectLater(
      () => api.refresh(RefreshRequest(refreshToken: first)),
      throwsA(isA<ApiException>()),
    );
  });

  test('wrong password surfaces INVALID_CREDENTIALS through ApiFailure', () async {
    try {
      await api.login(LoginRequest(
        identifier: 'nobody-${DateTime.now().microsecondsSinceEpoch}@lizmo.test',
        password: 'definitely-wrong',
      ));
      fail('expected the call to throw');
    } catch (error) {
      final failure = ApiFailure.from(error);
      // Proves the error contract survives the round trip: the client parses
      // the backend's code rather than falling back to UNKNOWN.
      expect(failure.code, 'INVALID_CREDENTIALS');
      expect(failure.message, isNotEmpty);
      expect(failure.isNetwork, isFalse);
    }
  });

  test('validation errors carry per-field messages', () async {
    try {
      await api.register(RegisterRequest(
        name: 'Short Password',
        email: uniqueEmail(),
        password: 'short',
      ));
      fail('expected the call to throw');
    } catch (error) {
      final failure = ApiFailure.from(error);
      expect(failure.code, 'VALIDATION_FAILED');
      expect(failure.fields['password'], isNotNull);
    }
  });

  test('unreachable host is reported as a network failure', () async {
    final offline = AuthApi(ApiClient(basePath: 'http://localhost:59999'));
    try {
      await offline.login(LoginRequest(identifier: 'a@b.test', password: 'whatever1'));
      fail('expected the call to throw');
    } catch (error) {
      final failure = ApiFailure.from(error);
      // Distinguishing this matters: the user can act on "no connection".
      expect(failure.isNetwork, isTrue);
    }
  });
}
