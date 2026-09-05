import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/admin_providers.dart';
import 'package:lizmo_admin/main.dart';
import 'package:lizmo_admin/router.dart';
import 'package:lizmo_admin/screens/admin_login_screen.dart';
import 'package:lizmo_admin/screens/invitations_screen.dart';
import 'package:lizmo_admin/screens/landlord_detail_screen.dart';
import 'package:lizmo_admin/screens/landlords_screen.dart';
import 'package:lizmo_admin/screens/platform_payments_screen.dart';
import 'package:lizmo_admin/widgets/platform_payment_card.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Drives the shell directly, without touching storage or the network.
class _FakeAuth extends AuthController {
  _FakeAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

LandlordSummary _landlord({
  String id = 'l1',
  String name = 'Elena Bautista',
  int properties = 2,
  int locked = 0,
  int beds = 6,
}) =>
    LandlordSummary(
      userId: id,
      name: name,
      email: 'elena@example.com',
      properties: properties,
      lockedProperties: locked,
      occupiedUnits: 1,
      occupiedBeds: beds,
    );

AdminPropertySummary _property({String status = 'ACTIVE'}) => AdminPropertySummary(
      id: 'p1',
      name: 'Sunrise Apartments',
      address: '12 Mabini St',
      code: 'PH4CP4G2',
      accountStatus: status,
      units: 3,
      occupiedUnits: 1,
      beds: 6,
      occupiedBeds: 4,
    );

/// The console, with the API answering whatever a test needs it to.
///
/// Every screen reads from it now, so a test that does not override this is a
/// test about an error state rather than the one it meant to write.
Widget _app(
  AuthState initial, {
  List<LandlordSummary>? landlords,
  LandlordDetail? landlord,
  List<PendingInvitation>? invitations,
}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(initial)),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        landlordsProvider.overrideWith((ref) async => landlords ?? const []),
        invitationsProvider.overrideWith((ref) async => invitations ?? const []),
        landlordProvider.overrideWith((ref, id) async => landlord),
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
  });

  group('the landlords list', () {
    testWidgets('shows each landlord and what they are billed for',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        landlords: [_landlord(), _landlord(id: 'l2', name: 'Rodel Cruz')],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Elena Bautista'), findsOneWidget);
      expect(find.text('Rodel Cruz'), findsOneWidget);
      // Slots, not money: nothing raises an invoice yet, and a total of zero
      // pesos would read as "everybody has paid".
      expect(find.text('Billable slots'), findsOneWidget);
    });

    testWidgets('a partly locked landlord is not simply "locked"',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        landlords: [_landlord(properties: 3, locked: 1)],
      ));
      await tester.pumpAndSettle();

      // The lock is per property. Telling an admin the landlord is locked
      // would have them chasing the wrong thing.
      expect(find.text('1 of 3 locked'), findsOneWidget);
    });

    testWidgets('every property locked says so plainly', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        landlords: [_landlord(properties: 2, locked: 2)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('All locked'), findsOneWidget);
    });

    testWidgets('a landlord opens their own page', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        landlords: [_landlord()],
        landlord: LandlordDetail(
          landlord: _landlord(),
          properties: [_property()],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elena Bautista'));
      await tester.pumpAndSettle();

      expect(find.byType(LandlordDetailScreen), findsOneWidget);
      expect(find.text('Sunrise Apartments'), findsOneWidget);
    });
  });

  group('one landlord', () {
    Widget page({String status = 'ACTIVE'}) => _app(
          _signedIn({LizmoProfile.admin}),
          landlords: [_landlord()],
          landlord: LandlordDetail(
            landlord: _landlord(),
            properties: [_property(status: status)],
          ),
        );

    testWidgets('offers to lock an active property', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator));

      await tester.tap(find.widgetWithText(InkWell, 'Landlords'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elena Bautista').first);
      await tester.pumpAndSettle();

      expect(find.text('Lock'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('offers to unlock a locked one, and says why it matters',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(page(status: 'LOCKED'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Landlords'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elena Bautista').first);
      await tester.pumpAndSettle();

      expect(find.text('Unlock'), findsOneWidget);
      // An admin looking for an invoice and finding none should learn that
      // none exists, not conclude the page is broken.
      expect(find.textContaining('No invoices yet'), findsOneWidget);
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

  group('invitations', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(InkWell, 'Invitations'));
      await tester.pumpAndSettle();
    }

    testWidgets('an address is required before anything is sent',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();
      await open(tester);

      await tester.tap(find.text('Send invitation'));
      await tester.pump();

      expect(find.text('Enter an email address'), findsOneWidget);
    });

    testWidgets('nonsense is refused before the round trip', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin})));
      await tester.pumpAndSettle();
      await open(tester);

      await tester.enterText(find.byType(TextFormField).first, 'elena');
      await tester.tap(find.text('Send invitation'));
      await tester.pump();

      expect(find.text('That does not look like an email address'), findsOneWidget);
    });

    testWidgets('outstanding invitations are listed with their age',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        invitations: [
          PendingInvitation(
            id: 'i1',
            email: 'rodel@example.com',
            sentAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
            expiresAt: DateTime.now().toUtc().add(const Duration(days: 4)),
            expired: false,
          ),
        ],
      ));
      await tester.pumpAndSettle();
      await open(tester);

      expect(find.text('rodel@example.com'), findsOneWidget);
      // How long ago, not a timestamp: the question is whether to chase.
      expect(find.text('3 days ago'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);
    });

    testWidgets('an expired invitation stays on the list', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        invitations: [
          PendingInvitation(
            id: 'i1',
            email: 'gone@example.com',
            sentAt: DateTime.now().toUtc().subtract(const Duration(days: 9)),
            expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
            expired: true,
          ),
        ],
      ));
      await tester.pumpAndSettle();
      await open(tester);

      // Somebody has to notice that a landlord never signed up. One that
      // silently disappears after seven days is one nobody follows up.
      expect(find.text('Expired'), findsOneWidget);
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
