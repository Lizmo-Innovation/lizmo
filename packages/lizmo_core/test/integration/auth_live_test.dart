@Tags(['live'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
///
/// Signing up now needs the code that was emailed, so this reads it back out
/// of Mailpit, which is the same thing a person does with their inbox.
void main() {
  const baseUrl = String.fromEnvironment(
    'LIZMO_API_BASE_URL',
    defaultValue: 'http://localhost:8082',
  );
  const mailpitUrl = String.fromEnvironment(
    'LIZMO_MAILPIT_URL',
    defaultValue: 'http://localhost:8026',
  );
  const password = 'Sunrise2Bed!';

  late AuthApi api;
  late SigningUpApi signingUp;

  setUp(() {
    final client = ApiClient(basePath: baseUrl);
    api = AuthApi(client);
    signingUp = SigningUpApi(client);
  });

  String uniqueEmail() => 'live${DateTime.now().microsecondsSinceEpoch}@lizmo.test';

  /// The six digits Lizmo just emailed, read from the subject line.
  Future<String> codeSentTo(String email) async {
    final response = await http.get(
      Uri.parse('$mailpitUrl/api/v1/search?query=${Uri.encodeQueryComponent('to:$email')}'),
    );
    final messages =
        (jsonDecode(response.body) as Map<String, dynamic>)['messages'] as List;
    expect(messages, isNotEmpty, reason: 'no email reached Mailpit for $email');

    final subject = (messages.first as Map<String, dynamic>)['Subject'] as String;
    final digits = RegExp(r'\d{6}').firstMatch(subject);
    expect(digits, isNotNull, reason: 'no code in subject: $subject');
    return digits!.group(0)!;
  }

  Future<AuthResponse> signUp(String email, {String name = 'Live Test'}) async {
    await signingUp.startRegistration(StartRegistrationRequest(email: email));
    final response = await signingUp.completeRegistration(
      CompleteRegistrationRequest(
        email: email,
        code: await codeSentTo(email),
        name: name,
        password: password,
      ),
    );
    return response!;
  }

  test('signing up issues tokens and a tenant profile', () async {
    final response = await signUp(uniqueEmail());

    expect(response.accessToken, isNotEmpty);
    expect(response.refreshToken, isNotEmpty);
    // A tenant and nothing else: there is no self-service landlord any more.
    expect(response.profiles, ['TENANT']);
    expect(response.expiresIn, 3600);

    // The mapping the app actually depends on.
    final session = Session.fromResponse(response);
    expect(session.isTenant, isTrue);
    expect(session.isLandlord, isFalse);
    expect(session.hasMultipleProfiles, isFalse);
  });

  test('the code is good for one account only', () async {
    final email = uniqueEmail();
    await signingUp.startRegistration(StartRegistrationRequest(email: email));
    final code = await codeSentTo(email);

    await signingUp.completeRegistration(CompleteRegistrationRequest(
      email: email, code: code, name: 'First', password: password));

    await expectLater(
      () => signingUp.completeRegistration(CompleteRegistrationRequest(
          email: email, code: code, name: 'Second', password: password)),
      throwsA(isA<ApiException>()),
    );
  });

  test('a weak password is refused by code, and names what is missing', () async {
    final email = uniqueEmail();
    await signingUp.startRegistration(StartRegistrationRequest(email: email));

    try {
      await signingUp.completeRegistration(CompleteRegistrationRequest(
        email: email,
        code: await codeSentTo(email),
        name: 'Weak',
        password: 'nodigitsorcaps',
      ));
      fail('expected the call to throw');
    } catch (error) {
      final failure = ApiFailure.from(error);
      expect(failure.code, 'WEAK_PASSWORD');
      // The app mirrors these rules under the field; if the wording drifts the
      // user is told two different things.
      expect(failure.message, contains('a capital letter'));
      expect(failure.message, contains('a number'));
      expect(failure.message, contains('a symbol'));
    }
  });

  test('the rule the app enforces is the rule the server enforces', () async {
    // The mirror in PasswordRules exists so the rules can be shown while
    // somebody types. If it drifts, the app promises an account the server
    // then refuses.
    final email = uniqueEmail();
    expect(PasswordRules.isAcceptable(password), isTrue);

    await signingUp.startRegistration(StartRegistrationRequest(email: email));
    final response = await signingUp.completeRegistration(
      CompleteRegistrationRequest(
        email: email,
        code: await codeSentTo(email),
        name: 'Mirror',
        password: password,
      ),
    );
    expect(response, isNotNull);
  });

  test('login then refresh rotates the refresh token', () async {
    final email = uniqueEmail();
    await signUp(email, name: 'Rotation');

    final login = await api.login(
      LoginRequest(identifier: email, password: password),
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
    final email = uniqueEmail();
    await signingUp.startRegistration(StartRegistrationRequest(email: email));

    try {
      await signingUp.completeRegistration(CompleteRegistrationRequest(
        email: email,
        code: await codeSentTo(email),
        name: '',
        password: password,
      ));
      fail('expected the call to throw');
    } catch (error) {
      final failure = ApiFailure.from(error);
      expect(failure.code, 'VALIDATION_FAILED');
      expect(failure.fields['name'], isNotNull);
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
