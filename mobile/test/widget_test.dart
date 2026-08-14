import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/auth/auth_controller.dart';
import 'package:lizmo/auth/auth_state.dart';
import 'package:lizmo/app_shell.dart';
import 'package:lizmo/screens/login_screen.dart';
import 'package:lizmo/screens/rent_roll_screen.dart';

/// Drives the shell directly, without touching secure storage or the network.
class _FakeAuth extends AuthController {
  _FakeAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

Widget _app(AuthState initial) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(initial)),
      ],
      child: const MaterialApp(home: AppShell()),
    );

void main() {
  group('app shell routes on auth state', () {
    testWidgets('signed out shows login', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RentRollScreen), findsNothing);
    });

    testWidgets('unknown shows a splash, never app content', (tester) async {
      await tester.pumpWidget(_app(const AuthUnknown()));
      // Matters on launch: showing content before tokens are checked would
      // flash the app to a user who is not signed in.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(RentRollScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('signed in shows app content', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedIn(Session(
        userId: 'u1',
        name: 'Ana Reyes',
        profiles: {LizmoProfile.tenant},
        accessToken: 'token',
      ))));
      expect(find.byType(RentRollScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('login screen', () {
    testWidgets('rejects empty fields before calling the API', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email or phone number'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('password is obscured and can be revealed', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));

      EditableText passwordField() => tester.widget<EditableText>(
            find.byType(EditableText).last,
          );

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(passwordField().obscureText, isFalse);
    });
  });

  group('session', () {
    test('exposes role switching only when more than one profile is held', () {
      const tenantOnly = Session(
        userId: 'u1', name: 'Ana', accessToken: 't',
        profiles: {LizmoProfile.tenant},
      );
      const both = Session(
        userId: 'u2', name: 'Elena', accessToken: 't',
        profiles: {LizmoProfile.tenant, LizmoProfile.landlord},
      );

      expect(tenantOnly.hasMultipleProfiles, isFalse);
      expect(both.hasMultipleProfiles, isTrue);
      expect(both.isLandlord, isTrue);
    });

    test('unknown profile values are ignored rather than crashing', () {
      // Forward compatibility: the backend may add a profile this build has
      // never heard of, and an older app must keep working.
      expect(LizmoProfile.parse('STAFF'), isNull);
      expect(LizmoProfile.parse('tenant'), LizmoProfile.tenant);
    });
  });
}
