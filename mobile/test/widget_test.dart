import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/auth/active_role.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo/router.dart';
import 'package:lizmo/screens/login_screen.dart';
import 'package:lizmo/screens/register_screen.dart';
import 'package:lizmo/screens/rent_roll_screen.dart';
import 'package:lizmo/screens/tenant_home_screen.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Drives routing directly, without touching secure storage or the network.
class _FakeAuth extends AuthController {
  _FakeAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

Widget _app(AuthState initial) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(initial)),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      ],
      child: const LizmoApp(),
    );

AuthSignedIn _signedIn(Set<LizmoProfile> profiles) => AuthSignedIn(
      Session(
        userId: 'u1',
        name: 'Ana Reyes',
        profiles: profiles,
        accessToken: 'token',
      ),
    );

void main() {
  group('routing follows auth state', () {
    testWidgets('signed out lands on login', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RentRollScreen), findsNothing);
    });

    testWidgets('unknown holds on the splash, never app content', (tester) async {
      await tester.pumpWidget(_app(const AuthUnknown()));
      await tester.pump();

      // Showing content before tokens are checked would flash the app at
      // someone who is not signed in.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(RentRollScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a tenant lands on their own screen', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.tenant})));
      await tester.pumpAndSettle();

      expect(find.byType(TenantHomeScreen), findsOneWidget);
      expect(find.byType(RentRollScreen), findsNothing);
    });

    testWidgets('a landlord lands on the rent roll', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();

      expect(find.byType(RentRollScreen), findsOneWidget);
      expect(find.byType(TenantHomeScreen), findsNothing);
    });
  });

  group('route guards', () {
    testWidgets('a tenant cannot reach the rent roll by URL', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();

      // Navigate straight at the landlord route, as a typed URL or stale deep
      // link would. The rent roll lists every tenant in the property with their
      // payment status, so reaching it must not be possible.
      container.read(routerProvider).go(Routes.landlord);
      await tester.pumpAndSettle();

      expect(find.byType(RentRollScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('signing out from any screen returns to login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TenantHomeScreen), findsOneWidget);

      // The router listens to auth, so no screen has to handle this itself.
      container.read(authControllerProvider.notifier).state = const AuthSignedOut();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TenantHomeScreen), findsNothing);
    });
  });

  group('role switching', () {
    testWidgets('a single-profile user sees no switcher', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.tenant})));
      await tester.pumpAndSettle();

      expect(find.text('Tenant'), findsNothing);
      expect(find.text('Landlord'), findsNothing);
    });

    testWidgets('holding both opens on landlord with a switcher', (tester) async {
      await tester.pumpWidget(
        _app(_signedIn({LizmoProfile.tenant, LizmoProfile.landlord})),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RentRollScreen), findsOneWidget);
      expect(find.text('Tenant'), findsOneWidget);
      expect(find.text('Landlord'), findsOneWidget);
    });

    testWidgets('switching navigates between the two homes', (tester) async {
      await tester.pumpWidget(
        _app(_signedIn({LizmoProfile.tenant, LizmoProfile.landlord})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tenant'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantHomeScreen), findsOneWidget);
      expect(find.byType(RentRollScreen), findsNothing);

      await tester.tap(find.text('Landlord'));
      await tester.pumpAndSettle();
      expect(find.byType(RentRollScreen), findsOneWidget);
    });

    test('default role prefers landlord when both are held', () {
      expect(
        ActiveRoleController.defaultFor({LizmoProfile.tenant, LizmoProfile.landlord}),
        LizmoProfile.landlord,
      );
      expect(ActiveRoleController.defaultFor({LizmoProfile.tenant}), LizmoProfile.tenant);
      expect(ActiveRoleController.defaultFor({}), isNull);
    });
  });

  group('registration', () {
    testWidgets('is reachable from login without a session', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New to Lizmo? Create an account'));
      await tester.pumpAndSettle();

      // The signed-out redirect has to permit /register, or a new user could
      // never get past login.
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('can go back to login', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New to Lizmo? Create an account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I already have an account'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('rejects empty fields before calling the API', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New to Lizmo? Create an account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter an email address or phone number'), findsOneWidget);
      expect(find.text('Choose a password'), findsOneWidget);
    });

    testWidgets('enforces the same password length as the server', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New to Lizmo? Create an account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Reyes');
      await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'short');
      await tester.tap(find.text('Create account'));
      await tester.pump();

      // Caught here rather than after a round trip.
      expect(find.text('Use at least 8 characters'), findsOneWidget);
    });

    testWidgets('landlord choice is off by default and toggles', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New to Lizmo? Create an account'));
      await tester.pumpAndSettle();

      Checkbox box() => tester.widget<Checkbox>(find.byType(Checkbox));
      expect(box().value, isFalse, reason: 'most accounts are tenants');

      await tester.tap(find.text('I rent out property'));
      await tester.pump();

      expect(box().value, isTrue);
    });
  });

  group('login screen', () {
    testWidgets('rejects empty fields before calling the API', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email or phone number'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('password is obscured and can be revealed', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      EditableText passwordField() =>
          tester.widget<EditableText>(find.byType(EditableText).last);

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      expect(passwordField().obscureText, isFalse);
    });
  });

  group('routes', () {
    test('paths are distinct', () {
      final paths = {
        Routes.splash,
        Routes.login,
        Routes.tenant,
        Routes.landlord,
        Routes.noProfile,
      };
      expect(paths.length, 5, reason: 'a duplicated path would shadow a route');
    });
  });
}
