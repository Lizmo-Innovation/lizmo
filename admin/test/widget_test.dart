import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/main.dart';
import 'package:lizmo_admin/router.dart';
import 'package:lizmo_admin/screens/admin_login_screen.dart';
import 'package:lizmo_admin/screens/invitations_screen.dart';
import 'package:lizmo_admin/screens/landlords_screen.dart';
import 'package:lizmo_admin/screens/platform_payments_screen.dart';
import 'package:lizmo_admin/widgets/platform_payment_card.dart';
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

    testWidgets('a platform admin lands on the landlords list', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // Landlords rather than the payment queue: payments are a task you sit
      // down to do, landlords are the subject the console is about.
      expect(find.byType(LandlordsScreen), findsOneWidget);
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

    testWidgets('an admin who also rents still gets in', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(
        _app(_signedIn({LizmoProfile.tenant, LizmoProfile.admin})),
      );
      await tester.pumpAndSettle();

      // Lizmo staff may rent somewhere too; that must not lock them out.
      expect(find.byType(LandlordsScreen), findsOneWidget);
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

  group('the console frame', () {
    testWidgets('the rail moves between screens', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // The console had no navigation at all before: one screen, and a way
      // out. A tool somebody works in needs somewhere to go.
      await tester.tap(find.widgetWithText(InkWell, 'Payments'));
      await tester.pumpAndSettle();
      expect(find.byType(PlatformPaymentsScreen), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Invitations'));
      await tester.pumpAndSettle();
      expect(find.byType(InvitationsScreen), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Landlords'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordsScreen), findsOneWidget);
    });

    testWidgets('every screen says plainly that it is empty', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // This screen used to render five invented landlords with Confirm and
      // Reject buttons wired to nothing. A console that looks finished and
      // does nothing is worse than one that admits what it is.
      expect(find.text('No landlords yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Payments'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing to review'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
    });

    testWidgets('a narrow window keeps the rail, drops its labels',
        (tester) async {
      tester.view
        ..physicalSize = const Size(600 * 2, 800 * 2)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // A browser dragged to half a screen is a normal way to use a console.
      // The rail narrows rather than pushing the content off the edge.
      expect(find.text('Lizmo admin'), findsNothing);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('sign out is reachable', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();

      // An admin session can confirm payments to Lizmo, so ending one on a
      // shared machine must be easy.
      expect(find.text('Sign out'), findsOneWidget);
    });
  });

  group('the payment card', () {
    // Built, and not yet placed on any screen: nothing raises a billing cycle,
    // so there is nothing for the queue to list. Tested directly so the
    // component stays honest until the endpoint exists.
    Widget card(LizmoStatus status, String label) => MaterialApp(
          home: Scaffold(
            body: PlatformPaymentCard(
              landlord: 'Elena Bautista',
              subtitle: 'Sunrise Apartments · March',
              amount: '\u20b12,480',
              status: status,
              statusLabel: label,
              onConfirm: () {},
              onReject: () {},
              onViewProof: () {},
            ),
          ),
        );

    testWidgets('a pending payment offers a decision', (tester) async {
      await tester.pumpWidget(card(LizmoStatus.pending, 'Pending'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('a settled payment offers none', (tester) async {
      await tester.pumpWidget(card(LizmoStatus.paid, 'Confirmed'));
      await tester.pumpAndSettle();

      // Confirmed rows have nothing left to decide.
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Reject'), findsNothing);
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
