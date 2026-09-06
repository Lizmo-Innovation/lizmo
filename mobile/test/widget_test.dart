import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/auth/active_role.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo/router.dart';
import 'package:lizmo/screens/forgot_password_screen.dart';
import 'package:lizmo/screens/login_screen.dart';
import 'package:lizmo/screens/register_screen.dart';
import 'package:lizmo/screens/create_property_screen.dart';
import 'package:lizmo/screens/create_unit_screen.dart';
import 'package:lizmo/screens/property_detail_screen.dart';
import 'package:lizmo/screens/find_property_screen.dart';
import 'package:lizmo/screens/scan_code_screen.dart';
import 'package:lizmo/screens/property_share_screen.dart';
import 'package:lizmo/screens/landlord_home_screen.dart';
import 'package:lizmo/screens/property_list_screen.dart';
import 'package:lizmo/screens/splash_screen.dart';
import 'package:lizmo/screens/tenant_home_screen.dart';
import 'package:lizmo/screens/my_place_screen.dart';
import 'package:lizmo/screens/tenant_detail_screen.dart';
import 'package:lizmo/widgets/notification_bell.dart';
import 'package:lizmo/screens/tenants_screen.dart';
import 'package:lizmo/screens/unit_detail_screen.dart';
import 'package:lizmo/screens/unit_utilities_screen.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/tenant/tenant_providers.dart';
import 'package:lizmo/notifications/notification_providers.dart';

/// Serves a fixed reachability, and becomes reachable when retried.
class _FakeHealth extends BackendHealth {
  _FakeHealth(this._initial);

  final BackendReachability _initial;
  int checks = 0;

  @override
  BackendReachability build() => _initial;

  @override
  Future<void> check() async {
    checks++;
    state = BackendReachability.reachable;
  }
}

/// Drives routing directly, without touching secure storage or the network.
class _FakeAuth extends AuthController {
  _FakeAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// Stands in for the sign-up half of the session controller.
///
/// The screens are the subject here; the calls behind them are covered against
/// a real API in lizmo_core's live tests.
class _SigningUpAuth extends AuthController {
  _SigningUpAuth({this.resendAfterSeconds = 60, this.failCompletionWith});

  final int resendAfterSeconds;
  final ApiFailure? failCompletionWith;

  String? startedWith;
  bool completed = false;

  @override
  AuthState build() => const AuthSignedOut();

  @override
  Future<int> startRegistration(String email) async {
    startedWith = email;
    return resendAfterSeconds;
  }

  @override
  Future<void> completeRegistration({
    required String email,
    required String code,
    required String name,
    required String password,
  }) async {
    if (failCompletionWith != null) throw failCompletionWith!;
    completed = true;
    state = _signedIn({LizmoProfile.tenant});
  }
}

/// Stands in for the password-reset half of the session controller.
class _ResettingAuth extends AuthController {
  _ResettingAuth({this.resendAfterSeconds = 60, this.failCompletionWith});

  final int resendAfterSeconds;
  final ApiFailure? failCompletionWith;

  String? startedWith;
  String? usedCode;
  String? chosePassword;

  @override
  AuthState build() => const AuthSignedOut();

  @override
  Future<int> startPasswordReset(String email) async {
    startedWith = email;
    return resendAfterSeconds;
  }

  @override
  Future<void> completePasswordReset({
    required String email,
    required String code,
    required String password,
  }) async {
    if (failCompletionWith != null) throw failCompletionWith!;
    usedCode = code;
    chosePassword = password;
    state = _signedIn({LizmoProfile.tenant});
  }
}

/// The reset screen on its own, without going through login first.
Widget _resetApp({AuthController? auth}) => ProviderScope(
      overrides: [
        authControllerProvider
            .overrideWith(() => auth ?? _FakeAuth(const AuthSignedOut())),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      ],
      child: const MaterialApp(home: ForgotPasswordScreen()),
    );

/// Address step done, leaving the code and password step on screen.
Future<void> _reachResetStep(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const ValueKey('reset-email')), 'ana@example.com');
  await tester.tap(find.text('Send me a code'));
  await tester.pumpAndSettle();
}

/// The sign-up screen on its own, without going through login first.
Widget _signUpApp({AuthController? auth}) => ProviderScope(
      overrides: [
        authControllerProvider
            .overrideWith(() => auth ?? _FakeAuth(const AuthSignedOut())),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      ],
      child: const MaterialApp(home: RegisterScreen()),
    );

/// Address, then code, leaving the name and password step on screen.
Future<void> _reachDetails(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), 'ana@example.com');
  await tester.tap(find.text('Send me a code'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField), '483920');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

/// The tick or the empty circle beside one password rule.
Icon _ruleIcon(WidgetTester tester, String label) => tester.widget<Icon>(
      find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
        matching: find.byType(Icon),
      ),
    );

Widget _app(AuthState initial) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuth(initial)),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        // Routing tests care where you land, not what loads there.
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        // A tenant screen reads this on build. Left to the real provider it
        // would reach for the network from every routing test.
        myTenantProfileProvider
            .overrideWith((ref) async => TenantProfileResponse(readyForALease: true)),
        myTenantDocumentsProvider
            .overrideWith((ref) async => const <TenantDocumentResponse>[]),
        myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
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


/// Records created properties so a test can assert the list reflects them,
/// standing in for the API without touching the network.
class _FakePropertiesApi extends PropertiesApi {
  _FakePropertiesApi(this.store);

  final List<PropertyResponse> store;
  PropertyRequest? lastRequest;

  @override
  Future<PropertyResponse?> createProperty(
    PropertyRequest propertyRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastRequest = propertyRequest;
    final created = PropertyResponse(
      id: 'new-${store.length}',
      name: propertyRequest.name,
      address: propertyRequest.address,
      type: PropertyResponseTypeEnum.fromJson(propertyRequest.type.toJson()),
      usage: PropertyResponseUsageEnum.fromJson(propertyRequest.usage.toJson()),
      unitCount: 0,
    );
    store.add(created);
    return created;
  }
}


/// Serves one property and records updates, so the edit flow can be driven
/// without the network.
class _EditablePropertiesApi extends PropertiesApi {
  _EditablePropertiesApi(this.current);

  PropertyResponse current;
  PropertyRequest? lastUpdate;

  @override
  Future<PropertyResponse?> getProperty(String id, {Future<void>? abortTrigger}) async =>
      current;

  @override
  Future<PropertyResponse?> updateProperty(
    String id,
    PropertyRequest propertyRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastUpdate = propertyRequest;
    current = PropertyResponse(
      id: id,
      name: propertyRequest.name,
      address: propertyRequest.address,
      type: PropertyResponseTypeEnum.fromJson(propertyRequest.type.toJson()),
      usage: PropertyResponseUsageEnum.fromJson(propertyRequest.usage.toJson()),
      unitCount: current.unitCount,
    );
    return current;
  }

  String? deletedId;

  @override
  Future<void> deleteProperty(String id, {Future<void>? abortTrigger}) async {
    deletedId = id;
  }
}


/// Serves one unit and records updates, for driving the unit edit form.
class _EditableUnitsApi extends UnitsApi {
  _EditableUnitsApi(this.current);

  UnitResponse current;
  UnitRequest? lastUpdate;

  @override
  Future<UnitResponse?> getUnit(String id, {Future<void>? abortTrigger}) async => current;

  @override
  Future<UnitResponse?> updateUnit(
    String id,
    UnitRequest unitRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastUpdate = unitRequest;
    return current;
  }

  String? deletedId;

  @override
  Future<void> deleteUnit(String id, {Future<void>? abortTrigger}) async {
    deletedId = id;
  }
}


/// Serves one unit's beds and records what was added or removed.
class _FakeBedsApi extends UnitsApi {
  _FakeBedsApi(this.unit, this.beds);

  final UnitResponse unit;
  final List<BedResponse> beds;

  BedRequest? lastCreated;
  String? deletedId;
  Object? createFailure;

  @override
  Future<UnitResponse?> getUnit(String id, {Future<void>? abortTrigger}) async => unit;

  @override
  Future<List<BedResponse>?> listBeds(String id, {Future<void>? abortTrigger}) async =>
      List.of(beds);

  @override
  Future<BedResponse?> createBed(
    String id,
    BedRequest bedRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastCreated = bedRequest;
    if (createFailure != null) throw createFailure!;
    final created = BedResponse(
      id: 'b${beds.length + 1}',
      unitId: id,
      bedLabel: bedRequest.bedLabel,
      status: BedResponseStatusEnum.VACANT,
    );
    beds.add(created);
    return created;
  }

  @override
  Future<void> deleteBed(String id, {Future<void>? abortTrigger}) async {
    deletedId = id;
    beds.removeWhere((b) => b.id == id);
  }

  BedRequest? lastRename;
  Object? renameFailure;

  MaintenanceRequest? lastMaintenance;
  MaintenanceRequest? lastUnitMaintenance;

  List<UtilityResponse> utilities = [
    UtilityResponse(kind: UtilityResponseKindEnum.WIFI, enabled: false),
    UtilityResponse(kind: UtilityResponseKindEnum.ELECTRICITY, enabled: false),
    UtilityResponse(kind: UtilityResponseKindEnum.WATER, enabled: false),
  ];

  UtilitiesResponseBillingEnum billing = UtilitiesResponseBillingEnum.COMBINED;

  UtilitiesRequest? lastUtilities;

  @override
  Future<UtilitiesResponse?> listUtilities(String id,
          {Future<void>? abortTrigger}) async =>
      UtilitiesResponse(billing: billing, utilities: List.of(utilities));

  @override
  Future<UtilitiesResponse?> setUtilities(
    String id,
    UtilitiesRequest utilitiesRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastUtilities = utilitiesRequest;
    return UtilitiesResponse(billing: billing, utilities: List.of(utilities));
  }
  UnitResponse? unitOverride;

  @override
  Future<UnitResponse?> setUnitMaintenance(
    String id,
    MaintenanceRequest maintenanceRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastUnitMaintenance = maintenanceRequest;
    return unit;
  }

  @override
  Future<BedResponse?> setBedMaintenance(
    String id,
    MaintenanceRequest maintenanceRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastMaintenance = maintenanceRequest;
    final index = beds.indexWhere((b) => b.id == id);
    final updated = BedResponse(
      id: id,
      unitId: beds[index].unitId,
      bedLabel: beds[index].bedLabel,
      status: maintenanceRequest.underMaintenance
          ? BedResponseStatusEnum.MAINTENANCE
          : BedResponseStatusEnum.VACANT,
    );
    beds[index] = updated;
    return updated;
  }

  @override
  Future<BedResponse?> updateBed(
    String id,
    BedRequest bedRequest, {
    Future<void>? abortTrigger,
  }) async {
    lastRename = bedRequest;
    if (renameFailure != null) throw renameFailure!;
    final index = beds.indexWhere((b) => b.id == id);
    final renamed = BedResponse(
      id: id,
      unitId: beds[index].unitId,
      bedLabel: bedRequest.bedLabel,
      status: beds[index].status,
    );
    beds[index] = renamed;
    return renamed;
  }
}


/// Opens the Properties tab.
///
/// A landlord now lands on Today, so every test that starts by tapping a
/// property has to get to the list first. Keyed rather than found by label,
/// because "Properties" is also a stat on the home screen.
Future<void> _openProperties(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('tab-properties'));
  if (tab.evaluate().isEmpty) return;
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  group('routing follows auth state', () {
    testWidgets('signed out lands on login', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(PropertyListScreen), findsNothing);
    });

    testWidgets('unknown holds on the splash, never app content', (tester) async {
      await tester.pumpWidget(_app(const AuthUnknown()));
      await tester.pump();

      // Showing content before tokens are checked would flash the app at
      // someone who is not signed in.
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(PropertyListScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a tenant lands on their own screen', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.tenant})));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(TenantHomeScreen), findsOneWidget);
      expect(find.byType(LandlordHomeScreen), findsNothing);
    });

    testWidgets('a landlord lands on Today, not the property list',
        (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();

      // Properties moved to a tab; the section's front door is the dashboard.
      expect(find.byType(LandlordHomeScreen), findsOneWidget);
      expect(find.byType(PropertyListScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsNothing);
    });
  });

  group('route guards', () {
    testWidgets('a tenant cannot reach the landlord home by URL', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();
      await _openProperties(tester);

      // Navigate straight at the landlord route, as a typed URL or stale deep
      // link would. It exposes another landlord's portfolio, so a tenant must
      // not reach it.
      container.read(routerProvider).go(Routes.landlord);
      await tester.pumpAndSettle();

      expect(find.byType(PropertyListScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('signing out from any screen returns to login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
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

      expect(find.byType(LandlordHomeScreen), findsOneWidget);
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
      expect(find.byType(LandlordHomeScreen), findsNothing);

      await tester.tap(find.text('Landlord'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordHomeScreen), findsOneWidget);
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

    testWidgets('finishing moves the user off the form', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(const AuthSignedOut())),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();

      container.read(routerProvider).go(Routes.register);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // Registering signs the user straight in. Without /register in the
      // move-along set they stayed on the form they had just submitted.
      container.read(authControllerProvider.notifier).state =
          _signedIn({LizmoProfile.tenant});
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('a landlord signing in from here lands on Today', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(const AuthSignedOut())),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go(Routes.register);
      await tester.pumpAndSettle();

      container.read(authControllerProvider.notifier).state =
          _signedIn({LizmoProfile.tenant, LizmoProfile.landlord});
      await tester.pumpAndSettle();

      expect(find.byType(LandlordHomeScreen), findsOneWidget);
    });

    testWidgets('asks for an address and nothing else, first', (tester) async {
      await tester.pumpWidget(_signUpApp());
      await tester.pumpAndSettle();

      // Nothing is stored until the last step, so there is no reason to ask
      // for a name or a password before the address is proved.
      expect(find.text('Send me a code'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Full name'), findsNothing);
      expect(find.text('Password'), findsNothing);
    });

    testWidgets('will not send a code to something that is not an address',
        (tester) async {
      await tester.pumpWidget(_signUpApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'ana');
      await tester.tap(find.text('Send me a code'));
      await tester.pump();

      expect(find.text('That does not look like an email address'), findsOneWidget);
    });

    testWidgets('a sent code moves on, and says where it went', (tester) async {
      final auth = _SigningUpAuth();
      await tester.pumpWidget(_signUpApp(auth: auth));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'ana@example.com');
      await tester.tap(find.text('Send me a code'));
      await tester.pumpAndSettle();

      expect(auth.startedWith, 'ana@example.com');
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('ana@example.com'), findsOneWidget);
    });

    testWidgets("the resend button waits out the server's cooldown",
        (tester) async {
      final auth = _SigningUpAuth(resendAfterSeconds: 3);
      await tester.pumpWidget(_signUpApp(auth: auth));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'ana@example.com');
      await tester.tap(find.text('Send me a code'));
      await tester.pump();

      // Every tap is an email somebody has to receive, so the button is
      // disabled while it counts rather than tapped and refused.
      expect(find.text('Send another in 3s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Send another in 2s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Send another code'), findsOneWidget);
    });

    testWidgets('a partial code is refused before the round trip',
        (tester) async {
      await tester.pumpWidget(_signUpApp(auth: _SigningUpAuth()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'ana@example.com');
      await tester.tap(find.text('Send me a code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the six digits'), findsOneWidget);
    });

    testWidgets('the password rules tick off as they are met', (tester) async {
      await tester.pumpWidget(_signUpApp(auth: _SigningUpAuth()));
      await tester.pumpAndSettle();
      await _reachDetails(tester);

      expect(_ruleIcon(tester, 'A number').icon, Icons.circle_outlined);

      await tester.enterText(find.byType(TextFormField).at(1), 'Sunrise2Bed!');
      await tester.pump();

      // Shown as they are met rather than after a refusal: somebody choosing a
      // password can see what is wanted while they type.
      expect(_ruleIcon(tester, 'A number').icon, Icons.check_circle);
      expect(_ruleIcon(tester, 'A symbol like ! or @').icon, Icons.check_circle);
    });

    testWidgets('a weak password never reaches the server', (tester) async {
      final auth = _SigningUpAuth();
      await tester.pumpWidget(_signUpApp(auth: auth));
      await tester.pumpAndSettle();
      await _reachDetails(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Reyes');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(auth.completed, isFalse);
    });

    testWidgets('a rejected code sends you back to the code step',
        (tester) async {
      final auth = _SigningUpAuth(
        failCompletionWith: const ApiFailure(
          code: 'OTP_INCORRECT',
          message: 'That code is not right. 4 tries left.',
        ),
      );
      await tester.pumpWidget(_signUpApp(auth: auth));
      await tester.pumpAndSettle();
      await _reachDetails(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Reyes');
      await tester.enterText(find.byType(TextFormField).at(1), 'Sunrise2Bed!');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      // The code is only ever checked by the call that finishes signing up, so
      // the failure arrives a screen late. It belongs to the code screen.
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('4 tries left'), findsOneWidget);
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

  _tenantProfileTests();
  _propertyShareTests();
  _findingAPlaceTests();
  _scanningTests();
  _landlordRequestTests();
  _tenantLeaseTests();

  group('property list states', () {
    Widget appWith(Override propertiesOverride) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesOverride,
          ],
          child: const LizmoApp(),
        );

    PropertyResponse property(String name, int units) => PropertyResponse(
          id: name,
          name: name,
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: units,
        );

    testWidgets('shows the properties and their unit counts', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async => [
              property('Sunrise Apartments', 2),
              property('Sunset Residences', 1),
            ]),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.text('Sunrise Apartments'), findsOneWidget);
      expect(find.text('Sunset Residences'), findsOneWidget);
      // Singular and plural, because "1 units" reads as a bug to a user.
      expect(find.text('2 units'), findsOneWidget);
      expect(find.text('1 unit'), findsOneWidget);
    });

    testWidgets('header totals are derived from the loaded rows', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async => [
              property('Sunrise Apartments', 2),
              property('Sunset Residences', 3),
            ]),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      // Two properties, five units — counts cannot disagree with the list.
      expect(find.text('2'), findsWidgets);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('an empty portfolio explains what to do', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.text('No properties yet'), findsOneWidget);
      // Never a bare spinner or blank screen.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a network failure is distinguished from a rejection', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async =>
            throw const ApiFailure(code: 'NETWORK_UNAVAILABLE', message: 'no signal')),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      // A landlord with no signal and one locked for an unpaid invoice need
      // different messages; ApiFailure.isNetwork is what separates them.
      expect(find.text("Can't reach Lizmo"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a rejection shows the backend message', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async => throw const ApiFailure(
              code: 'ACCOUNT_LOCKED_UNPAID_INVOICE',
              message: 'Your Lizmo invoice is unpaid.',
            )),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Your Lizmo invoice is unpaid.'), findsOneWidget);
    });
  });

  group('signing out', () {
    testWidgets('a tenant can sign out from the account sheet', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.tenant})));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      expect(find.byType(TenantHomeScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();

      // The sheet says who is signed in, so a shared phone does not sign the
      // wrong person out.
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('a landlord can reach the account sheet too', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      expect(find.byType(PropertyListScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('the sheet names which roles the account holds', (tester) async {
      await tester.pumpWidget(
        _app(_signedIn({LizmoProfile.tenant, LizmoProfile.landlord})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Tenant · Landlord'), findsOneWidget);
    });

    testWidgets('signing out lands on login', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();
      await _openProperties(tester);

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // The sheet closes and the router reacts to auth state — no screen
      // navigates to login itself.
      expect(find.text('Sign out'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TenantHomeScreen), findsNothing);
    });
  });

  group('creating a property', () {
    testWidgets('the add button opens the form', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePropertyScreen), findsOneWidget);
      expect(find.text('Add a property'), findsOneWidget);
    });

    testWidgets('empty fields are caught before calling the API', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save property'));

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save property'));
      await tester.pump();

      expect(find.text('Give the property a name'), findsOneWidget);
      expect(find.text('Add an address'), findsOneWidget);
    });

    testWidgets('type defaults to boarding house and can be changed', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      // All four are visible rather than hidden behind a dropdown, so the
      // default is a visible choice rather than an unnoticed one.
      expect(find.textContaining('Boarding House'), findsOneWidget);
      expect(find.text('Apartment'), findsOneWidget);
      expect(find.text('Condo'), findsOneWidget);
      expect(find.text('Single House'), findsOneWidget);

      await tester.tap(find.text('Condo'));
      await tester.pump();
    });

    testWidgets('the back arrow returns to the property list', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      // Nested under /landlord, so back goes to the list rather than out of
      // the app.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(CreatePropertyScreen), findsNothing);
    });

    testWidgets('a tenant cannot reach the form by URL', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();
      await _openProperties(tester);

      // The guard matched exact paths before this, so every sub-route under
      // /landlord was reachable by anyone signed in.
      container.read(routerProvider).go(Routes.propertyNew);
      await tester.pumpAndSettle();

      expect(find.byType(CreatePropertyScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });
  });

  group('LZ-030 acceptance', () {
    testWidgets('name, address and type reach the API, and the property '
        'then appears in the list', (tester) async {
      final store = <PropertyResponse>[];
      final api = _FakePropertiesApi(store);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesApiProvider.overrideWithValue(api),
          // Reads the same store the fake writes to, so invalidating after a
          // save is what makes the new row appear.
          propertiesProvider.overrideWith((ref) async => List.of(store)),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.text('No properties yet'), findsOneWidget);

      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Mabuhay Bedspace');
      await tester.enterText(find.byType(TextFormField).at(1), '7 Katipunan Ave');
      await tester.tap(find.text('Condo'));
      await tester.pump();

      await tester.ensureVisible(find.text('Save property'));

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save property'));
      await tester.pumpAndSettle();

      // All three fields captured, and the type is the one chosen rather than
      // the default.
      expect(api.lastRequest!.name, 'Mabuhay Bedspace');
      expect(api.lastRequest!.address, '7 Katipunan Ave');
      expect(api.lastRequest!.type, PropertyRequestTypeEnum.CONDO);

      // Back on the list, with the new property visible — no manual refresh.
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(CreatePropertyScreen), findsNothing);
      expect(find.text('Mabuhay Bedspace'), findsOneWidget);
      expect(find.text('No properties yet'), findsNothing);
    });
  });

  group('LZ-031 units', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: 2,
        );

    UnitResponse unit({
      required String number,
      required UnitResponseRentalModeEnum mode,
      int capacity = 1,
      int bedCount = 0,
      num? rent,
      num? potentialMonthlyRent,
    }) =>
        UnitResponse(
          id: 'u-$number',
          propertyId: 'p1',
          unitNumber: number,
          rentalMode: mode,
          capacity: capacity,
          bedCount: bedCount,
          rent: rent,
          potentialMonthlyRent: potentialMonthlyRent,
          status: UnitResponseStatusEnum.VACANT,
        );

    Widget appWith(List<UnitResponse> units) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesProvider.overrideWith((ref) async => [property()]),
            unitsProvider('p1').overrideWith((ref) async => units),
          ],
          child: const LizmoApp(),
        );

    testWidgets('tapping a property opens its units', (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '2B', mode: UnitResponseRentalModeEnum.BEDSPACE,
            capacity: 4, bedCount: 4, rent: 2500),
      ]));
      await tester.pumpAndSettle();

      await _openProperties(tester);

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(find.text('Unit 2B'), findsOneWidget);
    });

    testWidgets('bedspace and whole units read differently', (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '2B', mode: UnitResponseRentalModeEnum.BEDSPACE,
            capacity: 4, bedCount: 2, rent: 2500, potentialMonthlyRent: 5000),
        unit(number: '1A', mode: UnitResponseRentalModeEnum.WHOLE_UNIT,
            rent: 7000, potentialMonthlyRent: 7000),
      ]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // The distinction the whole product turns on, visible at a glance.
      expect(find.textContaining('Bedspace'), findsOneWidget);
      expect(find.textContaining('Whole unit'), findsOneWidget);
      expect(find.text('per month, all beds'), findsOneWidget);
      expect(find.text('per month'), findsOneWidget);
      expect(find.text('2 beds'), findsOneWidget);

      // Both figures are monthly, so they are comparable: two beds at 2500
      // against a whole unit at 7000.
      expect(find.text('₱5000'), findsOneWidget);
      expect(find.text('₱7000'), findsOneWidget);
    });

    testWidgets('the header totals what the property brings in', (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '2B', mode: UnitResponseRentalModeEnum.BEDSPACE,
            capacity: 4, bedCount: 4, rent: 2500, potentialMonthlyRent: 10000),
        unit(number: '1A', mode: UnitResponseRentalModeEnum.WHOLE_UNIT,
            rent: 7000, potentialMonthlyRent: 7000),
      ]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.text('Per month'), findsOneWidget);
      expect(find.text('₱17000'), findsOneWidget);
    });

    testWidgets('a property with no rents set totals a dash, not zero',
        (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '2B', mode: UnitResponseRentalModeEnum.BEDSPACE,
            capacity: 4, bedCount: 4),
      ]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // Nothing is known about the price, which is not the same as free.
      expect(find.textContaining('₱0'), findsNothing);
    });

    testWidgets('a large total is not clipped', (tester) async {
      await tester.pumpWidget(appWith([
        for (var i = 0; i < 8; i++)
          unit(number: 'U$i', mode: UnitResponseRentalModeEnum.BEDSPACE,
              capacity: 6, bedCount: 6, rent: 2500, potentialMonthlyRent: 15000),
      ]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // ₱120000 is wider than the stat card, so the figure scales down rather
      // than losing a digit -- a landlord with a real portfolio hits this.
      expect(find.text('₱120000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a unit with no rent shows a dash, not zero', (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '1A', mode: UnitResponseRentalModeEnum.WHOLE_UNIT),
      ]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // Zero would claim the unit is free; not-set is a different statement.
      // Two dashes: the unit card, and the property total in the header, which
      // has nothing to add up either.
      expect(find.text('—'), findsNWidgets(2));
      expect(find.textContaining('₱0'), findsNothing);
    });

    testWidgets('a property with no units explains what to add', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.text('No units yet'), findsOneWidget);
    });

    testWidgets('the add-unit form asks the mode first and warns it is final',
        (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Add a unit'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateUnitScreen), findsOneWidget);
      expect(find.text('Bedspace'), findsOneWidget);
      expect(find.text('Whole unit'), findsOneWidget);
      // The API refuses to change it later; discovering that afterwards is worse.
      expect(find.text('This cannot be changed later.'), findsOneWidget);
    });

    testWidgets('capacity is asked for bedspaces and hidden for whole units',
        (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add a unit'));
      await tester.pumpAndSettle();

      expect(find.text('How many beds?'), findsOneWidget);
      expect(find.text('Default rent per bed (optional)'), findsOneWidget);

      await tester.tap(find.text('Whole unit'));
      await tester.pumpAndSettle();

      // A whole unit has one tenancy, so a bed count would be meaningless.
      expect(find.text('How many beds?'), findsNothing);
      expect(find.text('Rent (optional)'), findsOneWidget);
    });

    testWidgets('the new-property route is not swallowed by the id route',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();
      await _openProperties(tester);

      // /properties/new and /properties/:id both match the same shape; order
      // decides, and getting it wrong would open a property called "new".
      container.read(routerProvider).go(Routes.propertyNew);
      await tester.pumpAndSettle();

      expect(find.byType(CreatePropertyScreen), findsOneWidget);
      expect(find.byType(PropertyDetailScreen), findsNothing);
    });
  });

  group('editing a property', () {
    PropertyResponse existing() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St, Quezon City',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: 2,
        );

    Widget appWith(_EditablePropertiesApi api) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesApiProvider.overrideWithValue(api),
            propertiesProvider.overrideWith((ref) async => [api.current]),
            unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
          ],
          child: const LizmoApp(),
        );

    testWidgets('the form opens prefilled with the current values', (tester) async {
      final api = _EditablePropertiesApi(existing());
      await tester.pumpWidget(appWith(api));
      await tester.pumpAndSettle();

      await _openProperties(tester);

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit property'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePropertyScreen), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);

      // Read the field values rather than matching text: the list beneath is
      // still in the tree, and the name field's own hint is the same string.
      final fields = tester
          .widgetList<EditableText>(find.descendant(
            of: find.byType(CreatePropertyScreen),
            matching: find.byType(EditableText),
          ))
          .toList();

      // Prefilled, so a landlord fixing a typo does not retype everything.
      expect(fields[0].controller.text, 'Sunrise Apartments');
      expect(fields[1].controller.text, '12 Mabini St, Quezon City');
    });

    testWidgets('changes are sent and reflected in the list', (tester) async {
      final api = _EditablePropertiesApi(existing());
      await tester.pumpWidget(appWith(api));
      await tester.pumpAndSettle();

      await _openProperties(tester);

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Sunrise Residences');
      await tester.tap(find.text('Apartment'));
      await tester.pump();
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(api.lastUpdate!.name, 'Sunrise Residences');
      expect(api.lastUpdate!.type, PropertyRequestTypeEnum.APARTMENT);
      // The address was untouched, so it must survive unchanged rather than
      // being blanked by a partial update.
      expect(api.lastUpdate!.address, '12 Mabini St, Quezon City');
    });

    testWidgets('an empty name is refused before calling the API', (tester) async {
      final api = _EditablePropertiesApi(existing());
      await tester.pumpWidget(appWith(api));
      await tester.pumpAndSettle();

      await _openProperties(tester);

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.text('Give the property a name'), findsOneWidget);
      expect(api.lastUpdate, isNull);
    });
  });

  group('editing a unit', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: 1,
        );

    UnitResponse bedspace({int capacity = 4, int bedCount = 4, num? rent = 2500}) =>
        UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          floor: '2',
          rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
          capacity: capacity,
          bedCount: bedCount,
          rent: rent,
          status: UnitResponseStatusEnum.VACANT,
        );

    Widget appWith(_EditableUnitsApi api) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            unitsApiProvider.overrideWithValue(api),
            propertiesProvider.overrideWith((ref) async => [property()]),
            unitsProvider('p1').overrideWith((ref) async => [api.current]),
          ],
          child: const LizmoApp(),
        );

    Future<void> openEditForm(WidgetTester tester, _EditableUnitsApi api) async {
      await tester.pumpWidget(appWith(api));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();
      // The unit card shows the unit; its fields are behind the pencil, as on
      // the property screen.
      await tester.tap(find.byTooltip('Edit unit'));
      await tester.pumpAndSettle();
    }

    testWidgets('the edit pencil opens the unit prefilled', (tester) async {
      final api = _EditableUnitsApi(bedspace());
      await openEditForm(tester, api);

      expect(find.text('Edit unit'), findsOneWidget);

      final fields = tester
          .widgetList<EditableText>(find.descendant(
            of: find.byType(CreateUnitScreen),
            matching: find.byType(EditableText),
          ))
          .toList();

      // Unit number, floor, capacity, rent — in the order they appear.
      expect(fields[0].controller.text, '2B');
      expect(fields[1].controller.text, '2');
      expect(fields[2].controller.text, '4');
      expect(fields[3].controller.text, '2500');
    });

    testWidgets('rental mode is locked while editing', (tester) async {
      final api = _EditableUnitsApi(bedspace());
      await openEditForm(tester, api);

      // Shown so the landlord can see what it is, but not offered as a choice:
      // the API refuses to change it.
      expect(find.text('This cannot be changed. Create a new unit instead.'),
          findsOneWidget);

      await tester.tap(find.text('Whole unit'));
      await tester.pump();

      // Still a bedspace, so the bed count question remains.
      expect(find.text('How many beds?'), findsOneWidget);
    });

    testWidgets('lowering the bed count warns what it will remove', (tester) async {
      final api = _EditableUnitsApi(bedspace(capacity: 4, bedCount: 4));
      await openEditForm(tester, api);

      await tester.enterText(find.byType(TextFormField).at(2), '2');
      await tester.pump();

      // Beds follow the count now, so lowering it deletes them. Said before
      // saving rather than discovered afterwards.
      expect(find.text('Saving will remove 2 beds.'), findsOneWidget);

      // The warning makes the form taller, so the button can sit below the fold.
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      // No longer refused -- this is how a landlord removes beds.
      expect(api.lastUpdate!.capacity, 2);
    });

    testWidgets('raising the bed count warns about nothing', (tester) async {
      final api = _EditableUnitsApi(bedspace(capacity: 4, bedCount: 4));
      await openEditForm(tester, api);

      await tester.enterText(find.byType(TextFormField).at(2), '6');
      await tester.pump();

      expect(find.textContaining('will remove'), findsNothing);

      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(api.lastUpdate!.capacity, 6);
    });

    testWidgets('changes are sent, with the mode unchanged', (tester) async {
      final api = _EditableUnitsApi(bedspace());
      await openEditForm(tester, api);

      await tester.enterText(find.byType(TextFormField).at(3), '2750');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(api.lastUpdate!.rent, 2750);
      expect(api.lastUpdate!.unitNumber, '2B');
      // Sent back as it was, since the API compares it and rejects a change.
      expect(api.lastUpdate!.rentalMode, UnitRequestRentalModeEnum.BEDSPACE);
    });
  });

  group('deleting a unit', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: 1,
        );

    UnitResponse unit({required int bedCount, required int capacity}) => UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          rentalMode: capacity > 1
              ? UnitResponseRentalModeEnum.BEDSPACE
              : UnitResponseRentalModeEnum.WHOLE_UNIT,
          capacity: capacity,
          bedCount: bedCount,
          rent: 2500,
          status: UnitResponseStatusEnum.VACANT,
        );

    Future<_EditableUnitsApi> openEdit(WidgetTester tester, UnitResponse u) async {
      final api = _EditableUnitsApi(u);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          unitsApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => [u]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit unit'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('an empty unit can be deleted, after confirming', (tester) async {
      final api = await openEdit(tester, unit(bedCount: 0, capacity: 1));

      await tester.ensureVisible(find.text('Delete this unit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this unit'));
      await tester.pumpAndSettle();

      // Named in the dialog, so a landlord with several screens open does not
      // have to trust they tapped the right one.
      expect(find.text('Delete unit 2B?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(api.deletedId, 'u1');
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      final api = await openEdit(tester, unit(bedCount: 0, capacity: 1));

      await tester.ensureVisible(find.text('Delete this unit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this unit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.deletedId, isNull);
      // Still on the form, not popped back.
      expect(find.byType(CreateUnitScreen), findsOneWidget);
    });

    testWidgets('a unit with beds explains why it cannot be deleted', (tester) async {
      final api = await openEdit(tester, unit(bedCount: 4, capacity: 4));

      await tester.ensureVisible(find.textContaining('cannot be deleted'));
      await tester.pumpAndSettle();

      // The API refuses this, so no button is offered that cannot work.
      expect(find.textContaining('This unit has 4 beds'), findsOneWidget);
      expect(find.text('Delete this unit'), findsNothing);
      expect(api.deletedId, isNull);
    });

    testWidgets('creating a unit offers no delete', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add a unit'));
      await tester.pumpAndSettle();

      // There is nothing to delete yet.
      expect(find.text('Delete this unit'), findsNothing);
    });
  });

  group('residential or commercial', () {
    Widget appWith(_FakePropertiesApi api, List<PropertyResponse> store) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesApiProvider.overrideWithValue(api),
            propertiesProvider.overrideWith((ref) async => store),
          ],
          child: const LizmoApp(),
        );

    Future<_FakePropertiesApi> openForm(WidgetTester tester) async {
      final store = <PropertyResponse>[];
      final api = _FakePropertiesApi(store);
      await tester.pumpWidget(appWith(api, store));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('the form asks usage first and starts residential', (tester) async {
      await openForm(tester);

      expect(find.text('Used for'), findsOneWidget);
      expect(find.text('Residential'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);

      // Residential types on offer, commercial ones not.
      expect(find.textContaining('Boarding House'), findsOneWidget);
      expect(find.text('Office'), findsNothing);
      expect(find.text('Warehouse'), findsNothing);
    });

    testWidgets('choosing commercial swaps the type list', (tester) async {
      await openForm(tester);

      await tester.tap(find.text('Commercial'));
      await tester.pumpAndSettle();

      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Retail Space'), findsOneWidget);
      expect(find.text('Warehouse'), findsOneWidget);
      expect(find.text('Stall'), findsOneWidget);

      // The residential types are gone, so an invalid pair cannot be assembled.
      expect(find.text('Boarding House'), findsNothing);
      expect(find.text('Condo'), findsNothing);
    });

    testWidgets('a commercial property saves a matching pair', (tester) async {
      final api = await openForm(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Mabini Arcade');
      await tester.enterText(find.byType(TextFormField).at(1), '14 Mabini St');

      await tester.tap(find.text('Commercial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Warehouse'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save property'));
      await tester.pumpAndSettle();

      expect(api.lastRequest!.usage, PropertyRequestUsageEnum.COMMERCIAL);
      expect(api.lastRequest!.type, PropertyRequestTypeEnum.WAREHOUSE);
    });

    testWidgets('switching usage drops a type the new usage forbids', (tester) async {
      final api = await openForm(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Mabini Arcade');
      await tester.enterText(find.byType(TextFormField).at(1), '14 Mabini St');

      // Pick a residential type, then convert. Carrying CONDO across would send
      // a pair the API refuses.
      await tester.tap(find.text('Condo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commercial'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save property'));
      await tester.pumpAndSettle();

      expect(api.lastRequest!.usage, PropertyRequestUsageEnum.COMMERCIAL);
      expect(api.lastRequest!.type, PropertyRequestTypeEnum.OFFICE);
    });

    testWidgets('the list marks commercial properties and leaves the rest alone',
        (tester) async {
      final store = [
        PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 2,
        ),
        PropertyResponse(
          id: 'p2',
          name: 'Mabini Arcade',
          address: '14 Mabini St',
          type: PropertyResponseTypeEnum.OFFICE,
          usage: PropertyResponseUsageEnum.COMMERCIAL,
          unitCount: 1,
        ),
      ];

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => store),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      // Kind and address share a line now.
      expect(find.textContaining('Commercial \u00b7 Office'), findsOneWidget);
      // Residential is the norm; labelling it on every card would be noise.
      expect(find.textContaining('Boarding House'), findsOneWidget);
      expect(find.textContaining('Residential'), findsNothing);
    });

    testWidgets('editing a commercial property opens on its usage', (tester) async {
      final api = _EditablePropertiesApi(PropertyResponse(
        id: 'p1',
        name: 'Mabini Arcade',
        address: '14 Mabini St',
        type: PropertyResponseTypeEnum.RETAIL_SPACE,
        usage: PropertyResponseUsageEnum.COMMERCIAL,
        unitCount: 0,
      ));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [api.current]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Mabini Arcade'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Commercial types on offer, not residential ones -- the form opened on
      // the property's own usage rather than the default.
      expect(find.text('Retail Space'), findsOneWidget);
      expect(find.text('Boarding House'), findsNothing);
    });
  });

  group('units in a commercial property', () {
    PropertyResponse commercial() => PropertyResponse(
          id: 'p1',
          name: 'Mabini Arcade',
          address: '14 Mabini St',
          type: PropertyResponseTypeEnum.RETAIL_SPACE,
          usage: PropertyResponseUsageEnum.COMMERCIAL,
          unitCount: 0,
        );

    PropertyResponse residential() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 0,
        );

    Future<void> openAddUnit(WidgetTester tester, PropertyResponse property) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property]),
          propertyProvider('p1').overrideWith((ref) async => property),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text(property.name!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add a unit'));
      await tester.pumpAndSettle();
    }

    testWidgets('the rental mode question is not asked', (tester) async {
      await openAddUnit(tester, commercial());

      // No choice offered -- a shop cannot be let by the bed.
      expect(find.text('Bedspace'), findsNothing);
      expect(find.text('Whole unit'), findsNothing);

      // The single possible answer is stated instead of asked.
      expect(find.text('The whole unit is rented to one tenant.'), findsOneWidget);

      // And the warning that the choice is permanent goes with the choice.
      expect(find.text('This cannot be changed later.'), findsNothing);
    });

    testWidgets('no bed count is asked either', (tester) async {
      await openAddUnit(tester, commercial());

      expect(find.text('How many beds?'), findsNothing);
    });

    testWidgets('the property screen hides the beds counter', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [commercial()]),
          unitsProvider('p1').overrideWith((ref) async => [
                UnitResponse(
                  id: 'u1',
                  propertyId: 'p1',
                  unitNumber: 'Stall 1',
                  rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
                  capacity: 1,
                  bedCount: 0,
                  rent: 8000,
                  status: UnitResponseStatusEnum.VACANT,
                ),
              ]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Mabini Arcade'));
      await tester.pumpAndSettle();

      // A bed count here is always zero, which reads as setup the landlord has
      // forgotten rather than something that cannot apply.
      expect(find.text('Rentable'), findsNothing);
      expect(find.text('Units'), findsWidgets);
    });

    testWidgets('a residential property keeps the beds counter', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [residential()]),
          unitsProvider('p1').overrideWith((ref) async => [
                UnitResponse(
                  id: 'u1',
                  propertyId: 'p1',
                  unitNumber: '2B',
                  rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
                  capacity: 4,
                  bedCount: 3,
                  rent: 2500,
                  status: UnitResponseStatusEnum.VACANT,
                ),
              ]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.text('Rentable'), findsOneWidget);
    });

    testWidgets('a residential property is still asked', (tester) async {
      await openAddUnit(tester, residential());

      expect(find.text('Bedspace'), findsOneWidget);
      expect(find.text('Whole unit'), findsOneWidget);
      expect(find.text('This cannot be changed later.'), findsOneWidget);
    });
  });

  group('the back arrow', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 1,
        );

    UnitResponse unit() => UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
          capacity: 2,
          bedCount: 2,
          rent: 2500,
          status: UnitResponseStatusEnum.VACANT,
        );

    /// Left of centre is the whole claim: "upper left" is a position, so the
    /// test checks the position rather than which slot it was passed to.
    void expectUpperLeft(WidgetTester tester, Finder backArrow) {
      final screen = tester.getSize(find.byType(MaterialApp)).width;
      final arrow = tester.getCenter(backArrow);
      expect(arrow.dx, lessThan(screen / 2));
    }

    testWidgets('sits upper left on the property screen, opposite edit',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => [unit()]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expectUpperLeft(tester, find.byTooltip('Back'));

      // It used to share a row with edit on the right; they now face each other.
      expect(
        tester.getCenter(find.byTooltip('Back')).dx,
        lessThan(tester.getCenter(find.byTooltip('Edit property')).dx),
      );
    });

    testWidgets('sits upper left on the beds screen', (tester) async {
      final api = _FakeBedsApi(unit(), [
        BedResponse(
          id: 'b1',
          unitId: 'u1',
          bedLabel: 'Bed 1',
          status: BedResponseStatusEnum.VACANT,
        ),
      ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          unitsApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => [unit()]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();

      expectUpperLeft(tester, find.byTooltip('Back'));
    });

    testWidgets('the form screens keep theirs upper left too', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      // These use an AppBar, which places it there already -- pinned so the two
      // patterns cannot drift apart again.
      expectUpperLeft(tester, find.byType(BackButton));
    });
  });

  group('beds in a bedspace unit', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 1,
        );

    UnitResponse unit({int capacity = 4, int bedCount = 4}) => UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
          capacity: capacity,
          bedCount: bedCount,
          rent: 2500,
          status: UnitResponseStatusEnum.VACANT,
        );

    BedResponse bed(String id, String label, BedResponseStatusEnum status,
            {num? rent}) =>
        BedResponse(
            id: id, unitId: 'u1', bedLabel: label, status: status, rent: rent);

    Future<_FakeBedsApi> openBeds(WidgetTester tester,
        {List<BedResponse>? beds}) async {
      final rows = beds ??
          [
            bed('b1', 'Bed 1', BedResponseStatusEnum.VACANT),
            bed('b2', 'Bed 2', BedResponseStatusEnum.VACANT),
          ];
      final u = unit(capacity: rows.length, bedCount: rows.length);
      final api = _FakeBedsApi(u, rows);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          unitsApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => [u]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      // One target now: the card opens the unit, and its beds are already on
      // the screen that opens.
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('the bed row on a unit card opens its beds', (tester) async {
      await openBeds(tester);

      expect(find.byType(UnitDetailScreen), findsOneWidget);
      expect(find.text('Bed 1'), findsOneWidget);
      expect(find.text('Bed 2'), findsOneWidget);
      // Tapping a unit shows it. It used to open the edit form, past a live
      // delete button.
      expect(find.byType(CreateUnitScreen), findsNothing);
    });

    testWidgets('beds cannot be added or removed here', (tester) async {
      await openBeds(tester);

      // How many beds a unit has is its bed count, set on the unit. A second
      // control here would let the two disagree.
      expect(find.text('+ Add a bed'), findsNothing);
      expect(find.byTooltip('Remove Bed 1'), findsNothing);
      expect(find.byTooltip('Remove Bed 2'), findsNothing);
    });

    testWidgets('editing is behind the pencil, not the whole screen',
        (tester) async {
      await openBeds(tester);

      await tester.tap(find.byTooltip('Edit unit'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateUnitScreen), findsOneWidget);
    });

    testWidgets('occupancy is shown per bed', (tester) async {
      await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.OCCUPIED),
        bed('b2', 'Bed 2', BedResponseStatusEnum.VACANT),
        bed('b3', 'Bed 3', BedResponseStatusEnum.MAINTENANCE),
      ]);

      expect(find.text('Occupied'), findsOneWidget);
      expect(find.text('Vacant'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
    });

    testWidgets('a bed can be renamed', (tester) async {
      final api = await openBeds(tester);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename bed'));
      await tester.pumpAndSettle();

      // Prefilled with the current name, so a small correction is a small edit.
      final field = tester.widget<EditableText>(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(EditableText),
      ));
      expect(field.controller.text, 'Bed 1');

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'Bed 1 upper bunk',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(api.lastRename!.bedLabel, 'Bed 1 upper bunk');
      expect(find.text('Bed 1 upper bunk'), findsOneWidget);
    });

    testWidgets('an empty name is refused before calling the API', (tester) async {
      final api = await openBeds(tester);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename bed'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        '   ',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Give the bed a name'), findsOneWidget);
      expect(api.lastRename, isNull);
    });

    testWidgets('cancelling renames nothing', (tester) async {
      final api = await openBeds(tester);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename bed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.lastRename, isNull);
      expect(find.text('Bed 1'), findsOneWidget);
    });

    testWidgets('a duplicate name is reported without leaving the list',
        (tester) async {
      final api = await openBeds(tester);
      api.renameFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        message: 'A bed with that label already exists in this unit.',
      );

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename bed'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'Bed 2',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('A bed with that label already exists in this unit.'),
          findsOneWidget);
      expect(find.byType(UnitDetailScreen), findsOneWidget);
    });

    testWidgets('an occupied bed can still be renamed', (tester) async {
      await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.OCCUPIED),
      ]);

      // The name describes the bed, not the tenancy, so renaming is offered
      // even here -- unlike taking it out of service.
      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();

      expect(find.text('Rename bed'), findsOneWidget);
      expect(find.text('Take out of service'), findsNothing);
      expect(
        find.textContaining('Occupied beds cannot be taken out of service'),
        findsOneWidget,
      );
    });

    testWidgets('a vacant bed can be taken out of service', (tester) async {
      final api = await openBeds(tester);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take out of service'));
      await tester.pumpAndSettle();

      expect(api.lastMaintenance!.underMaintenance, isTrue);
      expect(find.text('Maintenance'), findsOneWidget);
    });

    testWidgets('a bed out of service can be returned to it', (tester) async {
      final api = await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.MAINTENANCE),
        bed('b2', 'Bed 2', BedResponseStatusEnum.VACANT),
      ]);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();

      // The action reads as the opposite when the bed is already out.
      expect(find.text('Take out of service'), findsNothing);
      await tester.tap(find.text('Return to service'));
      await tester.pumpAndSettle();

      expect(api.lastMaintenance!.underMaintenance, isFalse);
    });

    testWidgets('a bed out of service does not count as rentable',
        (tester) async {
      await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.MAINTENANCE),
        bed('b2', 'Bed 2', BedResponseStatusEnum.VACANT),
        bed('b3', 'Bed 3', BedResponseStatusEnum.VACANT),
      ]);

      // Three beds exist; two can be let.
      expect(find.text('Rentable'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a bed on the unit rate says nothing about price', (tester) async {
      await openBeds(tester);

      // The unit's rate is in the header. Repeating it under every bed spent a
      // line per row to report that nothing was unusual.
      expect(find.text('Bed 1'), findsOneWidget);
      expect(find.text('Bed 2'), findsOneWidget);
      expect(find.textContaining('unit rate'), findsNothing);
    });

    testWidgets('a bed with its own price shows that instead', (tester) async {
      await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.VACANT, rent: 2000),
        bed('b2', 'Bed 2', BedResponseStatusEnum.VACANT),
      ]);

      // Only the exception is printed: a bed priced on its own. The other is
      // silent, so the one line that carries information stands out.
      expect(find.text('₱2000'), findsOneWidget);
      expect(find.textContaining('unit rate'), findsNothing);
    });

    testWidgets('a price can be set on one bed', (tester) async {
      final api = await openBeds(tester);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set price'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        '2000',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(api.lastRename!.rent, 2000);
      // The label rides along, or the PUT would blank it.
      expect(api.lastRename!.bedLabel, 'Bed 1');
    });

    testWidgets('clearing the price hands the bed back to the unit rate',
        (tester) async {
      final api = await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.VACANT, rent: 2000),
      ]);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set price'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(api.lastRename!.rent, isNull);
    });

    testWidgets('a price of zero is refused before calling the API',
        (tester) async {
      final api = await openBeds(tester);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set price'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        '0',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Zero would read as free, which is not what an unset price means.
      expect(find.text('Enter more than zero'), findsOneWidget);
      expect(api.lastRename, isNull);
    });

    testWidgets('renaming keeps the price', (tester) async {
      final api = await openBeds(tester, beds: [
        bed('b1', 'Bed 1', BedResponseStatusEnum.VACANT, rent: 2000),
      ]);

      await tester.tap(find.text('Bed 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename bed'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'Lower bunk',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // A PUT carries the whole bed, so the rent has to travel with the name.
      expect(api.lastRename!.bedLabel, 'Lower bunk');
      expect(api.lastRename!.rent, 2000);
    });

    testWidgets('a unit with no beds says where they come from', (tester) async {
      await openBeds(tester, beds: []);

      expect(find.text('No beds yet'), findsOneWidget);
    });
  });

  group('deleting a property', () {
    Future<_EditablePropertiesApi> openEdit(WidgetTester tester,
        {int unitCount = 0}) async {
      final api = _EditablePropertiesApi(PropertyResponse(
        id: 'p1',
        name: 'Sunrise Apartments',
        address: '12 Mabini St',
        type: PropertyResponseTypeEnum.BOARDING_HOUSE,
        usage: PropertyResponseUsageEnum.RESIDENTIAL,
        unitCount: unitCount,
      ));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [api.current]),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit property'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('an empty property can be deleted, after confirming',
        (tester) async {
      final api = await openEdit(tester);

      await tester.ensureVisible(find.text('Delete this property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this property'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sunrise Apartments?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(api.deletedId, 'p1');

      // Back on the list, not on the property's own screen -- that one is
      // about to stop existing.
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(PropertyDetailScreen), findsNothing);
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      final api = await openEdit(tester);

      await tester.ensureVisible(find.text('Delete this property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(api.deletedId, isNull);
      expect(find.byType(CreatePropertyScreen), findsOneWidget);
    });

    testWidgets('a property with units explains what to clear first',
        (tester) async {
      final api = await openEdit(tester, unitCount: 3);

      await tester.ensureVisible(find.textContaining('This property has 3 units'));
      await tester.pumpAndSettle();

      // The API refuses this, so no button is offered that cannot work.
      expect(find.text('Delete this property'), findsNothing);
      expect(api.deletedId, isNull);
    });

    testWidgets('creating a property offers no delete', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this property'), findsNothing);
    });
  });

  group('filtering units by floor', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 4,
        );

    UnitResponse whole(String number, String? floor, num rent) => UnitResponse(
          id: 'u-$number',
          propertyId: 'p1',
          unitNumber: number,
          floor: floor,
          rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
          capacity: 1,
          bedCount: 0,
          bedsUnderMaintenance: 0,
          rent: rent,
          potentialMonthlyRent: rent,
          status: UnitResponseStatusEnum.VACANT,
        );

    Future<void> open(WidgetTester tester, List<UnitResponse> units) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => units),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
    }

    testWidgets('one floor offers no filter', (tester) async {
      await open(tester, [whole('1A', '1', 7000), whole('1B', '1', 6000)]);

      // A control that cannot narrow anything is furniture.
      expect(find.text('All'), findsNothing);
      expect(find.text('Floor 1'), findsNothing);
    });

    testWidgets('several floors offer a chip each', (tester) async {
      await open(tester, [
        whole('1A', '1', 7000),
        whole('2A', '2', 8000),
        whole('10A', '10', 9000),
      ]);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Floor 1'), findsOneWidget);
      expect(find.text('Floor 2'), findsOneWidget);
      expect(find.text('Floor 10'), findsOneWidget);
    });

    testWidgets('floors sort numerically, so 10 follows 9', (tester) async {
      await open(tester, [
        whole('10A', '10', 9000),
        whole('2A', '2', 8000),
        whole('9A', '9', 7000),
      ]);

      final xs = {
        for (final f in ['Floor 2', 'Floor 9', 'Floor 10'])
          f: tester.getCenter(find.text(f)).dx,
      };

      // Plain string sorting would put "10" before "2".
      expect(xs['Floor 2']!, lessThan(xs['Floor 9']!));
      expect(xs['Floor 9']!, lessThan(xs['Floor 10']!));
    });

    testWidgets('choosing a floor narrows the list and the figures',
        (tester) async {
      await open(tester, [
        whole('1A', '1', 7000),
        whole('2A', '2', 8000),
        whole('2B', '2', 5000),
      ]);

      // Everything, before filtering.
      expect(find.text('₱20000'), findsOneWidget);

      await tester.tap(find.text('Floor 2'));
      await tester.pumpAndSettle();

      expect(find.text('Unit 2A'), findsOneWidget);
      expect(find.text('Unit 2B'), findsOneWidget);
      expect(find.text('Unit 1A'), findsNothing);

      // The figures describe the floor now, and the title says so, or the
      // header would be a property total sitting over one floor's list.
      expect(find.text('Floor 2'), findsWidgets);
      expect(find.text('₱13000'), findsOneWidget);
    });

    testWidgets('units with no floor get a bucket of their own', (tester) async {
      await open(tester, [
        whole('1A', '1', 7000),
        whole('X', null, 4000),
      ]);

      // Without one, filtering would quietly hide them.
      expect(find.text('No floor'), findsOneWidget);

      await tester.tap(find.text('No floor'));
      await tester.pumpAndSettle();

      expect(find.text('Unit X'), findsOneWidget);
      expect(find.text('Unit 1A'), findsNothing);
      expect(find.text('No floor set'), findsOneWidget);
    });

    testWidgets('All puts everything back', (tester) async {
      await open(tester, [whole('1A', '1', 7000), whole('2A', '2', 8000)]);

      await tester.tap(find.text('Floor 2'));
      await tester.pumpAndSettle();
      expect(find.text('Unit 1A'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Unit 1A'), findsOneWidget);
      expect(find.text('Unit 2A'), findsOneWidget);
      expect(find.text('₱15000'), findsOneWidget);
    });
  });

  group('a unit out of service', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 2,
        );

    UnitResponse closed() => UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
          capacity: 4,
          bedCount: 4,
          bedsUnderMaintenance: 0,
          rent: 2500,
          status: UnitResponseStatusEnum.MAINTENANCE,
        );

    UnitResponse open() => UnitResponse(
          id: 'u2',
          propertyId: 'p1',
          unitNumber: '1A',
          rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
          capacity: 1,
          bedCount: 0,
          bedsUnderMaintenance: 0,
          rent: 7000,
          potentialMonthlyRent: 7000,
          status: UnitResponseStatusEnum.VACANT,
        );

    Widget appWith(List<UnitResponse> units, {UnitsApi? api}) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            if (api != null) unitsApiProvider.overrideWithValue(api),
            propertiesProvider.overrideWith((ref) async => [property()]),
            unitsProvider('p1').overrideWith((ref) async => units),
          ],
          child: const LizmoApp(),
        );

    testWidgets('its beds stop counting towards the property', (tester) async {
      await tester.pumpWidget(appWith([closed(), open()]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // The closed unit has four beds; none of them can be let, so the
      // rentable count is zero and only the open unit's rent is totalled.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('₱7000'), findsWidgets);
    });

    testWidgets('the card says so, rather than just showing a dash',
        (tester) async {
      await tester.pumpWidget(appWith([closed()]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.text('Out of service'), findsOneWidget);
    });

    testWidgets('a whole unit out of service is marked too', (tester) async {
      final shutWholeUnit = UnitResponse(
        id: 'u2',
        propertyId: 'p1',
        unitNumber: '1A',
        rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
        capacity: 1,
        bedCount: 0,
        bedsUnderMaintenance: 0,
        rent: 7000,
        status: UnitResponseStatusEnum.MAINTENANCE,
      );

      await tester.pumpWidget(appWith([shutWholeUnit]));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // It has no beds, so it would otherwise carry no chip at all.
      expect(find.text('Out of service'), findsOneWidget);
    });

    testWidgets('the unit screen offers to reopen it', (tester) async {
      final api = _FakeBedsApi(closed(), []);
      await tester.pumpWidget(appWith([closed()], api: api));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Out of service'), findsWidgets);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to service'));
      await tester.pumpAndSettle();

      expect(api.lastUnitMaintenance!.underMaintenance, isFalse);
    });

    testWidgets('an open unit is offered the other direction', (tester) async {
      final api = _FakeBedsApi(open(), []);
      await tester.pumpWidget(appWith([open()], api: api));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 1A'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take out of service'));
      await tester.pumpAndSettle();

      expect(api.lastUnitMaintenance!.underMaintenance, isTrue);
    });
  });

  group('fixed monthly utilities', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 1,
        );

    UnitResponse unit({num? monthlyUtilities}) => UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
          capacity: 2,
          bedCount: 2,
          bedsUnderMaintenance: 0,
          rent: 2500,
          potentialMonthlyRent: 5000,
          monthlyUtilities: monthlyUtilities,
          status: UnitResponseStatusEnum.VACANT,
        );

    Future<_FakeBedsApi> openUnit(WidgetTester tester,
        {num? monthlyUtilities,
        List<UtilityResponse>? utilities,
        UtilitiesResponseBillingEnum? billing}) async {
      final u = unit(monthlyUtilities: monthlyUtilities);
      final api = _FakeBedsApi(u, []);
      if (utilities != null) api.utilities = utilities;
      if (billing != null) api.billing = billing;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          unitsApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => [u]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('a unit charging nothing says so, not zero', (tester) async {
      await openUnit(tester);

      // Nothing switched on is a different statement from a charge of nothing.
      expect(find.text('None charged'), findsOneWidget);
    });

    testWidgets('a unit charging something shows the monthly figure',
        (tester) async {
      await openUnit(tester, monthlyUtilities: 1700);

      expect(find.text('A fixed ₱1700 each month'), findsOneWidget);
    });

    testWidgets('the row opens the utilities screen', (tester) async {
      await openUnit(tester);

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();

      expect(find.byType(UnitUtilitiesScreen), findsOneWidget);
      // All three, whether or not they have ever been set up.
      expect(find.text('WiFi'), findsOneWidget);
      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets('each utility is switched independently', (tester) async {
      final api = await openUnit(tester);

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();

      // WiFi on at 500, the other two left alone.
      await tester.enterText(find.byType(TextFormField).at(0), '500');
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      final sent = api.lastUtilities!.utilities;
      expect(sent.length, 3);
      final wifi = sent.firstWhere((u) => u.kind == UtilityRequestKindEnum.WIFI);
      expect(wifi.enabled, isTrue);
      expect(wifi.amount, 500);
      expect(
        sent.where((u) => u.enabled).length,
        1,
        reason: 'switching WiFi on must not switch the others on',
      );
    });

    testWidgets('switching one on with no amount is refused before saving',
        (tester) async {
      final api = await openUnit(tester);

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      // A charge with no amount is not a charge; the API refuses it too.
      expect(find.text('Set an amount, or switch WiFi off'), findsOneWidget);
      expect(api.lastUtilities, isNull);
    });

    testWidgets('an amount survives being switched off', (tester) async {
      final api = await openUnit(tester, utilities: [
        UtilityResponse(
            kind: UtilityResponseKindEnum.WIFI, enabled: true, amount: 500),
        UtilityResponse(kind: UtilityResponseKindEnum.ELECTRICITY, enabled: false),
        UtilityResponse(kind: UtilityResponseKindEnum.WATER, enabled: false),
      ]);

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();

      // Switch WiFi off without clearing the field.
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      final wifi = api.lastUtilities!.utilities
          .firstWhere((u) => u.kind == UtilityRequestKindEnum.WIFI);
      expect(wifi.enabled, isFalse);
      // Sent along, so turning it back on does not mean retyping the figure.
      expect(wifi.amount, 500);
    });

    testWidgets('a zero amount is refused', (tester) async {
      final api = await openUnit(tester);

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '0');
      await tester.tap(find.byType(Switch).at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      // Zero would read as free, which is what switching off means.
      expect(find.text('Enter more than zero'), findsOneWidget);
      expect(api.lastUtilities, isNull);
    });

    testWidgets('the running total follows the switches', (tester) async {
      await openUnit(tester, utilities: [
        UtilityResponse(
            kind: UtilityResponseKindEnum.WIFI, enabled: true, amount: 500),
        UtilityResponse(
            kind: UtilityResponseKindEnum.ELECTRICITY, enabled: true, amount: 1200),
        UtilityResponse(
            kind: UtilityResponseKindEnum.WATER, enabled: false, amount: 300),
      ]);

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();

      // Water is set up but not charged, so it is not in the total.
      expect(find.text('₱1700'), findsOneWidget);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();

      expect(find.text('₱2000'), findsOneWidget);
    });
  });

  group('how utilities are billed', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 1,
        );

    UnitResponse unit() => UnitResponse(
          id: 'u1',
          propertyId: 'p1',
          unitNumber: '2B',
          rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
          capacity: 2,
          bedCount: 2,
          bedsUnderMaintenance: 0,
          rent: 2500,
          potentialMonthlyRent: 5000,
          monthlyUtilities: 500,
          status: UnitResponseStatusEnum.VACANT,
        );

    Future<_FakeBedsApi> openUtilities(WidgetTester tester,
        {UtilitiesResponseBillingEnum? billing}) async {
      final u = unit();
      final api = _FakeBedsApi(u, []);
      api.utilities = [
        UtilityResponse(
            kind: UtilityResponseKindEnum.WIFI, enabled: true, amount: 500),
        UtilityResponse(kind: UtilityResponseKindEnum.ELECTRICITY, enabled: false),
        UtilityResponse(kind: UtilityResponseKindEnum.WATER, enabled: false),
      ];
      if (billing != null) api.billing = billing;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          unitsApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [property()]),
          unitsProvider('p1').overrideWith((ref) async => [u]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('both ways of billing are offered', (tester) async {
      await openUtilities(tester);

      expect(find.text('How is it billed?'), findsOneWidget);
      expect(find.text('Added to the rent'), findsOneWidget);
      expect(find.text('Billed separately'), findsOneWidget);
    });

    testWidgets('it opens on whatever the unit already does', (tester) async {
      await openUtilities(tester, billing: UtilitiesResponseBillingEnum.SEPARATE);

      // Seeded from the API, not defaulted, or saving would silently switch a
      // unit back to combined.
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();
    });

    testWidgets('choosing separate is sent on save', (tester) async {
      final api = await openUtilities(tester);

      // The form is long enough that the choice sits below the fold.
      await tester.ensureVisible(find.text('Billed separately'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billed separately'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      expect(api.lastUtilities!.billing, UtilitiesRequestBillingEnum.SEPARATE);
    });

    testWidgets('a unit already billing separately keeps doing so',
        (tester) async {
      final api =
          await openUtilities(tester, billing: UtilitiesResponseBillingEnum.SEPARATE);

      // Saving without touching the choice must not quietly reset it.
      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      expect(api.lastUtilities!.billing, UtilitiesRequestBillingEnum.SEPARATE);
    });

    testWidgets('the choice does not change the amounts', (tester) async {
      final api = await openUtilities(tester);

      expect(find.text('₱500'), findsOneWidget);

      // The form is long enough that the choice sits below the fold.
      await tester.ensureVisible(find.text('Billed separately'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Billed separately'));
      await tester.pumpAndSettle();

      // Presentation, not arithmetic.
      expect(find.text('₱500'), findsOneWidget);

      await tester.ensureVisible(find.text('Save utilities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save utilities'));
      await tester.pumpAndSettle();

      final wifi = api.lastUtilities!.utilities
          .firstWhere((u) => u.kind == UtilityRequestKindEnum.WIFI);
      expect(wifi.amount, 500);
    });
  });

  group('a property description', () {
    PropertyResponse property({String? description}) => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          description: description,
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 1,
          potentialMonthlyRent: 10000,
        );

    Future<void> open(WidgetTester tester, {String? description}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider
              .overrideWith((ref) async => [property(description: description)]),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows on the property screen when there is one',
        (tester) async {
      await open(tester, description: 'Quiet street, five minutes from the LRT.');

      expect(find.text('Quiet street, five minutes from the LRT.'),
          findsOneWidget);
    });

    testWidgets('takes no room when there is none', (tester) async {
      await open(tester);

      // No empty card: a property without a description should look like a
      // property without a description, not like one that failed to load.
      expect(find.text('More'), findsNothing);
    });

    testWidgets('a short one is not offered a More control', (tester) async {
      await open(tester, description: 'Newly repainted.');

      // The control is noise on a one-line description.
      expect(find.text('Newly repainted.'), findsOneWidget);
      expect(find.text('More'), findsNothing);
    });

    testWidgets('a long one is clamped and can be expanded', (tester) async {
      final long = List.filled(80, 'Quiet street near the LRT.').join(' ');
      await open(tester, description: long);

      // Clamped, or three hundred words would push the units off the phone.
      expect(find.text('More'), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsNothing);
    });

    testWidgets('the form sends what was typed', (tester) async {
      final store = <PropertyResponse>[];
      final api = _FakePropertiesApi(store);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => List.of(store)),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Mabuhay Bedspace');
      await tester.enterText(find.byType(TextFormField).at(1), '7 Katipunan Ave');
      await tester.enterText(
          find.byType(TextFormField).at(2), 'Curfew at 11pm.');

      await tester.ensureVisible(find.text('Save property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save property'));
      await tester.pumpAndSettle();

      expect(api.lastRequest!.description, 'Curfew at 11pm.');
    });

    testWidgets('leaving it blank sends nothing, not an empty string',
        (tester) async {
      final store = <PropertyResponse>[];
      final api = _FakePropertiesApi(store);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => List.of(store)),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Mabuhay Bedspace');
      await tester.enterText(find.byType(TextFormField).at(1), '7 Katipunan Ave');

      await tester.ensureVisible(find.text('Save property'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save property'));
      await tester.pumpAndSettle();

      // No description and an empty one are different statements.
      expect(api.lastRequest!.description, isNull);
    });
  });

  group('the landlord tab bar', () {
    Widget app() => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesProvider.overrideWith((ref) async => [
                  PropertyResponse(
                    id: 'p1',
                    name: 'Sunrise Apartments',
                    address: '12 Mabini St',
                    type: PropertyResponseTypeEnum.BOARDING_HOUSE,
                    usage: PropertyResponseUsageEnum.RESIDENTIAL,
                    unitCount: 1,
                    potentialMonthlyRent: 10000,
                  )
                ]),
            unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
            myTenantsProvider.overrideWith((ref) async => const <LeaseResponse>[]),
          ],
          child: const LizmoApp(),
        );

    testWidgets('three sections, opening on Today', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tab-today')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-properties')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-tenants')), findsOneWidget);
      expect(find.byType(LandlordHomeScreen), findsOneWidget);
    });

    testWidgets('the dashboard says which parts are not built', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Real figures where they exist, and named dependencies where they do
      // not. Fake numbers would be a lie about the state of the product.
      expect(find.text('₱10000'), findsOneWidget);
      expect(find.text('Needs leases and billing'), findsOneWidget);
      expect(find.text('Needs leases'), findsNWidgets(2));
    });

    testWidgets('tenants is empty for a reason it explains', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-tenants')));
      await tester.pumpAndSettle();

      expect(find.byType(TenantsScreen), findsOneWidget);
      // It used to say "Leases are not built yet", which stopped being true
      // and stayed on the screen. An empty list now means an empty list.
      expect(find.text('No tenants yet'), findsOneWidget);
      expect(find.textContaining('not built'), findsNothing);
    });

    testWidgets('each tab keeps its own stack', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-properties')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      expect(find.byType(PropertyDetailScreen), findsOneWidget);

      // Away and back: the property is still open, not reset to the list.
      await tester.tap(find.byKey(const ValueKey('tab-tenants')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-properties')));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    testWidgets('tapping the tab you are on returns it to its root',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-properties')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-properties')));
      await tester.pumpAndSettle();

      // Which is what a second tap means everywhere else.
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(PropertyDetailScreen), findsNothing);
    });
  });

  group('a whole unit shows itself', () {
    testWidgets('its facts replace the old apology', (tester) async {
      final unit = UnitResponse(
        id: 'u1',
        propertyId: 'p1',
        unitNumber: '1A',
        floor: '1',
        sizeSqm: 24.5,
        rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
        capacity: 1,
        bedCount: 0,
        bedsUnderMaintenance: 0,
        rent: 7000,
        potentialMonthlyRent: 7000,
        status: UnitResponseStatusEnum.VACANT,
      );
      final api = _FakeBedsApi(unit, []);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          unitsApiProvider.overrideWithValue(api),
          propertiesProvider.overrideWith((ref) async => [
                PropertyResponse(
                  id: 'p1',
                  name: 'Sunrise Apartments',
                  address: '12 Mabini St',
                  type: PropertyResponseTypeEnum.BOARDING_HOUSE,
                  usage: PropertyResponseUsageEnum.RESIDENTIAL,
                  unitCount: 1,
                )
              ]),
          unitsProvider('p1').overrideWith((ref) async => [unit]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 1A'));
      await tester.pumpAndSettle();

      // It used to apologise for having nothing inside it. These are the
      // unit's own facts, which were otherwise only in the edit form.
      expect(find.text('One whole unit, one tenant'), findsOneWidget);
      expect(find.text('24.5 sqm'), findsOneWidget);
      expect(find.text('Vacant'), findsOneWidget);
      expect(find.textContaining('no beds to set up'), findsNothing);

      // And everything it could already do, it still does.
      expect(find.text('Utilities'), findsOneWidget);
      expect(find.byTooltip('Edit unit'), findsOneWidget);
      expect(find.byTooltip('More'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });

  group('the backend must be reachable before the app opens', () {
    Widget appWith(_FakeHealth health) => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuth(const AuthSignedOut())),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            backendHealthProvider.overrideWith(() => health),
            propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
          ],
          child: const LizmoApp(),
        );

    testWidgets('an unreachable backend holds the splash', (tester) async {
      await tester.pumpWidget(appWith(_FakeHealth(BackendReachability.unreachable)));
      await tester.pump(const Duration(seconds: 4)); // past the splash hold

      // Login would only fail, and a restored session would show a portfolio
      // that looks empty rather than unreachable.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text("Can't reach Lizmo"), findsOneWidget);
    });

    testWidgets('retrying lets the app through', (tester) async {
      final health = _FakeHealth(BackendReachability.unreachable);
      await tester.pumpWidget(appWith(health));
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(health.checks, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('a reachable backend is not held up', (tester) async {
      await tester.pumpWidget(appWith(_FakeHealth(BackendReachability.reachable)));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('the splash still waits out its hold when reachable',
        (tester) async {
      await tester.pumpWidget(appWith(_FakeHealth(BackendReachability.reachable)));
      await tester.pump(const Duration(milliseconds: 500));

      // Reachable is not a licence to skip the splash.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

/// Captures what the profile form sends, and hands back what it would have
/// stored, so a test can assert on the request rather than on the screen only.
class _RecordingTenantProfileApi extends TenantProfileApi {
  _RecordingTenantProfileApi(this._profile);

  final TenantProfileResponse _profile;
  TenantProfileRequest? saved;

  @override
  Future<TenantProfileResponse?> getMyTenantProfile({Future<void>? abortTrigger}) async =>
      _profile;

  @override
  Future<TenantProfileResponse?> updateMyTenantProfile(
    TenantProfileRequest request, {
    Future<void>? abortTrigger,
  }) async {
    saved = request;
    return _profile;
  }
}

void _tenantProfileTests() {
  group('tenant profile', () {
    Widget appWith(
      TenantProfileResponse profile, {
      _RecordingTenantProfileApi? api,
      List<TenantDocumentResponse> documents = const [],
    }) =>
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            myTenantProfileProvider.overrideWith((ref) async => profile),
            myTenantDocumentsProvider.overrideWith((ref) async => documents),
            if (api != null) tenantProfileApiProvider.overrideWithValue(api),
          ],
          child: const LizmoApp(),
        );

    /// A photograph the server says is stored.
    TenantDocumentResponse photograph(TenantDocumentResponseDocTypeEnum kind) =>
        TenantDocumentResponse(
          docType: kind,
          // Presigned and short-lived, as the real one is.
          url: 'https://example-bucket.test/tenants/u1/x.jpg?X-Amz-Expires=600',
          urlExpiresInSeconds: 600,
          byteSize: 40000,
          uploadedAt: DateTime.utc(2026, 8, 1),
        );

    List<TenantDocumentResponse> bothPhotographs() => [
          photograph(TenantDocumentResponseDocTypeEnum.VALID_ID),
          photograph(TenantDocumentResponseDocTypeEnum.TENANT_PHOTO),
        ];

    /// Everything a lease needs.
    TenantProfileResponse complete() => TenantProfileResponse(
          birthdate: DateTime.utc(1998, 4, 12),
          permanentAddress: 'Brgy. San Isidro, Naga City',
          occupation: 'Nurse at Bicol Medical Center',
          emergencyContactName: 'Rosa Dela Cruz',
          emergencyContactRelationship: 'Mother',
          emergencyContactPhone: '09171234567',
          idType: TenantProfileResponseIdTypeEnum.PHILSYS,
          idNumber: '1234-5678-9012',
          readyForALease: true,
        );

    /// What a field actually holds, as against the hint sitting behind it.
    /// find.text sees both, so seeded values have to be read off the
    /// controllers.
    List<String> fieldValues(WidgetTester tester) => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();

    /// The form is longer than a phone, so Save sits past the fold. The first
    /// Scrollable is the form itself — the others are the ID dropdown and the
    /// single-line fields, which do not scroll anywhere.
    Future<void> saveProfile(WidgetTester tester) async {
      // A focused field scrolls itself back into view on every relayout, so
      // it has to let go before the form can be scrolled to the end — the same
      // reason a real keyboard has to come down to reach the button.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      // Dragged rather than ensureVisible: the drag clamps at the scroll
      // extent, so it always lands at the bottom of the form. Comfortably
      // further than the form is long -- at 600 it stopped clamping the day
      // the identity card was added, and the button was then found but not
      // hit, so the save silently never happened.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
    }

    Future<void> openProfile(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My profile'));
      await tester.pumpAndSettle();
    }

    testWidgets('the home screen asks an unfinished profile to be finished',
        (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await tester.pumpAndSettle();

      expect(find.text('Finish your profile'), findsOneWidget);
    });

    testWidgets('a finished profile is not nagged', (tester) async {
      await tester.pumpWidget(appWith(complete(), documents: bothPhotographs()));
      await tester.pumpAndSettle();

      // A banner that never goes away is one a tenant stops reading.
      expect(find.text('Finish your profile'), findsNothing);
    });

    testWidgets('the prompt opens the profile', (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open my profile'));
      await tester.pumpAndSettle();

      expect(find.text('My profile'), findsOneWidget);
    });

    testWidgets('says who you are signed in as', (tester) async {
      await tester.pumpWidget(appWith(complete()));
      await openProfile(tester);

      // A page called "My profile" that never says whose it is reads as
      // broken, and somebody being asked for an ID number wants to see they
      // are filling it in as themselves.
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('The name your landlord sees'), findsOneWidget);
    });

    testWidgets('the name is shown, not offered as a field', (tester) async {
      await tester.pumpWidget(appWith(complete()));
      await openProfile(tester);

      // Nothing changes a name yet, so a box that looks typeable would promise
      // something that does not work.
      expect(fieldValues(tester), isNot(contains('Ana Reyes')));
    });

    testWidgets('stored details are shown for editing', (tester) async {
      await tester.pumpWidget(appWith(complete()));
      await openProfile(tester);

      expect(
        fieldValues(tester),
        containsAll(['Rosa Dela Cruz', 'Nurse at Bicol Medical Center',
            'Mother', '09171234567', '1234-5678-9012']),
      );
      expect(find.text('April 12, 1998'), findsOneWidget);
      expect(find.text('PhilSys (National ID)'), findsWidgets);
    });

    testWidgets('an unset birthdate reads as a dash, never as a date',
        (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      // Null is not a date, and certainly not today.
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('the banner says what a lease still needs', (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      // Named rather than counted, and in the order the form asks for them.
      expect(
        find.textContaining('an emergency contact, your ID details, '
            'a photo of your ID and a 1x1 or selfie'),
        findsOneWidget,
      );
    });

    testWidgets('the banner clears as the last field is filled in',
        (tester) async {
      // Everything, both photographs included, but the ID number.
      await tester.pumpWidget(appWith(
        TenantProfileResponse(
          emergencyContactName: 'Rosa Dela Cruz',
          emergencyContactPhone: '09171234567',
          idType: TenantProfileResponseIdTypeEnum.UMID,
          readyForALease: false,
        ),
        documents: bothPhotographs(),
      ));
      await openProfile(tester);

      expect(find.textContaining('your ID details'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '1234-5678-9012'),
        '0111-2222222-3',
      );
      await tester.pumpAndSettle();

      // Without waiting for a save: the tenant can see they are done.
      expect(find.text('Your profile is ready for a lease.'), findsOneWidget);
    });

    testWidgets('both photographs are asked for by name', (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      // A 1x1 is not a second ID, and a tenant should not have to guess which
      // of the two a tile means.
      expect(find.text('Photo of your ID'), findsOneWidget);
      expect(find.text('1x1 or selfie'), findsOneWidget);
      expect(find.text('Add'), findsNWidgets(2));
    });

    testWidgets('an uploaded photograph says so and offers to replace it',
        (tester) async {
      await tester.pumpWidget(appWith(
        TenantProfileResponse(readyForALease: false),
        documents: [photograph(TenantDocumentResponseDocTypeEnum.VALID_ID)],
      ));
      await openProfile(tester);

      expect(find.text('Uploaded'), findsOneWidget);
      // "Replace", because a second upload supersedes the first rather than
      // adding to it.
      expect(find.text('Replace'), findsOneWidget);
      // The other tile is still waiting.
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('the banner counts a missing photograph, not just fields',
        (tester) async {
      await tester.pumpWidget(appWith(
        complete(),
        documents: [photograph(TenantDocumentResponseDocTypeEnum.VALID_ID)],
      ));
      await openProfile(tester);

      // Every detail typed in and an ID photographed, and still not ready: a
      // landlord asked for a face as well as a document.
      expect(find.textContaining('a 1x1 or selfie'), findsOneWidget);
      expect(find.text('Your profile is ready for a lease.'), findsNothing);
    });

    testWidgets('details and both photographs together are what ready means',
        (tester) async {
      await tester.pumpWidget(appWith(complete(), documents: bothPhotographs()));
      await openProfile(tester);

      expect(find.text('Your profile is ready for a lease.'), findsOneWidget);
    });

    testWidgets('the tenant is told what happens to their photo metadata',
        (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      // An ID photographed at home carries the home's coordinates. Stripping it
      // silently is right; saying so is what earns the upload.
      expect(
        find.textContaining('Location and camera details are removed'),
        findsOneWidget,
      );
    });

    testWidgets('a half-finished profile still saves', (tester) async {
      final api = _RecordingTenantProfileApi(TenantProfileResponse(readyForALease: false));
      await tester.pumpWidget(
        appWith(TenantProfileResponse(readyForALease: false), api: api),
      );
      await openProfile(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nurse at Bicol Medical Center'),
        'Student',
      );
      await saveProfile(tester);

      // Refusing the lot over the missing ID would leave nothing saved at all.
      expect(api.saved?.occupation, 'Student');
      expect(api.saved?.emergencyContactName, isNull);
    });

    testWidgets('clearing a field sends null rather than spaces', (tester) async {
      final api = _RecordingTenantProfileApi(complete());
      await tester.pumpWidget(appWith(complete(), api: api));
      await openProfile(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nurse at Bicol Medical Center'),
        '   ',
      );
      await saveProfile(tester);

      // Null, not "   ": "never said" has to stay tellable from a real answer.
      expect(api.saved?.occupation, isNull);
    });

    testWidgets('the birthdate survives a timezone east of UTC', (tester) async {
      final api = _RecordingTenantProfileApi(complete());
      await tester.pumpWidget(appWith(complete(), api: api));
      await openProfile(tester);

      await saveProfile(tester);

      // The client formats birthdate through toUtc(). Held as local midnight,
      // a Manila birthdate would go over the wire as the day before.
      final sent = api.saved!.birthdate!;
      expect(sent.isUtc, isTrue);
      expect(sent.toUtc().day, 12);
      expect(sent.toUtc().month, 4);
    });
  });
}

void _propertyShareTests() {
  group('sharing a property', () {
    PropertyResponse property({String? code = 'PHK7M4Q2'}) => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          code: code,
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 1,
          potentialMonthlyRent: 10000,
        );

    Future<void> openProperty(WidgetTester tester, {String? code = 'PHK7M4Q2'}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property(code: code)]),
          propertyProvider('p1').overrideWith((ref) async => property(code: code)),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
    }

    Future<void> openShare(WidgetTester tester, {String? code = 'PHK7M4Q2'}) async {
      await openProperty(tester, code: code);
      await tester.tap(find.byTooltip('Share this place'));
      await tester.pumpAndSettle();
    }

    testWidgets('the property screen offers it in one tap', (tester) async {
      await openProperty(tester);

      // In the header, not down with the units: it is about the property as a
      // whole, and a landlord showing it to somebody should not have to scroll.
      expect(find.byTooltip('Share this place'), findsOneWidget);
    });

    testWidgets('the address confirms it is the right building', (tester) async {
      await openShare(tester);

      // This page gets held out to somebody standing in front of the place.
      expect(find.text('12 Mabini St'), findsOneWidget);
    });

    testWidgets('what kind of place it is, before anyone scans', (tester) async {
      await openShare(tester);

      // Both halves named here. The property list omits "Residential" because
      // it is the majority and would be noise on every row; here it is telling
      // a stranger what they are looking at.
      expect(find.text('Residential · Boarding House'), findsOneWidget);
    });

    testWidgets('the code is shown large enough to read out', (tester) async {
      await openShare(tester);

      expect(find.text('PHK7M4Q2'), findsOneWidget);
      expect(find.text('Property code'), findsOneWidget);

      // Most people will type this rather than scan it, and often it is being
      // read by somebody older than the person holding the phone. Well above
      // the app's ordinary body size of 14.
      final code = tester.widget<Text>(find.text('PHK7M4Q2'));
      expect(code.style!.fontSize, greaterThanOrEqualTo(24));
    });

    testWidgets('the landlord can send it on', (tester) async {
      await openShare(tester);

      // The native sheet covers both asks: social apps, chat, and the
      // platform's own Save Image / Save to Files.
      expect(find.text('Share or save this code'), findsOneWidget);
    });

    testWidgets('the exported image names the place', (tester) async {
      await openShare(tester);

      final card = find.byKey(shareCardKey);
      // An image of a QR on its own, forwarded into a group chat, tells nobody
      // which building it opens.
      for (final line in [
        'Sunrise Apartments',
        '12 Mabini St',
        'Residential · Boarding House',
        'PHK7M4Q2',
      ]) {
        expect(
          find.descendant(of: card, matching: find.text(line)),
          findsOneWidget,
          reason: '"\$line" should travel with the code',
        );
      }
    });

    testWidgets('no controls are painted into the image', (tester) async {
      await openShare(tester);

      // The capture renders the live tree, so anything left inside the card
      // ends up in the picture — a copy button somebody cannot press, in an
      // image of a building.
      expect(
        find.descendant(
          of: find.byKey(shareCardKey),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(shareCardKey),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
      // Still reachable, just outside the card.
      expect(find.text('Copy code'), findsOneWidget);
    });

    testWidgets('the landlord instruction stays out of the image',
        (tester) async {
      await openShare(tester);

      // It is guidance for the person holding the phone, and nonsense to
      // whoever receives the picture.
      expect(
        find.descendant(
          of: find.byKey(shareCardKey),
          matching: find.textContaining('Show this to anyone'),
        ),
        findsNothing,
      );
      expect(find.textContaining('Show this to anyone'), findsOneWidget);
    });

    testWidgets('what gets shared is a real image of the card', (tester) async {
      await openShare(tester);

      // Driving the share sheet is impossible in a test, so the seam is the
      // capture: this is the part that can silently produce nothing, or produce
      // an image too small for the QR in it to survive printing.
      // The nearest boundary above the marked card. Searching for "a
      // RepaintBoundary with a GlobalKey" finds Flutter's root one first and
      // captures the whole screen — which passed this test for the wrong
      // reason until the exported image turned out to be 1170x2532.
      final boundary = find
          .ancestor(
            of: find.byKey(shareCardKey),
            matching: find.byType(RepaintBoundary),
          )
          .evaluate()
          .first;
      final key = boundary.widget.key as GlobalKey;

      // runAsync, because rasterizing a boundary and decoding a PNG are real
      // asynchronous work. Awaited directly inside testWidgets they deadlock:
      // the fake-async zone never lets them complete, and the test hangs rather
      // than failing — which is exactly what it did.
      final png = await tester.runAsync(
        () => captureBoundaryPng(key, pixelRatio: 3),
      );
      expect(png, isNotNull);

      // A real PNG, by its signature, not merely non-empty bytes.
      expect(png!.sublist(0, 8),
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

      final decoded = (await tester.runAsync(() => decodeImageFromList(png)))!;
      // Captured at 3x, so the QR survives being printed or zoomed into rather
      // than turning to mush.
      expect(decoded.width, greaterThan(600));
      // And it is the card, not the screen: a full-screen capture would be
      // 844 logical points tall, and would carry the app bar and the share
      // button into the image somebody receives.
      expect(decoded.height, lessThan(844 * 3));
    });

    testWidgets('type grows with the screen, and never shrinks', (tester) async {
      await openShare(tester);
      final onPhone = tester.widget<Text>(find.text('PHK7M4Q2')).style!.fontSize!;

      // A tablet-sized surface. Gently larger — the scale is the square root of
      // the ratio, so a much wider screen does not double the type.
      tester.view.physicalSize = const Size(834 * 3, 1194 * 3);
      tester.view.devicePixelRatio = 3.0;
      // Restored by hand rather than with view.reset(), which reverts to the
      // binding's original 800x600 — undoing the phone-shaped surface that
      // flutter_test_config installs, for every test declared after this one.
      addTearDown(() {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
      });
      await tester.pumpAndSettle();

      final onTablet = tester.widget<Text>(find.text('PHK7M4Q2')).style!.fontSize!;
      expect(onTablet, greaterThan(onPhone));
      // Clamped: the same ratio applied literally would give headings the size
      // of a fist.
      expect(onTablet, lessThan(onPhone * 1.4));
    });

    testWidgets('a QR is drawn for the code', (tester) async {
      await openShare(tester);

      expect(find.byType(QrImageView), findsOneWidget);
    });

    test('the QR encodes the code and nothing else', () {
      // Asserted on the function rather than read back off the widget:
      // QrImageView keeps its data private, and this is where the decision
      // lives. It was a URL until we admitted there is no domain behind it —
      // a QR that resolves nowhere is worse than one a camera app simply
      // shows as text.
      expect(PropertyShareScreen.qrPayloadFor('PHK7M4Q2'), 'PHK7M4Q2');
    });

    testWidgets('the logo sits in the middle of the code', (tester) async {
      await openShare(tester);

      expect(find.byType(QrImageView), findsOneWidget);
      // Drawn over the QR rather than handed to the package: the icon has
      // transparency, and without an opaque plate the modules show through it.
      //
      // This asserts the widget is in the tree, not that a logo appears —
      // Image.asset paints nothing in a widget test, so nothing here can prove
      // that. Scannability with the mark actually in place was checked by
      // rendering the code, compositing the real icon over it and decoding it:
      // it reads down to 120px wide and fails around 90px.
      expect(
        find.descendant(of: find.byType(Stack), matching: find.byType(Image)),
        findsOneWidget,
      );
    });

    testWidgets('covering the middle raises the error correction', (tester) async {
      await openShare(tester);

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      // The package defaults to L, which recovers 7%. Cover the centre of that
      // and the code stops scanning in poor light, at an angle, or on a
      // photocopied sign. This is the assertion that fails if someone adds a
      // logo to another QR and forgets why this one works.
      expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);
    });

    testWidgets('the QR stays dark on white in either theme', (tester) async {
      await openShare(tester);

      // A QR that followed the app's dark mode would invert, and an inverted
      // QR does not scan.
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.backgroundColor, Colors.white);
      expect(qr.dataModuleStyle.color, LizmoColors.ink);
    });

    testWidgets('copying puts the code on the clipboard', (tester) async {
      await openShare(tester);

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );

      await tester.tap(find.text('Copy code'));
      await tester.pumpAndSettle();

      // The code alone, not the URL: this gets pasted into a message to a
      // tenant, who types it into the app.
      expect(copied, 'PHK7M4Q2');
      expect(find.text('Code copied'), findsOneWidget);
    });

  });
}

/// Records what a tenant asked for, and can refuse the way the API does.
class _FakeAskingApi extends AskingForARoomApi {
  _FakeAskingApi({this.failWith});

  final ApiFailure? failWith;
  RentalRequestCreate? sent;

  @override
  Future<RentalRequestResponse?> sendRentalRequest(
    RentalRequestCreate request, {
    Future<void>? abortTrigger,
  }) async {
    if (failWith != null) throw failWith!;
    sent = request;
    return RentalRequestResponse(
      id: 'r1',
      unitId: request.unitId,
      bedId: request.bedId,
      status: RentalRequestResponseStatusEnum.PENDING,
    );
  }

  @override
  Future<List<RentalRequestResponse>?> listMyRentalRequests({
    Future<void>? abortTrigger,
  }) async => const [];
}

void _findingAPlaceTests() {
  group('finding a place', () {
    PropertyByCodeResponse place({
      List<VacantBed> beds = const [],
      List<VacantUnit> units = const [],
    }) => PropertyByCodeResponse(
      id: 'p1',
      code: 'PHK7M4Q2',
      name: 'Sunrise Apartments',
      address: '12 Mabini St',
      type: PropertyByCodeResponseTypeEnum.BOARDING_HOUSE,
      usage: PropertyByCodeResponseUsageEnum.RESIDENTIAL,
      vacantWholeUnits: units.length,
      vacantBeds: beds.length,
      floors: [
        if (beds.isNotEmpty || units.isNotEmpty)
          VacancyFloor(floor: '2', wholeUnits: units, bedspaces: beds),
      ],
    );

    VacantBed bed({num? rent = 2500, num? utilities, bool included = false}) =>
        VacantBed(
          unitId: 'u1',
          unitNumber: '2B',
          bedId: 'b1',
          bedLabel: 'Bed 1',
          rent: rent,
          monthlyUtilities: utilities,
          utilitiesIncluded: included,
        );

    Widget appWith({
      PropertyByCodeResponse? found,
      ApiFailure? lookupFails,
      _FakeAskingApi? asking,
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        propertyByCodeProvider('PHK7M4Q2').overrideWith((ref) async {
          if (lookupFails != null) throw lookupFails;
          return found ?? place();
        }),
        if (asking != null) askingForARoomApiProvider.overrideWithValue(asking),
      ],
      child: const LizmoApp(),
    );

    /// The My place tab, then its way out to typing.
    ///
    /// Finding somewhere lives under My place now: it is the same question as
    /// "where do I live", asked before the answer exists.
    ///
    /// The primary action opens the camera, which is what most tenants will
    /// use and what no widget test can drive. Going through the typing link is
    /// both the way to reach the field and a check that the fallback is
    /// reachable at all — a camera-only path would strand anyone who refuses
    /// permission.
    Future<void> openFind(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-place')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type the code instead'));
      await tester.pumpAndSettle();
    }

    Future<void> enterCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.pumpAndSettle();
      await tester.tap(find.text('See what is free'));
      await tester.pumpAndSettle();
    }

    testWidgets('My place is the way in', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-place')));
      await tester.pumpAndSettle();

      // A tenant with no lease has exactly one thing to do in this app, and
      // the tab that will hold their tenancy is where they do it.
      expect(find.text('Scan a property code'), findsOneWidget);
    });

    testWidgets('the code is upper-cased as it is typed', (tester) async {
      await tester.pumpWidget(appWith());
      await openFind(tester);

      await tester.enterText(find.byType(TextField), 'phk7m4q2');
      await tester.pumpAndSettle();

      // Read off the field rather than found by text: the hint is the same
      // string, so find.text would match whether the formatter ran or not.
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.controller.text, 'PHK7M4Q2');
    });

    testWidgets('a half-typed code cannot be submitted', (tester) async {
      await tester.pumpWidget(appWith());
      await openFind(tester);

      await tester.enterText(find.byType(TextField), 'PHK7');
      await tester.pumpAndSettle();

      // Visibly disabled, not merely inert: a button that looks tappable and
      // does nothing reads as the app being broken.
      final button = tester.widget<PrimaryActionButton>(
        find.byType(PrimaryActionButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a code finds the place and what is free', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: [bed()])));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.text('Sunrise Apartments'), findsWidgets);
      expect(find.text('12 Mabini St'), findsOneWidget);
      expect(find.text('1 space free'), findsOneWidget);
      expect(find.text('Bed 1'), findsOneWidget);
      expect(find.text('Floor 2'), findsOneWidget);
    });

    testWidgets('a full house says so rather than showing nothing', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(found: place()));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      // Nothing free is a real answer, not an empty screen.
      expect(find.text('Nothing free here at the moment'), findsOneWidget);
    });

    testWidgets('the price is what the tenant would actually hand over', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(found: place(beds: [bed(utilities: 800)])));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      // Rent alone is not the comparison a tenant is making.
      expect(find.text('P2500 a month, plus P800 utilities'), findsNothing);
      expect(
        find.textContaining('a month, plus'),
        findsOneWidget,
      );
    });

    testWidgets('utilities folded into the rent are said so', (tester) async {
      await tester.pumpWidget(
        appWith(found: place(beds: [bed(utilities: 800, included: true)])),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.textContaining('utilities included'), findsOneWidget);
    });

    testWidgets('an unpriced bed says so rather than reading as free', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(found: place(beds: [bed(rent: null)])));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.text('Price not set'), findsOneWidget);
    });

    testWidgets('asking sends the unit and the bed', (tester) async {
      final asking = _FakeAskingApi();
      await tester.pumpWidget(
        appWith(found: place(beds: [bed()]), asking: asking),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      await tester.tap(find.text('Ask for this'));
      await tester.pumpAndSettle();

      expect(asking.sent?.unitId, 'u1');
      expect(asking.sent?.bedId, 'b1');
      // The row stops offering it again once asked.
      expect(find.text('Asked'), findsOneWidget);
      expect(find.text('Ask for this'), findsNothing);
    });

    testWidgets('an unfinished profile is explained in the second person', (
      tester,
    ) async {
      final asking = _FakeAskingApi(
        failWith: const ApiFailure(
          code: 'TENANT_PROFILE_INCOMPLETE',
          // What the server actually says: written for a landlord reading
          // about somebody else.
          message: 'This tenant cannot sign a lease yet. They still need an ID.',
        ),
      );
      await tester.pumpWidget(
        appWith(found: place(beds: [bed()]), asking: asking),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      await tester.tap(find.text('Ask for this'));
      await tester.pumpAndSettle();

      // Said to the tenant about themselves, with the way to fix it.
      expect(find.text('Finish your profile first'), findsOneWidget);
      expect(find.textContaining('This tenant cannot'), findsNothing);
      expect(find.text('Open my profile'), findsOneWidget);
    });

    testWidgets('a slot taken while reading is shown as it happened', (
      tester,
    ) async {
      final asking = _FakeAskingApi(
        failWith: const ApiFailure(
          code: 'SLOT_UNAVAILABLE',
          message: 'That bed has been taken.',
        ),
      );
      await tester.pumpWidget(
        appWith(found: place(beds: [bed()]), asking: asking),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      await tester.tap(find.text('Ask for this'));
      await tester.pumpAndSettle();

      expect(find.text('That bed has been taken.'), findsOneWidget);
      // And it is not marked as asked, because it was not.
      expect(find.text('Asked'), findsNothing);
    });

    testWidgets('a wrong code explains the alphabet', (tester) async {
      await tester.pumpWidget(
        appWith(
          lookupFails: const ApiFailure(
            code: 'NOT_FOUND',
            message: 'No property uses that code.',
          ),
        ),
      );
      await openFind(tester);
      await enterCode(tester, 'PHZZZZZZ');

      expect(find.text('No place with that code'), findsOneWidget);
      // The commonest typo, given the alphabet deliberately omits them.
      expect(find.textContaining('no O or I'), findsOneWidget);
    });
  });
}

void _scanningTests() {
  group('scanning a code', () {
    // No camera in a widget test, so the assertions sit on the function that
    // decides what a scan meant. That is where the decisions are: which
    // formats to accept, and what to do with everything else pointed at it.

    test('a bare code is taken as it is', () {
      expect(codeFromScan('PHK7M4Q2'), 'PHK7M4Q2');
    });

    test('a URL gives up its last path segment', () {
      // The QR carries a bare code today. It was briefly a link and may be
      // again once there is a domain, and signs printed under either scheme
      // have to keep working.
      expect(codeFromScan('https://lizmo.app/p/PHK7M4Q2'), 'PHK7M4Q2');
      expect(codeFromScan('https://lizmo.app/p/PHK7M4Q2/'), 'PHK7M4Q2');
    });

    test('a tracking query does not become part of the code', () {
      expect(
        codeFromScan('https://lizmo.app/p/PHK7M4Q2?utm_source=poster'),
        'PHK7M4Q2',
      );
      expect(codeFromScan('https://lizmo.app/p/PHK7M4Q2#top'), 'PHK7M4Q2');
    });

    test('case and separators survive a sign that was retyped', () {
      expect(codeFromScan('phk7m4q2'), 'PHK7M4Q2');
      expect(codeFromScan('  PHK7-M4Q2  '), 'PHK7M4Q2');
    });

    test('somebody else QR code is refused rather than looked up', () {
      // A tenant sweeping a camera across a wall will hit a Wi-Fi code, a
      // payment code, a shop receipt. Rejecting them here keeps the camera
      // looking instead of navigating to a certain 404.
      for (final other in [
        'WIFI:S:CoffeeShop;T:WPA;P:hunter2;;',
        'https://example.com/promo',
        '00020101021228',
        'Just some text',
        '',
      ]) {
        expect(codeFromScan(other), isNull, reason: other);
      }
    });

    test('a code with the letters the alphabet avoids is not ours', () {
      // O and I are excluded from the alphabet precisely because they are
      // misread as zero and one. Something containing them was misread.
      expect(codeFromScan('PHOOOOOO'), isNull);
      expect(codeFromScan('PHIIIIII'), isNull);
    });

    test('a code of the wrong length is refused', () {
      expect(codeFromScan('PHK7M4'), isNull);
      expect(codeFromScan('PHK7M4Q2M'), isNull);
      expect(codeFromScan('LZ7K4M2A'), isNull);
    });

    test('nothing scanned is nothing', () {
      expect(codeFromScan(null), isNull);
    });
  });
}

/// Answers requests the way the API does, and records what was answered.
class _FakeAnsweringApi extends RequestsToAnswerApi {
  _FakeAnsweringApi({this.failWith});

  final ApiFailure? failWith;
  String? accepted;
  AcceptRequest? acceptedOn;
  String? declined;

  @override
  Future<LeaseResponse?> acceptRentalRequest(
    String id, {
    AcceptRequest? acceptRequest,
    Future<void>? abortTrigger,
  }) async {
    if (failWith != null) throw failWith!;
    accepted = id;
    acceptedOn = acceptRequest;
    return LeaseResponse(id: 'l1', status: LeaseResponseStatusEnum.ACTIVE);
  }

  @override
  Future<RentalRequestForLandlord?> declineRentalRequest(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    declined = id;
    return RentalRequestForLandlord(
      id: id,
      status: RentalRequestForLandlordStatusEnum.DECLINED,
    );
  }
}

void _landlordRequestTests() {
  group('answering requests', () {
    PropertyResponse property() => PropertyResponse(
      id: 'p1',
      name: 'Sunrise Apartments',
      address: '12 Mabini St',
      code: 'PHK7M4Q2',
      type: PropertyResponseTypeEnum.BOARDING_HOUSE,
      usage: PropertyResponseUsageEnum.RESIDENTIAL,
      unitCount: 1,
    );

    RentalRequestForLandlord request({
      String id = 'r1',
      String name = 'Ana Reyes',
      String? bedLabel = 'Bed 1',
    }) => RentalRequestForLandlord(
      id: id,
      propertyId: 'p1',
      unitId: 'u1',
      unitNumber: '2B',
      bedId: bedLabel == null ? null : 'b1',
      bedLabel: bedLabel,
      status: RentalRequestForLandlordStatusEnum.PENDING,
      tenantId: 't1',
      tenantName: name,
      tenantPhone: '09171234567',
      occupation: 'Nurse',
      permanentAddress: 'Naga City',
      age: 27,
      idType: RentalRequestForLandlordIdTypeEnum.PHILSYS,
      askingRent: 2500,
    );

    Widget appWith({
      List<RentalRequestForLandlord> waiting = const [],
      _FakeAnsweringApi? answering,
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => [property()]),
        propertyProvider('p1').overrideWith((ref) async => property()),
        unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        pendingRequestsProvider('p1').overrideWith((ref) async => waiting),
        propertyLeasesProvider('p1').overrideWith((ref) async => const <LeaseResponse>[]),
        if (answering != null)
          requestsToAnswerApiProvider.overrideWithValue(answering),
      ],
      child: const LizmoApp(),
    );

    Future<void> openProperty(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
    }

    testWidgets('no strip when nobody is waiting', (tester) async {
      await tester.pumpWidget(appWith());
      await openProperty(tester);

      // A row that permanently reads "0 requests" is one a landlord learns to
      // stop seeing.
      expect(find.textContaining('asking about'), findsNothing);
    });

    testWidgets('one person waiting reads as one person', (tester) async {
      await tester.pumpWidget(appWith(waiting: [request()]));
      await openProperty(tester);

      expect(find.text('Somebody is asking about a room'), findsOneWidget);
    });

    testWidgets('several are counted', (tester) async {
      await tester.pumpWidget(
        appWith(waiting: [request(), request(id: 'r2', name: 'Bea')]),
      );
      await openProperty(tester);

      expect(find.text('2 people are asking about rooms'), findsOneWidget);
    });

    testWidgets('the strip opens the queue', (tester) async {
      await tester.pumpWidget(appWith(waiting: [request()]));
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();

      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('for Bed 1 in 2B'), findsOneWidget);
    });

    testWidgets('answering the last one empties the queue', (tester) async {
      // The only way to see the empty state, and the right one: the strip is
      // hidden when nothing is waiting, so a landlord reaches it by clearing
      // the queue rather than by opening an empty screen. It also checks the
      // list refreshes after an answer instead of showing a stale row.
      var waiting = [request()];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
          ),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
          propertyProvider('p1').overrideWith((ref) async => property()),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
          propertyLeasesProvider('p1')
              .overrideWith((ref) async => const <LeaseResponse>[]),
          pendingRequestsProvider('p1').overrideWith((ref) async => waiting),
          requestsToAnswerApiProvider.overrideWithValue(_FakeAnsweringApi()),
        ],
        child: const LizmoApp(),
      ));
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();

      waiting = const [];
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      expect(find.text('Nobody waiting'), findsOneWidget);
      expect(find.textContaining('scans your code'), findsOneWidget);
    });

    testWidgets('the landlord is told enough to decide', (tester) async {
      await tester.pumpWidget(appWith(waiting: [request()]));
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();

      expect(find.text('Nurse'), findsOneWidget);
      expect(find.text('Naga City'), findsOneWidget);
      // Their own number: arranging a viewing is the next thing that happens.
      expect(find.text('09171234567'), findsOneWidget);
      // The age, not a date to do arithmetic on.
      expect(find.text('27 years old'), findsOneWidget);
      // What they carry, without the number.
      expect(find.text('PHILSYS'), findsOneWidget);
    });

    testWidgets('the emergency contact is not part of an application',
        (tester) async {
      await tester.pumpWidget(appWith(waiting: [request()]));
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();

      // A third person who never used Lizmo and never agreed to anything.
      // Who to ring if something happens to somebody who does not live here
      // yet is no use to a landlord deciding whether to let them.
      expect(find.textContaining('In an emergency'), findsNothing);
      expect(find.textContaining('Rosa'), findsNothing);
    });

    testWidgets('accepting asks first, then sends', (tester) async {
      final answering = _FakeAnsweringApi();
      await tester.pumpWidget(
        appWith(waiting: [request()], answering: answering),
      );
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // The terms are settled first: accepting gives away a room, tells
      // everybody else it has gone, and writes a rent into a lease.
      expect(find.text('Accept Ana Reyes'), findsOneWidget);
      expect(answering.accepted, isNull);

      // Filled in from what the tenant was looking at, rather than left blank
      // for somebody to retype. Read off the field itself: the placeholder
      // carries the same number, so find.text would match twice.
      expect(
        tester.widget<EditableText>(find.byType(EditableText).first)
            .controller.text,
        '2500',
      );

      // The sheet scrolls now that it carries deposit and advance, so the
      // button can start below the fold.
      await tester.ensureVisible(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();

      expect(answering.accepted, 'r1');
      expect(answering.acceptedOn?.rentAmount, 2500);
      expect(answering.acceptedOn?.startDate, isNotNull);
    });

    testWidgets('the rent can be changed before accepting', (tester) async {
      final answering = _FakeAnsweringApi();
      await tester.pumpWidget(
        appWith(waiting: [request()], answering: answering),
      );
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // A landlord who agreed something else on the phone should not have to
      // change the listing to record it.
      await tester.enterText(find.byType(TextFormField).first, '3000');
      // The sheet scrolls now that it carries deposit and advance, so the
      // button can start below the fold.
      await tester.ensureVisible(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();

      expect(answering.acceptedOn?.rentAmount, 3000);
    });

    testWidgets('a rent of nothing is refused', (tester) async {
      final answering = _FakeAnsweringApi();
      await tester.pumpWidget(
        appWith(waiting: [request()], answering: answering),
      );
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '0');
      // The sheet scrolls now that it carries deposit and advance, so the
      // button can start below the fold.
      await tester.ensureVisible(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept and create the lease'));
      await tester.pump();

      // Zero would read as free for the life of the lease.
      expect(find.text('The rent has to be more than nothing'), findsOneWidget);
      expect(answering.accepted, isNull);
    });

    testWidgets('backing out of the terms accepts nothing', (tester) async {
      final answering = _FakeAnsweringApi();
      await tester.pumpWidget(
        appWith(waiting: [request()], answering: answering),
      );
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();

      expect(answering.accepted, isNull);
    });

    testWidgets('declining does not ask', (tester) async {
      final answering = _FakeAnsweringApi();
      await tester.pumpWidget(
        appWith(waiting: [request()], answering: answering),
      );
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();

      // Declining takes nothing away from anybody and is easily done again.
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      expect(answering.declined, 'r1');
    });

    testWidgets('a bed taken while the screen was open is explained', (
      tester,
    ) async {
      final answering = _FakeAnsweringApi(
        failWith: const ApiFailure(
          code: 'SLOT_UNAVAILABLE',
          message: 'That bed is already let.',
        ),
      );
      await tester.pumpWidget(
        appWith(waiting: [request()], answering: answering),
      );
      await openProperty(tester);
      await tester.tap(find.text('Somebody is asking about a room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      // The sheet scrolls now that it carries deposit and advance, so the
      // button can start below the fold.
      await tester.ensureVisible(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept and create the lease'));
      await tester.pumpAndSettle();

      expect(find.text('That bed is already let.'), findsOneWidget);
    });
  });
}

void _tenantLeaseTests() {
  group('a tenant with a lease', () {
    Widget appWith(List<LeaseResponse> leases) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => leases),
      ],
      child: const LizmoApp(),
    );

    LeaseResponse lease({int dueDay = 5, String? bedLabel = 'Bed 1'}) =>
        LeaseResponse(
          id: 'l1',
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedId: bedLabel == null ? null : 'b1',
          bedLabel: bedLabel,
          rentAmount: 2500,
          dueDateDay: dueDay,
          status: LeaseResponseStatusEnum.ACTIVE,
        );

    /// The lease facts live on My place now, not on the home screen. Home
    /// answers "what needs me"; this answers "where do I live".
    Future<void> openMyPlace(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-place')));
      await tester.pumpAndSettle();
    }

    testWidgets('a tenancy replaces the invitation to look', (tester) async {
      await tester.pumpWidget(appWith([lease()]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      // Somebody who has somewhere to live does not need asking whether they
      // are looking for somewhere to live.
      expect(find.text('Bed 1, 2B'), findsOneWidget);
      expect(find.text('Scan a property code'), findsNothing);
    });

    testWidgets('without one, the invitation stands', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.textContaining('not renting through Lizmo yet'), findsOneWidget);
      expect(find.text('Scan a property code'), findsOneWidget);
    });

    testWidgets('a whole unit is named as a unit', (tester) async {
      await tester.pumpWidget(appWith([lease(bedLabel: null)]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Unit 2B'), findsWidgets);
    });

    testWidgets('the rent day reads as a date', (tester) async {
      await tester.pumpWidget(appWith([lease(dueDay: 22)]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      // "the 22" looks like a bug.
      expect(find.text('The 22nd'), findsOneWidget);
    });

    testWidgets('the awkward ordinals are right', (tester) async {
      for (final (day, expected) in [
        (1, '1st'),
        (2, '2nd'),
        (3, '3rd'),
        (11, '11th'),
        (12, '12th'),
        (13, '13th'),
        (21, '21st'),
      ]) {
        // Torn down between cases. Pumping a second app over the first reuses
        // the ProviderScope element, and the already-resolved lease provider
        // keeps its first answer — so every case after the first would assert
        // against day one.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(appWith([lease(dueDay: day)]));
        await tester.pumpAndSettle();
        await openMyPlace(tester);
        expect(
          find.text('The $expected'),
          findsOneWidget,
          reason: 'day $day should read as $expected',
        );
      }
    });

    testWidgets('the home screen says what is waiting, not what is invented',
        (tester) async {
      await tester.pumpWidget(appWith([lease()]));
      await tester.pumpAndSettle();

      // This screen used to carry three hardcoded billing periods and a header
      // naming a property the tenant had never heard of. A brand-new tenant
      // was told they owed 2,500 pesos, overdue.
      expect(find.text('Billing periods'), findsNothing);
      expect(find.text('+ Submit a payment'), findsNothing);
      expect(find.text('August 2026'), findsNothing);
      expect(find.text('Sunrise Apartments'), findsOneWidget);
    });

    testWidgets('payments and maintenance say plainly that they are empty',
        (tester) async {
      await tester.pumpWidget(appWith([lease()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-payments')));
      await tester.pumpAndSettle();
      expect(find.text('No bills yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab-maintenance')));
      await tester.pumpAndSettle();
      expect(find.text('Not built yet'), findsOneWidget);
    });

    testWidgets('each tab keeps its own stack', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();

      await openMyPlace(tester);
      await tester.tap(find.text('Type the code instead'));
      await tester.pumpAndSettle();
      expect(find.byType(FindPropertyScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab-payments')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-place')));
      await tester.pumpAndSettle();

      // Coming back lands where you left, which is what a tab bar is for.
      expect(find.byType(FindPropertyScreen), findsOneWidget);
    });
  });

  group('being told what happened', () {
    NotificationResponse note({
      required String id,
      String title = 'Your request was accepted',
      String message = 'You have Bed 1 in 2B.',
      bool unread = true,
    }) => NotificationResponse(
      id: id,
      type: NotificationResponseTypeEnum.REQUEST_ACCEPTED,
      title: title,
      message: message,
      unread: unread,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    Widget appWith(List<NotificationResponse> news) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
        myRentalRequestsProvider.overrideWith(
          (ref) async => const <RentalRequestResponse>[],
        ),
        myNotificationsProvider.overrideWith((ref) async => news),
      ],
      child: const LizmoApp(),
    );

    Future<void> openTheBell(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('notification-bell')));
      await tester.pumpAndSettle();
    }

    /// The reason this moved off the home screen. As a section it rendered
    /// nothing when there was nothing waiting, so somebody who had never had
    /// a notification had no way to learn that notifications existed.
    testWidgets('the bell is there with nothing waiting', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('notification-bell')), findsOneWidget);

      await openTheBell(tester);
      expect(find.text('Nothing yet'), findsOneWidget);
    });

    testWidgets('the bell opens the news', (tester) async {
      await tester.pumpWidget(appWith([note(id: 'n1')]));
      await tester.pumpAndSettle();

      // Not on the home screen any more: it lives behind the bell.
      expect(find.text('Your request was accepted'), findsNothing);

      await openTheBell(tester);
      expect(find.text('Your request was accepted'), findsOneWidget);
      expect(find.text('You have Bed 1 in 2B.'), findsOneWidget);
    });

    testWidgets('the unread count rides on the bell', (tester) async {
      await tester.pumpWidget(appWith([
        note(id: 'n1'),
        note(id: 'n2', title: 'That one has gone'),
        note(id: 'n3', title: 'Old news', unread: false),
      ]));
      await tester.pumpAndSettle();

      // Two, not three: a badge counts what is waiting, not what exists.
      expect(
        find.descendant(
          of: find.byType(NotificationBell),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('nothing unread means no badge', (tester) async {
      await tester.pumpWidget(appWith([note(id: 'n1', unread: false)]));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(NotificationBell),
          matching: find.text('1'),
        ),
        findsNothing,
      );

      await openTheBell(tester);
      // Nothing to clear, so the screen does not offer to clear it.
      expect(find.byKey(const ValueKey('mark-all-read')), findsNothing);
    });

    /// Home answers "what needs me". A notification is news about something
    /// that already happened, and must not displace that.
    testWidgets('the home screen is unchanged by news', (tester) async {
      await tester.pumpWidget(appWith([note(id: 'n1')]));
      await tester.pumpAndSettle();

      expect(find.text('Nothing needs you'), findsOneWidget);
    });

    testWidgets('a landlord has the same bell', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
          ),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith(
            (ref) async => const <PropertyResponse>[],
          ),
          myNotificationsProvider.overrideWith(
            (ref) async => [note(id: 'n1', title: 'Somebody has asked')],
          ),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await openTheBell(tester);

      // Being told what happened is not a tenant feature.
      expect(find.text('Somebody has asked'), findsOneWidget);
    });
  });

  group('the landlord looking at a tenant', () {
    LeaseResponse tenancy({String id = 'l1', String name = 'Ana Reyes'}) =>
        LeaseResponse(
          id: id,
          tenantId: 't1',
          tenantName: name,
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedId: 'b1',
          bedLabel: 'Bed 1',
          rentAmount: 2500,
          dueDateDay: 5,
          status: LeaseResponseStatusEnum.ACTIVE,
        );

    TenantForLandlord person({
      String? emergencyName = 'Rosa Dela Cruz',
      String? idNumber = '1234-5678-9012',
      int? age = 26,
      String? occupation,
    }) => TenantForLandlord(
      leaseId: 'l1',
      tenantId: 't1',
      name: 'Ana Reyes',
      phone: '09171112222',
      email: 'ana@example.com',
      age: age,
      occupation: occupation,
      emergencyContactName: emergencyName,
      emergencyContactRelationship: 'Mother',
      emergencyContactPhone: '09171234567',
      idType: TenantForLandlordIdTypeEnum.DRIVERS_LICENSE,
      idNumber: idNumber,
    );

    Widget appWith({
      List<LeaseResponse> tenants = const [],
      TenantForLandlord? detail,
      Object? detailError,
      List<TenantDocumentResponse> documents = const [],
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myTenantsProvider.overrideWith((ref) async => tenants),
        leaseTenantProvider('l1').overrideWith((ref) async {
          if (detailError != null) throw detailError;
          return detail ?? person();
        }),
        leaseTenantDocumentsProvider('l1').overrideWith(
          (ref) async => documents,
        ),
      ],
      child: const LizmoApp(),
    );

    Future<void> openTenants(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-tenants')));
      await tester.pumpAndSettle();
    }

    testWidgets('the list shows who is living where', (tester) async {
      await tester.pumpWidget(appWith(tenants: [tenancy()]));
      await tester.pumpAndSettle();
      await openTenants(tester);

      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.textContaining('Bed 1, 2B'), findsOneWidget);
    });

    /// The reason the whole screen exists. A tenant cannot ask about a bed
    /// without naming somebody to ring, and until now the one person who
    /// might need to ring them could not read it.
    testWidgets('the emergency contact is reachable', (tester) async {
      await tester.pumpWidget(appWith(tenants: [tenancy()]));
      await tester.pumpAndSettle();
      await openTenants(tester);

      await tester.tap(find.byKey(const ValueKey('tenant-l1')));
      await tester.pumpAndSettle();

      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(find.text('Rosa Dela Cruz'), findsOneWidget);
      expect(find.text('09171234567'), findsOneWidget);
      expect(find.text('Mother'), findsOneWidget);
    });

    /// go_router builds the stack for a nested route, so the AppBar gets its
    /// own back arrow. Worth pinning: without a way back, a landlord who taps
    /// a tenant is stuck on them.
    testWidgets('there is a way back to the list', (tester) async {
      await tester.pumpWidget(appWith(tenants: [tenancy()]));
      await tester.pumpAndSettle();
      await openTenants(tester);
      await tester.tap(find.byKey(const ValueKey('tenant-l1')));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(TenantsScreen), findsOneWidget);
    });

    testWidgets('the ID reads as the tenant chose it', (tester) async {
      await tester.pumpWidget(appWith(tenants: [tenancy()]));
      await tester.pumpAndSettle();
      await openTenants(tester);
      await tester.tap(find.byKey(const ValueKey('tenant-l1')));
      await tester.pumpAndSettle();

      // Not DRIVERS_LICENSE. The tenant picked "Driving licence" from a list,
      // and their landlord sees the same words for the same document.
      expect(find.text('Driving licence'), findsOneWidget);
      expect(find.text('1234-5678-9012'), findsOneWidget);
    });

    /// Null is not empty and not zero. "No occupation recorded" and
    /// "unemployed" are different statements, and only the tenant makes the
    /// second one.
    testWidgets('a fact nobody gave reads as a dash', (tester) async {
      await tester.pumpWidget(appWith(
        tenants: [tenancy()],
        detail: person(occupation: null, age: null),
      ));
      await tester.pumpAndSettle();
      await openTenants(tester);
      await tester.tap(find.byKey(const ValueKey('tenant-l1')));
      await tester.pumpAndSettle();

      // Occupation, age and permanent address: three the tenant never gave.
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('0'), findsNothing);
    });

    /// A tenancy that ended answers 404, and the screen says so rather than
    /// showing a half-empty record of somebody who has moved out.
    testWidgets('an ended tenancy is not readable', (tester) async {
      await tester.pumpWidget(appWith(
        tenants: [tenancy()],
        detailError: const ApiFailure(
          code: 'NOT_FOUND',
          message: 'That tenancy has ended.',
        ),
      ));
      await tester.pumpAndSettle();
      await openTenants(tester);
      await tester.tap(find.byKey(const ValueKey('tenant-l1')));
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsOneWidget);
      expect(find.text('That tenancy has ended.'), findsOneWidget);
      expect(find.text('Rosa Dela Cruz'), findsNothing);
    });
  });

  group('forgetting a password', () {
    testWidgets('is reachable from login without a session', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('forgot-password')));
      await tester.pumpAndSettle();

      // The signed-out redirect has to permit it, or somebody locked out could
      // never reach the one screen that would let them back in.
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('asks for an address and nothing else, first', (tester) async {
      await tester.pumpWidget(_resetApp());
      await tester.pumpAndSettle();

      expect(find.text('Send me a code'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('New password'), findsNothing);
    });

    testWidgets('will not send a code to something that is not an address',
        (tester) async {
      final auth = _ResettingAuth();
      await tester.pumpWidget(_resetApp(auth: auth));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('reset-email')), 'not-an-address');
      await tester.tap(find.text('Send me a code'));
      await tester.pumpAndSettle();

      expect(find.text('That does not look like an email address'),
          findsOneWidget);
      expect(auth.startedWith, isNull);
    });

    /// The server answers identically whether or not the address has an
    /// account. A screen that behaved differently would leak exactly what the
    /// server refuses to.
    testWidgets('moves on without claiming the address has an account',
        (tester) async {
      await tester.pumpWidget(_resetApp(auth: _ResettingAuth()));
      await tester.pumpAndSettle();
      await _reachResetStep(tester);

      expect(find.textContaining('If ana@example.com has a Lizmo account'),
          findsOneWidget);
      // Never "we sent you a code" -- the app cannot stand behind that.
      expect(find.textContaining('We sent'), findsNothing);
    });

    testWidgets('the code and the new password are asked for together',
        (tester) async {
      await tester.pumpWidget(_resetApp(auth: _ResettingAuth()));
      await tester.pumpAndSettle();
      await _reachResetStep(tester);

      expect(find.byKey(const ValueKey('reset-code')), findsOneWidget);
      expect(find.byKey(const ValueKey('reset-password')), findsOneWidget);
    });

    testWidgets('a weak password is refused before anything is sent',
        (tester) async {
      final auth = _ResettingAuth();
      await tester.pumpWidget(_resetApp(auth: auth));
      await tester.pumpAndSettle();
      await _reachResetStep(tester);

      await tester.enterText(find.byKey(const ValueKey('reset-code')), '483920');
      await tester.enterText(
          find.byKey(const ValueKey('reset-password')), 'short');
      await tester.tap(find.text('Set my password'));
      await tester.pumpAndSettle();

      expect(auth.chosePassword, isNull);
    });

    testWidgets('the code and password reach the controller', (tester) async {
      final auth = _ResettingAuth();
      await tester.pumpWidget(_resetApp(auth: auth));
      await tester.pumpAndSettle();
      await _reachResetStep(tester);

      await tester.enterText(find.byKey(const ValueKey('reset-code')), '483920');
      await tester.enterText(
          find.byKey(const ValueKey('reset-password')), 'Moonrise7Bed!');
      await tester.tap(find.text('Set my password'));
      await tester.pumpAndSettle();

      expect(auth.startedWith, 'ana@example.com');
      expect(auth.usedCode, '483920');
      expect(auth.chosePassword, 'Moonrise7Bed!');
    });

    /// The code is only ever checked by the call that spends it, so a wrong one
    /// surfaces here rather than on a screen of its own.
    testWidgets('a rejected code is reported under the form', (tester) async {
      final auth = _ResettingAuth(
        failCompletionWith: const ApiFailure(
          code: 'OTP_INCORRECT',
          message: 'That code is not right. 4 tries left.',
        ),
      );
      await tester.pumpWidget(_resetApp(auth: auth));
      await tester.pumpAndSettle();
      await _reachResetStep(tester);

      await tester.enterText(find.byKey(const ValueKey('reset-code')), '000000');
      await tester.enterText(
          find.byKey(const ValueKey('reset-password')), 'Moonrise7Bed!');
      await tester.tap(find.text('Set my password'));
      await tester.pumpAndSettle();

      expect(find.text('That code is not right. 4 tries left.'), findsOneWidget);
      // Still on the form, rather than thrown back a step.
      expect(find.byKey(const ValueKey('reset-password')), findsOneWidget);
    });

    testWidgets('resending is refused until the countdown runs out',
        (tester) async {
      await tester
          .pumpWidget(_resetApp(auth: _ResettingAuth(resendAfterSeconds: 2)));
      await tester.pumpAndSettle();
      await _reachResetStep(tester);

      // Every tap is an email somebody has to receive, so the button is
      // disabled rather than tapped and told off.
      expect(find.textContaining('Send another in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Send another code'), findsOneWidget);
    });

    testWidgets('finishing signs the user in and moves them along',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(const AuthSignedOut())),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
          myTenantProfileProvider.overrideWith(
            (ref) async => TenantProfileResponse(readyForALease: true),
          ),
          myRentalRequestsProvider.overrideWith(
            (ref) async => const <RentalRequestResponse>[],
          ),
          myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
          myNotificationsProvider.overrideWith(
            (ref) async => const <NotificationResponse>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LizmoApp()),
      );
      await tester.pumpAndSettle();

      container.read(routerProvider).go(Routes.forgotPassword);
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      // Resetting signs them straight in. Without the route in the move-along
      // set they would sit on the form they had just submitted.
      container.read(authControllerProvider.notifier).state =
          _signedIn({LizmoProfile.tenant});
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });
  });

  group('a tenant photograph', () {
    /// A 1x1 PNG. Image.network cannot fetch anything in a widget test, so
    /// every image here ends in errorBuilder -- which is fine: what is being
    /// tested is that a tap opens the viewer and that it closes again, not
    /// how a JPEG decodes.
    TenantDocumentResponse photo(TenantDocumentResponseDocTypeEnum kind) =>
        TenantDocumentResponse(
          docType: kind,
          url: 'https://example.invalid/${kind.toJson()}.jpg',
          urlExpiresInSeconds: 300,
        );

    Widget appWith(List<TenantDocumentResponse> documents) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myTenantsProvider.overrideWith((ref) async => const <LeaseResponse>[]),
        leaseTenantProvider('l1').overrideWith(
          (ref) async => TenantForLandlord(
            leaseId: 'l1',
            tenantId: 't1',
            name: 'Ana Reyes',
            idType: TenantForLandlordIdTypeEnum.DRIVERS_LICENSE,
            idNumber: '1234-5678-9012',
          ),
        ),
        leaseTenantDocumentsProvider('l1').overrideWith((ref) async => documents),
      ],
      child: const MaterialApp(home: TenantDetailScreen(leaseId: 'l1')),
    );

    testWidgets('the name is readable against the bar behind it',
        (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();

      final bar = tester.widget<AppBar>(find.byType(AppBar));
      final title = tester.widget<Text>(
        find.descendant(of: find.byType(AppBar), matching: find.text('Ana Reyes')),
      );

      // LizmoType.screenTitle is white because it is drawn on the teal
      // header. On the canvas-coloured bar this screen used to have, that was
      // white on almost-white.
      expect(title.style?.color, LizmoColors.white);
      expect(bar.backgroundColor, LizmoColors.teal900);
    });

    testWidgets('tapping one opens it large', (tester) async {
      await tester.pumpWidget(
          appWith([photo(TenantDocumentResponseDocTypeEnum.VALID_ID)]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('close-photo')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('photo-VALID_ID')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('close-photo')), findsOneWidget);
      // Pinch and drag come from here rather than being written by hand.
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('the viewer says which photograph it is showing',
        (tester) async {
      await tester.pumpWidget(
          appWith([photo(TenantDocumentResponseDocTypeEnum.TENANT_PHOTO)]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('photo-TENANT_PHOTO')));
      await tester.pumpAndSettle();

      // "Photo", not TENANT_PHOTO.
      expect(find.text('Photo'), findsWidgets);
    });

    testWidgets('closing returns to the tenant', (tester) async {
      await tester.pumpWidget(
          appWith([photo(TenantDocumentResponseDocTypeEnum.VALID_ID)]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('photo-VALID_ID')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-photo')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('close-photo')), findsNothing);
      expect(find.text('1234-5678-9012'), findsOneWidget);
    });

    /// A presigned URL that has lapsed leaves nothing to enlarge. Opening a
    /// black screen with a broken-image glyph on it would be worse than
    /// saying so.
    testWidgets('an expired photograph explains itself', (tester) async {
      await tester.pumpWidget(
          appWith([photo(TenantDocumentResponseDocTypeEnum.VALID_ID)]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('photo-VALID_ID')));
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be loaded'), findsOneWidget);
    });
  });

  group('paperwork on a lease', () {
    LeaseDocumentResponse doc({
      String id = 'd1',
      String label = 'Signed contract',
      bool shared = true,
      String contentType = 'application/pdf',
    }) => LeaseDocumentResponse(
      id: id,
      docType: LeaseDocumentResponseDocTypeEnum.LEASE_CONTRACT,
      label: label,
      url: 'https://example.invalid/$id.pdf',
      urlExpiresInSeconds: 600,
      contentType: contentType,
      byteSize: 1024,
      sharedWithTenant: shared,
      uploadedAt: DateTime.now(),
    );

    Widget appWith(List<LeaseDocumentResponse> documents) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myTenantsProvider.overrideWith((ref) async => const <LeaseResponse>[]),
        leaseTenantProvider('l1').overrideWith(
          (ref) async => TenantForLandlord(
            leaseId: 'l1',
            tenantId: 't1',
            name: 'Ana Reyes',
          ),
        ),
        leaseTenantDocumentsProvider('l1').overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        leaseDocumentsProvider('l1').overrideWith((ref) async => documents),
      ],
      child: const MaterialApp(home: TenantDetailScreen(leaseId: 'l1')),
    );

    testWidgets('an empty list says so rather than showing nothing',
        (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();

      expect(find.text('Attachments'), findsOneWidget);
      expect(find.text('Nothing attached yet.'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-attachment')), findsOneWidget);
    });

    testWidgets('each one names itself', (tester) async {
      await tester.pumpWidget(appWith([doc()]));
      await tester.pumpAndSettle();

      expect(find.text('Signed contract'), findsOneWidget);
    });

    /// A landlord who cannot tell at a glance which documents their tenant is
    /// reading will eventually share the wrong one. So it is on the row, not
    /// hidden behind a menu.
    testWidgets('every row says who can see it', (tester) async {
      await tester.pumpWidget(appWith([
        doc(id: 'd1', label: 'Signed contract'),
        doc(id: 'd2', label: 'My own notes', shared: false),
      ]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Your tenant can see this'), findsOneWidget);
      expect(find.textContaining('Only you can see this'), findsOneWidget);
    });

    testWidgets('a PDF and a photograph are told apart', (tester) async {
      await tester.pumpWidget(appWith([
        doc(id: 'd1', label: 'Contract'),
        doc(id: 'd2', label: 'Receipt photo', contentType: 'image/jpeg'),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    /// There is no copy of this anywhere else, and the tenant may be relying
    /// on it, so the confirmation says both things.
    testWidgets('deleting asks first, and says who else loses it',
        (tester) async {
      await tester.pumpWidget(appWith([doc()]));
      await tester.pumpAndSettle();

      // Attachments are the last card on a long screen, so the button is
      // below the fold until it is scrolled to.
      await tester.ensureVisible(find.byKey(const ValueKey('delete-d1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-d1')));
      await tester.pumpAndSettle();

      expect(find.text('Delete this document?'), findsOneWidget);
      expect(find.textContaining('for you and for your tenant'), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      // Backing out changes nothing.
      expect(find.text('Signed contract'), findsOneWidget);
    });

    testWidgets('the sharing control is on every row', (tester) async {
      await tester.pumpWidget(appWith([doc()]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('share-d1')), findsOneWidget);
    });

    /// The row used to carry only share and delete, so a landlord could file
    /// paperwork and never look at it again.
    testWidgets('a landlord can open their own attachment', (tester) async {
      await tester.pumpWidget(appWith([doc()]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('open-d1')), findsOneWidget);
    });

    /// Nothing on the row said it could be tapped, which is how somebody
    /// concludes the app cannot show them their own contract.
    testWidgets('the row says what tapping it does', (tester) async {
      await tester.pumpWidget(appWith([
        doc(id: 'd1', label: 'Contract'),
        doc(id: 'd2', label: 'Receipt', contentType: 'image/jpeg'),
      ]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tap to download'), findsOneWidget);
      expect(find.textContaining('Tap to view'), findsOneWidget);
    });

    /// The document icon is the obvious thing to reach for. It used to sit
    /// outside the tap target and do nothing.
    testWidgets('the icon is part of the tap target', (tester) async {
      await tester.pumpWidget(
          appWith([doc(id: 'd1', label: 'Receipt', contentType: 'image/jpeg')]));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('open-d1')),
          matching: find.byIcon(Icons.image_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping an attached image opens the viewer', (tester) async {
      await tester.pumpWidget(
          appWith([doc(id: 'd1', label: 'Receipt', contentType: 'image/jpeg')]));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('open-d1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-d1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('close-photo')), findsOneWidget);
    });
  });

  group('a tenant reading their own paperwork', () {
    LeaseResponse tenancy() => LeaseResponse(
          id: 'l1',
          tenantId: 't1',
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedId: 'b1',
          bedLabel: 'Bed 1',
          rentAmount: 2500,
          dueDateDay: 5,
          status: LeaseResponseStatusEnum.ACTIVE,
        );

    LeaseDocumentResponse doc({
      String id = 'd1',
      String label = 'Signed contract',
      String contentType = 'application/pdf',
    }) => LeaseDocumentResponse(
      id: id,
      docType: LeaseDocumentResponseDocTypeEnum.LEASE_CONTRACT,
      label: label,
      url: 'https://example.invalid/$id',
      urlExpiresInSeconds: 600,
      contentType: contentType,
      byteSize: 1024,
      sharedWithTenant: true,
      uploadedAt: DateTime.now(),
    );

    Widget appWith(List<LeaseDocumentResponse> documents) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myRentalRequestsProvider.overrideWith(
          (ref) async => const <RentalRequestResponse>[],
        ),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => [tenancy()]),
        myLeaseDocumentsProvider('l1').overrideWith((ref) async => documents),
      ],
      child: const LizmoApp(),
    );

    Future<void> openMyPlace(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-place')));
      await tester.pumpAndSettle();
    }

    testWidgets('a shared document appears under the tenancy', (tester) async {
      await tester.pumpWidget(appWith([doc()]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Your documents'), findsOneWidget);
      expect(find.text('Signed contract'), findsOneWidget);
    });

    /// A tenancy with no paperwork must look exactly as it did before this
    /// existed. An empty "Your documents" panel reads as a fault.
    testWidgets('nothing shared leaves no trace', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Your documents'), findsNothing);
      expect(find.byType(MyPlaceScreen), findsOneWidget);
    });

    /// The screen used to promise that a copy of the contract was "not
    /// recorded yet". It can be now, and stale copy on a screen a tenant reads
    /// is how they stop believing the rest of it.
    testWidgets('the screen no longer says a contract cannot be kept',
        (tester) async {
      await tester.pumpWidget(appWith([doc()]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.textContaining('copy of your contract'), findsNothing);
      // What genuinely is missing still says so.
      expect(find.textContaining('deposit or advance'), findsOneWidget);
    });

    testWidgets('a PDF and an image are told apart', (tester) async {
      await tester.pumpWidget(appWith([
        doc(id: 'd1', label: 'Contract'),
        doc(id: 'd2', label: 'Receipt', contentType: 'image/jpeg'),
      ]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    /// A PDF is downloaded rather than opened. The link behind it lapses in
    /// minutes, so a browser tab shows something about to stop existing --
    /// no use for a contract, whose whole point is having your own copy.
    testWidgets('a PDF offers a download and an image a view', (tester) async {
      await tester.pumpWidget(appWith([
        doc(id: 'd1', label: 'Contract'),
        doc(id: 'd2', label: 'Receipt', contentType: 'image/jpeg'),
      ]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Tap to download'), findsOneWidget);
      expect(find.text('Tap to view'), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('tapping an image opens it large', (tester) async {
      await tester.pumpWidget(
          appWith([doc(id: 'd2', label: 'Receipt', contentType: 'image/jpeg')]));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      await tester.tap(find.byKey(const ValueKey('shared-doc-d2')));
      await tester.pumpAndSettle();

      // The same viewer the landlord gets, rather than a second one.
      expect(find.byKey(const ValueKey('close-photo')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });

  group('deposit and advance', () {
    LeaseResponse tenancy({num? deposit, num? advance, num? returned,
        String? settlement}) => LeaseResponse(
      id: 'l1',
      tenantId: 't1',
      tenantName: 'Ana Reyes',
      propertyName: 'Sunrise Apartments',
      unitNumber: '2B',
      bedId: 'b1',
      bedLabel: 'Bed 1',
      rentAmount: 2500,
      depositAmount: deposit,
      advanceAmount: advance,
      depositReturned: returned,
      depositSettlement: settlement,
      dueDateDay: 5,
      startDate: DateTime.utc(2026, 10, 1),
      status: LeaseResponseStatusEnum.ACTIVE,
    );

    Widget tenantApp(LeaseResponse lease) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myRentalRequestsProvider.overrideWith(
          (ref) async => const <RentalRequestResponse>[],
        ),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => [lease]),
        myLeaseDocumentsProvider('l1').overrideWith(
          (ref) async => const <LeaseDocumentResponse>[],
        ),
      ],
      child: const LizmoApp(),
    );

    Future<void> openMyPlace(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-place')));
      await tester.pumpAndSettle();
    }

    testWidgets('the tenant sees what they handed over', (tester) async {
      await tester.pumpWidget(tenantApp(tenancy(deposit: 5000, advance: 2500)));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Before you moved in'), findsOneWidget);
      expect(find.text('₱5000'), findsOneWidget);
      expect(find.text('₱2500'), findsOneWidget);
    });

    /// The two are constantly muddled, and the difference only matters at the
    /// end of the tenancy -- when it matters a great deal.
    testWidgets('each says which kind of money it is', (tester) async {
      await tester.pumpWidget(tenantApp(tenancy(deposit: 5000, advance: 2500)));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.textContaining('given back when you move out'), findsOneWidget);
      expect(find.textContaining('pays for your first month'), findsOneWidget);
    });

    /// A tenancy where neither was recorded shows no card, rather than a panel
    /// of dashes implying somebody forgot to fill it in.
    testWidgets('nothing recorded shows no card', (tester) async {
      await tester.pumpWidget(tenantApp(tenancy()));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Before you moved in'), findsNothing);
    });

    /// Null is not zero. A landlord who took no deposit and one who has not
    /// recorded it are different facts, and a tenant asking "did I pay a
    /// deposit?" needs to be able to tell them apart.
    testWidgets('a recorded zero is not the same as nothing', (tester) async {
      await tester.pumpWidget(tenantApp(tenancy(deposit: 0)));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Before you moved in'), findsOneWidget);
      expect(find.text('₱0'), findsOneWidget);
    });

    /// What was withheld and why is the thing a former tenant wants months
    /// later, and the landlord holding the only copy is how a disagreement
    /// becomes their word against nobody's.
    testWidgets('the settlement is shown once the deposit is returned',
        (tester) async {
      await tester.pumpWidget(tenantApp(tenancy(
        deposit: 5000,
        returned: 4500,
        settlement: 'Withheld ₱500 for the window latch.',
      )));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Deposit returned'), findsOneWidget);
      expect(find.text('₱4500'), findsOneWidget);
      expect(find.text('Withheld ₱500 for the window latch.'), findsOneWidget);
    });

    testWidgets('a live tenancy shows no settlement', (tester) async {
      await tester.pumpWidget(tenantApp(tenancy(deposit: 5000)));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Deposit returned'), findsNothing);
    });
  });
}
