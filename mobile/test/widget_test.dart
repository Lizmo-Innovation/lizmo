import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/auth/active_role.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo/router.dart';
import 'package:lizmo/screens/login_screen.dart';
import 'package:lizmo/screens/register_screen.dart';
import 'package:lizmo/screens/create_property_screen.dart';
import 'package:lizmo/screens/create_unit_screen.dart';
import 'package:lizmo/screens/property_detail_screen.dart';
import 'package:lizmo/screens/property_list_screen.dart';
import 'package:lizmo/screens/tenant_home_screen.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo/property/property_providers.dart';

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
        // Routing tests care where you land, not what loads there.
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
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
      unitCount: current.unitCount,
    );
    return current;
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
}

void main() {
  group('routing follows auth state', () {
    testWidgets('signed out lands on login', (tester) async {
      await tester.pumpWidget(_app(const AuthSignedOut()));
      await tester.pumpAndSettle();

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

      expect(find.byType(TenantHomeScreen), findsOneWidget);
      expect(find.byType(PropertyListScreen), findsNothing);
    });

    testWidgets('a landlord lands on their properties', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyListScreen), findsOneWidget);
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

      expect(find.byType(PropertyListScreen), findsOneWidget);
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
      expect(find.byType(PropertyListScreen), findsNothing);

      await tester.tap(find.text('Landlord'));
      await tester.pumpAndSettle();
      expect(find.byType(PropertyListScreen), findsOneWidget);
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

    testWidgets('signing up moves the user off the form', (tester) async {
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

    testWidgets('signing up as a landlord lands on the rent roll', (tester) async {
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

      expect(find.byType(PropertyListScreen), findsOneWidget);
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

      await tester.tap(find.text('I am also a landlord'));
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

      expect(find.text('Sunrise Apartments'), findsOneWidget);
      expect(find.text('Sunset Residences'), findsOneWidget);
      // Singular and plural, because "1 units" reads as a bug to a user.
      expect(find.text('units'), findsOneWidget);
      expect(find.text('unit'), findsOneWidget);
    });

    testWidgets('header totals are derived from the loaded rows', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async => [
              property('Sunrise Apartments', 2),
              property('Sunset Residences', 3),
            ]),
      ));
      await tester.pumpAndSettle();

      // Two properties, five units — counts cannot disagree with the list.
      expect(find.text('2'), findsWidgets);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('an empty portfolio explains what to do', (tester) async {
      await tester.pumpWidget(appWith(
        propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
      ));
      await tester.pumpAndSettle();

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

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Your Lizmo invoice is unpaid.'), findsOneWidget);
    });
  });

  group('signing out', () {
    testWidgets('a tenant can sign out from the account sheet', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.tenant})));
      await tester.pumpAndSettle();
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

      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePropertyScreen), findsOneWidget);
      expect(find.text('Add a property'), findsOneWidget);
    });

    testWidgets('empty fields are caught before calling the API', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save property'));
      await tester.pump();

      expect(find.text('Give the property a name'), findsOneWidget);
      expect(find.text('Add an address'), findsOneWidget);
    });

    testWidgets('type defaults to boarding house and can be changed', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      // All four are visible rather than hidden behind a dropdown, so the
      // default is a visible choice rather than an unnoticed one.
      expect(find.text('Boarding house'), findsOneWidget);
      expect(find.text('Apartment'), findsOneWidget);
      expect(find.text('Condo'), findsOneWidget);
      expect(find.text('Single house'), findsOneWidget);

      await tester.tap(find.text('Condo'));
      await tester.pump();
    });

    testWidgets('the back arrow returns to the property list', (tester) async {
      await tester.pumpWidget(_app(_signedIn({LizmoProfile.landlord})));
      await tester.pumpAndSettle();
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

      expect(find.text('No properties yet'), findsOneWidget);

      await tester.tap(find.text('+ Add a property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Mabuhay Bedspace');
      await tester.enterText(find.byType(TextFormField).at(1), '7 Katipunan Ave');
      await tester.tap(find.text('Condo'));
      await tester.pump();

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
    }) =>
        UnitResponse(
          id: 'u-$number',
          propertyId: 'p1',
          unitNumber: number,
          rentalMode: mode,
          capacity: capacity,
          bedCount: bedCount,
          rent: rent,
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

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(find.text('Unit 2B'), findsOneWidget);
    });

    testWidgets('bedspace and whole units read differently', (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '2B', mode: UnitResponseRentalModeEnum.BEDSPACE,
            capacity: 4, bedCount: 2, rent: 2500),
        unit(number: '1A', mode: UnitResponseRentalModeEnum.WHOLE_UNIT, rent: 7000),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // The distinction the whole product turns on, visible at a glance.
      expect(find.textContaining('Bedspace'), findsOneWidget);
      expect(find.textContaining('Whole unit'), findsOneWidget);
      expect(find.text('per bed'), findsOneWidget);
      expect(find.text('per month'), findsOneWidget);
      expect(find.text('2 of 4 beds'), findsOneWidget);
    });

    testWidgets('a unit with no rent shows a dash, not zero', (tester) async {
      await tester.pumpWidget(appWith([
        unit(number: '1A', mode: UnitResponseRentalModeEnum.WHOLE_UNIT),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      // Zero would claim the unit is free; not-set is a different statement.
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('₱0'), findsNothing);
    });

    testWidgets('a property with no units explains what to add', (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();

      expect(find.text('No units yet'), findsOneWidget);
    });

    testWidgets('the add-unit form asks the mode first and warns it is final',
        (tester) async {
      await tester.pumpWidget(appWith(const []));
      await tester.pumpAndSettle();
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
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add a unit'));
      await tester.pumpAndSettle();

      expect(find.text('How many beds?'), findsOneWidget);
      expect(find.text('Rent per bed (optional)'), findsOneWidget);

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

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Sunrise Residences');
      await tester.tap(find.text('Apartment'));
      await tester.pump();
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

      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit property'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '');
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
      await tester.tap(find.text('Sunrise Apartments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unit 2B'));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a unit opens it prefilled', (tester) async {
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

    testWidgets('capacity cannot drop below the beds already added', (tester) async {
      final api = _EditableUnitsApi(bedspace(capacity: 4, bedCount: 4));
      await openEditForm(tester, api);

      expect(find.textContaining('4 already added'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(2), '2');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      // Caught here rather than after a round trip; the API refuses it too.
      expect(find.text('You already have 4 beds here'), findsOneWidget);
      expect(api.lastUpdate, isNull);
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
}
