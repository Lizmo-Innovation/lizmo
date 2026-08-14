import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/main.dart';
import 'package:lizmo_admin/router.dart';
import 'package:lizmo_admin/screens/admin_login_screen.dart';
import 'package:lizmo_admin/screens/platform_payments_screen.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Drives the shell directly, without touching storage or the network.
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
      child: const LizmoAdminApp(),
    );

AuthSignedIn _signedIn(Set<LizmoProfile> profiles) => AuthSignedIn(
      Session(
        userId: 'u1',
        name: 'Staff Member',
        profiles: profiles,
        accessToken: 'token',
      ),
    );

void _desktop(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1280 * 2, 900 * 2)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  group('admin gate', () {
    testWidgets('signed out shows login', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(PlatformPaymentsScreen), findsNothing);
    });

    testWidgets('a platform admin reaches the queue', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      expect(find.byType(PlatformPaymentsScreen), findsOneWidget);
    });

    testWidgets('a landlord with valid credentials is refused', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(
        _app(_signedIn({LizmoProfile.tenant, LizmoProfile.landlord})),
      );
      await tester.pumpAndSettle();

      // Signing in successfully is not enough: this console verifies payments
      // made to Lizmo, and a customer must never reach it.
      expect(find.byType(PlatformPaymentsScreen), findsNothing);
      expect(find.textContaining('not a Lizmo admin'), findsOneWidget);
    });

    testWidgets('an admin who also rents still reaches the queue', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(
        _app(_signedIn({LizmoProfile.tenant, LizmoProfile.admin})),
      );
      await tester.pumpAndSettle();

      // Lizmo staff may rent somewhere too; that must not lock them out.
      expect(find.byType(PlatformPaymentsScreen), findsOneWidget);
    });

    testWidgets('a landlord cannot reach the queue by URL', (tester) async {
      _desktop(tester);

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuth(_signedIn({LizmoProfile.tenant, LizmoProfile.landlord})),
          ),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoAdminApp()),
      );
      await tester.pumpAndSettle();

      // Typing the URL is the obvious way to try to bypass a client-side gate,
      // so the redirect must run on direct navigation too, not just on taps.
      container.read(routerProvider).go(Routes.payments);
      await tester.pumpAndSettle();

      expect(find.byType(PlatformPaymentsScreen), findsNothing);
      expect(find.textContaining('not a Lizmo admin'), findsOneWidget);
    });

    testWidgets('unknown auth state shows neither login nor the queue', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(const AuthUnknown()));
      // pump, not pumpAndSettle: the splash spinner never stops animating, so
      // settling would wait forever.
      await tester.pump();

      expect(find.byType(AdminLoginScreen), findsNothing);
      expect(find.byType(PlatformPaymentsScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('review queue', () {
    testWidgets('lists payments with their statuses', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      expect(find.text('LIZMO ADMIN'), findsOneWidget);
      expect(find.text('Platform payments'), findsOneWidget);
      expect(find.byType(StatusChip), findsNWidgets(4));
    });

    testWidgets('only pending payments expose confirm/reject', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // Confirmed and overdue rows have nothing left to decide.
      expect(find.text('Confirm'), findsNWidgets(2));
      expect(find.text('Reject'), findsNWidgets(2));
    });

    testWidgets('sign out is reachable from the header', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // An admin session can confirm payments to Lizmo, so ending one on a
      // shared machine must be easy.
      expect(find.text('Sign out'), findsOneWidget);
    });
  });

  group('login form', () {
    testWidgets('rejects empty fields before calling the API', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email or phone number'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('warns that the session is tab-scoped', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      // Tokens are held in memory only, so this is behaviour worth stating
      // rather than letting admins discover it.
      expect(find.textContaining('Sessions end'), findsOneWidget);
    });
  });
}
