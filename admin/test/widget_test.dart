import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/admin_providers.dart';
import 'package:lizmo_admin/main.dart';
import 'package:lizmo_admin/router.dart';
import 'package:lizmo_admin/screens/accept_invitation_screen.dart';
import 'package:lizmo_admin/screens/admin_login_screen.dart';
import 'package:lizmo_admin/screens/delete_account_info_screen.dart';
import 'package:lizmo_admin/screens/settings_screen.dart';
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
  List<PlatformPaymentForAdmin>? payments,
  List<PlatformStatementResponse>? statements,
  AdminApi? api,
}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(initial)),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        landlordsProvider.overrideWith((ref) async => landlords ?? const []),
        invitationsProvider.overrideWith((ref) async => invitations ?? const []),
        landlordProvider.overrideWith((ref, id) async => landlord),
        platformPaymentsProvider.overrideWith((ref) async => payments ?? const []),
        landlordStatementsProvider
            .overrideWith((ref, id) async => statements ?? const []),
        if (api != null) adminApiProvider.overrideWithValue(api),
      ],
      child: const LizmoAdminApp(),
    );

/// The invitation page at a given token, with the API answering for it.
Widget _inviteApp({
  InvitationDetailsResponse? invitation,
  Object? failure,
  AuthState auth = const AuthSignedOut(),
}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(auth)),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        invitationDetailsProvider.overrideWith((ref, token) async {
          if (failure != null) throw failure;
          return invitation;
        }),
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

/// Keeps what the Payments queue asked of the API.
class _FakeAdminApi extends AdminApi {
  final confirmed = <String>[];
  final rejected = <(String, String?)>[];

  @override
  Future<PlatformPaymentForAdmin?> confirmPlatformPayment(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    confirmed.add(id);
    return null;
  }

  @override
  Future<PlatformPaymentForAdmin?> rejectPlatformPayment(
    String id, {
    PlatformPaymentRejection? platformPaymentRejection,
    Future<void>? abortTrigger,
  }) async {
    rejected.add((id, platformPaymentRejection?.remarks));
    return null;
  }
}

PlatformPaymentForAdmin _sentToLizmo() => PlatformPaymentForAdmin(
      id: 'pp1',
      statementId: 's1',
      landlordId: 'l1',
      landlordName: 'Elena Bautista',
      statementLabel: 'September 2026',
      properties: 2,
      statementAmountDue: 450,
      statementOutstanding: 450,
      amountPaid: 450,
      paymentDate: DateTime.utc(2026, 9, 3),
      paymentMethod: PlatformPaymentForAdminPaymentMethodEnum.fromJson('GCASH'),
      status: PlatformPaymentForAdminStatusEnum.fromJson('PENDING_VERIFICATION'),
      remarks: 'Ref 4012',
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

    /// One landlord's page is still the Landlords section. The rail compared
    /// the address exactly, so on /landlords/<id> nothing in it was lit.
    testWidgets('the rail still marks Landlords on one landlord', (tester) async {
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

      final lit = find.descendant(
        of: find.widgetWithText(InkWell, 'Landlords'),
        matching: find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == LizmoColors.tealBg),
      );
      expect(lit, findsOneWidget);
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
      // An admin looking for a statement and finding none should learn that
      // none exists, not conclude the page is broken.
      expect(find.textContaining('No statements yet'), findsOneWidget);
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

  group('an invited landlord', () {
    testWidgets('the link opens a page of their own, not the staff console',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_inviteApp(
        invitation: InvitationDetailsResponse(
          email: 'elena@example.com',
          hasAccount: false,
        ),
      ));
      await tester.pumpAndSettle();

      final router = ProviderScope.containerOf(
        tester.element(find.byType(LizmoAdminApp)),
      ).read(routerProvider);
      router.go('/invite/a-token');
      await tester.pumpAndSettle();

      // Before this page existed, an invited landlord following their link was
      // redirected to the console sign-in and could go no further.
      expect(find.byType(AcceptInvitationScreen), findsOneWidget);
      expect(find.byType(AdminLoginScreen), findsNothing);
      expect(find.text('elena@example.com'), findsOneWidget);
      expect(find.text('Create my account'), findsOneWidget);
    });

    testWidgets('a new landlord is shown the password rules', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_inviteApp(
        invitation: InvitationDetailsResponse(
          email: 'elena@example.com',
          hasAccount: false,
        ),
      ));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/invite/a-token');
      await tester.pumpAndSettle();

      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('A capital letter'), findsOneWidget);
    });

    testWidgets('somebody who already rents is asked for the password they have',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_inviteApp(
        invitation: InvitationDetailsResponse(
          email: 'ana@example.com',
          hasAccount: true,
        ),
      ));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/invite/a-token');
      await tester.pumpAndSettle();

      // A forwarded link must not hand a stranger somebody else's tenancies,
      // so the existing password is the proof.
      expect(find.text('Your Lizmo password'), findsOneWidget);
      expect(find.text('Your name'), findsNothing);
      expect(find.textContaining('you keep everything you already have'),
          findsOneWidget);
    });

    testWidgets('an expired link says so, and what to do', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_inviteApp(
        failure: const ApiFailure(
          code: 'INVITATION_EXPIRED',
          message: 'This invitation has expired.',
        ),
      ));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/invite/a-token');
      await tester.pumpAndSettle();

      expect(find.text('This invitation has expired'), findsOneWidget);
      expect(find.textContaining('Ask Lizmo to send a new invitation'),
          findsOneWidget);
    });

    testWidgets('a used link is refused the same way', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_inviteApp(
        failure: const ApiFailure(
          code: 'INVITATION_INVALID',
          message: 'This invitation has already been used. Sign in instead.',
        ),
      ));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/invite/a-token');
      await tester.pumpAndSettle();

      // One invitation, one landlord: the link dies the moment it is used.
      expect(find.text('This link cannot be used'), findsOneWidget);
    });
  });

  group('the account deletion page', () {
    Widget publicPage({String? support = 'help@lizmo.test'}) => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
                () => _FakeAuth(const AuthSignedOut())),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            supportContactProvider.overrideWith((ref) async => support),
          ],
          child: const LizmoAdminApp(),
        );

    testWidgets('opens without signing in', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(publicPage());
      await tester.pumpAndSettle();

      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/delete-account');
      await tester.pumpAndSettle();

      // Google Play requires this reachable without installing anything, and
      // somebody who has already uninstalled cannot sign in to ask.
      expect(find.byType(DeleteAccountInfoScreen), findsOneWidget);
      expect(find.byType(AdminLoginScreen), findsNothing);
    });

    testWidgets('says what goes, what stays, and where to write',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(publicPage());
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/delete-account');
      await tester.pumpAndSettle();

      expect(find.text('What is deleted'), findsOneWidget);
      expect(find.text('What is kept, and for how long'), findsOneWidget);
      // The address comes from a setting, so correcting it is a console visit
      // rather than a redeploy.
      expect(find.textContaining('help@lizmo.test'), findsOneWidget);
    });

    testWidgets('still explains itself when the address cannot be loaded',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(publicPage(support: null));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(LizmoAdminApp)))
          .read(routerProvider)
          .go('/delete-account');
      await tester.pumpAndSettle();

      // A policy page that fails to render because one request failed is a
      // policy page that is not there.
      expect(find.text('What is deleted'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('shows the address the public page will carry', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.admin}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          landlordsProvider.overrideWith((ref) async => const []),
          invitationsProvider.overrideWith((ref) async => const []),
          landlordProvider.overrideWith((ref, id) async => null),
          platformSettingsProvider.overrideWith(
              (ref) async => PlatformSettings(supportEmail: 'help@lizmo.test')),
        ],
        child: const LizmoAdminApp(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('help@lizmo.test'), findsOneWidget);
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

  group('checking payments to Lizmo', () {
    Future<void> openPayments(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Payments'));
      await tester.pumpAndSettle();
    }

    /// Enough on the row to decide without opening anything else.
    testWidgets('a payment waiting says who, for what, and how much',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin}),
          payments: [_sentToLizmo()]));
      await openPayments(tester);

      // Two properties, not one: the statement is the whole month's account.
      expect(find.text('Elena Bautista · 2 properties'), findsOneWidget);
      expect(find.text('₱450'), findsOneWidget);
      expect(find.textContaining('for September 2026'), findsOneWidget);
      expect(find.textContaining('"Ref 4012"'), findsOneWidget);
      expect(find.text('To check'), findsOneWidget);
    });

    testWidgets('confirming it is sent to Lizmo', (tester) async {
      _desktop(tester);
      final api = _FakeAdminApi();
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin}),
          payments: [_sentToLizmo()], api: api));
      await openPayments(tester);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(api.confirmed, ['pp1']);
    });

    /// The landlord is told the reason, so it is asked for.
    testWidgets('refusing it asks why, and passes the reason on',
        (tester) async {
      _desktop(tester);
      final api = _FakeAdminApi();
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin}),
          payments: [_sentToLizmo()], api: api));
      await openPayments(tester);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('reject-platform-reason')),
          'Nothing arrived.');
      await tester.tap(find.byKey(const ValueKey('reject-platform-confirm')));
      await tester.pumpAndSettle();

      expect(api.rejected, [('pp1', 'Nothing arrived.')]);
    });

    testWidgets('backing out of the reason refuses nothing', (tester) async {
      _desktop(tester);
      final api = _FakeAdminApi();
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.admin}),
          payments: [_sentToLizmo()], api: api));
      await openPayments(tester);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.rejected, isEmpty);
    });
  });

  group("a landlord's statements", () {
    PlatformInvoiceLine line({
      String id = 'l1',
      String property = 'Sunrise Apartments',
      int beds = 9,
      int units = 1,
      num amount = 600,
      String? invoiceNumber,
    }) => PlatformInvoiceLine(
          id: id,
          propertyId: 'p-$id',
          propertyName: property,
          occupiedBeds: beds,
          occupiedUnits: units,
          bedRate: 50,
          unitRate: 150,
          amountDue: amount,
          invoiceNumber: invoiceNumber,
        );

    PlatformStatementResponse statement({
      String status = 'UNPAID',
      bool overdue = false,
      List<PlatformInvoiceLine>? lines,
    }) => PlatformStatementResponse(
          id: 's1',
          label: 'September 2026',
          amountDue: 750,
          amountPaid: status == 'PAID' ? 750 : 0,
          outstanding: status == 'PAID' ? 0 : 750,
          status: PlatformStatementResponseStatusEnum.fromJson(status),
          overdue: overdue,
          locked: false,
          lines: lines ??
              [
                line(),
                line(
                  id: 'l2',
                  property: 'Seaview Lodge',
                  beds: 0,
                  units: 1,
                  amount: 150,
                ),
              ],
          payments: const [],
        );

    Future<void> openLandlord(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elena Bautista'));
      await tester.pumpAndSettle();
    }

    Widget page({
      String status = 'UNPAID',
      bool overdue = false,
      List<PlatformStatementResponse>? statements,
    }) => _app(
      _signedIn({LizmoProfile.admin}),
      landlords: [_landlord()],
      landlord: LandlordDetail(landlord: _landlord(), properties: [_property()]),
      statements: statements ?? [statement(status: status, overdue: overdue)],
    );

    /// One row a month, itemised: an admin chasing a landlord can see which
    /// buildings the figure is made of.
    testWidgets('a landlord page lists the month and what it covers',
        (tester) async {
      _desktop(tester);
      await tester.pumpWidget(page(overdue: true));
      await openLandlord(tester);

      expect(find.text('Statements'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('₱750'), findsOneWidget);
      // The property list above names Sunrise too, so the line itself is what
      // this checks.
      expect(find.text('9 beds · 1 units · ₱600'), findsOneWidget);
      expect(find.text('Seaview Lodge'), findsOneWidget);
      expect(find.text('0 beds · 1 units · ₱150'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    /// Paid, each line names the invoice the landlord can file.
    testWidgets('a paid statement shows each invoice number', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(page(statements: [
        statement(status: 'PAID', lines: [
          line(invoiceNumber: 'LZM-2026-09-0007'),
        ]),
      ]));
      await openLandlord(tester);

      expect(find.text('9 beds · 1 units · ₱600 · LZM-2026-09-0007'),
          findsOneWidget);
      expect(find.widgetWithText(StatusChip, 'Paid'), findsOneWidget);
    });

    testWidgets('no statements says how they come about', (tester) async {
      _desktop(tester);
      await tester.pumpWidget(_app(
        _signedIn({LizmoProfile.admin}),
        landlords: [_landlord()],
        landlord: LandlordDetail(landlord: _landlord(), properties: [_property()]),
      ));
      await openLandlord(tester);

      expect(find.textContaining('bills a landlord on the 1st'), findsOneWidget);
    });
  });
}
