import 'package:lizmo/billing/payment_channel_providers.dart';
import 'package:lizmo/screens/payment_channels_screen.dart';
import 'package:lizmo/widgets/payment_channel_sheet.dart';
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
import 'package:lizmo/widgets/declare_payment_sheet.dart';
import 'package:lizmo/widgets/end_tenancy_sheet.dart';
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
import 'package:lizmo/screens/delete_account_screen.dart';
import 'package:lizmo/screens/notifications_screen.dart';
import 'package:lizmo/screens/inquiry_screen.dart';
import 'package:lizmo/inquiry/inquiry_providers.dart';
import 'package:lizmo/screens/tenant_payments_screen.dart';
import 'package:lizmo/screens/tenant_profile_screen.dart';
import 'package:lizmo/widgets/section_tab_bar.dart';
import 'package:lizmo/screens/rent_roll_screen.dart';
import 'package:lizmo/maintenance/maintenance_providers.dart';
import 'package:lizmo/platform/lizmo_billing_providers.dart';
import 'package:lizmo/screens/lizmo_billing_screen.dart';
import 'package:lizmo/widgets/pay_lizmo_sheet.dart';
import 'package:lizmo/widgets/full_screen_image.dart';
import 'package:lizmo/screens/maintenance_inbox_screen.dart';
import 'package:lizmo/screens/maintenance_report_screen.dart';
import 'package:lizmo/screens/update_screen.dart';
import 'package:lizmo/app_version.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:http/http.dart' show MultipartFile;

/// Answers what the oldest allowed build is, or refuses to.
class _FakeVersionApi extends AdminApi {
  _FakeVersionApi({this.answer, this.fails = false});

  final AppVersion? answer;
  final bool fails;
  int calls = 0;

  @override
  Future<AppVersion?> getAppVersion({Future<void>? abortTrigger}) async {
    calls++;
    if (fails) throw ApiException(500, 'nope');
    return answer;
  }
}

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
            .overrideWith((ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true)),
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
/// Which tab is lit.
int _tabIndex(WidgetTester tester) =>
    tester.widget<SectionTabBar>(find.byType(SectionTabBar)).index;

/// Everything tenancy l1's screen reads, pinned, for tests that arrive at it
/// from somewhere other than the tenant list.
List<Override> _tenancyL1() => [
      myTenantsProvider.overrideWith((ref) async => const <LeaseResponse>[]),
      leaseTenantProvider('l1').overrideWith(
        (ref) async =>
            TenantForLandlord(leaseId: 'l1', tenantId: 't1', name: 'Ana Reyes'),
      ),
      leaseTenantDocumentsProvider('l1')
          .overrideWith((ref) async => const <TenantDocumentResponse>[]),
      leaseDocumentsProvider('l1')
          .overrideWith((ref) async => const <LeaseDocumentResponse>[]),
      leaseBillingProvider('l1')
          .overrideWith((ref) async => const <BillingPeriodResponse>[]),
      leasePaymentsProvider('l1')
          .overrideWith((ref) async => const <PaymentResponse>[]),
    ];

/// Keeps what the Rent tab asked of the API, without a network.
class _FakeRentApi extends RentApi {
  final declared = <({String billingPeriodId, String amountPaid, String? paymentMethod,
      String? channelId})>[];

  @override
  Future<PaymentResponse?> declarePayment(
    String leaseId,
    String billingPeriodId,
    String amountPaid, {
    String? paymentDate,
    String? paymentMethod,
    String? remarks,
    String? channelId,
    MultipartFile? proof,
    Future<void>? abortTrigger,
  }) async {
    declared.add((
      billingPeriodId: billingPeriodId,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      channelId: channelId,
    ));
    return null;
  }

  final confirmed = <String>[];
  final refused = <(String, String?)>[];
  final recorded = <RecordPaymentRequest>[];

  @override
  Future<PaymentResponse?> confirmPayment(
    String leaseId,
    String paymentId, {
    Future<void>? abortTrigger,
  }) async {
    confirmed.add(paymentId);
    return null;
  }

  @override
  Future<PaymentResponse?> rejectPayment(
    String leaseId,
    String paymentId, {
    String? remarks,
    Future<void>? abortTrigger,
  }) async {
    refused.add((paymentId, remarks));
    return null;
  }

  @override
  Future<PaymentResponse?> recordPayment(
    String leaseId,
    RecordPaymentRequest recordPaymentRequest, {
    Future<void>? abortTrigger,
  }) async {
    recorded.add(recordPaymentRequest);
    return null;
  }
}

/// Keeps what the tenant's Maintenance tab asked of the API.
class _FakeMaintenanceApi extends MaintenanceApi {
  _FakeMaintenanceApi(this.answer);

  final MaintenanceReportResponse answer;
  final reported = <String>[];
  final photos = <String>[];
  final withdrawn = <String>[];
  final fixed = <String>[];
  final reopened = <(String, String?)>[];

  @override
  Future<MaintenanceReportResponse?> reportProblem(
    ReportProblemRequest reportProblemRequest, {
    Future<void>? abortTrigger,
  }) async {
    reported.add(reportProblemRequest.description);
    return answer;
  }

  @override
  Future<MaintenanceReportResponse?> addMaintenancePhoto(
    String id,
    MultipartFile photo, {
    Future<void>? abortTrigger,
  }) async {
    photos.add(id);
    return answer;
  }

  @override
  Future<MaintenanceReportResponse?> withdrawMaintenanceReport(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    withdrawn.add(id);
    return answer;
  }

  @override
  Future<MaintenanceReportResponse?> confirmMaintenanceFixed(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    fixed.add(id);
    return answer;
  }

  @override
  Future<MaintenanceReportResponse?> reopenMaintenanceReport(
    String id,
    MaintenanceNote maintenanceNote, {
    Future<void>? abortTrigger,
  }) async {
    reopened.add((id, maintenanceNote.text));
    return answer;
  }
}

/// Keeps what the landlord's report screen asked of the API.
class _FakeMaintenanceToHandleApi extends MaintenanceToHandleApi {
  final started = <(String, String?)>[];
  final resolved = <(String, String?)>[];

  @override
  Future<MaintenanceReportResponse?> startMaintenance(
    String id, {
    MaintenanceNote? maintenanceNote,
    Future<void>? abortTrigger,
  }) async {
    started.add((id, maintenanceNote?.text));
    return null;
  }

  @override
  Future<MaintenanceReportResponse?> resolveMaintenance(
    String id, {
    MaintenanceNote? maintenanceNote,
    Future<void>? abortTrigger,
  }) async {
    resolved.add((id, maintenanceNote?.text));
    return null;
  }
}

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

    /// It lived under /tenant, and the tenant guard sends an account with no
    /// tenant profile straight back to its dashboard.
    testWidgets('a landlord can reach account deletion', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
          canDeleteMyAccountProvider.overrideWith((ref) async {}),
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      // A task, so it covers the tabs rather than opening inside one.
      expect(find.byType(SectionTabBar), findsNothing);
    });

    /// A form covers the tabs, and Back lands on the tab it was opened over.
    /// The profile used to live under Home, so opening it from Payments threw
    /// the tenant across to Home to fill it in.
    testWidgets('the profile covers whichever tab it was opened from',
        (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.tenant})));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-rent')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My profile'));
      await tester.pumpAndSettle();

      expect(find.byType(TenantProfileScreen), findsOneWidget);
      expect(find.byType(SectionTabBar), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
      expect(_tabIndex(tester), 1);
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
      expect(find.text('₱5,000'), findsOneWidget);
      expect(find.text('₱7,000'), findsOneWidget);
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
      expect(find.text('₱17,000'), findsOneWidget);
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

      // ₱120,000 is wider than the stat card, so the figure scales down rather
      // than losing a digit -- a landlord with a real portfolio hits this.
      expect(find.text('₱120,000'), findsOneWidget);
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

  group('photographs of a place', () {
    PropertyResponse property() => PropertyResponse(
          id: 'p1',
          name: 'Sunrise Apartments',
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          usage: PropertyResponseUsageEnum.RESIDENTIAL,
          unitCount: 0,
        );

    PropertyPhoto photo(String id, int position) => PropertyPhoto(
          id: id,
          url: 'https://example.invalid/$id.jpg',
          position: position,
          uploadedAt: DateTime.now(),
        );

    Future<void> openProperty(
      WidgetTester tester, {
      required _FakePhotosApi api,
      PickedImage? picked,
    }) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.landlord}))),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          propertiesProvider.overrideWith((ref) async => [property()]),
          propertyProvider('p1').overrideWith((ref) async => property()),
          unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
          myInquiriesProvider
              .overrideWith((ref) async => const <InquirySummary>[]),
          propertiesApiProvider.overrideWithValue(api),
          if (picked != null) ...[
            pickGalleryImageProvider.overrideWithValue(() async => picked),
            takePhotoProvider.overrideWithValue(() async => picked),
          ],
        ],
        child: const LizmoApp(),
      ));
      await tester.pumpAndSettle();
      await _openProperties(tester);
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
    }

    /// The reason the feature exists, said on the screen where somebody can
    /// do something about it.
    testWidgets('a place with no photos says what that costs them',
        (tester) async {
      await openProperty(tester, api: _FakePhotosApi([]));

      expect(find.byKey(const ValueKey('property-photos')), findsOneWidget);
      expect(find.textContaining('A photo is what makes them ask'),
          findsOneWidget);
    });

    testWidgets('the photos are shown, and the first is the cover',
        (tester) async {
      await openProperty(
          tester, api: _FakePhotosApi([photo('a', 0), photo('b', 1)]));

      expect(find.text('Cover'), findsOneWidget);
      expect(find.textContaining('2 of 8'), findsOneWidget);
    });

    testWidgets('a photo from the gallery is uploaded', (tester) async {
      final api = _FakePhotosApi([]);
      await openProperty(
        tester,
        api: api,
        picked: (name: 'house.jpg', bytes: Uint8List.fromList([1, 2, 3])),
      );

      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-from-gallery')));
      await tester.pumpAndSettle();

      expect(api.uploads, 1);
    });

    /// A landlord standing in front of their own building should not have to
    /// photograph it, leave the app, and come back.
    testWidgets('the camera is offered as well as the gallery', (tester) async {
      final api = _FakePhotosApi([]);
      await openProperty(
        tester,
        api: api,
        picked: (name: 'house.jpg', bytes: Uint8List.fromList([1, 2, 3])),
      );

      await tester.tap(find.byKey(const ValueKey('add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('photo-from-camera')));
      await tester.pumpAndSettle();

      expect(api.uploads, 1);
    });

    /// The only ordering question anybody has: which one represents the
    /// place. Nobody cares whether the fifth comes before the sixth.
    testWidgets('any photo can be made the cover', (tester) async {
      final api = _FakePhotosApi([photo('a', 0), photo('b', 1)]);
      await openProperty(tester, api: api);

      await tester.tap(find.byKey(const ValueKey('photo-menu-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make this the cover'));
      await tester.pumpAndSettle();

      expect(api.ordered, ['b', 'a']);
    });

    testWidgets('the cover is not offered as its own cover', (tester) async {
      await openProperty(
          tester, api: _FakePhotosApi([photo('a', 0), photo('b', 1)]));

      await tester.tap(find.byKey(const ValueKey('photo-menu-a')));
      await tester.pumpAndSettle();

      expect(find.text('Make this the cover'), findsNothing);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('removing one asks first', (tester) async {
      final api = _FakePhotosApi([photo('a', 0)]);
      await openProperty(tester, api: api);

      await tester.tap(find.byKey(const ValueKey('photo-menu-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(api.removed, isNull);

      await tester.tap(find.byKey(const ValueKey('photo-menu-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-remove-photo')));
      await tester.pumpAndSettle();

      expect(api.removed, 'a');
    });

    /// Eight is the server's limit, and a button that only fails is worse
    /// than no button.
    testWidgets('a full set stops offering Add', (tester) async {
      await openProperty(
        tester,
        api: _FakePhotosApi([for (var i = 0; i < 8; i++) photo('p$i', i)]),
      );

      expect(find.byKey(const ValueKey('add-photo')), findsNothing);
      expect(find.textContaining('8 of 8'), findsOneWidget);
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
      // The bed's own chip, in the dashboard's words. It said "Maintenance",
      // which is also the name of the tab where tenants report things broken.
      expect(
        find.descendant(
            of: find.byType(StatusChip), matching: find.text('Out of service')),
        findsOneWidget,
      );
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
      // The bed's own chip, in the dashboard's words. It said "Maintenance",
      // which is also the name of the tab where tenants report things broken.
      expect(
        find.descendant(
            of: find.byType(StatusChip), matching: find.text('Out of service')),
        findsOneWidget,
      );
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
      expect(find.text('₱2,000'), findsOneWidget);
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
      expect(find.text('₱20,000'), findsOneWidget);

      await tester.tap(find.text('Floor 2'));
      await tester.pumpAndSettle();

      expect(find.text('Unit 2A'), findsOneWidget);
      expect(find.text('Unit 2B'), findsOneWidget);
      expect(find.text('Unit 1A'), findsNothing);

      // The figures describe the floor now, and the title says so, or the
      // header would be a property total sitting over one floor's list.
      expect(find.text('Floor 2'), findsWidgets);
      expect(find.text('₱13,000'), findsOneWidget);
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
      expect(find.text('₱15,000'), findsOneWidget);
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
      expect(find.text('₱7,000'), findsWidgets);
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

      expect(find.text('A fixed ₱1,700 each month'), findsOneWidget);
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
      expect(find.text('₱1,700'), findsOneWidget);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();

      expect(find.text('₱2,000'), findsOneWidget);
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
            collectionsProvider.overrideWith((ref) async => CollectionsSummary(
                  dueThisMonth: 0,
                  collectedThisMonth: 0,
                  outstandingAllTime: 0,
                  awaitingConfirmation: 0,
                  tenanciesInArrears: 0,
                )),
            occupancyProvider.overrideWith((ref) async => OccupancySummary(
                  lettable: 0,
                  occupied: 0,
                  empty: 0,
                  outOfService: 0,
                  earningRent: 0,
                  emptyRent: 0,
                )),
          ],
          child: const LizmoApp(),
        );

    testWidgets('five sections, opening on Today', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tab-today')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-rent')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-properties')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-tenants')), findsOneWidget);
      expect(find.byKey(const ValueKey('tab-maintenance')), findsOneWidget);
      expect(find.byType(LandlordHomeScreen), findsOneWidget);
    });

    /// It was on Today, Rent and Maintenance only, so news went unread on the
    /// two tabs a landlord spends most of their time in.
    testWidgets('every tab carries the bell', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      for (final tab in [
        'tab-today',
        'tab-rent',
        'tab-properties',
        'tab-tenants',
        'tab-maintenance',
      ]) {
        await tester.tap(find.byKey(ValueKey(tab)));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('notification-bell')), findsOneWidget,
            reason: 'no bell on $tab');
      }
    });

    /// Collections was a placeholder reading "Needs leases and billing" from
    /// the first day this screen existed. Both now exist, so the promise is
    /// gone -- while the parts genuinely unbuilt still say so.
    testWidgets('Today counts what is waiting, not what is owned',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('To answer'), findsOneWidget);
      expect(find.text('To confirm'), findsOneWidget);
      expect(find.text('Behind'), findsOneWidget);

      // The Properties tab's own figures are no longer repeated here.
      expect(find.text('Per month'), findsNothing);
      expect(find.text('₱10,000'), findsNothing);

      // And the last placeholder, from before leases existed, is gone.
      expect(find.text('Coming up'), findsNothing);
      expect(find.text('Needs leases'), findsNothing);

      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Occupancy'), findsOneWidget);
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

  group('a version too old to be used', () {
    const play = 'https://play.google.com/store/apps/details?id=app.lizmo';
    const appStore = 'https://apps.apple.com/app/lizmo';

    Widget appOn(
      String installed, {
      AppVersion? allowed,
      bool fails = false,
      List<Uri>? opened,
    }) =>
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            appVersionApiProvider.overrideWithValue(
                _FakeVersionApi(answer: allowed, fails: fails)),
            installedVersionProvider.overrideWithValue(() async => installed),
            openLinkProvider.overrideWithValue((uri) async {
              opened?.add(uri);
              return true;
            }),
            propertiesProvider
                .overrideWith((ref) async => const <PropertyResponse>[]),
            myTenantProfileProvider.overrideWith((ref) async =>
                TenantProfileResponse(
                    contactPhone: '09170000001', readyForALease: true)),
            myTenantDocumentsProvider
                .overrideWith((ref) async => const <TenantDocumentResponse>[]),
            myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
          ],
          child: const LizmoApp(),
        );

    /// Signed in, and stopped anyway: a version we have refused is one whose
    /// payments we would rather it did not send.
    testWidgets('an older version is stopped, session or no session',
        (tester) async {
      await tester.pumpWidget(appOn('1.1.0',
          allowed: AppVersion(
              minimumAndroidVersion: '1.1.1', androidUpdateUrl: play)));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateScreen), findsOneWidget);
      expect(find.byType(TenantHomeScreen), findsNothing);
      expect(find.text('Time to update Lizmo'), findsOneWidget);
    });

    /// What a string comparison gets wrong, and the reason this is done part
    /// by part.
    testWidgets('1.9.0 is older than 1.10.0', (tester) async {
      await tester.pumpWidget(appOn('1.9.0',
          allowed: AppVersion(
              minimumAndroidVersion: '1.10.0', androidUpdateUrl: play)));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateScreen), findsOneWidget);
    });

    testWidgets('the oldest allowed version itself carries on', (tester) async {
      await tester.pumpWidget(appOn('1.1.1',
          allowed: AppVersion(
              minimumAndroidVersion: '1.1.1', androidUpdateUrl: play)));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(UpdateScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('a newer version carries on', (tester) async {
      await tester.pumpWidget(appOn('2.0.0',
          allowed: AppVersion(
              minimumAndroidVersion: '1.1.1', androidUpdateUrl: play)));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    /// A missing part is a zero, so these are one version rather than two.
    testWidgets('1.1 and 1.1.0 are the same version', (tester) async {
      await tester.pumpWidget(appOn('1.1',
          allowed: AppVersion(
              minimumAndroidVersion: '1.1.0', androidUpdateUrl: play)));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    /// What every operator has until they set one.
    testWidgets('no minimum for this platform turns the check off',
        (tester) async {
      await tester.pumpWidget(appOn('1.0.0',
          allowed: AppVersion(androidUpdateUrl: play)));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    /// The two platforms ship apart, so an Android minimum says nothing about
    /// an iPhone -- which may be waiting on a review that has not cleared.
    testWidgets("an iPhone ignores Android's minimum", (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(appOn('1.0.0',
            allowed: AppVersion(
                minimumAndroidVersion: '2.0.0',
                androidUpdateUrl: play,
                iosUpdateUrl: appStore)));
        await tester.pumpAndSettle();
        await _openProperties(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(find.byType(UpdateScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('an iPhone is stopped by its own minimum, and sent to the '
        'App Store', (tester) async {
      final opened = <Uri>[];
      // Put back before the body ends: the binding checks these are unset
      // before any tearDown of ours runs.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(appOn('1.0.0',
            allowed: AppVersion(
                minimumAndroidVersion: '',
                minimumIosVersion: '1.1.0',
                androidUpdateUrl: play,
                iosUpdateUrl: appStore),
            opened: opened));
        await tester.pumpAndSettle();

        expect(find.byType(UpdateScreen), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('open-update-link')));
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(opened, [Uri.parse(appStore)]);
    });

    /// Being locked out of your own tenancy because a request failed is worse
    /// than running a version we would rather you had replaced.
    testWidgets('a check that fails opens the app', (tester) async {
      await tester.pumpWidget(appOn('1.0.0', fails: true));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(UpdateScreen), findsNothing);
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    /// The console refuses these, but a row written by hand could still carry
    /// one, and it must not lock out every phone.
    testWidgets('a version nobody can read opens the app', (tester) async {
      await tester.pumpWidget(appOn('1.0.0',
          allowed: AppVersion(
              minimumAndroidVersion: 'latest', androidUpdateUrl: play)));
      await tester.pumpAndSettle();
      await _openProperties(tester);

      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('the button opens the Android link', (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(appOn('1.0.0',
          allowed: AppVersion(
              minimumAndroidVersion: '1.1.1',
              androidUpdateUrl: play,
              iosUpdateUrl: appStore),
          opened: opened));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open-update-link')));
      await tester.pumpAndSettle();

      expect(opened, [Uri.parse(play)]);
    });

    /// A button that opens nothing is worse than no button: it reads as the
    /// app being broken rather than as an update being due.
    testWidgets('no link for this platform means no button', (tester) async {
      await tester.pumpWidget(appOn('1.0.0',
          allowed: AppVersion(
              minimumAndroidVersion: '1.1.1', iosUpdateUrl: appStore)));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('open-update-link')), findsNothing);
      expect(find.textContaining('from your app store'), findsOneWidget);
    });

    /// Nothing else can be reached while the app is refused, including by a
    /// stale deep link.
    testWidgets('no route gets past the update screen', (tester) async {
      final container = ProviderContainer(overrides: [
        authControllerProvider
            .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        appVersionApiProvider.overrideWithValue(_FakeVersionApi(
            answer: AppVersion(
                minimumAndroidVersion: '1.1.1', androidUpdateUrl: play))),
        installedVersionProvider.overrideWithValue(() async => '1.0.0'),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const LizmoApp()));
      await tester.pumpAndSettle();

      container.read(routerProvider).go(Routes.tenantHome);
      await tester.pumpAndSettle();
      expect(find.byType(UpdateScreen), findsOneWidget);

      container.read(routerProvider).go(Routes.login);
      await tester.pumpAndSettle();
      expect(find.byType(UpdateScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('comparing two versions', () {
    test('part by part, not as text', () {
      expect(compareVersions('1.9.0', '1.10.0'), isNegative);
      expect(compareVersions('1.10.0', '1.9.0'), isPositive);
      expect(compareVersions('2.0.0', '1.99.99'), isPositive);
    });

    test('a missing part is a zero', () {
      expect(compareVersions('1.1', '1.1.0'), 0);
      expect(compareVersions('1', '1.0.0'), 0);
      expect(compareVersions('1.1', '1.1.1'), isNegative);
    });

    /// Null, so the caller opens the app rather than deciding on nonsense.
    test('anything that is not digits and dots is null', () {
      expect(compareVersions('v1.1.1', '1.1.1'), isNull);
      expect(compareVersions('1.1.1', '1.0.0-beta'), isNull);
      expect(compareVersions('', '1.0.0'), isNull);
      expect(compareVersions('latest', '1.0.0'), isNull);
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
  group('waiting on a landlord', () {
    Widget appWith(InquirySummary thread) => ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            myTenantProfileProvider.overrideWith((ref) async =>
                TenantProfileResponse(
                    contactPhone: '09170000001', readyForALease: true)),
            myTenantDocumentsProvider
                .overrideWith((ref) async => const <TenantDocumentResponse>[]),
            myNotificationsProvider
                .overrideWith((ref) async => const <NotificationResponse>[]),
            myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
            myInquiriesProvider.overrideWith((ref) async => [thread]),
          ],
          child: const LizmoApp(),
        );

    InquirySummary asked({String? lastMessage, bool unread = false}) =>
        InquirySummary(
          id: 'i1',
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          withName: 'Elena Bautista',
          status: InquirySummaryStatusEnum.OPEN,
          lastMessage: lastMessage,
          unread: unread,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

    /// Nothing said yet: the card is the nudge to say something, since a
    /// conversation nobody has opened is the one a landlord never answers.
    testWidgets('a conversation with nothing in it asks for a word',
        (tester) async {
      await tester.pumpWidget(appWith(asked()));
      await tester.pumpAndSettle();

      expect(find.textContaining('null'), findsNothing);
      expect(find.text('Waiting for a reply'), findsOneWidget);
      expect(find.textContaining('Say what you are looking for'), findsOneWidget);
    });

    testWidgets('a reply is said plainly, with what they wrote', (tester) async {
      await tester.pumpWidget(appWith(
          asked(lastMessage: 'Yes, from the 15th', unread: true)));
      await tester.pumpAndSettle();

      expect(find.text('They have replied'), findsOneWidget);
      expect(find.textContaining('Yes, from the 15th'), findsOneWidget);
    });
  });

  group('tenant profile', () {
    Widget appWith(
      TenantProfileResponse profile, {
      _RecordingTenantProfileApi? api,
      List<TenantDocumentResponse> documents = const [],
      List<InquirySummary> threads = const [],
    }) =>
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn({LizmoProfile.tenant}))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            myTenantProfileProvider.overrideWith((ref) async => profile),
            myTenantDocumentsProvider.overrideWith((ref) async => documents),
            myInquiriesProvider.overrideWith((ref) async => threads),
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
          contactPhone: '09170000001',
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

    /// Without a number they cannot ask about a room at all, which is the
    /// more urgent of the two gaps.
    testWidgets('the home screen asks for a number when there is none',
        (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await tester.pumpAndSettle();

      expect(find.text('Add your mobile number'), findsOneWidget);
    });

    /// It used to nag anybody whose profile was unfinished, whether or not
    /// anything was waiting on it. Nothing is, until they have asked.
    testWidgets('an unfinished profile with nothing waiting is left alone',
        (tester) async {
      await tester.pumpWidget(appWith(
        TenantProfileResponse(contactPhone: '09170000001', readyForALease: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add your mobile number'), findsNothing);
      expect(find.text('A landlord is waiting on you'), findsNothing);
    });

    testWidgets('a conversation waiting on an unfinished profile says who is '
        'held up', (tester) async {
      await tester.pumpWidget(appWith(
        TenantProfileResponse(contactPhone: '09170000001', readyForALease: false),
        threads: [
          InquirySummary(
            id: 'i1',
            propertyId: 'p1',
            propertyName: 'Sunrise Apartments',
            withName: 'Elena Bautista',
            status: InquirySummaryStatusEnum.OPEN,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('A landlord is waiting on you'), findsOneWidget);
      expect(find.textContaining('cannot be accepted until you add'), findsOneWidget);
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
      await tester.tap(find.text('Add my number'));
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
      // Typed, not read out: the field is the same box somebody edits.
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('birthdate-field')))
            .controller
            ?.text,
        '04/12/1998',
      );
      expect(find.text('PhilSys (National ID)'), findsWidgets);
    });

    testWidgets('an unset birthdate is empty, never today', (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('birthdate-field')))
            .controller
            ?.text,
        isEmpty,
      );
      // And says what shape to type it in, rather than leaving them guessing.
      expect(find.text('MM/DD/YYYY'), findsOneWidget);
    });

    /// The reason this field exists: scrolling a calendar back to 1998 is
    /// miserable, and the picker's own keyboard mode refused what it was given.
    testWidgets('a birthday can be typed', (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      await tester.enterText(
          find.byKey(const ValueKey('birthdate-field')), '04121998');
      await tester.pump();

      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('birthdate-field')))
            .controller
            ?.text,
        '04/12/1998',
      );
    });

    testWidgets('the banner says what a lease still needs', (tester) async {
      await tester.pumpWidget(appWith(
        TenantProfileResponse(contactPhone: '09170000001', readyForALease: false),
      ));
      await openProfile(tester);

      // Named rather than counted, and in the order the form asks for them.
      expect(
        find.textContaining('an emergency contact, your ID details '
            'and a photo of your ID'),
        findsOneWidget,
      );
    });

    /// The gate in front of asking, which comes before any of the rest.
    testWidgets('with no number the banner asks for that first', (tester) async {
      await tester.pumpWidget(appWith(TenantProfileResponse(readyForALease: false)));
      await openProfile(tester);

      expect(find.textContaining('Add your mobile number so you can ask about a room'),
          findsOneWidget);
    });

    testWidgets('the number is saved with the rest of the profile',
        (tester) async {
      final api = _RecordingTenantProfileApi(complete());
      await tester.pumpWidget(appWith(complete(), api: api));
      await openProfile(tester);

      await tester.enterText(
          find.byKey(const ValueKey('contact-phone')), '09991112222');
      await saveProfile(tester);

      expect(api.saved?.contactPhone, '09991112222');
    });

    testWidgets('the banner clears as the last field is filled in',
        (tester) async {
      // Everything, the ID photograph included, but the ID number.
      await tester.pumpWidget(appWith(
        TenantProfileResponse(
          contactPhone: '09170000001',
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
      await tester.pumpWidget(appWith(complete()));
      await openProfile(tester);

      // Every detail typed in, and still not ready: an ID number typed into a
      // form is not an ID anybody has seen.
      expect(find.textContaining('a photo of your ID'), findsOneWidget);
      expect(find.text('Your profile is ready for a lease.'), findsNothing);
    });

    /// A 1x1 used to be demanded as well, from somebody who had not moved in.
    testWidgets('a selfie is no longer part of being ready', (tester) async {
      await tester.pumpWidget(appWith(
        complete(),
        documents: [photograph(TenantDocumentResponseDocTypeEnum.VALID_ID)],
      ));
      await openProfile(tester);

      expect(find.text('Your profile is ready for a lease.'), findsOneWidget);
    });

    testWidgets('details and the ID photograph together are what ready means',
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

/// Records what a tenant asked about, and can refuse the way the API does.
class _FakeAskingApi extends AskingAboutAPlaceApi {
  _FakeAskingApi({this.failWith});

  final ApiFailure? failWith;
  StartInquiry? sent;

  @override
  Future<InquiryThread?> startInquiry(
    StartInquiry startInquiry, {
    Future<void>? abortTrigger,
  }) async {
    if (failWith != null) throw failWith!;
    sent = startInquiry;
    return InquiryThread(
      inquiry: InquirySummary(
        id: 'i1',
        propertyId: startInquiry.propertyId,
        propertyName: 'Sunrise Apartments',
        status: InquirySummaryStatusEnum.OPEN,
      ),
      messages: const [],
    );
  }

  @override
  Future<InquiryThread?> readInquiry(String id, {Future<void>? abortTrigger}) async =>
      InquiryThread(
        inquiry: InquirySummary(
          id: id,
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          status: InquirySummaryStatusEnum.OPEN,
        ),
        messages: const [],
      );

  @override
  Future<List<InquirySummary>?> listMyInquiries({
    Future<void>? abortTrigger,
  }) async => const [];
}

void _findingAPlaceTests() {
  group('finding a place', () {
    PropertyByCodeResponse place({
      int beds = 0,
      int units = 0,
      num? cheapest = 2500,
      num? dearest,
      bool utilitiesOnTop = false,
      String? floor = '2',
      List<String> photos = const [],
    }) => PropertyByCodeResponse(
      photos: photos,
      id: 'p1',
      code: 'PHK7M4Q2',
      name: 'Sunrise Apartments',
      address: '12 Mabini St',
      type: PropertyByCodeResponseTypeEnum.BOARDING_HOUSE,
      usage: PropertyByCodeResponseUsageEnum.RESIDENTIAL,
      vacantWholeUnits: units,
      vacantBeds: beds,
      floors: [
        if (beds > 0 || units > 0)
          VacancyFloor(
            floor: floor,
            wholeUnits: units,
            beds: beds,
            cheapestRent: cheapest,
            dearestRent: dearest ?? cheapest,
            utilitiesOnTop: utilitiesOnTop,
          ),
      ],
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
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        propertyByCodeProvider('PHK7M4Q2').overrideWith((ref) async {
          if (lookupFails != null) throw lookupFails;
          return found ?? place();
        }),
        if (asking != null) inquiriesApiProvider.overrideWithValue(asking),
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
      await tester.tap(find.text('See what is vacant'));
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

    testWidgets('a code finds the place and how much is vacant', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 3)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.text('Sunrise Apartments'), findsWidgets);
      expect(find.text('12 Mabini St'), findsOneWidget);
      expect(find.text('3 spaces vacant'), findsOneWidget);
      expect(find.text('2nd floor'), findsOneWidget);
      expect(find.text('3 bedspaces vacant'), findsOneWidget);
    });

    /// The landlord types this field themselves. A number becomes an ordinary
    /// English floor; a word stands as they wrote it, because "Roof deck
    /// floor" is not a thing anybody says.
    testWidgets('a floor is named the way it is said', (tester) async {
      for (final (written, shown) in [
        ('1', '1st floor'),
        ('2', '2nd floor'),
        ('3', '3rd floor'),
        ('4', '4th floor'),
        ('11', '11th floor'),
        ('21', '21st floor'),
        ('Ground', 'Ground'),
        ('Mezzanine', 'Mezzanine'),
      ]) {
        await tester.pumpWidget(
            appWith(found: place(beds: 2, floor: written)));
        await openFind(tester);
        await enterCode(tester, 'PHK7M4Q2');

        expect(find.text(shown), findsOneWidget,
            reason: 'a floor written "$written" should read "$shown"');
      }
    });

    /// Nothing says it, so it is not claimed to be the second floor either.
    testWidgets('a floor nobody named is ground level', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 2, floor: null)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.text('Ground level'), findsOneWidget);
    });

    /// The whole point: somebody with the code learns how much is vacant and
    /// what it costs, not which rooms exist or which one is empty.
    testWidgets('no room is named to somebody with the code', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 3, units: 1)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.textContaining('Bed '), findsNothing);
      expect(find.textContaining('Unit '), findsNothing);
      expect(find.text('1 unit and 3 bedspaces vacant'), findsOneWidget);
    });

    testWidgets('one price reads as one price, two as a range', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 2)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');
      expect(find.text('\u20b12,500'), findsOneWidget);

      await tester.pumpWidget(
          appWith(found: place(beds: 2, cheapest: 2500, dearest: 3200)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');
      expect(find.text('\u20b12,500\u2013\u20b13,200'), findsOneWidget);
    });

    /// A rent runs to five figures, and 7500 against 75000 is a difference
    /// nobody should have to count digits to see.
    testWidgets('a five-figure rent is grouped', (tester) async {
      await tester.pumpWidget(
          appWith(found: place(beds: 1, cheapest: 12500, dearest: 12500)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.text('\u20b112,500'), findsOneWidget);
    });

    /// The reason photographs exist: somebody deciding whether to spend an
    /// afternoon travelling across town to look at a place.
    testWidgets('the place is shown before it is described', (tester) async {
      await tester.pumpWidget(appWith(
          found: place(beds: 2, photos: const [
        'https://example.invalid/front.jpg',
        'https://example.invalid/kitchen.jpg',
      ])));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      final photos = find.byKey(const ValueKey('property-photos'));
      expect(photos, findsOneWidget);
      // Above the address, which is the order somebody reads them in.
      expect(tester.getTopLeft(photos).dy,
          lessThan(tester.getTopLeft(find.text('12 Mabini St')).dy));
    });

    /// Most places have none, and an empty strip would be a grey box where
    /// the building should be.
    testWidgets('a place with no photos shows no strip', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 2)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.byKey(const ValueKey('property-photos')), findsNothing);
      expect(find.text('12 Mabini St'), findsOneWidget);
    });

    testWidgets('a full house says so rather than showing nothing', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(found: place(beds: 0)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      // No vacancy is a real answer, not an empty screen.
      expect(find.text('No vacant at the moment'), findsOneWidget);
    });

    /// Rent alone is not what a tenant hands over, and utilities are charged
    /// per unit, so they are flagged rather than added to a bed's price.
    testWidgets('utilities charged on top are flagged', (tester) async {
      await tester.pumpWidget(
          appWith(found: place(beds: 2, utilitiesOnTop: true)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.textContaining('+ utilities'), findsOneWidget);
    });

    testWidgets('utilities folded into the rent are not flagged', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 2)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.textContaining('+ utilities'), findsNothing);
    });

    testWidgets('an unpriced floor says so rather than reading as vacant', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(found: place(beds: 1, cheapest: null)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.text('Price not set'), findsOneWidget);
    });

    /// The button starts the conversation and drops the tenant into it: the
    /// next thing to do is say what they are looking for, and a tenant left on
    /// the vacancy screen has nowhere to say it.
    testWidgets('asking names the place and opens the conversation',
        (tester) async {
      final asking = _FakeAskingApi();
      await tester.pumpWidget(
        appWith(found: place(beds: 2), asking: asking),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      await tester.tap(find.byKey(const ValueKey('ask-about-place')));
      await tester.pumpAndSettle();

      expect(asking.sent?.propertyId, 'p1');
      expect(find.byType(InquiryScreen), findsOneWidget);
    });

    testWidgets('a full house offers nothing to ask for', (tester) async {
      await tester.pumpWidget(appWith(found: place(beds: 0)));
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      expect(find.byKey(const ValueKey('ask-about-place')), findsNothing);
    });

    /// It used to send them to a profile form and leave them to find their
    /// way back. A number is the whole of what asking takes, so it is asked
    /// on the room they are looking at.
    testWidgets('a tenant with no number is asked for one, here', (
      tester,
    ) async {
      final asking = _FakeAskingApi(
        failWith: const ApiFailure(
          code: 'TENANT_PROFILE_INCOMPLETE',
          // What the server actually says.
          message: 'Add a phone number before asking about a room.',
        ),
      );
      await tester.pumpWidget(
        appWith(found: place(beds: 2), asking: asking),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      await tester.tap(find.byKey(const ValueKey('ask-about-place')));
      // Not pumpAndSettle: the sheet's field takes focus, and a blinking
      // cursor never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('What number can the landlord ring?'), findsOneWidget);
      expect(find.byKey(const ValueKey('ask-phone-field')), findsOneWidget);
    });

    testWidgets('a place filled while reading is shown as it happened', (
      tester,
    ) async {
      final asking = _FakeAskingApi(
        failWith: const ApiFailure(
          code: 'SLOT_UNAVAILABLE',
          message: 'Nothing is free here at the moment.',
        ),
      );
      await tester.pumpWidget(
        appWith(found: place(beds: 2), asking: asking),
      );
      await openFind(tester);
      await enterCode(tester, 'PHK7M4Q2');

      await tester.tap(find.byKey(const ValueKey('ask-about-place')));
      await tester.pumpAndSettle();

      expect(find.text('Nothing is free here at the moment.'), findsOneWidget);
      // And no conversation was opened, because none was started.
      expect(find.byType(InquiryScreen), findsNothing);
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

/// Stands in for the conversation endpoints: records what was said, what was
/// closed, and the terms a tenancy was written on.
class _FakeInquiriesApi extends AskingAboutAPlaceApi {
  _FakeInquiriesApi({
    this.thread,
    this.failWith,
  });

  InquiryThread? thread;
  final ApiFailure? failWith;

  final said = <String>[];
  String? closed;
  String? leased;
  AcceptRequest? leasedOn;
  StartInquiry? started;

  int reads = 0;

  @override
  Future<InquiryThread?> readInquiry(String id, {Future<void>? abortTrigger}) async {
    reads++;
    if (thread == null) {
      throw const ApiFailure(code: 'NOT_FOUND', message: 'No such conversation.');
    }
    return thread;
  }

  @override
  Future<InquiryMessageResponse?> sendInquiryMessage(
    String id,
    NewMessage newMessage, {
    Future<void>? abortTrigger,
  }) async {
    if (failWith != null) throw failWith!;
    said.add(newMessage.body);
    return InquiryMessageResponse(
      id: 'm${said.length}',
      body: newMessage.body,
      sentAt: DateTime.now(),
      mine: true,
    );
  }

  @override
  Future<LeaseResponse?> startLeaseFromInquiry(
    String id, {
    AcceptRequest? acceptRequest,
    Future<void>? abortTrigger,
  }) async {
    if (failWith != null) throw failWith!;
    leased = id;
    leasedOn = acceptRequest;
    return LeaseResponse(id: 'l1', status: LeaseResponseStatusEnum.ACTIVE);
  }

  @override
  Future<InquirySummary?> closeInquiry(String id, {Future<void>? abortTrigger}) async {
    closed = id;
    return InquirySummary(id: id, status: InquirySummaryStatusEnum.CLOSED);
  }

  @override
  Future<InquiryThread?> startInquiry(
    StartInquiry startInquiry, {
    Future<void>? abortTrigger,
  }) async {
    if (failWith != null) throw failWith!;
    started = startInquiry;
    return InquiryThread(
      inquiry: InquirySummary(
        id: 'i1',
        propertyId: startInquiry.propertyId,
        propertyName: 'Sunrise Apartments',
        status: InquirySummaryStatusEnum.OPEN,
      ),
      messages: const [],
    );
  }
}

void _landlordRequestTests() {
  group('a conversation about a place', () {
    PropertyResponse property() => PropertyResponse(
      id: 'p1',
      name: 'Sunrise Apartments',
      address: '12 Mabini St',
      code: 'PHK7M4Q2',
      type: PropertyResponseTypeEnum.BOARDING_HOUSE,
      usage: PropertyResponseUsageEnum.RESIDENTIAL,
      unitCount: 1,
    );

    InquirySummary summary({
      String id = 'i1',
      String withName = 'Ana Reyes',
      InquirySummaryStatusEnum status = InquirySummaryStatusEnum.OPEN,
      String? lastMessage = 'Is there a bed free in November?',
      bool unread = true,
    }) =>
        InquirySummary(
          id: id,
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          withName: withName,
          status: status,
          lastMessage: lastMessage,
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
          unread: unread,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        );

    Applicant applicant({List<String> stillNeeds = const []}) => Applicant(
          tenantId: 't1',
          name: 'Ana Reyes',
          phone: '09171234567',
          age: 27,
          occupation: 'Nurse',
          permanentAddress: 'Naga City',
          idType: ApplicantIdTypeEnum.PHILSYS,
          stillNeeds: stillNeeds,
        );

    InquiryThread thread({
      Applicant? who,
      InquirySummaryStatusEnum status = InquirySummaryStatusEnum.OPEN,
      List<InquiryMessageResponse>? messages,
    }) =>
        InquiryThread(
          inquiry: summary(status: status),
          applicant: who,
          messages: messages ??
              [
                InquiryMessageResponse(
                  id: 'm1',
                  body: 'Is there a bed free in November?',
                  sentAt: DateTime.now().subtract(const Duration(hours: 3)),
                  mine: who == null,
                ),
                InquiryMessageResponse(
                  id: 'm2',
                  body: 'Yes, from the 15th. Want to see it Saturday?',
                  sentAt: DateTime.now().subtract(const Duration(hours: 2)),
                  mine: who != null,
                ),
              ],
        );

    Widget appWith({
      required _FakeInquiriesApi api,
      Set<LizmoProfile> profiles = const {LizmoProfile.landlord},
      List<InquirySummary> inbox = const [],
      List<FreeRoom> free = const [],
    }) =>
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuth(_signedIn(profiles))),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesProvider.overrideWith((ref) async => [property()]),
            propertyProvider('p1').overrideWith((ref) async => property()),
            unitsProvider('p1')
                .overrideWith((ref) async => const <UnitResponse>[]),
            propertyLeasesProvider('p1')
                .overrideWith((ref) async => const <LeaseResponse>[]),
            freeRoomsProvider('p1').overrideWith((ref) async => free),
            myTenantProfileProvider.overrideWith((ref) async =>
                TenantProfileResponse(
                    contactPhone: '09170000001', readyForALease: true)),
            myTenantDocumentsProvider
                .overrideWith((ref) async => const <TenantDocumentResponse>[]),
            myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
            myInquiriesProvider.overrideWith((ref) async => inbox),
            inquiriesApiProvider.overrideWithValue(api),
          ],
          child: const LizmoApp(),
        );

    /// The landlord's conversations live in the Asking half of Tenants.
    Future<void> openAsking(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-tenants')));
      await tester.pumpAndSettle();
      // The header stat is also labelled Asking; the segment is the one
      // inside the control.
      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('tenants-segment')),
        matching: find.textContaining('Inquiries'),
      ));
      await tester.pumpAndSettle();
    }

    /// Opens the thread through the app, the way a tap on Today's card does.
    Future<void> open(WidgetTester tester, _FakeInquiriesApi api,
        {Set<LizmoProfile> profiles = const {LizmoProfile.landlord},
        List<FreeRoom> free = const []}) async {
      await tester.pumpWidget(appWith(
          api: api, profiles: profiles, free: free, inbox: [summary()]));
      await tester.pumpAndSettle();

      if (profiles.contains(LizmoProfile.landlord)) {
        await tester.tap(find.byKey(const ValueKey('inquiry-i1')));
      } else {
        await tester.tap(find.text('Open'));
      }
      await tester.pumpAndSettle();
    }

    // ---- reading one ------------------------------------------------------

    testWidgets('both sides of the conversation are there, in order',
        (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      expect(find.text('Is there a bed free in November?'), findsOneWidget);
      expect(find.text('Yes, from the 15th. Want to see it Saturday?'),
          findsOneWidget);
      expect(find.byType(InquiryScreen), findsOneWidget);
    });

    /// The ID type without its number, no photographs, no emergency contact.
    /// Anyone can print a code and stick it on a gate.
    testWidgets('the landlord sees who is asking', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      expect(find.byKey(const ValueKey('applicant')), findsOneWidget);
      expect(find.text('Ana Reyes'), findsWidgets);
      expect(find.textContaining('27 years old'), findsOneWidget);
      expect(find.text('09171234567'), findsOneWidget);
    });

    testWidgets('the tenant sees no panel about themselves', (tester) async {
      final api = _FakeInquiriesApi(thread: thread());
      await open(tester, api, profiles: {LizmoProfile.tenant});

      expect(find.byKey(const ValueKey('applicant')), findsNothing);
      expect(find.byKey(const ValueKey('start-lease')), findsNothing);
    });

    // ---- saying something -------------------------------------------------

    testWidgets('a message is sent and the box emptied', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      await tester.enterText(find.byKey(const ValueKey('message-field')),
          'Saturday at two suits me');
      await tester.tap(find.byKey(const ValueKey('send-message')));
      await tester.pumpAndSettle();

      expect(api.said, ['Saturday at two suits me']);
      expect(
          tester.widget<TextField>(find.byKey(const ValueKey('message-field')))
              .controller!
              .text,
          isEmpty);
    });

    testWidgets('an empty message is not sent', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      await tester.enterText(find.byKey(const ValueKey('message-field')), '   ');
      await tester.tap(find.byKey(const ValueKey('send-message')));
      await tester.pumpAndSettle();

      expect(api.said, isEmpty);
    });

    testWidgets('a message that fails says so and keeps the words',
        (tester) async {
      final api = _FakeInquiriesApi(
        thread: thread(who: applicant()),
        failWith: const ApiFailure(code: 'NETWORK', message: 'No connection.'),
      );
      await open(tester, api);

      await tester.enterText(
          find.byKey(const ValueKey('message-field')), 'Still interested');
      await tester.tap(find.byKey(const ValueKey('send-message')));
      await tester.pumpAndSettle();

      expect(find.text('No connection.'), findsOneWidget);
      // Retyping what you just wrote is the worst possible answer to a
      // failed send.
      expect(
          tester.widget<TextField>(find.byKey(const ValueKey('message-field')))
              .controller!
              .text,
          'Still interested');
    });

    // ---- writing the tenancy ----------------------------------------------

    testWidgets('a tenant who has not finished cannot be leased to yet',
        (tester) async {
      final api = _FakeInquiriesApi(
          thread: thread(who: applicant(stillNeeds: ['an emergency contact'])));
      await open(tester, api);

      expect(find.byKey(const ValueKey('tenant-still-needs')), findsOneWidget);
      expect(find.textContaining('an emergency contact'), findsOneWidget);
      expect(
          tester
              .widget<PrimaryActionButton>(
                  find.byKey(const ValueKey('start-lease')))
              .onPressed,
          isNull);
    });

    testWidgets('the landlord picks the room, and it is sent with the rent',
        (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api, free: const [
        FreeRoom(unitId: 'u1', bedId: 'b1', label: 'Unit 2B · Bed 1', rent: 2500),
        FreeRoom(unitId: 'u2', bedId: null, label: 'Unit 3A', rent: 12500),
      ]);

      await tester.tap(find.byKey(const ValueKey('start-lease')));
      await tester.pumpAndSettle();

      // The tenant was never shown the rooms, so this is where one is chosen.
      expect(find.text('Which room'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('room-b1')));
      await tester.pumpAndSettle();

      // The sheet is taller than the phone: the button is below the fold.
      final accept = find.byKey(const ValueKey('accept-and-create'));
      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      await tester.tap(accept);
      await tester.pumpAndSettle();

      expect(api.leased, 'i1');
      expect(api.leasedOn?.unitId, 'u1');
      expect(api.leasedOn?.bedId, 'b1');
      expect(api.leasedOn?.rentAmount, 2500);
    });

    testWidgets('a conversation that already has a tenancy says so',
        (tester) async {
      final api = _FakeInquiriesApi(
          thread: thread(
              who: applicant(), status: InquirySummaryStatusEnum.LEASED));
      await open(tester, api);

      expect(find.byKey(const ValueKey('already-leased')), findsOneWidget);
      expect(find.byKey(const ValueKey('start-lease')), findsNothing);
      // Still talking, though: it is the same two people.
      expect(find.byKey(const ValueKey('message-field')), findsOneWidget);
    });

    // ---- ending it --------------------------------------------------------

    testWidgets('closing asks first, and backing out closes nothing',
        (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      await tester.tap(find.byKey(const ValueKey('close-inquiry')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it open'));
      await tester.pumpAndSettle();
      expect(api.closed, isNull);

      await tester.tap(find.byKey(const ValueKey('close-inquiry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-close-inquiry')));
      await tester.pumpAndSettle();

      expect(api.closed, 'i1');
    });

    testWidgets('a closed conversation takes nothing more', (tester) async {
      final api = _FakeInquiriesApi(
          thread: thread(
              who: applicant(), status: InquirySummaryStatusEnum.CLOSED));
      await open(tester, api);

      expect(find.byKey(const ValueKey('inquiry-closed')), findsOneWidget);
      expect(find.byKey(const ValueKey('message-field')), findsNothing);
      expect(find.byKey(const ValueKey('close-inquiry')), findsNothing);
    });

    // ---- the way in -------------------------------------------------------

    testWidgets('Today lists who is waiting on an answer', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api, inbox: [
        summary(),
        summary(id: 'i2', withName: 'Bea Santos', unread: false),
      ]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inquiries-card')), findsOneWidget);
      expect(find.text('1 waiting on you'), findsOneWidget);
      expect(find.text('Ana Reyes'), findsWidgets);
      expect(find.text('Bea Santos'), findsOneWidget);
    });

    testWidgets('nobody asking leaves the card off Today', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inquiries-card')), findsNothing);
    });

    testWidgets('a conversation on Today opens it', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      expect(find.byType(InquiryScreen), findsOneWidget);
    });

    /// Lizmo has no live connection, so an open conversation reads itself
    /// again while somebody is in it. Without this, two people typing at
    /// each other saw nothing until one of them pulled down.
    testWidgets('an open conversation keeps itself current', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await open(tester, api);

      final onOpening = api.reads;

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(api.reads, onOpening + 1);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(api.reads, onOpening + 2);
    });

    /// A dot and a shade of grey was thin for the one thing this list is
    /// read to find.
    testWidgets('an unread conversation is named in bold', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api, inbox: [
        summary(),
        summary(id: 'i2', withName: 'Bea Santos', unread: false),
      ]));
      await tester.pumpAndSettle();
      await openAsking(tester);

      TextStyle nameIn(String id, String who) => tester
          .widget<Text>(find.descendant(
            of: find.byKey(ValueKey('thread-$id')),
            matching: find.text(who),
          ))
          .style!;

      expect(nameIn('i1', 'Ana Reyes').fontWeight, FontWeight.w700);
      expect(nameIn('i2', 'Bea Santos').fontWeight, FontWeight.w500);
    });

    /// Without it you cannot tell this morning's unanswered message from one
    /// three weeks old, which is what decides who gets answered first.
    testWidgets('each row says how long ago', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      final now = DateTime.now();

      InquirySummary at(String id, DateTime when) => InquirySummary(
            id: id,
            propertyId: 'p1',
            propertyName: 'Sunrise Apartments',
            withName: 'Asker $id',
            status: InquirySummaryStatusEnum.OPEN,
            lastMessage: 'Hello',
            lastMessageAt: when,
            unread: false,
            createdAt: when,
          );

      await tester.pumpWidget(appWith(api: api, inbox: [
        at('i1', now.subtract(const Duration(minutes: 20))),
        at('i2', now.subtract(const Duration(hours: 5))),
        at('i3', now.subtract(const Duration(days: 30))),
      ]));
      await tester.pumpAndSettle();
      await openAsking(tester);

      expect(find.text('20m'), findsOneWidget);
      expect(find.text('5h'), findsOneWidget);
      // A month back is a date, not "720h".
      final old = now.subtract(const Duration(days: 30));
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      expect(find.text('${old.day} ${months[old.month - 1]}'), findsOneWidget);
    });

    // ---- the whole list ---------------------------------------------------

    /// Today shows what is still going. This is everything, including what is
    /// over -- "what did that person say in March" is a real question, and the
    /// card is a to-do list rather than an archive.
    testWidgets('every conversation is listed, waiting on you first',
        (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api, inbox: [
        summary(id: 'i3', withName: 'Carla Diaz', unread: false,
            status: InquirySummaryStatusEnum.CLOSED),
        summary(id: 'i2', withName: 'Bea Santos', unread: false,
            status: InquirySummaryStatusEnum.LEASED),
        summary(withName: 'Ana Reyes'),
      ]));
      await tester.pumpAndSettle();
      await openAsking(tester);

      final ana = tester.getTopLeft(find.byKey(const ValueKey('thread-i1'))).dy;
      final bea = tester.getTopLeft(find.byKey(const ValueKey('thread-i2'))).dy;
      final carla = tester.getTopLeft(find.byKey(const ValueKey('thread-i3'))).dy;

      // Unanswered, then the tenancy, then what is over.
      expect(ana, lessThan(bea));
      expect(bea, lessThan(carla));
      // The chips on the rows. "Renting" is also the other segment's label,
      // so this counts the chip inside the list.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('thread-i2')),
          matching: find.text('Renting'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('a conversation in the list opens it', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api, inbox: [summary()]));
      await tester.pumpAndSettle();
      await openAsking(tester);

      await tester.tap(find.byKey(const ValueKey('thread-i1')));
      await tester.pumpAndSettle();

      expect(find.byType(InquiryScreen), findsOneWidget);
    });

    testWidgets('nothing yet says what will appear here', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api));
      await tester.pumpAndSettle();
      await openAsking(tester);

      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    /// A card on a dashboard, not an inbox: a landlord with twenty of them
    /// would have nothing else on the screen.
    testWidgets('Today shows three and offers the rest', (tester) async {
      final api = _FakeInquiriesApi(thread: thread(who: applicant()));
      await tester.pumpWidget(appWith(api: api, inbox: [
        for (var i = 1; i <= 5; i++)
          summary(id: 'i$i', withName: 'Asker $i', unread: i == 1),
      ]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inquiry-i1')), findsOneWidget);
      expect(find.byKey(const ValueKey('inquiry-i5')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('all-conversations')));
      await tester.pumpAndSettle();

      // Straight to the half that holds them, not to Renting.
      expect(find.byKey(const ValueKey('thread-i5')), findsOneWidget);
    });

    /// The tenant's side: the card that said only "waiting for a reply" now
    /// opens the conversation, and says when the landlord has written.
    testWidgets('the tenant is told there is a reply, and can open it',
        (tester) async {
      final api = _FakeInquiriesApi(thread: thread());
      await tester.pumpWidget(appWith(
          api: api,
          profiles: {LizmoProfile.tenant},
          inbox: [summary(withName: 'Elena Bautista')]));
      await tester.pumpAndSettle();

      expect(find.text('They have replied'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(InquiryScreen), findsOneWidget);
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
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => leases),
        myBillingProvider('l1').overrideWith(
          (ref) async => const <BillingPeriodResponse>[],
        ),
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

    /// Payments used to say Lizmo could not record anything and that the
    /// tenant should keep their own receipts. It shows real rent now, so what
    /// an empty list means has changed: no months yet, not no feature.
    testWidgets('payments shows the rent schedule, empty or not',
        (tester) async {
      await tester.pumpWidget(appWith([lease()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-rent')));
      await tester.pumpAndSettle();

      expect(find.text('Nothing due yet'), findsOneWidget);
      expect(find.textContaining('cannot record payments'), findsNothing);
    });

    /// It said "Not built yet" and told tenants to tell their landlord the
    /// way they normally would.
    testWidgets('maintenance lets a tenant report a problem', (tester) async {
      await tester.pumpWidget(appWith([lease()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-maintenance')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-problem')), findsOneWidget);
      expect(find.text('Not built yet'), findsNothing);
    });

    testWidgets('every tab carries the bell', (tester) async {
      await tester.pumpWidget(appWith([lease()]));
      await tester.pumpAndSettle();

      for (final tab in [
        'tab-home',
        'tab-rent',
        'tab-place',
        'tab-maintenance',
      ]) {
        await tester.tap(find.byKey(ValueKey(tab)));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('notification-bell')), findsOneWidget,
            reason: 'no bell on $tab');
      }
    });

    testWidgets('each tab keeps its own stack', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();

      await openMyPlace(tester);
      await tester.tap(find.text('Type the code instead'));
      await tester.pumpAndSettle();
      expect(find.byType(FindPropertyScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab-rent')));
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
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
        myInquiriesProvider.overrideWith(
          (ref) async => const <InquirySummary>[],
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

    /// Tapping news used to only mark it read. News about rent opens the rent,
    /// and the notifications close on the way rather than staying in Home.
    testWidgets('news about rent opens the rent', (tester) async {
      await tester.pumpWidget(appWith([
        NotificationResponse(
          id: 'n1',
          type: NotificationResponseTypeEnum.RENT_OVERDUE,
          title: 'Rent is late',
          message: 'October is overdue.',
          unread: false,
          leaseId: 'l1',
          createdAt: DateTime.now(),
        ),
      ]));
      await tester.pumpAndSettle();
      await openTheBell(tester);

      await tester.tap(find.text('Rent is late'));
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
      expect(_tabIndex(tester), 1);

      await tester.tap(find.byKey(const ValueKey('tab-home')));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsNothing);
    });

    Widget landlordWith(NotificationResponse news) => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
            ),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesProvider.overrideWith(
              (ref) async => const <PropertyResponse>[],
            ),
            myNotificationsProvider.overrideWith((ref) async => [news]),
            myInquiriesProvider.overrideWith(
              (ref) async => const <InquirySummary>[],
            ),
            inquiriesApiProvider.overrideWithValue(_FakeInquiriesApi(
              thread: InquiryThread(
                inquiry: InquirySummary(
                  id: 'i1',
                  propertyId: 'p1',
                  propertyName: 'Sunrise Apartments',
                  status: InquirySummaryStatusEnum.OPEN,
                ),
                messages: const [],
              ),
            )),
            ..._tenancyL1(),
          ],
          child: const LizmoApp(),
        );

    /// The dead end this was built for: told a tenant had paid, with no way
    /// to the tenant. It opens inside Today, and Back returns to the news.
    testWidgets('a landlord told somebody paid is taken to the tenant',
        (tester) async {
      await tester.pumpWidget(landlordWith(NotificationResponse(
        id: 'n1',
        type: NotificationResponseTypeEnum.PAYMENT_CONFIRMED,
        title: 'A tenant says they have paid',
        message: 'P2500 is waiting for you to confirm.',
        unread: false,
        leaseId: 'l1',
        createdAt: DateTime.now(),
      )));
      await tester.pumpAndSettle();
      await openTheBell(tester);

      await tester.tap(find.text('A tenant says they have paid'));
      await tester.pumpAndSettle();

      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(_tabIndex(tester), 0);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('a landlord told somebody wrote is taken to the conversation',
        (tester) async {
      await tester.pumpWidget(landlordWith(NotificationResponse(
        id: 'n1',
        type: NotificationResponseTypeEnum.INQUIRY_MESSAGE,
        title: 'Somebody is asking about your place',
        message: 'There is a new message about Sunrise Apartments.',
        unread: false,
        relatedEntityType: NotificationResponseRelatedEntityTypeEnum.INQUIRY,
        relatedEntityId: 'i1',
        propertyId: 'p1',
        createdAt: DateTime.now(),
      )));
      await tester.pumpAndSettle();
      await openTheBell(tester);

      await tester.tap(find.text('Somebody is asking about your place'));
      await tester.pumpAndSettle();

      expect(find.byType(InquiryScreen), findsOneWidget);
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
            (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
          ),
          myInquiriesProvider.overrideWith(
            (ref) async => const <InquirySummary>[],
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
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myInquiriesProvider.overrideWith(
          (ref) async => const <InquirySummary>[],
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
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myInquiriesProvider.overrideWith(
          (ref) async => const <InquirySummary>[],
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
      expect(find.text('₱5,000'), findsOneWidget);
      expect(find.text('₱2,500'), findsOneWidget);
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
      expect(find.text('₱4,500'), findsOneWidget);
      expect(find.text('Withheld ₱500 for the window latch.'), findsOneWidget);
    });

    testWidgets('a live tenancy shows no settlement', (tester) async {
      await tester.pumpWidget(tenantApp(tenancy(deposit: 5000)));
      await tester.pumpAndSettle();
      await openMyPlace(tester);

      expect(find.text('Deposit returned'), findsNothing);
    });
  });

  group('ending a tenancy', () {
    LeaseResponse tenancy({num? deposit}) => LeaseResponse(
          id: 'l1',
          tenantId: 't1',
          tenantName: 'Ana Reyes',
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          unitId: 'u1',
          unitNumber: '2B',
          bedId: 'b1',
          bedLabel: 'Bed 1',
          rentAmount: 2500,
          depositAmount: deposit,
          dueDateDay: 5,
          startDate: DateTime.utc(2026, 10, 1),
          status: LeaseResponseStatusEnum.ACTIVE,
        );

    Widget appWith({num? deposit}) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myTenantsProvider.overrideWith((ref) async => [tenancy(deposit: deposit)]),
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
        leaseDocumentsProvider('l1').overrideWith(
          (ref) async => const <LeaseDocumentResponse>[],
        ),
      ],
      child: const MaterialApp(home: TenantDetailScreen(leaseId: 'l1')),
    );

    /// Scrolls rather than ensureVisible. ListView(children:) builds lazily,
    /// so the button -- last on a long screen -- does not exist in the tree
    /// until it is scrolled towards, and ensureVisible cannot reach a widget
    /// that was never built.
    Future<void> reachTheButton(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('end-tenancy')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> openSheet(WidgetTester tester) async {
      await reachTheButton(tester);
      await tester.tap(find.byKey(const ValueKey('end-tenancy')));
      await tester.pumpAndSettle();
    }

    /// The whole point. Nothing in the app could end a tenancy, so a bed once
    /// let could never be let again.
    testWidgets('there is a way to end one at all', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await reachTheButton(tester);

      expect(find.byKey(const ValueKey('end-tenancy')), findsOneWidget);
    });

    testWidgets('the sheet says what ending it does', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.textContaining('goes back on the market'), findsOneWidget);
      expect(find.textContaining('is told'), findsOneWidget);
    });

    /// Ran-its-course and stopped-early are different things to look back on,
    /// and nothing else in the record can tell them apart.
    testWidgets('how it ended is asked, not assumed', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.text('Ran its course'), findsOneWidget);
      expect(find.text('Stopped early'), findsOneWidget);
    });

    testWidgets('a tenancy with no deposit is not asked to settle one',
        (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.text('Settling the deposit'), findsNothing);
      expect(find.byKey(const ValueKey('deposit-returned')), findsNothing);
    });

    testWidgets('a tenancy with one is', (tester) async {
      await tester.pumpWidget(appWith(deposit: 5000));
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.text('Settling the deposit'), findsOneWidget);
      expect(find.textContaining('You took ₱5,000'), findsOneWidget);
    });

    /// Caught before it costs a round trip, and the server refuses it too.
    testWidgets('returning more than was taken is refused', (tester) async {
      await tester.pumpWidget(appWith(deposit: 5000));
      await tester.pumpAndSettle();
      await openSheet(tester);

      await tester.enterText(
          find.byKey(const ValueKey('deposit-returned')), '6000');
      await tester.ensureVisible(find.text('End the tenancy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End the tenancy'));
      await tester.pumpAndSettle();

      expect(find.textContaining('more than the ₱5,000 you took'), findsOneWidget);
      // Still on the sheet rather than having ended anything.
      expect(find.byType(EndTenancySheet), findsOneWidget);
    });

    testWidgets('"all of it" fills in the whole deposit', (tester) async {
      await tester.pumpWidget(appWith(deposit: 5000));
      await tester.pumpAndSettle();
      await openSheet(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('return-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('return-all')));
      await tester.pumpAndSettle();

      expect(find.text('5000'), findsWidgets);
    });

    /// The note goes nowhere a tenant can see, and nowhere the landlord can
    /// read back yet either. Saying so beats leaving somebody hunting for it.
    testWidgets('the note admits it cannot be read back yet', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await openSheet(tester);

      expect(find.textContaining('does not see this'), findsOneWidget);
    });

    testWidgets('backing out ends nothing', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();
      await openSheet(tester);

      await tester.ensureVisible(find.text('Not yet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();

      expect(find.byType(EndTenancySheet), findsNothing);
      expect(find.byType(TenantDetailScreen), findsOneWidget);
    });
  });

  group('rent, month by month', () {
    BillingPeriodResponse month({
      String id = 'b1',
      String label = 'October 2026',
      num due = 2500,
      num paid = 0,
      bool overdue = false,
      BillingPeriodResponseStatusEnum status =
          BillingPeriodResponseStatusEnum.UNPAID,
    }) => BillingPeriodResponse(
      id: id,
      label: label,
      periodStart: DateTime.utc(2026, 10, 3),
      periodEnd: DateTime.utc(2026, 11, 2),
      dueDate: DateTime.utc(2026, 10, 5),
      amountDue: due,
      amountPaid: paid,
      outstanding: due - paid < 0 ? 0 : due - paid,
      status: status,
      overdue: overdue,
    );

    Widget appWith(
      List<BillingPeriodResponse> periods, {
      List<PaymentResponse> payments = const [],
      PaymentDetails? details,
      DateTime? today,
    }) => ProviderScope(
      overrides: [
        // Two days before the months below fall due, unless a test says.
        todayProvider.overrideWithValue(today ?? DateTime(2026, 10, 3)),
        if (details != null)
          leasePaymentDetailsProvider('l1').overrideWith((ref) async => details),
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myInquiriesProvider.overrideWith(
          (ref) async => const <InquirySummary>[],
        ),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => [
              LeaseResponse(
                id: 'l1',
                tenantId: 't1',
                propertyName: 'Sunrise Apartments',
                unitNumber: '2B',
                bedLabel: 'Bed 1',
                rentAmount: 2500,
                dueDateDay: 5,
                startDate: DateTime.utc(2026, 10, 3),
                status: LeaseResponseStatusEnum.ACTIVE,
              ),
            ]),
        myLeaseDocumentsProvider('l1').overrideWith(
          (ref) async => const <LeaseDocumentResponse>[],
        ),
        myBillingProvider('l1').overrideWith((ref) async => periods),
        myPaymentsProvider('l1').overrideWith((ref) async => payments),
      ],
      child: const LizmoApp(),
    );

    Future<void> openPayments(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-rent')));
      await tester.pumpAndSettle();
    }

    // ---- Home says what is due ------------------------------------------

    Finder dueCard(Finder finder) => find.descendant(
          of: find.byKey(const ValueKey('rent-due')),
          matching: finder,
        );

    PaymentResponse payment(
      PaymentResponseStatusEnum status, {
      String? reason,
      String? sentTo,
    }) =>
        PaymentResponse(
          id: 'p1',
          billingPeriodId: 'b1',
          amountPaid: 2500,
          paymentDate: DateTime.utc(2026, 10, 3),
          sentTo: sentTo,
          status: status,
          rejectionReason: reason,
        );

    // The kicker is the Text itself, keyed.
    Finder kicker(String text) => dueCard(find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.key == const ValueKey('rent-status-kicker') &&
        widget.data == text));

    /// Home said nothing about rent beyond the monthly figure. Somebody who
    /// opens the app on the 3rd wants to know that it is due on the 5th.
    testWidgets('Home says what is due, and when', (tester) async {
      await tester.pumpWidget(appWith([month()]));
      await tester.pumpAndSettle();

      expect(kicker('Due in 2 days'), findsOneWidget);
      expect(dueCard(find.text('₱2,500 due on 5 Oct')), findsOneWidget);
      expect(dueCard(find.text('I have paid')), findsOneWidget);
      expect(dueCard(find.text('How to pay')), findsOneWidget);
    });

    testWidgets('on rent day it is due today', (tester) async {
      await tester.pumpWidget(appWith([month()], today: DateTime(2026, 10, 5)));
      await tester.pumpAndSettle();

      expect(kicker('Due today'), findsOneWidget);
    });

    /// Five days out, the same day the reminder goes. Before that a month
    /// that is open is not yet something to act on.
    testWidgets('a month more than five days off is not due yet',
        (tester) async {
      await tester.pumpWidget(appWith([month()], today: DateTime(2026, 9, 28)));
      await tester.pumpAndSettle();

      expect(kicker('Paid up'), findsOneWidget);
      expect(dueCard(find.text('Next rent: ₱2,500 on 5 Oct.')), findsOneWidget);
      expect(dueCard(find.text('I have paid')), findsNothing);
    });

    /// The number is about to be pasted into GCash; retyped digits are how
    /// money goes to the wrong account.
    testWidgets('due soon offers the landlord\'s account to copy',
        (tester) async {
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
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(appWith([month()],
          details: PaymentDetails(channels: [
            PaymentChannelView(
              id: 'c1',
              channel: 'GCash',
              accountName: 'Elena Reyes',
              accountNumber: '09171112222',
              qrUrlExpiresInSeconds: 600,
            ),
          ])));
      await tester.pumpAndSettle();

      expect(dueCard(find.text('GCash · Elena Reyes')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rent-status-copy')));
      await tester.pumpAndSettle();

      expect(copied, '09171112222');
      expect(dueCard(find.text('Copied')), findsOneWidget);
    });

    testWidgets('how to pay opens the Rent tab', (tester) async {
      await tester.pumpWidget(appWith([month()]));
      await tester.pumpAndSettle();

      await tester.tap(dueCard(find.text('How to pay')));
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
    });

    testWidgets('saying you paid from Home opens the same sheet',
        (tester) async {
      await tester.pumpWidget(appWith([month()]));
      await tester.pumpAndSettle();

      await tester.tap(dueCard(find.text('I have paid')));
      await tester.pumpAndSettle();

      expect(find.text('Tell your landlord you have paid'), findsOneWidget);
    });

    /// Offered "I have paid" a second time, somebody would reasonably think
    /// the first one had been lost.
    testWidgets('a payment already said is not asked for again',
        (tester) async {
      await tester.pumpWidget(appWith([month()],
          payments: [payment(PaymentResponseStatusEnum.PENDING_VERIFICATION)]));
      await tester.pumpAndSettle();

      expect(kicker('Waiting for your landlord'), findsOneWidget);
      expect(dueCard(find.text('You paid ₱2,500 on 3 Oct')), findsOneWidget);
      expect(dueCard(find.text('I have paid')), findsNothing);
      expect(dueCard(find.text('How to pay')), findsNothing);
    });

    testWidgets('a waiting payment on Home says which account it went to',
        (tester) async {
      await tester.pumpWidget(appWith([month()], payments: [
        payment(PaymentResponseStatusEnum.PENDING_VERIFICATION,
            sentTo: 'GCash · Elena Reyes · 09171112222'),
      ]));
      await tester.pumpAndSettle();

      expect(dueCard(find.textContaining('Sent to GCash · Elena Reyes · 09171112222')),
          findsOneWidget);
    });

    /// Their words, quoted, so the tenant knows whose they are -- and what to
    /// fix before sending it again.
    testWidgets('a refused payment quotes the landlord\'s reason',
        (tester) async {
      await tester.pumpWidget(appWith([month()], payments: [
        payment(PaymentResponseStatusEnum.REJECTED,
            reason: 'No GCash transfer on 3 Oct.'),
      ]));
      await tester.pumpAndSettle();

      expect(kicker('Not received'), findsOneWidget);
      expect(dueCard(find.text('Your landlord didn\'t find your ₱2,500')), findsOneWidget);
      expect(dueCard(find.text('"No GCash transfer on 3 Oct."')), findsOneWidget);
    });

    testWidgets('a refusal without a reason says there was none',
        (tester) async {
      await tester.pumpWidget(appWith([month()],
          payments: [payment(PaymentResponseStatusEnum.REJECTED)]));
      await tester.pumpAndSettle();

      expect(dueCard(find.textContaining('They didn\'t say why')), findsOneWidget);
    });

    testWidgets('telling them again opens the same sheet', (tester) async {
      await tester.pumpWidget(appWith([month()], payments: [
        payment(PaymentResponseStatusEnum.REJECTED, reason: 'Nothing arrived'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(dueCard(find.text('Tell them again')));
      await tester.pumpAndSettle();

      expect(find.text('Tell your landlord you have paid'), findsOneWidget);
    });

    testWidgets('late rent on Home is called late', (tester) async {
      await tester.pumpWidget(appWith([month(overdue: true)],
          today: DateTime(2026, 10, 6)));
      await tester.pumpAndSettle();

      expect(kicker('Late'), findsOneWidget);
      expect(dueCard(find.text('₱2,500 overdue')), findsOneWidget);
      expect(dueCard(find.text('October 2026 was due on 5 Oct.')), findsOneWidget);
      expect(dueCard(find.text('I have paid')), findsOneWidget);
    });

    testWidgets('months late are counted and added up', (tester) async {
      await tester.pumpWidget(appWith([
        month(overdue: true),
        month(id: 'b2', label: 'November 2026', overdue: true),
      ], today: DateTime(2026, 11, 20)));
      await tester.pumpAndSettle();

      expect(kicker('2 months late'), findsOneWidget);
      expect(dueCard(find.text('₱5,000 overdue')), findsOneWidget);
    });

    /// Still late until the landlord confirms, but the tenant sees their
    /// payment was received, and is not asked for it twice.
    testWidgets('late with a payment waiting says so, and does not ask again',
        (tester) async {
      await tester.pumpWidget(appWith([month(overdue: true)],
          payments: [payment(PaymentResponseStatusEnum.PENDING_VERIFICATION)],
          today: DateTime(2026, 10, 8)));
      await tester.pumpAndSettle();

      expect(kicker('Late'), findsOneWidget);
      expect(find.byKey(const ValueKey('rent-status-note')), findsOneWidget);
      expect(dueCard(find.textContaining('Waiting for your landlord to confirm')),
          findsOneWidget);
      expect(dueCard(find.text('I have paid')), findsNothing);
    });

    testWidgets('nothing owed says so', (tester) async {
      await tester.pumpWidget(appWith([
        month(paid: 2500, status: BillingPeriodResponseStatusEnum.PAID),
      ]));
      await tester.pumpAndSettle();

      expect(kicker('Paid up'), findsOneWidget);
      expect(dueCard(find.text('You\'re all set for October 2026')), findsOneWidget);
      // Paid early: October is settled, so the next rent is November's.
      expect(dueCard(find.text('Next rent: ₱2,500 on 5 Nov.')), findsOneWidget);
      expect(dueCard(find.text('I have paid')), findsNothing);
    });

    /// It showed the monthly rent, from before payments were recorded.
    testWidgets('the header shows what is owed', (tester) async {
      await tester.pumpWidget(appWith([
        month(),
        month(id: 'b2', label: 'November 2026', paid: 1000,
            status: BillingPeriodResponseStatusEnum.PARTIALLY_PAID),
      ]));
      await tester.pumpAndSettle();

      final header = find.byType(LatticeHeader);
      expect(find.descendant(of: header, matching: find.text('Owed')),
          findsOneWidget);
      expect(find.descendant(of: header, matching: find.text('₱4,000')),
          findsOneWidget);
      expect(find.text('Monthly rent'), findsNothing);
    });

    /// The tab was a bell, under the bell in the header.
    testWidgets('Home is a house, not a second bell', (tester) async {
      await tester.pumpWidget(appWith([month()]));
      await tester.pumpAndSettle();

      final homeTab = find.byKey(const ValueKey('tab-home'));
      expect(find.descendant(of: homeTab, matching: find.byIcon(Icons.home_outlined)),
          findsOneWidget);
      expect(
          find.descendant(
              of: homeTab, matching: find.byIcon(Icons.notifications_none)),
          findsNothing);
    });

    testWidgets('Rent is the second tab', (tester) async {
      await tester.pumpWidget(appWith([month()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-rent')));
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
      expect(_tabIndex(tester), 1);
      expect(
          find.descendant(
              of: find.byType(LatticeHeader), matching: find.text('Rent')),
          findsOneWidget);
    });

    testWidgets('a month shows what is owed and what came in', (tester) async {
      await tester.pumpWidget(appWith([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Due'), findsWidgets);
      expect(find.text('Outstanding'), findsOneWidget);
      expect(find.text('₱2,500'), findsWidgets);
    });

    /// The number somebody actually opened the screen to find, so no client
    /// has to do the subtraction and none can get it wrong.
    testWidgets('a part payment leaves the rest showing', (tester) async {
      await tester.pumpWidget(appWith([
        month(
          paid: 1000,
          status: BillingPeriodResponseStatusEnum.PARTIALLY_PAID,
        ),
      ]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(find.text('₱1,000'), findsOneWidget);
      expect(find.text('₱1,500'), findsOneWidget);
    });

    testWidgets('a settled month says so', (tester) async {
      await tester.pumpWidget(appWith([
        month(paid: 2500, status: BillingPeriodResponseStatusEnum.PAID),
      ]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      // Scoped to the chip: "Paid" is also a ledger column heading, so a bare
      // find.text matches twice in a settled row.
      expect(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.text('Paid'),
        ),
        findsOneWidget,
      );
      expect(find.text('Settled'), findsOneWidget);
    });

    /// Late is louder than unpaid. Rent merely not yet due is the ordinary
    /// state of the current month and must not look like a problem.
    testWidgets('late rent is called late, and pending rent is not',
        (tester) async {
      await tester.pumpWidget(appWith([
        month(id: 'b1', label: 'October 2026', overdue: true),
        month(id: 'b2', label: 'November 2026'),
      ]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Due'), findsWidgets);
    });

    /// The month somebody opens this to check is almost always the current
    /// one, and the server sends oldest first.
    testWidgets('the newest month is at the top', (tester) async {
      await tester.pumpWidget(appWith([
        month(id: 'b1', label: 'October 2026'),
        month(id: 'b2', label: 'November 2026'),
      ]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      final october = tester.getTopLeft(find.text('October 2026')).dy;
      final november = tester.getTopLeft(find.text('November 2026')).dy;
      expect(november, lessThan(october));
    });

    testWidgets('no months yet says why, not that nothing works',
        (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(find.text('Nothing due yet'), findsOneWidget);
      expect(find.textContaining('once the tenancy has started'), findsOneWidget);
    });
  });

  group('recording rent', () {
    BillingPeriodResponse month({
      String id = 'b1',
      num due = 2500,
      num paid = 0,
      BillingPeriodResponseStatusEnum status =
          BillingPeriodResponseStatusEnum.UNPAID,
    }) => BillingPeriodResponse(
      id: id,
      label: 'October 2026',
      periodStart: DateTime.utc(2026, 10, 3),
      periodEnd: DateTime.utc(2026, 11, 2),
      dueDate: DateTime.utc(2026, 10, 5),
      amountDue: due,
      amountPaid: paid,
      outstanding: due - paid,
      status: status,
      overdue: false,
    );

    PaymentResponse waiting({
      String id = 'p1',
      num amount = 2500,
      String? note,
    }) => PaymentResponse(
      id: id,
      billingPeriodId: 'b1',
      periodLabel: 'October 2026',
      amountPaid: amount,
      paymentDate: DateTime.utc(2026, 10, 4),
      paymentMethod: PaymentResponsePaymentMethodEnum.GCASH,
      status: PaymentResponseStatusEnum.PENDING_VERIFICATION,
      remarks: note,
      proofUrlExpiresInSeconds: 600,
    );

    // ---- the tenant's side ------------------------------------------------

    Widget tenantApp(
      List<BillingPeriodResponse> months, {
      PaymentDetails? payment,
      _FakeRentApi? api,
    }) => ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(DateTime(2026, 10, 3)),
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myInquiriesProvider.overrideWith(
          (ref) async => const <InquirySummary>[],
        ),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => [
              LeaseResponse(
                id: 'l1',
                tenantId: 't1',
                propertyName: 'Sunrise Apartments',
                unitNumber: '2B',
                rentAmount: 2500,
                dueDateDay: 5,
                status: LeaseResponseStatusEnum.ACTIVE,
              ),
            ]),
        myLeaseDocumentsProvider('l1').overrideWith(
          (ref) async => const <LeaseDocumentResponse>[],
        ),
        myBillingProvider('l1').overrideWith((ref) async => months),
        leasePaymentDetailsProvider('l1')
            .overrideWith((ref) async => payment ?? PaymentDetails()),
        if (api != null) rentApiProvider.overrideWithValue(api),
      ],
      child: const LizmoApp(),
    );

    Future<void> openPayments(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-rent')));
      await tester.pumpAndSettle();
    }

    testWidgets('an unpaid month invites the tenant to say they paid',
        (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(find.textContaining('Tap if you have paid'), findsOneWidget);
    });

    /// A settled month has nothing to declare against it, and a row that looks
    /// tappable and is not is worse than one that plainly is not.
    testWidgets('a settled month is not tappable', (tester) async {
      await tester.pumpWidget(tenantApp([
        month(paid: 2500, status: BillingPeriodResponseStatusEnum.PAID),
      ]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(find.textContaining('Tap if you have paid'), findsNothing);
      expect(find.byKey(const ValueKey('month-b1')), findsNothing);
    });

    /// Said before anything is typed. A tenant who taps this and watches the
    /// month stay unpaid would think the app had lost it.
    testWidgets('the sheet says the landlord has to confirm it',
        (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      expect(find.byType(DeclarePaymentSheet), findsOneWidget);
      expect(find.textContaining('only counts as paid once they do'),
          findsOneWidget);
    });

    testWidgets('the amount is prefilled with what is left', (tester) async {
      await tester.pumpWidget(tenantApp([
        month(paid: 1000, status: BillingPeriodResponseStatusEnum.PARTIALLY_PAID),
      ]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
          find.byKey(const ValueKey('payment-amount')));
      expect(field.controller?.text, '1500');
    });

    /// The figures cannot say "I paid from my sister's number", and that is
    /// exactly what would otherwise make a landlord hesitate.
    testWidgets('a note can be added, and is not demanded', (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);
      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('payment-note')), findsOneWidget);
      expect(find.textContaining('Your landlord sees this'), findsOneWidget);
    });

    testWidgets('the amount is required', (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);
      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('payment-amount')), '');
      await tester.ensureVisible(find.text('I have paid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I have paid'));
      await tester.pumpAndSettle();

      expect(find.text('How much did you pay?'), findsOneWidget);
      // Still on the sheet, having declared nothing.
      expect(find.byType(DeclarePaymentSheet), findsOneWidget);
    });

    PaymentChannelView gcash() => PaymentChannelView(
          id: 'c1',
          channel: 'GCash',
          accountName: 'Elena Reyes',
          accountNumber: '09171112222',
          qrUrlExpiresInSeconds: 600,
        );

    Finder landlordPanel(Finder matching) => find.descendant(
          of: find.byKey(const ValueKey('landlord-how-to-pay')),
          matching: matching,
        );

    Future<void> tapShown(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    /// Where to send it, before anybody taps "I have paid".
    testWidgets('the Rent tab says how to pay the landlord', (tester) async {
      await tester.pumpWidget(tenantApp([month()],
          payment: PaymentDetails(
            channels: [gcash()],
            note: 'Cash to Aling Nena at unit 1A',
          )));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(landlordPanel(find.text('How to pay your landlord')), findsOneWidget);
      expect(landlordPanel(find.text('09171112222')), findsOneWidget);
      expect(landlordPanel(find.text('Cash to Aling Nena at unit 1A')), findsOneWidget);
    });

    testWidgets('a landlord who has added nothing yet is said to have added nothing',
        (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);

      expect(landlordPanel(find.textContaining('has not added how to pay yet')),
          findsOneWidget);
    });

    /// So the landlord opens the right app before confirming.
    testWidgets('saying which account it went to sends it, with the method',
        (tester) async {
      final api = _FakeRentApi();
      await tester.pumpWidget(tenantApp([month()],
          payment: PaymentDetails(channels: [gcash()]), api: api));
      await tester.pumpAndSettle();
      await openPayments(tester);
      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      expect(find.text('Send it to'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('method-MAYA')));
      await tapShown(tester, find.byKey(const ValueKey('sent-to-c1')));
      await tapShown(tester, find.text('I have paid'));

      expect(api.declared.single.channelId, 'c1');
      // Picking the GCash account picked GCash, over the Maya tapped before.
      expect(api.declared.single.paymentMethod, 'GCASH');
      expect(api.declared.single.billingPeriodId, 'b1');
    });

    /// Cash went to nobody's account, whatever was tapped on the way.
    testWidgets('cash sends no account', (tester) async {
      final api = _FakeRentApi();
      await tester.pumpWidget(tenantApp([month()],
          payment: PaymentDetails(channels: [gcash()]), api: api));
      await tester.pumpAndSettle();
      await openPayments(tester);
      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('sent-to-c1')));
      await tapShown(tester, find.byKey(const ValueKey('method-CASH')));
      await tapShown(tester, find.text('I have paid'));

      expect(api.declared.single.channelId, isNull);
      expect(api.declared.single.paymentMethod, 'CASH');
    });

    testWidgets('with no channels the sheet asks nothing about accounts',
        (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);
      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sent-to-none')), findsNothing);
    });

    testWidgets('proof is offered, not demanded', (tester) async {
      await tester.pumpWidget(tenantApp([month()]));
      await tester.pumpAndSettle();
      await openPayments(tester);
      await tester.tap(find.byKey(const ValueKey('month-b1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('attach-proof')), findsOneWidget);
      // Specific: the note is optional too, so a bare "Optional" now matches
      // twice.
      expect(find.textContaining('if you paid by GCash'), findsOneWidget);
    });

    // ---- the landlord's side ----------------------------------------------

    Widget landlordApp({
      List<BillingPeriodResponse> months = const [],
      List<PaymentResponse> payments = const [],
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myTenantsProvider.overrideWith((ref) async => [
              LeaseResponse(
                id: 'l1',
                tenantId: 't1',
                tenantName: 'Ana Reyes',
                propertyId: 'p1',
                unitId: 'u1',
                unitNumber: '2B',
                rentAmount: 2500,
                status: LeaseResponseStatusEnum.ACTIVE,
              ),
            ]),
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
        leaseDocumentsProvider('l1').overrideWith(
          (ref) async => const <LeaseDocumentResponse>[],
        ),
        leaseBillingProvider('l1').overrideWith((ref) async => months),
        leasePaymentsProvider('l1').overrideWith((ref) async => payments),
      ],
      child: const MaterialApp(home: TenantDetailScreen(leaseId: 'l1')),
    );

    Future<void> reachRent(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.text('Rent'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the landlord sees what is outstanding', (tester) async {
      await tester.pumpWidget(landlordApp(months: [month(), month(id: 'b2')]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      expect(find.text('Outstanding'), findsOneWidget);
      expect(find.text('₱5,000'), findsOneWidget);
    });

    /// A tenant who said they paid three days ago and has heard nothing is the
    /// failure this whole feature exists to avoid.
    testWidgets('a waiting payment is put in front of them', (tester) async {
      await tester.pumpWidget(
          landlordApp(months: [month()], payments: [waiting()]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      expect(find.text('One payment is waiting on you'), findsOneWidget);
      expect(find.textContaining('₱2,500 for October 2026'), findsOneWidget);
      expect(find.text('Paid by GCash'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm-p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('reject-p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('reject-p1')), findsOneWidget);
    });

    /// Rent comes first now. It sat below the contact details, the emergency
    /// contact, the deposit and the ID, so the Confirm button the dashboard
    /// had sent the landlord for was a long scroll away.
    testWidgets('Confirm is on screen without scrolling', (tester) async {
      await tester.pumpWidget(
          landlordApp(months: [month()], payments: [waiting()]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('confirm-p1')).hitTestable(),
          findsOneWidget);
    });

    testWidgets('the landlord sees which account it was sent to', (tester) async {
      await tester.pumpWidget(landlordApp(months: [month()], payments: [
        PaymentResponse(
          id: 'p1',
          billingPeriodId: 'b1',
          periodLabel: 'October 2026',
          amountPaid: 2500,
          paymentDate: DateTime.utc(2026, 10, 4),
          paymentMethod: PaymentResponsePaymentMethodEnum.GCASH,
          sentTo: 'GCash · Elena Reyes · 09171112222',
          status: PaymentResponseStatusEnum.PENDING_VERIFICATION,
          proofUrlExpiresInSeconds: 600,
        ),
      ]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      expect(find.text('Sent to GCash · Elena Reyes · 09171112222'), findsOneWidget);
    });

    testWidgets('the landlord reads the note while deciding', (tester) async {
      await tester.pumpWidget(landlordApp(
        months: [month()],
        payments: [waiting(note: 'Sent from my sister’s number.')],
      ));
      await tester.pumpAndSettle();
      await reachRent(tester);

      expect(find.text('Sent from my sister’s number.'), findsOneWidget);
    });

    testWidgets('no note leaves the card uncluttered', (tester) async {
      await tester.pumpWidget(
          landlordApp(months: [month()], payments: [waiting()]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      expect(find.text('One payment is waiting on you'), findsOneWidget);
    });

    testWidgets('nothing waiting means no prompt', (tester) async {
      await tester.pumpWidget(landlordApp(months: [month()]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      expect(find.textContaining('waiting on you'), findsNothing);
    });

    /// The tenant is told the answer, and "not confirmed" with no reason is
    /// how a disagreement becomes a row.
    testWidgets('refusing asks why first', (tester) async {
      await tester.pumpWidget(
          landlordApp(months: [month()], payments: [waiting()]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      await tester.tap(find.byKey(const ValueKey('reject-p1')));
      await tester.pumpAndSettle();

      expect(find.text('Say it did not arrive?'), findsOneWidget);
      expect(find.byKey(const ValueKey('reject-reason')), findsOneWidget);
      expect(find.textContaining('Your tenant sees this'), findsOneWidget);
    });

    testWidgets('backing out of the reason refuses nothing', (tester) async {
      await tester.pumpWidget(
          landlordApp(months: [month()], payments: [waiting()]));
      await tester.pumpAndSettle();
      await reachRent(tester);

      await tester.tap(find.byKey(const ValueKey('reject-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('One payment is waiting on you'), findsOneWidget);
    });
  });

  group('collections', () {
    ArrearsRow behind({
      String leaseId = 'l1',
      String tenant = 'Ana Reyes',
      int months = 2,
      num owed = 5000,
    }) => ArrearsRow(
      leaseId: leaseId,
      tenantName: tenant,
      propertyName: 'Sunrise Apartments',
      unitNumber: '2B',
      bedLabel: 'Bed 1',
      outstanding: owed,
      monthsLate: months,
      oldestDueDate: DateTime.utc(2026, 8, 5),
    );

    Widget appWith({
      num due = 5000,
      num collected = 2500,
      num outstanding = 7500,
      int waiting = 0,
      List<ArrearsRow> arrears = const [],
      List<AwaitingRow> awaiting = const [],
      List<InquirySummary>? threads,
      List<PlatformStatementResponse> lizmo = const [],
      // Pinned to none unless a test says; null leaves it unread.
      List<MaintenanceReportResponse>? repairs = const [],
      ApiFailure? repairsFail,
      List<PropertyResponse> properties = const [],
      // Pinned to none unless a test says; null leaves it unread.
      List<PaymentChannelResponse>? channels = const [],
      int occupied = 0,
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => properties),
        if (channels != null)
          myPaymentChannelsProvider.overrideWith((ref) async => channels),
        occupancyProvider.overrideWith((ref) async => OccupancySummary(
              lettable: 4,
              occupied: occupied,
              empty: 4 - occupied,
              outOfService: 0,
              earningRent: 0,
              emptyRent: 0,
              vacancies: [
                for (final property in properties)
                  VacancyRow(
                    propertyId: property.id,
                    propertyName: property.name,
                    lettable: 4,
                    occupied: occupied,
                    empty: 4 - occupied,
                    emptyRent: 0,
                  ),
              ],
            )),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        collectionsProvider.overrideWith((ref) async => CollectionsSummary(
              dueThisMonth: due,
              collectedThisMonth: collected,
              outstandingAllTime: outstanding,
              awaitingConfirmation: waiting,
              tenanciesInArrears: arrears.length,
              inArrears: arrears,
              awaiting: awaiting,
            )),
        if (threads != null)
          myInquiriesProvider.overrideWith((ref) async => threads),
        if (repairsFail != null)
          maintenanceToHandleProvider.overrideWith((ref) async => throw repairsFail)
        else if (repairs != null)
          maintenanceToHandleProvider.overrideWith((ref) async => repairs),
        myLizmoStatementsProvider.overrideWith((ref) async => lizmo),
        ..._tenancyL1(),
      ],
      child: const LizmoApp(),
    );

    testWidgets('the three figures a landlord opens the app for',
        (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.text('Due'), findsOneWidget);
      expect(find.text('₱5,000'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('₱2,500'), findsOneWidget);
      expect(find.text('Owed in all'), findsOneWidget);
      expect(find.text('₱7,500'), findsOneWidget);
    });

    /// Four zeroes read as a broken screen rather than an empty portfolio.
    testWidgets('nothing let says so in words', (tester) async {
      await tester.pumpWidget(
          appWith(due: 0, collected: 0, outstanding: 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('once somebody is renting from you'),
          findsOneWidget);
      expect(find.text('Due'), findsNothing);
    });

    /// The only line here about the landlord's own behaviour rather than
    /// their tenants'.
    testWidgets('anything waiting on the landlord is said first',
        (tester) async {
      await tester.pumpWidget(appWith(waiting: 2));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('confirm-card')), findsOneWidget);
      expect(find.text('2 waiting for you to confirm'), findsOneWidget);
    });

    testWidgets('nothing waiting means no prompt', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('confirm-card')), findsNothing);
    });

    testWidgets('a tenant behind is named, with how far and how much',
        (tester) async {
      await tester.pumpWidget(appWith(arrears: [behind()]));
      await tester.pumpAndSettle();

      expect(find.text('Behind on rent'), findsOneWidget);
      expect(find.text('One tenant'), findsOneWidget);
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.textContaining('Bed 1, 2B · 2 months late'), findsOneWidget);
      expect(find.text('₱5,000'), findsWidgets);
    });

    testWidgets('one month late reads as one month', (tester) async {
      await tester.pumpWidget(
          appWith(arrears: [behind(months: 1, owed: 2500)]));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 month late'), findsOneWidget);
    });

    /// Seeing who is behind and then having to go and find them is the half
    /// of this that wastes the time.
    testWidgets('tapping one opens that tenant, inside Today', (tester) async {
      await tester.pumpWidget(appWith(arrears: [behind()]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('arrears-l1')));
      await tester.pumpAndSettle();

      expect(find.byType(TenantDetailScreen), findsOneWidget);
      // Still Today. It used to switch to the Tenants tab.
      expect(_tabIndex(tester), 0);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // And Back comes here, not to a tenant list never looked at.
      expect(find.byType(LandlordHomeScreen), findsOneWidget);
      expect(find.byType(TenantsScreen), findsNothing);
    });

    /// The banner said somebody was waiting and could not be tapped. Each
    /// waiting payment is now a row naming whose it is.
    /// Which account to open before confirming, so nobody searches GCash for a
    /// bank transfer.
    testWidgets('a waiting payment on Today says which account it went to',
        (tester) async {
      await tester.pumpWidget(appWith(waiting: 1, awaiting: [
        AwaitingRow(
          leaseId: 'l1',
          paymentId: 'pay1',
          tenantName: 'Ana Reyes',
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedLabel: 'Bed 1',
          amount: 2500,
          paidOn: DateTime.utc(2026, 9, 3),
          sentTo: 'GCash · Elena Reyes · 09171112222',
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Sent to GCash · Elena Reyes · 09171112222'), findsOneWidget);
    });

    testWidgets('each waiting payment is named, and opens its tenant',
        (tester) async {
      await tester.pumpWidget(appWith(waiting: 1, awaiting: [
        AwaitingRow(
          leaseId: 'l1',
          paymentId: 'pay1',
          tenantName: 'Ana Reyes',
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedLabel: 'Bed 1',
          amount: 2500,
          paidOn: DateTime.utc(2026, 9, 3),
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('Bed 1, 2B · paid 3 Sep'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('awaiting-pay1')));
      await tester.pumpAndSettle();

      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(_tabIndex(tester), 0);
    });

    testWidgets('nobody behind means no list', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('arrears-card')), findsNothing);
    });

    // ---- Today as a to-do list ------------------------------------------

    InquirySummary asking({bool unread = true}) => InquirySummary(
          id: 'i1',
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          withName: 'Miguel Cruz',
          status: InquirySummaryStatusEnum.OPEN,
          lastMessage: 'Is there a bed free in November?',
          lastMessageAt: DateTime.now(),
          unread: unread,
          createdAt: DateTime.now(),
        );

    /// A conversation where they spoke last is one nobody has answered, and
    /// that is what Today counts.
    testWidgets('an unanswered conversation is marked on Today',
        (tester) async {
      await tester.pumpWidget(appWith(threads: [asking()]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inquiries-card')), findsOneWidget);
      expect(find.text('1 waiting on you'), findsOneWidget);
    });

    testWidgets('one already answered is listed without a nudge',
        (tester) async {
      await tester.pumpWidget(appWith(threads: [asking(unread: false)]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inquiries-card')), findsOneWidget);
      expect(find.text('1 waiting on you'), findsNothing);
    });

    Finder inHeader(Finder finder) =>
        find.descendant(of: find.byType(LatticeHeader), matching: finder);

    /// "Do I need to do anything" answered before the first scroll.
    testWidgets('the header counts what is waiting', (tester) async {
      await tester.pumpWidget(appWith(
        waiting: 2,
        arrears: [behind()],
        threads: [asking()],
      ));
      await tester.pumpAndSettle();

      // One to answer and one behind; two to confirm.
      expect(inHeader(find.text('1')), findsNWidgets(2));
      expect(inHeader(find.text('2')), findsOneWidget);
    });

    /// A zero it has not earned would say nobody is waiting.
    testWidgets('a count not yet known is a dash, not a zero', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      // The queue is not pinned here, so it never arrives.
      expect(inHeader(find.text('—')), findsOneWidget);
    });

    testWidgets('nothing waiting says so outright', (tester) async {
      await tester.pumpWidget(appWith(threads: const []));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('all-caught-up')), findsOneWidget);
      expect(find.text('Nothing needs you'), findsOneWidget);
    });

    testWidgets('anything waiting means no all-clear', (tester) async {
      await tester.pumpWidget(appWith(threads: const [], waiting: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('all-caught-up')), findsNothing);
    });

    /// Unknown is not nothing. An all-clear over a queue that never loaded
    /// would be a lie told at the worst moment.
    testWidgets('an unread queue is not an all-clear', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('all-caught-up')), findsNothing);
    });

    // ---- Repairs on Today -------------------------------------------------

    MaintenanceReportResponse repair(
      String id, {
      String description = 'The ceiling fan grinds and stops',
      MaintenanceReportResponseStatusEnum status =
          MaintenanceReportResponseStatusEnum.SUBMITTED,
      bool reopened = false,
      int hoursAgo = 2,
    }) =>
        MaintenanceReportResponse(
          id: id,
          leaseId: 'l1',
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedLabel: 'Bed 1',
          tenantName: 'Ana Reyes',
          description: description,
          status: status,
          reopened: reopened,
          submittedAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
          updatedAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
        );

    Finder inRepairs(Finder finder) => find.descendant(
          of: find.byKey(const ValueKey('repairs-card')),
          matching: finder,
        );

    /// A tenant living with a broken fan is somebody waiting, and Today used
    /// to say "Nothing needs you" over them.
    testWidgets('a new repair is on Today, and opens', (tester) async {
      await tester.pumpWidget(appWith(threads: const [], repairs: [repair('m1')]));
      await tester.pumpAndSettle();

      expect(inRepairs(find.text('Repairs')), findsOneWidget);
      expect(inRepairs(find.text('1 new')), findsOneWidget);
      expect(inRepairs(find.text('The ceiling fan grinds and stops')), findsOneWidget);
      expect(inRepairs(find.text('Ana Reyes · Bed 1, 2B · Sunrise Apartments')),
          findsOneWidget);
      expect(inRepairs(find.text('New · 2h')), findsOneWidget);
      expect(find.byKey(const ValueKey('all-caught-up')), findsNothing);

      await tester.ensureVisible(find.byKey(const ValueKey('repair-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repair-m1')));
      await tester.pumpAndSettle();

      expect(find.byType(MaintenanceReportScreen), findsOneWidget);
    });

    /// The fix did not hold, which says more than how long ago.
    testWidgets('a reopened repair says it was reopened', (tester) async {
      await tester.pumpWidget(appWith(
          threads: const [], repairs: [repair('m1', reopened: true)]));
      await tester.pumpAndSettle();

      expect(inRepairs(find.text('Reopened')), findsOneWidget);
    });

    testWidgets('the header counts repairs apart from requests', (tester) async {
      await tester.pumpWidget(appWith(
        threads: [asking()],
        repairs: [repair('m1'), repair('m2', reopened: true)],
      ));
      await tester.pumpAndSettle();

      final header = find.byType(LatticeHeader);
      expect(find.descendant(of: header, matching: find.text('Repairs')), findsOneWidget);
      expect(find.descendant(of: header, matching: find.text('2')), findsOneWidget);
      expect(find.descendant(of: header, matching: find.text('To answer')), findsOneWidget);
    });

    /// In progress is the landlord's own work; fixed is the tenant's move.
    testWidgets('work already started or finished is not listed',
        (tester) async {
      await tester.pumpWidget(appWith(threads: const [], repairs: [
        repair('m1',
            description: 'Sink leaking',
            status: MaintenanceReportResponseStatusEnum.IN_PROGRESS),
        repair('m2',
            description: 'Light switch sparks',
            status: MaintenanceReportResponseStatusEnum.RESOLVED),
      ]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('repairs-card')), findsNothing);
      expect(find.byKey(const ValueKey('all-caught-up')), findsOneWidget);
    });

    testWidgets('work in progress is one line, not a row', (tester) async {
      await tester.pumpWidget(appWith(threads: const [], repairs: [
        repair('m1'),
        repair('m2',
            description: 'Sink leaking',
            status: MaintenanceReportResponseStatusEnum.IN_PROGRESS),
      ]));
      await tester.pumpAndSettle();

      expect(inRepairs(find.text('Sink leaking')), findsNothing);
      expect(inRepairs(find.text('1 in progress · See all repairs ›')), findsOneWidget);
    });

    /// Today is a summary; the Maintenance tab has them all.
    testWidgets('only the three that have waited longest are listed',
        (tester) async {
      await tester.pumpWidget(appWith(threads: const [], repairs: [
        repair('m1', description: 'Newest', hoursAgo: 1),
        repair('m2', description: 'Oldest', hoursAgo: 80),
        repair('m3', description: 'Middle', hoursAgo: 30),
        repair('m4', description: 'Second oldest', hoursAgo: 50),
      ]));
      await tester.pumpAndSettle();

      expect(inRepairs(find.text('4 new')), findsOneWidget);
      expect(inRepairs(find.text('Newest')), findsNothing);
      final oldest = tester.getTopLeft(inRepairs(find.text('Oldest'))).dy;
      final second = tester.getTopLeft(inRepairs(find.text('Second oldest'))).dy;
      expect(oldest, lessThan(second));
      expect(inRepairs(find.text('1 more · See all repairs ›')), findsOneWidget);
    });

    testWidgets('see all opens the Maintenance tab', (tester) async {
      await tester.pumpWidget(appWith(threads: const [], repairs: [
        repair('m1'),
        repair('m2', status: MaintenanceReportResponseStatusEnum.IN_PROGRESS),
      ]));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('repairs-see-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repairs-see-all')));
      await tester.pumpAndSettle();

      expect(find.byType(MaintenanceInboxScreen), findsOneWidget);
    });

    /// Hidden, a failure would read as nothing broken.
    testWidgets('repairs that cannot be read say so, and are no all-clear',
        (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        repairsFail: const ApiFailure(code: 'NETWORK_UNAVAILABLE', message: 'no signal'),
      ));
      await tester.pumpAndSettle();

      expect(inRepairs(find.text('no signal')), findsOneWidget);
      expect(find.byKey(const ValueKey('all-caught-up')), findsNothing);
    });

    // ---- getting started ------------------------------------------------------------------

    PropertyResponse aProperty(String id, String name, {int units = 0}) =>
        PropertyResponse(
          id: id,
          name: name,
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: units,
        );

    Finder inStarted(String id, Finder finder) => find.descendant(
          of: find.byKey(ValueKey('get-started-$id')),
          matching: finder,
        );

    /// An empty Today told a new landlord nothing about what to do next.
    testWidgets('a landlord with no property is told to add one',
        (tester) async {
      await tester.pumpWidget(appWith(threads: const [], properties: const []));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('get-started-first-property')), findsOneWidget);
      expect(find.text('Add your first property'), findsOneWidget);
    });

    testWidgets('a new property lists what is left to do', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments')],
      ));
      await tester.pumpAndSettle();

      expect(inStarted('p1', find.text('Set up Sunrise Apartments')), findsOneWidget);
      expect(inStarted('p1', find.text('0 of 3 done')), findsOneWidget);
      expect(inStarted('p1', find.text('Add units or beds')), findsOneWidget);
      expect(inStarted('p1', find.text('Choose how tenants pay you here')), findsOneWidget);
      expect(inStarted('p1', find.text('Share your property code')), findsOneWidget);
    });

    /// Three coral buttons would be three things shouting.
    testWidgets('only the next step is a button', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments', units: 2)],
      ));
      await tester.pumpAndSettle();

      expect(inStarted('p1', find.text('1 of 3 done')), findsOneWidget);
      expect(inStarted('p1', find.text('Do it')), findsOneWidget);
    });

    testWidgets('the next step opens where it is done', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments')],
      ));
      await tester.pumpAndSettle();

      await tester.tap(inStarted('p1', find.text('Do it')));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    /// An account switched off is one no tenant can see.
    testWidgets('a hidden account does not tick paying', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments', units: 2)],
        channels: [_myChannel(visible: false, properties: ['p1'])],
      ));
      await tester.pumpAndSettle();

      expect(inStarted('p1', find.text('1 of 3 done')), findsOneWidget);
    });

    testWidgets('an account used here ticks paying', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments', units: 2)],
        channels: [_myChannel(properties: ['p1'])],
      ));
      await tester.pumpAndSettle();

      expect(inStarted('p1', find.text('2 of 3 done')), findsOneWidget);
    });

    /// Somebody asking is the only sign the app has that the code got out.
    testWidgets('somebody asking to rent ticks sharing the code',
        (tester) async {
      await tester.pumpWidget(appWith(
        threads: [asking()],
        properties: [aProperty('p1', 'Sunrise Apartments', units: 2)],
        channels: [_myChannel(properties: ['p1'])],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('get-started-p1')), findsNothing);
    });

    testWidgets('a property somebody lives in has its code ticked',
        (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments', units: 2)],
        channels: [_myChannel(properties: ['p1'])],
        occupied: 1,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('get-started-p1')), findsNothing);
    });

    /// One card each: a landlord adding a second property is not starting over
    /// on the first.
    testWidgets('each unfinished property gets its own card', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [
          aProperty('p1', 'Sunrise Apartments'),
          aProperty('p2', 'Sunset Residences', units: 3),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('get-started-p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('get-started-p2')), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);
    });

    /// Scaffolding, not a permanent part of Today.
    testWidgets('nothing is shown once a property is set up', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments', units: 2)],
        channels: [_myChannel(properties: ['p1'])],
        occupied: 1,
      ));
      await tester.pumpAndSettle();

      expect(find.text('GET STARTED'), findsNothing);
      expect(find.byKey(const ValueKey('all-caught-up')), findsOneWidget);
    });

    /// A step ticked and then unticked reads as the app losing what was done.
    testWidgets('nothing is shown until every answer is in', (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        properties: [aProperty('p1', 'Sunrise Apartments')],
        channels: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('GET STARTED'), findsNothing);
    });

    PlatformStatementResponse statement({
      bool overdue = false,
      String paymentStatus = '',
    }) => PlatformStatementResponse(
          id: 's1',
          label: 'September 2026',
          billingDate: DateTime.utc(2026, 9, 1),
          dueDate: DateTime.utc(2026, 9, 1),
          amountDue: 450,
          amountPaid: 0,
          outstanding: 450,
          status: PlatformStatementResponseStatusEnum.fromJson('UNPAID'),
          overdue: overdue,
          locksOn: overdue ? DateTime.utc(2026, 10, 1) : null,
          locked: false,
          lines: [
            PlatformInvoiceLine(
              id: 'l1',
              propertyId: 'p1',
              propertyName: 'Sunrise Apartments',
              occupiedBeds: 9,
              occupiedUnits: 0,
              bedRate: 50,
              unitRate: 150,
              amountDue: 450,
            ),
          ],
          payments: [
            if (paymentStatus.isNotEmpty)
              PlatformPaymentResponse(
                id: 'pp1',
                amountPaid: 450,
                status: PlatformPaymentResponseStatusEnum.fromJson(paymentStatus),
              ),
          ],
        );

    /// Left alone it locks every property thirty days on, and a landlord who
    /// learns that from the lock has learned it too late.
    testWidgets('a Lizmo statement to pay is on Today', (tester) async {
      await tester.pumpWidget(
          appWith(threads: const [], lizmo: [statement(overdue: true)]));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('lizmo-statement-card')), findsOneWidget);
      expect(find.text('September 2026 · 1 property'), findsOneWidget);
      expect(find.text('Overdue · everything locks on 1 Oct'), findsOneWidget);
      expect(find.byKey(const ValueKey('all-caught-up')), findsNothing);
    });

    /// Paid and waiting for Lizmo is the landlord's part done.
    testWidgets('a statement already paid for is not asked for again',
        (tester) async {
      await tester.pumpWidget(appWith(
        threads: const [],
        lizmo: [statement(paymentStatus: 'PENDING_VERIFICATION')],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lizmo-statement-card')), findsNothing);
      expect(find.byKey(const ValueKey('all-caught-up')), findsOneWidget);
    });

    testWidgets('what needs you comes before the figures', (tester) async {
      await tester.pumpWidget(appWith(arrears: [behind()], threads: [asking()]));
      await tester.pumpAndSettle();

      final conversationsTop =
          tester.getTopLeft(find.byKey(const ValueKey('inquiries-card'))).dy;
      final arrearsTop =
          tester.getTopLeft(find.byKey(const ValueKey('arrears-card'))).dy;
      final figuresTop = tester.getTopLeft(find.text('Collections')).dy;

      expect(conversationsTop, lessThan(arrearsTop));
      expect(arrearsTop, lessThan(figuresTop));
    });
  });

  group('occupancy', () {
    VacancyRow vacancy({
      String id = 'p1',
      String name = 'Sunrise Apartments',
      int empty = 3,
      num emptyRent = 7500,
    }) => VacancyRow(
      propertyId: id,
      propertyName: name,
      lettable: 4,
      occupied: 4 - empty,
      empty: empty,
      emptyRent: emptyRent,
    );

    Widget appWith({
      int lettable = 4,
      int occupied = 1,
      int empty = 3,
      int outOfService = 0,
      num emptyRent = 7500,
      List<VacancyRow> vacancies = const [],
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        collectionsProvider.overrideWith((ref) async => CollectionsSummary(
              dueThisMonth: 0,
              collectedThisMonth: 0,
              outstandingAllTime: 0,
              awaitingConfirmation: 0,
              tenanciesInArrears: 0,
            )),
        occupancyProvider.overrideWith((ref) async => OccupancySummary(
              lettable: lettable,
              occupied: occupied,
              empty: empty,
              outOfService: outOfService,
              earningRent: 2500,
              emptyRent: emptyRent,
              vacancies: vacancies,
            )),
        unitsProvider('p1').overrideWith((ref) async => const <UnitResponse>[]),
        myInquiriesProvider
            .overrideWith((ref) async => const <InquirySummary>[]),
      ],
      child: const LizmoApp(),
    );

    /// Slots, not units. One tenant in a four-bed room is not a full building,
    /// and the headline is the sentence a landlord would say out loud.
    testWidgets('the headline counts lettable slots', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.text('Occupancy'), findsOneWidget);
      expect(find.text('1 of 4 let'), findsOneWidget);
    });

    /// The figure that turns "three beds free" into a reason to do something.
    testWidgets('empty space is priced', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.text('Potential earnings'), findsOneWidget);
      expect(find.text('₱7,500'), findsOneWidget);
    });

    /// A room off the market on purpose is not a vacancy anybody needs to
    /// fill, so it is counted apart.
    testWidgets('out of service is shown apart from empty', (tester) async {
      await tester.pumpWidget(appWith(outOfService: 2));
      await tester.pumpAndSettle();

      expect(find.text('Out of service'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('nothing out of service leaves the column off', (tester) async {
      await tester.pumpWidget(appWith());
      await tester.pumpAndSettle();

      expect(find.text('Out of service'), findsNothing);
    });

    testWidgets('nothing to let says what to do about it', (tester) async {
      await tester.pumpWidget(appWith(lettable: 0, occupied: 0, empty: 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Add a room or a unit'), findsOneWidget);
      expect(find.text('Potential earnings'), findsNothing);
    });

    testWidgets('where the space is, and how much it is worth',
        (tester) async {
      await tester.pumpWidget(appWith(vacancies: [vacancy()]));
      await tester.pumpAndSettle();

      expect(find.text('Where the space is'), findsOneWidget);
      expect(find.text('Sunrise Apartments'), findsOneWidget);
      expect(find.text('3 vacant'), findsOneWidget);
    });

    testWidgets('a full portfolio lists no vacancies', (tester) async {
      await tester.pumpWidget(appWith(occupied: 4, empty: 0, emptyRent: 0));
      await tester.pumpAndSettle();

      expect(find.text('4 of 4 let'), findsOneWidget);
      expect(find.text('Where the space is'), findsNothing);
    });

    /// The next thing a landlord wants is the room list they will advertise
    /// from.
    testWidgets('a vacancy row leads to the property, inside Today',
        (tester) async {
      await tester.pumpWidget(appWith(vacancies: [vacancy()]));
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('vacancy-p1'));
      await tester.scrollUntilVisible(row, 200,
          scrollable: find.byType(Scrollable).first);
      // Scrolled to, then settled: the getting-started cards above it change
      // the page's height as they arrive.
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      // It used to switch to the Properties tab.
      expect(_tabIndex(tester), 0);
    });
  });

  group('the Rent tab', () {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    BillingPeriodResponse period({
      String id = 'b1',
      num due = 2500,
      num paid = 0,
      bool overdue = false,
      BillingPeriodResponseStatusEnum status =
          BillingPeriodResponseStatusEnum.UNPAID,
    }) => BillingPeriodResponse(
      id: id,
      label: 'September 2026',
      periodStart: DateTime.utc(2026, 9, 5),
      periodEnd: DateTime.utc(2026, 10, 4),
      dueDate: DateTime.utc(2026, 9, 5),
      amountDue: due,
      amountPaid: paid,
      outstanding: due - paid < 0 ? 0 : due - paid,
      status: status,
      overdue: overdue,
    );

    RentRollRow row({
      String lease = 'l1',
      String tenant = 'Miguel Cruz',
      String propertyId = 'p1',
      String propertyName = 'Sunrise Apartments',
      String? bed = 'Bed 1',
      bool current = true,
      BillingPeriodResponse? month,
      List<WaitingPayment> waiting = const [],
    }) => RentRollRow(
      propertyId: propertyId,
      propertyName: propertyName,
      leaseId: lease,
      current: current,
      tenantName: tenant,
      unitNumber: '2B',
      bedLabel: bed,
      period: month ?? period(),
      waiting: waiting,
    );

    WaitingPayment claim() => WaitingPayment(
      paymentId: 'pay1',
      amount: 2500,
      paidOn: DateTime.utc(2026, 9, 3),
      method: WaitingPaymentMethodEnum.GCASH,
      note: 'Sent from my sister’s number.',
    );

    RentRoll roll(
      List<RentRollRow> rows, {
      String? earliest,
      num due = 2500,
      num collected = 0,
      num outstanding = 2500,
    }) => RentRoll(
      month: monthKey(thisMonth),
      earliestMonth: earliest ?? monthKey(thisMonth),
      due: due,
      collected: collected,
      outstanding: outstanding,
      rows: rows,
    );

    Widget appWith(
      RentRoll current, {
      RentRoll? previous,
      _FakeRentApi? api,
    }) => ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(DateTime(2026, 10, 3)),
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        rentRollProvider(monthKey(thisMonth)).overrideWith((ref) async => current),
        rentRollProvider(monthKey(lastMonth)).overrideWith(
          (ref) async => previous ?? roll(const [], due: 0, outstanding: 0),
        ),
        ..._tenancyL1(),
        if (api != null) rentApiProvider.overrideWithValue(api),
      ],
      child: const LizmoApp(),
    );

    Future<void> openRent(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-rent')));
      await tester.pumpAndSettle();
    }

    Finder inHeader(Finder finder) =>
        find.descendant(of: find.byType(LatticeHeader), matching: finder);

    testWidgets('Rent is a tab of its own, beside Today', (tester) async {
      await tester.pumpWidget(appWith(roll([row()])));
      await openRent(tester);

      expect(find.byType(RentRollScreen), findsOneWidget);
      expect(_tabIndex(tester), 1);
      expect(find.text(monthName(thisMonth)), findsOneWidget);
    });

    /// A section per building, a room per row, and where each stands.
    testWidgets('every room says what it owes and where it stands',
        (tester) async {
      await tester.pumpWidget(appWith(roll([
        row(),
        row(
          lease: 'l3',
          tenant: 'Carlo Reyes',
          bed: 'Bed 2',
          month: period(id: 'b3', overdue: true),
        ),
        row(
          lease: 'l2',
          tenant: 'Bea Santos',
          propertyId: 'p2',
          propertyName: 'Sunset Residences',
          bed: null,
          month: period(
            id: 'b2',
            paid: 2500,
            status: BillingPeriodResponseStatusEnum.PAID,
          ),
        ),
      ])));
      await openRent(tester);

      expect(find.text('Sunrise Apartments'), findsOneWidget);
      expect(find.text('Sunset Residences'), findsOneWidget);
      expect(find.text('Bed 1, 2B · due 5 Sep'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
    });

    testWidgets('the month\'s figures sit in the header', (tester) async {
      await tester.pumpWidget(appWith(
        roll([row()], due: 7500, collected: 2500, outstanding: 5000),
      ));
      await openRent(tester);

      expect(inHeader(find.text('₱7,500')), findsOneWidget);
      expect(inHeader(find.text('₱2,500')), findsOneWidget);
      expect(inHeader(find.text('₱5,000')), findsOneWidget);
    });

    testWidgets('a declared payment on the Rent tab says which account it went to',
        (tester) async {
      await tester.pumpWidget(appWith(roll([
        row(waiting: [
          WaitingPayment(
            paymentId: 'pay1',
            amount: 2500,
            paidOn: DateTime.utc(2026, 9, 3),
            method: WaitingPaymentMethodEnum.GCASH,
            sentTo: 'GCash · Elena Reyes · 09171112222',
          ),
        ]),
      ])));
      await openRent(tester);

      expect(find.text('Sent to GCash · Elena Reyes · 09171112222'), findsOneWidget);
    });

    /// Answered where it is read, rather than a tenant's screen away.
    testWidgets('a payment the tenant declared is confirmed on the row',
        (tester) async {
      final api = _FakeRentApi();
      await tester.pumpWidget(appWith(roll([row(waiting: [claim()])]), api: api));
      await openRent(tester);

      expect(find.text('Says they paid ₱2,500 by GCash on 3 Sep'), findsOneWidget);
      expect(find.text('Sent from my sister’s number.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm-pay1')));
      await tester.pumpAndSettle();

      expect(api.confirmed, ['pay1']);
      expect(find.text('Confirmed.'), findsOneWidget);
    });

    testWidgets('refusing one asks why, and passes the reason on',
        (tester) async {
      final api = _FakeRentApi();
      await tester.pumpWidget(appWith(roll([row(waiting: [claim()])]), api: api));
      await openRent(tester);

      await tester.tap(find.byKey(const ValueKey('reject-pay1')));
      await tester.pumpAndSettle();
      expect(find.text('Say it did not arrive?'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('reject-reason')), 'Nothing arrived');
      await tester.tap(find.byKey(const ValueKey('reject-confirm')));
      await tester.pumpAndSettle();

      expect(api.refused, [('pay1', 'Nothing arrived')]);
    });

    /// Cash handed over at the door had nowhere to go.
    testWidgets('cash can be written down, and counts straight away',
        (tester) async {
      final api = _FakeRentApi();
      await tester.pumpWidget(appWith(roll([row()]), api: api));
      await openRent(tester);

      await tester.tap(find.byKey(const ValueKey('record-b1')));
      await tester.pumpAndSettle();

      expect(find.text('Record a payment'), findsOneWidget);
      expect(find.textContaining('It counts straight away'), findsOneWidget);

      final submit = find.byKey(const ValueKey('record-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(api.recorded, hasLength(1));
      final written = api.recorded.single;
      expect(written.billingPeriodId, 'b1');
      // What was left, unless the landlord typed something else.
      expect(written.amountPaid, 2500);
      expect(written.paymentMethod, RecordPaymentRequestPaymentMethodEnum.CASH);
      expect(written.paymentDate, DateTime.utc(now.year, now.month, now.day));
    });

    testWidgets('a payment with no amount is not recorded', (tester) async {
      final api = _FakeRentApi();
      await tester.pumpWidget(appWith(roll([row()]), api: api));
      await openRent(tester);

      await tester.tap(find.byKey(const ValueKey('record-b1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('record-amount')), '');

      final submit = find.byKey(const ValueKey('record-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('How much did you receive?'), findsOneWidget);
      expect(api.recorded, isEmpty);
    });

    testWidgets('a settled month offers nothing to record', (tester) async {
      await tester.pumpWidget(appWith(roll([
        row(
          month: period(paid: 2500, status: BillingPeriodResponseStatusEnum.PAID),
        ),
      ])));
      await openRent(tester);

      expect(find.byKey(const ValueKey('record-b1')), findsNothing);
    });

    /// Still listed for the month they owed, and said so, so a landlord does
    /// not go looking for them in Tenants.
    testWidgets('somebody who moved out is listed, and says so',
        (tester) async {
      await tester.pumpWidget(appWith(roll([row(current: false)])));
      await openRent(tester);

      expect(find.textContaining('moved out'), findsOneWidget);

      // There is no tenant screen to open once a tenancy has ended.
      await tester.tap(find.text('Miguel Cruz'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantDetailScreen), findsNothing);
    });

    testWidgets('a room opens its tenant, inside Rent', (tester) async {
      await tester.pumpWidget(appWith(roll([row()])));
      await openRent(tester);

      await tester.tap(find.text('Miguel Cruz'));
      await tester.pumpAndSettle();

      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(_tabIndex(tester), 1);
    });

    testWidgets('months go back as far as there was rent, and no further',
        (tester) async {
      await tester.pumpWidget(appWith(
        roll([row()], earliest: monthKey(lastMonth)),
        previous: roll([row(tenant: 'Bea Santos')], earliest: monthKey(lastMonth)),
      ));
      await openRent(tester);

      IconButton arrow(String key) =>
          tester.widget<IconButton>(find.byKey(ValueKey(key)));

      // Never forward past this month: nothing is due in a month not begun.
      expect(arrow('month-forward').onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('month-back')));
      await tester.pumpAndSettle();

      expect(find.text(monthName(lastMonth)), findsOneWidget);
      expect(find.text('Bea Santos'), findsOneWidget);
      expect(arrow('month-back').onPressed, isNull);
      expect(arrow('month-forward').onPressed, isNotNull);
    });

    testWidgets('a month with nothing due says so', (tester) async {
      await tester.pumpWidget(appWith(roll(const [], due: 0, outstanding: 0)));
      await openRent(tester);

      expect(find.text('No rent due in ${monthName(thisMonth)}'), findsOneWidget);
    });
  });

  MaintenanceReportResponse maintenanceReport({
    String id = 'm1',
    String status = 'SUBMITTED',
    bool reopened = false,
    String? remarks,
    String? reopenReason,
  }) => MaintenanceReportResponse(
    id: id,
    leaseId: 'l1',
    propertyId: 'p1',
    propertyName: 'Sunrise Apartments',
    unitNumber: '2B',
    bedLabel: 'Bed 1',
    tenantName: 'Ana Reyes',
    description: 'The tap will not stop dripping.',
    status: MaintenanceReportResponseStatusEnum.fromJson(status),
    landlordRemarks: remarks,
    reopened: reopened,
    reopenReason: reopenReason,
    submittedAt: DateTime.utc(2026, 9, 3, 4),
    photoUrls: const [],
  );

  group('maintenance, as the tenant', () {
    Widget appWith({
      List<MaintenanceReportResponse> reports = const [],
      _FakeMaintenanceApi? api,
      bool renting = true,
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.tenant})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        myTenantProfileProvider.overrideWith(
          (ref) async => TenantProfileResponse(contactPhone: '09170000001', readyForALease: true),
        ),
        myTenantDocumentsProvider.overrideWith(
          (ref) async => const <TenantDocumentResponse>[],
        ),
        myInquiriesProvider.overrideWith(
          (ref) async => const <InquirySummary>[],
        ),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        myLeasesProvider.overrideWith((ref) async => renting
            ? [
                LeaseResponse(
                  id: 'l1',
                  tenantId: 't1',
                  propertyName: 'Sunrise Apartments',
                  unitNumber: '2B',
                  bedLabel: 'Bed 1',
                  rentAmount: 2500,
                  dueDateDay: 5,
                  status: LeaseResponseStatusEnum.ACTIVE,
                ),
              ]
            : const <LeaseResponse>[]),
        myMaintenanceProvider.overrideWith((ref) async => reports),
        if (api != null) maintenanceApiProvider.overrideWithValue(api),
      ],
      child: const LizmoApp(),
    );

    Future<void> openMaintenance(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-maintenance')));
      await tester.pumpAndSettle();
    }

    testWidgets('nothing reported yet offers the way to report',
        (tester) async {
      await tester.pumpWidget(appWith());
      await openMaintenance(tester);

      expect(find.byKey(const ValueKey('report-problem')), findsOneWidget);
      expect(find.text('Nothing reported'), findsOneWidget);
    });

    /// A report belongs to a tenancy: there is nothing to report about a room
    /// you do not live in.
    testWidgets('somebody not renting is told why they cannot report',
        (tester) async {
      await tester.pumpWidget(appWith(renting: false));
      await openMaintenance(tester);

      expect(find.text('Nothing to report yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-problem')), findsNothing);
    });

    testWidgets('reporting sends what was written to the landlord',
        (tester) async {
      final api = _FakeMaintenanceApi(maintenanceReport());
      await tester.pumpWidget(appWith(api: api));
      await openMaintenance(tester);

      await tester.tap(find.byKey(const ValueKey('report-problem')));
      await tester.pumpAndSettle();
      expect(find.text('Report a problem'), findsWidgets);

      await tester.enterText(
          find.byKey(const ValueKey('problem-description')), 'The tap drips.');
      final send = find.byKey(const ValueKey('send-report'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(api.reported, ['The tap drips.']);
      expect(api.photos, isEmpty);
      expect(find.text('Sent to your landlord.'), findsOneWidget);
    });

    testWidgets('a report has to say something', (tester) async {
      final api = _FakeMaintenanceApi(maintenanceReport());
      await tester.pumpWidget(appWith(api: api));
      await openMaintenance(tester);

      await tester.tap(find.byKey(const ValueKey('report-problem')));
      await tester.pumpAndSettle();
      final send = find.byKey(const ValueKey('send-report'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(find.text('Say what is broken'), findsOneWidget);
      expect(api.reported, isEmpty);
    });

    testWidgets('a report shows where it has got to, and what was said',
        (tester) async {
      await tester.pumpWidget(appWith(reports: [
        maintenanceReport(
            status: 'IN_PROGRESS', remarks: 'The plumber comes Saturday.'),
      ]));
      await openMaintenance(tester);

      expect(find.text('The tap will not stop dripping.'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Your landlord'), findsOneWidget);
      expect(find.text('The plumber comes Saturday.'), findsOneWidget);
    });

    testWidgets('a report nobody has started on can be taken back',
        (tester) async {
      final api = _FakeMaintenanceApi(maintenanceReport());
      await tester.pumpWidget(appWith(reports: [maintenanceReport()], api: api));
      await openMaintenance(tester);

      await tester.tap(find.byKey(const ValueKey('withdraw-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
      await tester.pumpAndSettle();

      expect(api.withdrawn, ['m1']);
    });

    /// Somebody may already have bought the part.
    testWidgets('once work has started there is nothing to take back',
        (tester) async {
      await tester.pumpWidget(
          appWith(reports: [maintenanceReport(status: 'IN_PROGRESS')]));
      await openMaintenance(tester);

      expect(find.byKey(const ValueKey('withdraw-m1')), findsNothing);
    });

    /// A landlord saying it is fixed and it being fixed are different things.
    testWidgets('the tenant has the last word on fixed', (tester) async {
      final api = _FakeMaintenanceApi(maintenanceReport());
      await tester.pumpWidget(appWith(
          reports: [maintenanceReport(status: 'RESOLVED')], api: api));
      await openMaintenance(tester);

      expect(find.text('Your landlord says this is fixed. Is it?'),
          findsOneWidget);
      expect(find.text('Is it fixed?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fixed-m1')));
      await tester.pumpAndSettle();

      expect(api.fixed, ['m1']);
    });

    testWidgets('still broken asks why, and will not send without it',
        (tester) async {
      final api = _FakeMaintenanceApi(maintenanceReport());
      await tester.pumpWidget(appWith(
          reports: [maintenanceReport(status: 'RESOLVED')], api: api));
      await openMaintenance(tester);

      await tester.tap(find.byKey(const ValueKey('reopen-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reopen-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Say what is still wrong'), findsOneWidget);
      expect(api.reopened, isEmpty);

      await tester.enterText(
          find.byKey(const ValueKey('reopen-reason')), 'Dripping again.');
      await tester.tap(find.byKey(const ValueKey('reopen-confirm')));
      await tester.pumpAndSettle();

      expect(api.reopened, [('m1', 'Dripping again.')]);
    });

    testWidgets('a reopened report says so', (tester) async {
      await tester.pumpWidget(appWith(reports: [
        maintenanceReport(reopened: true, reopenReason: 'Dripping again.'),
      ]));
      await openMaintenance(tester);

      expect(find.text('Reopened'), findsOneWidget);
      expect(find.text('You said it was still broken'), findsOneWidget);
    });
  });

  group('maintenance, as the landlord', () {
    Widget appWith({
      List<MaintenanceReportResponse> reports = const [],
      _FakeMaintenanceToHandleApi? api,
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        maintenanceToHandleProvider.overrideWith((ref) async => reports),
        for (final report in reports)
          maintenanceReportProvider(report.id!).overrideWith((ref) async => report),
        if (api != null) maintenanceToHandleApiProvider.overrideWithValue(api),
      ],
      child: const LizmoApp(),
    );

    Future<void> openMaintenance(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-maintenance')));
      await tester.pumpAndSettle();
    }

    testWidgets('Maintenance is the fifth tab', (tester) async {
      await tester.pumpWidget(appWith());
      await openMaintenance(tester);

      expect(find.byType(MaintenanceInboxScreen), findsOneWidget);
      expect(_tabIndex(tester), 4);
      expect(find.text('Nothing reported'), findsOneWidget);
    });

    /// The question a landlord opens this with is whose move it is.
    testWidgets('reports are grouped by whose move it is', (tester) async {
      await tester.pumpWidget(appWith(reports: [
        maintenanceReport(id: 'm1'),
        maintenanceReport(id: 'm2', status: 'IN_PROGRESS'),
        maintenanceReport(id: 'm3', status: 'RESOLVED'),
        maintenanceReport(id: 'm4', status: 'CLOSED'),
      ]));
      await openMaintenance(tester);

      expect(find.text('Needs you'), findsOneWidget);
      expect(find.text('Waiting for the tenant to confirm'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(LatticeHeader), matching: find.text('1')),
          findsNWidgets(3));
    });

    testWidgets('a report opens inside Maintenance, saying where and who',
        (tester) async {
      await tester.pumpWidget(appWith(reports: [maintenanceReport()]));
      await openMaintenance(tester);

      await tester.tap(find.byKey(const ValueKey('maintenance-m1')));
      await tester.pumpAndSettle();

      expect(find.byType(MaintenanceReportScreen), findsOneWidget);
      expect(_tabIndex(tester), 4);
      expect(find.text('Bed 1, 2B · Sunrise Apartments'), findsOneWidget);
      expect(find.text('Reported by Ana Reyes on 3 Sep'), findsOneWidget);
    });

    testWidgets('starting on it passes the remark on', (tester) async {
      final api = _FakeMaintenanceToHandleApi();
      await tester.pumpWidget(appWith(reports: [maintenanceReport()], api: api));
      await openMaintenance(tester);
      await tester.tap(find.byKey(const ValueKey('maintenance-m1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-maintenance')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('maintenance-remark')), 'Plumber Saturday.');
      await tester.tap(find.byKey(const ValueKey('remark-confirm')));
      await tester.pumpAndSettle();

      expect(api.started, [('m1', 'Plumber Saturday.')]);
    });

    /// The tenant is told either way; saying nothing sends nothing.
    testWidgets('marking fixed without a remark sends none', (tester) async {
      final api = _FakeMaintenanceToHandleApi();
      await tester.pumpWidget(appWith(reports: [maintenanceReport()], api: api));
      await openMaintenance(tester);
      await tester.tap(find.byKey(const ValueKey('maintenance-m1')));
      await tester.pumpAndSettle();

      final resolve = find.byKey(const ValueKey('resolve-maintenance'));
      await tester.ensureVisible(resolve);
      await tester.tap(resolve);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('remark-confirm')));
      await tester.pumpAndSettle();

      expect(api.resolved, [('m1', null)]);
    });

    /// A reopened report looks exactly like a new one otherwise, and is not.
    testWidgets('a reopened report says why, before anything else',
        (tester) async {
      await tester.pumpWidget(appWith(reports: [
        maintenanceReport(reopened: true, reopenReason: 'Dripping again.'),
      ]));
      await openMaintenance(tester);

      expect(find.text('Reopened'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('maintenance-m1')));
      await tester.pumpAndSettle();

      expect(find.text('Your tenant says it is still broken'), findsOneWidget);
      expect(find.text('Dripping again.'), findsOneWidget);
    });

    testWidgets('once marked fixed, the move is the tenant\'s',
        (tester) async {
      await tester.pumpWidget(
          appWith(reports: [maintenanceReport(status: 'RESOLVED')]));
      await openMaintenance(tester);
      await tester.tap(find.byKey(const ValueKey('maintenance-m1')));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for your tenant to confirm it is fixed.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('start-maintenance')), findsNothing);
      expect(find.byKey(const ValueKey('resolve-maintenance')), findsNothing);
    });
  });

  group('how tenants pay me', () {
    PropertyResponse aProperty(String id, String name) => PropertyResponse(
          id: id,
          name: name,
          address: '12 Mabini St',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: 1,
        );

    Widget appWith(
      _FakePaymentChannelsApi api, {
      Future<PickedImage?> Function()? pick,
      List<PropertyResponse> properties = const [],
    }) =>
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
            ),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesProvider.overrideWith((ref) async => properties),
            myNotificationsProvider.overrideWith(
              (ref) async => const <NotificationResponse>[],
            ),
            // Not the list providers: they read this fake, so a change and the
            // re-read after it are both what gets tested.
            paymentChannelsApiProvider.overrideWithValue(api),
            if (pick != null) pickGalleryImageProvider.overrideWithValue(pick),
          ],
          child: const LizmoApp(),
        );

    Future<void> openIt(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How tenants pay me'));
      await tester.pumpAndSettle();
    }

    Future<void> tapShown(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('a landlord finds it in the account menu', (tester) async {
      await tester.pumpWidget(appWith(_FakePaymentChannelsApi([])));
      await openIt(tester);

      expect(find.byType(PaymentChannelsScreen), findsOneWidget);
      expect(find.text('No ways to pay yet'), findsOneWidget);
    });

    testWidgets('the channels are listed, and a hidden one says so', (tester) async {
      await tester.pumpWidget(appWith(_FakePaymentChannelsApi([
        _myChannel(),
        _myChannel(id: 'c2', channel: 'Maya', number: '09173334444', visible: false),
      ])));
      await openIt(tester);

      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('Elena Reyes \u00b7 09171112222'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.widgetWithText(StatusChip, 'Hidden'), findsOneWidget);
    });

    testWidgets('adding a channel sends its details, then the QR chosen',
        (tester) async {
      final api = _FakePaymentChannelsApi([]);
      await tester.pumpWidget(appWith(api,
          pick: () async => (name: 'gcash.png', bytes: Uint8List.fromList([1, 2, 3]))));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('add-payment-channel')));
      await tester.enterText(find.byKey(const ValueKey('channel-field')), 'GCash');
      await tester.enterText(
          find.byKey(const ValueKey('account-name-field')), 'Elena Reyes');
      await tester.enterText(
          find.byKey(const ValueKey('account-number-field')), '09171112222');
      await tapShown(tester, find.byKey(const ValueKey('pick-qr')));
      await tapShown(tester, find.byKey(const ValueKey('save-channel')));

      expect(api.added.single.channel, 'GCash');
      expect(api.added.single.accountName, 'Elena Reyes');
      expect(api.added.single.accountNumber, '09171112222');
      expect(api.uploaded, [('new', 3)]);
      expect(find.byType(PaymentChannelSheet), findsNothing);
      expect(find.text('Elena Reyes \u00b7 09171112222'), findsOneWidget);
    });

    /// A channel with no number is a tenant told to pay and unable to.
    testWidgets('a blank account number is refused before calling the API',
        (tester) async {
      final api = _FakePaymentChannelsApi([]);
      await tester.pumpWidget(appWith(api));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('add-payment-channel')));
      await tester.enterText(find.byKey(const ValueKey('channel-field')), 'GCash');
      await tester.enterText(
          find.byKey(const ValueKey('account-name-field')), 'Elena Reyes');
      await tapShown(tester, find.byKey(const ValueKey('save-channel')));

      expect(find.text('Enter the account number'), findsOneWidget);
      expect(api.added, isEmpty);
    });

    testWidgets('switching one off sends it hidden, with its details unchanged',
        (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel()]);
      await tester.pumpWidget(appWith(api));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('channel-visible-c1')));

      expect(api.updated.single.$1, 'c1');
      expect(api.updated.single.$2.visible, isFalse);
      expect(api.updated.single.$2.accountNumber, '09171112222');
      expect(find.widgetWithText(StatusChip, 'Hidden'), findsOneWidget);
    });

    testWidgets('moving one down sends the whole new order', (tester) async {
      final api = _FakePaymentChannelsApi([
        _myChannel(),
        _myChannel(id: 'c2', channel: 'Maya'),
        _myChannel(id: 'c3', channel: 'BPI'),
      ]);
      await tester.pumpWidget(appWith(api));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('channel-down-c1')));

      expect(api.order, ['c2', 'c1', 'c3']);
    });

    testWidgets('deleting asks first, and backing out deletes nothing',
        (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel()]);
      await tester.pumpWidget(appWith(api));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('delete-channel-c1')));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(api.deleted, isEmpty);

      await tapShown(tester, find.byKey(const ValueKey('delete-channel-c1')));
      await tester.tap(find.byKey(const ValueKey('confirm-delete-channel')));
      await tester.pumpAndSettle();

      expect(api.deleted, ['c1']);
      expect(find.text('GCash'), findsNothing);
    });

    testWidgets('editing a channel can take its QR away', (tester) async {
      final api = _FakePaymentChannelsApi(
          [_myChannel(qrUrl: 'https://example.test/qr.jpg')]);
      await tester.pumpWidget(appWith(api));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('edit-channel-c1')));
      await tapShown(tester, find.byKey(const ValueKey('remove-qr')));
      await tapShown(tester, find.byKey(const ValueKey('save-channel')));

      expect(api.updated.single.$1, 'c1');
      expect(api.removedQr, ['c1']);
      expect(api.uploaded, isEmpty);
    });

    testWidgets('the note shows what was saved, and saves what is typed',
        (tester) async {
      final api = _FakePaymentChannelsApi([], note: 'Cash to Aling Nena at unit 1A');
      await tester.pumpWidget(appWith(api));
      await openIt(tester);

      final field = find.byKey(const ValueKey('payment-note-field'));
      await tester.ensureVisible(field);
      expect(find.text('Cash to Aling Nena at unit 1A'), findsOneWidget);

      await tester.enterText(field, 'Pay before the 5th, please');
      await tapShown(tester, find.byKey(const ValueKey('save-payment-note')));

      expect(api.savedNote, 'Pay before the 5th, please');
      expect(find.text('Note saved.'), findsOneWidget);
    });

    // ---- which properties an account is used for -----------------------------------------

    /// Rent landing in a wallet nobody chose for that property is the worse
    /// mistake, so a new account is asked about at once.
    testWidgets('a new account asks where it is used, and sends what is ticked',
        (tester) async {
      final api = _FakePaymentChannelsApi([]);
      await tester.pumpWidget(appWith(api, properties: [
        aProperty('p1', 'Sunrise Apartments'),
        aProperty('p2', 'Sunset Residences'),
      ]));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('add-payment-channel')));
      await tester.enterText(find.byKey(const ValueKey('channel-field')), 'GCash');
      await tester.enterText(
          find.byKey(const ValueKey('account-name-field')), 'Elena Reyes');
      await tester.enterText(
          find.byKey(const ValueKey('account-number-field')), '09171112222');
      await tapShown(tester, find.byKey(const ValueKey('save-channel')));

      expect(find.text('Where do you use GCash?'), findsOneWidget);
      await tapShown(tester, find.byKey(const ValueKey('channel-property-p1')));
      await tapShown(tester, find.byKey(const ValueKey('save-channel-properties')));

      expect(api.usedFor.single.$1, 'new');
      expect(api.usedFor.single.$2, ['p1']);
    });

    testWidgets('an account says where it is used, and changing it sends the lot',
        (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel(properties: ['p1'])]);
      await tester.pumpWidget(appWith(api, properties: [
        aProperty('p1', 'Sunrise Apartments'),
        aProperty('p2', 'Sunset Residences'),
      ]));
      await openIt(tester);

      expect(find.text('Used at Sunrise Apartments'), findsOneWidget);

      await tapShown(tester, find.byKey(const ValueKey('channel-properties-c1')));
      await tapShown(tester, find.byKey(const ValueKey('channel-property-p2')));
      await tapShown(tester, find.byKey(const ValueKey('save-channel-properties')));

      expect(api.usedFor.single.$2, ['p1', 'p2']);
      expect(find.text('Used at all 2 properties'), findsOneWidget);
    });

    /// One wallet everywhere is the common case.
    testWidgets('all my properties ticks every one', (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel()]);
      await tester.pumpWidget(appWith(api, properties: [
        aProperty('p1', 'Sunrise Apartments'),
        aProperty('p2', 'Sunset Residences'),
      ]));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('channel-properties-c1')));
      await tapShown(tester, find.byKey(const ValueKey('channel-properties-all')));
      await tapShown(tester, find.byKey(const ValueKey('save-channel-properties')));

      expect(api.usedFor.single.$2, ['p1', 'p2']);
    });

    /// Said plainly: an account used nowhere reaches nobody, and a landlord
    /// who has just added one would otherwise think it was working.
    testWidgets('an account used nowhere says so', (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel()]);
      await tester.pumpWidget(
          appWith(api, properties: [aProperty('p1', 'Sunrise Apartments')]));
      await openIt(tester);

      expect(find.text('Not used anywhere yet'), findsOneWidget);
    });

    testWidgets('ticking nothing is allowed, and says what it means',
        (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel(properties: ['p1'])]);
      await tester.pumpWidget(
          appWith(api, properties: [aProperty('p1', 'Sunrise Apartments')]));
      await openIt(tester);

      await tapShown(tester, find.byKey(const ValueKey('channel-properties-c1')));
      await tapShown(tester, find.byKey(const ValueKey('channel-property-p1')));

      expect(find.text('With none ticked, no tenant sees this account.'),
          findsOneWidget);
      await tapShown(tester, find.byKey(const ValueKey('save-channel-properties')));

      expect(api.usedFor.single.$1, 'c1');
      expect(api.usedFor.single.$2, isEmpty);
      expect(find.text('No tenants see this account now.'), findsOneWidget);
    });

    /// The first a landlord would otherwise hear of it is a tenant asking
    /// where to send rent.
    testWidgets('a property with no way to pay is called out', (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel(properties: ['p1'])]);
      await tester.pumpWidget(appWith(api, properties: [
        aProperty('p1', 'Sunrise Apartments'),
        aProperty('p2', 'Sunset Residences'),
      ]));
      await openIt(tester);

      expect(find.byKey(const ValueKey('properties-without-payment')), findsOneWidget);
      expect(find.text('Tenants at Sunset Residences have no way to pay you'),
          findsOneWidget);
    });

    /// A hidden account is one tenants cannot see, so it covers nothing.
    testWidgets('a hidden account leaves its property with no way to pay',
        (tester) async {
      final api = _FakePaymentChannelsApi(
          [_myChannel(visible: false, properties: ['p1'])]);
      await tester.pumpWidget(
          appWith(api, properties: [aProperty('p1', 'Sunrise Apartments')]));
      await openIt(tester);

      expect(find.text('Tenants at Sunrise Apartments have no way to pay you'),
          findsOneWidget);
    });

    testWidgets('every property covered says nothing at all', (tester) async {
      final api = _FakePaymentChannelsApi([_myChannel(properties: ['p1'])]);
      await tester.pumpWidget(
          appWith(api, properties: [aProperty('p1', 'Sunrise Apartments')]));
      await openIt(tester);

      expect(find.byKey(const ValueKey('properties-without-payment')), findsNothing);
    });
  });

  group('Lizmo billing', () {
    PlatformInvoiceLine line({
      String id = 'l1',
      String property = 'Sunrise Apartments',
      int beds = 8,
      int units = 1,
      num amount = 550,
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
          issuedAt: invoiceNumber == null ? null : DateTime.utc(2026, 10, 3),
        );

    PlatformStatementResponse statement({
      String status = 'UNPAID',
      num paid = 0,
      bool overdue = false,
      bool locked = false,
      List<PlatformInvoiceLine>? lines,
      List<PlatformPaymentResponse> payments = const [],
    }) => PlatformStatementResponse(
          id: 's1',
          label: 'September 2026',
          billingDate: DateTime.utc(2026, 9, 1),
          dueDate: DateTime.utc(2026, 9, 1),
          amountDue: 700,
          amountPaid: paid,
          outstanding: 700 - paid,
          status: PlatformStatementResponseStatusEnum.fromJson(status),
          overdue: overdue,
          locksOn: overdue && !locked ? DateTime.utc(2026, 10, 1) : null,
          locked: locked,
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
          payments: payments,
        );

    Widget appWith({
      List<PlatformStatementResponse> statements = const [],
      PaymentDetails? payment,
    }) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(_signedIn({LizmoProfile.landlord})),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        myLizmoStatementsProvider.overrideWith((ref) async => statements),
        lizmoPaymentDetailsProvider
            .overrideWith((ref) async => payment ?? PaymentDetails()),
      ],
      child: const LizmoApp(),
    );

    Future<void> openBilling(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lizmo billing'));
      await tester.pumpAndSettle();
    }

    testWidgets('a landlord finds it in the account menu', (tester) async {
      await tester.pumpWidget(appWith());
      await openBilling(tester);

      expect(find.byType(LizmoBillingScreen), findsOneWidget);
      expect(find.text('No statements yet'), findsOneWidget);
    });

    /// One bill for the month, and a number a landlord cannot check is a number
    /// they telephone about -- so each property says how it was counted.
    testWidgets('one statement breaks down by property', (tester) async {
      await tester.pumpWidget(appWith(statements: [statement()]));
      await openBilling(tester);

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('2 properties'), findsOneWidget);
      expect(find.text('₱700'), findsWidgets);
      expect(find.text('Sunrise Apartments'), findsOneWidget);
      expect(find.text('8 beds × ₱50 + 1 unit × ₱150'), findsOneWidget);
      expect(find.text('₱550'), findsOneWidget);
      expect(find.text('Seaview Lodge'), findsOneWidget);
      expect(find.text('1 unit × ₱150'), findsOneWidget);
      expect(find.text('₱150'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
    });

    /// Nothing is invoiced until it is paid, so there is no number to show yet.
    testWidgets('an unpaid statement names no invoice', (tester) async {
      await tester.pumpWidget(appWith(statements: [statement()]));
      await openBilling(tester);

      expect(find.textContaining('Invoice LZM'), findsNothing);
    });

    /// Paid in full, each property has a document of its own to file.
    testWidgets('a paid statement gives each property its invoice',
        (tester) async {
      await tester.pumpWidget(appWith(statements: [
        statement(status: 'PAID', paid: 700, lines: [
          line(invoiceNumber: 'LZM-2026-09-0007'),
          line(
            id: 'l2',
            property: 'Seaview Lodge',
            beds: 0,
            units: 1,
            amount: 150,
            invoiceNumber: 'LZM-2026-09-0008',
          ),
        ]),
      ]));
      await openBilling(tester);

      // Scoped to the chip: the figures carry a Paid label of their own.
      expect(find.widgetWithText(StatusChip, 'Paid'), findsOneWidget);
      expect(find.text('Invoice LZM-2026-09-0007 · issued 3 Oct'),
          findsOneWidget);
      expect(find.text('Invoice LZM-2026-09-0008 · issued 3 Oct'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('pay-statement-s1')), findsNothing);
    });

    PaymentChannelView channel({
      String id = 'c1',
      String name = 'GCash',
      String number = '09771231234',
      String? qrUrl,
    }) => PaymentChannelView(
          id: id,
          channel: name,
          accountName: 'Ariel Asebias',
          accountNumber: number,
          qrUrl: qrUrl,
          qrUrlExpiresInSeconds: 600,
        );

    testWidgets('each channel says whose account and which number',
        (tester) async {
      await tester.pumpWidget(appWith(
        statements: [statement()],
        payment: PaymentDetails(
          channels: [
            channel(),
            channel(id: 'c2', name: 'BPI', number: '1234 5678 90'),
          ],
          note: 'Put your property name in the reference.',
        ),
      ));
      await openBilling(tester);

      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('09771231234'), findsOneWidget);
      expect(find.text('BPI'), findsOneWidget);
      expect(find.text('1234 5678 90'), findsOneWidget);
      expect(find.text('Ariel Asebias'), findsNWidgets(2));
      expect(find.text('Put your property name in the reference.'), findsOneWidget);
      expect(find.textContaining('has not added payment details yet'), findsNothing);
    });

    /// About to be pasted into a wallet, and retyped digits are how money goes
    /// to the wrong account.
    testWidgets('tapping a number copies it', (tester) async {
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
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(appWith(
        statements: [statement()],
        payment: PaymentDetails(channels: [channel()]),
      ));
      await openBilling(tester);

      await tester.tap(find.byKey(const ValueKey('copy-channel-c1')));
      await tester.pumpAndSettle();

      expect(copied, '09771231234');
      expect(find.text('Copied'), findsOneWidget);
    });

    /// Scanned from another phone, so a thumbnail is not enough.
    testWidgets('a QR opens full screen, and a channel without one offers none',
        (tester) async {
      await tester.pumpWidget(appWith(
        statements: [statement()],
        payment: PaymentDetails(channels: [
          channel(qrUrl: 'https://example.test/qr.jpg'),
          channel(id: 'c2', name: 'BPI', number: '1234 5678 90'),
        ]),
      ));
      await openBilling(tester);

      expect(find.byKey(const ValueKey('qr-channel-c2')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('qr-channel-c1')));
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImage), findsOneWidget);
    });

    Finder inSheet(Finder matching) =>
        find.descendant(of: find.byType(PayLizmoSheet), matching: matching);

    /// So the number is copied where the payment is entered, not by closing
    /// the sheet to find it on the screen behind.
    testWidgets('the pay sheet shows where to send it, and copies there',
        (tester) async {
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
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(appWith(
        statements: [statement()],
        payment: PaymentDetails(
          channels: [channel(qrUrl: 'https://example.test/qr.jpg')],
          note: 'Put your property name in the reference.',
        ),
      ));
      await openBilling(tester);

      await tester.tap(find.byKey(const ValueKey('pay-statement-s1')));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Send it to')), findsOneWidget);
      expect(inSheet(find.text('09771231234')), findsOneWidget);
      expect(inSheet(find.byKey(const ValueKey('qr-channel-c1'))), findsOneWidget);
      expect(inSheet(find.text('Put your property name in the reference.')),
          findsOneWidget);

      await tester.tap(inSheet(find.byKey(const ValueKey('copy-channel-c1'))));
      await tester.pumpAndSettle();

      expect(copied, '09771231234');
      expect(inSheet(find.text('Copied')), findsOneWidget);
    });

    testWidgets('with no payment details the sheet says so too', (tester) async {
      await tester.pumpWidget(appWith(statements: [statement()]));
      await openBilling(tester);

      await tester.tap(find.byKey(const ValueKey('pay-statement-s1')));
      await tester.pumpAndSettle();

      expect(inSheet(find.textContaining('has not added payment details yet')),
          findsOneWidget);
    });

    testWidgets('no payment details says so rather than leaving a guess',
        (tester) async {
      await tester.pumpWidget(appWith(statements: [statement()]));
      await openBilling(tester);

      expect(find.textContaining('has not added payment details yet'),
          findsOneWidget);
    });

    testWidgets('a note with no channels is still shown, not called missing',
        (tester) async {
      await tester.pumpWidget(appWith(
        statements: [statement()],
        payment: PaymentDetails(note: 'Pay at the Lizmo office in Cebu.'),
      ));
      await openBilling(tester);

      expect(find.text('Pay at the Lizmo office in Cebu.'), findsOneWidget);
      expect(find.textContaining('has not added payment details yet'), findsNothing);
    });

    testWidgets('an overdue statement says when everything locks',
        (tester) async {
      await tester.pumpWidget(appWith(statements: [statement(overdue: true)]));
      await openBilling(tester);

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Overdue · everything locks on 1 Oct'), findsOneWidget);
    });

    testWidgets('a locked account says what the lock stops', (tester) async {
      await tester.pumpWidget(
          appWith(statements: [statement(overdue: true, locked: true)]));
      await openBilling(tester);

      expect(find.text('Locked'), findsOneWidget);
      expect(find.textContaining('no new units, beds or tenants'), findsOneWidget);
    });

    /// Nobody pays Lizmo in cash at the door.
    testWidgets('paying without proof is not sent', (tester) async {
      await tester.pumpWidget(appWith(statements: [statement()]));
      await openBilling(tester);

      await tester.tap(find.byKey(const ValueKey('pay-statement-s1')));
      await tester.pumpAndSettle();
      expect(find.text('Tell Lizmo you have paid'), findsOneWidget);
      // What the figure is for, so it is not paid blind.
      expect(find.textContaining('September 2026, 2 properties'),
          findsOneWidget);

      final send = find.byKey(const ValueKey('lizmo-send'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(find.text('Attach a screenshot of the payment'), findsOneWidget);
      expect(find.text('Tell Lizmo you have paid'), findsOneWidget);
    });

    testWidgets('a payment waiting for Lizmo is shown, and not asked again',
        (tester) async {
      await tester.pumpWidget(appWith(statements: [
        statement(payments: [
          PlatformPaymentResponse(
            id: 'pp1',
            amountPaid: 700,
            paymentDate: DateTime.utc(2026, 9, 3),
            status: PlatformPaymentResponseStatusEnum.fromJson(
                'PENDING_VERIFICATION'),
          ),
        ]),
      ]));
      await openBilling(tester);

      expect(find.text('Checking'), findsOneWidget);
      expect(find.text('₱700 sent 3 Sep · Waiting for Lizmo to check'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('pay-statement-s1')), findsNothing);
    });

    testWidgets('a refused payment says why', (tester) async {
      await tester.pumpWidget(appWith(statements: [
        statement(payments: [
          PlatformPaymentResponse(
            id: 'pp1',
            amountPaid: 700,
            paymentDate: DateTime.utc(2026, 9, 3),
            status: PlatformPaymentResponseStatusEnum.fromJson('REJECTED'),
            remarks: 'Nothing arrived under that reference.',
          ),
        ]),
      ]));
      await openBilling(tester);

      expect(find.text('₱700 sent 3 Sep · Not confirmed'), findsOneWidget);
      expect(find.text('Nothing arrived under that reference.'), findsOneWidget);
      // Refused is not paid: it can be paid again.
      expect(find.byKey(const ValueKey('pay-statement-s1')), findsOneWidget);
    });
  });
}

PaymentChannelResponse _myChannel({
  String id = 'c1',
  String? channel = 'GCash',
  String? name = 'Elena Reyes',
  String? number = '09171112222',
  bool visible = true,
  String? qrUrl,
  List<String> properties = const [],
}) =>
    PaymentChannelResponse(
      id: id,
      channel: channel,
      accountName: name,
      accountNumber: number,
      visible: visible,
      sortOrder: 0,
      qrUrl: qrUrl,
      qrUrlExpiresInSeconds: 600,
      propertyIds: properties,
    );

/// A landlord's own channels, played from a list in memory, keeping what was asked.
class _FakePaymentChannelsApi extends PaymentChannelsApi {
  _FakePaymentChannelsApi(List<PaymentChannelResponse> channels, {this.note})
      : channels = [...channels];

  final List<PaymentChannelResponse> channels;
  String? note;
  String? savedNote;
  final added = <PaymentChannelRequest>[];
  final updated = <(String, PaymentChannelRequest)>[];
  final deleted = <String>[];
  final uploaded = <(String, int)>[];
  final removedQr = <String>[];
  final usedFor = <(String, List<String>)>[];
  List<String>? order;

  @override
  Future<List<PaymentChannelResponse>?> listMyPaymentChannels({
    Future<void>? abortTrigger,
  }) async =>
      [...channels];

  @override
  Future<PaymentNote?> getMyPaymentNote({Future<void>? abortTrigger}) async =>
      PaymentNote(note: note);

  @override
  Future<PaymentNote?> updateMyPaymentNote(
    PaymentNote paymentNote, {
    Future<void>? abortTrigger,
  }) async {
    savedNote = paymentNote.note;
    note = paymentNote.note;
    return paymentNote;
  }

  @override
  Future<PaymentChannelResponse?> addMyPaymentChannel(
    PaymentChannelRequest paymentChannelRequest, {
    Future<void>? abortTrigger,
  }) async {
    added.add(paymentChannelRequest);
    final created = _myChannel(
      id: 'new',
      channel: paymentChannelRequest.channel,
      name: paymentChannelRequest.accountName,
      number: paymentChannelRequest.accountNumber,
    );
    channels.add(created);
    return created;
  }

  @override
  Future<PaymentChannelResponse?> updateMyPaymentChannel(
    String id,
    PaymentChannelRequest paymentChannelRequest, {
    Future<void>? abortTrigger,
  }) async {
    updated.add((id, paymentChannelRequest));
    final at = channels.indexWhere((channel) => channel.id == id);
    if (at < 0) return null;
    final was = channels[at];
    return channels[at] = _myChannel(
      id: id,
      channel: paymentChannelRequest.channel,
      name: paymentChannelRequest.accountName,
      number: paymentChannelRequest.accountNumber,
      visible: paymentChannelRequest.visible ?? was.visible ?? true,
      qrUrl: was.qrUrl,
      properties: was.propertyIds,
    );
  }

  @override
  Future<PaymentChannelResponse?> setMyPaymentChannelProperties(
    String id,
    ChannelProperties channelProperties, {
    Future<void>? abortTrigger,
  }) async {
    usedFor.add((id, [...channelProperties.propertyIds]));
    final at = channels.indexWhere((channel) => channel.id == id);
    if (at < 0) return null;
    final was = channels[at];
    return channels[at] = _myChannel(
      id: id,
      channel: was.channel,
      name: was.accountName,
      number: was.accountNumber,
      visible: was.visible ?? true,
      qrUrl: was.qrUrl,
      properties: [...channelProperties.propertyIds],
    );
  }

  @override
  Future<void> deleteMyPaymentChannel(String id, {Future<void>? abortTrigger}) async {
    deleted.add(id);
    channels.removeWhere((channel) => channel.id == id);
  }

  @override
  Future<PaymentChannelResponse?> uploadMyPaymentChannelQr(
    String id,
    MultipartFile qr, {
    Future<void>? abortTrigger,
  }) async {
    uploaded.add((id, qr.length));
    return null;
  }

  @override
  Future<PaymentChannelResponse?> removeMyPaymentChannelQr(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    removedQr.add(id);
    return null;
  }

  @override
  Future<List<PaymentChannelResponse>?> reorderMyPaymentChannels(
    PaymentChannelOrder paymentChannelOrder, {
    Future<void>? abortTrigger,
  }) async {
    order = [...paymentChannelOrder.ids];
    return channels;
  }
}

/// Records what was uploaded, reordered and removed.
class _FakePhotosApi extends PropertiesApi {
  _FakePhotosApi(this.photos);

  final List<PropertyPhoto> photos;
  int uploads = 0;
  List<String>? ordered;
  String? removed;

  @override
  Future<List<PropertyPhoto>?> listPropertyPhotos(
    String propertyId, {
    Future<void>? abortTrigger,
  }) async =>
      [...photos];

  @override
  Future<PropertyPhoto?> addPropertyPhoto(
    String propertyId,
    MultipartFile file, {
    Future<void>? abortTrigger,
  }) async {
    uploads++;
    final added = PropertyPhoto(
      id: 'new',
      url: 'https://example.invalid/new.jpg',
      position: photos.length,
      uploadedAt: DateTime.now(),
    );
    photos.add(added);
    return added;
  }

  @override
  Future<List<PropertyPhoto>?> reorderPropertyPhotos(
    String propertyId,
    PhotoOrder photoOrder, {
    Future<void>? abortTrigger,
  }) async {
    ordered = [...photoOrder.ids];
    photos.sort((a, b) =>
        photoOrder.ids.indexOf(a.id!).compareTo(photoOrder.ids.indexOf(b.id!)));
    return [...photos];
  }

  @override
  Future<void> deletePropertyPhoto(
    String propertyId,
    String photoId, {
    Future<void>? abortTrigger,
  }) async {
    removed = photoId;
    photos.removeWhere((photo) => photo.id == photoId);
  }
}
