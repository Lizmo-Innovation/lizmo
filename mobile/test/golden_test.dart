@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo/notifications/notification_providers.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/splash_screen.dart';

/// Renders each role's home screen for visual review.
/// Regenerate with `flutter test test/golden_test.dart --update-goldens`.
///
/// Renders with real type now that the fonts are bundled in lizmo_ui, so a
/// typography regression is visible here. Tagged `golden` and excluded from CI:
/// they are generated on Windows and rasterise differently on Linux.
class _PinnedHealth extends BackendHealth {
  _PinnedHealth(this._state);

  final BackendReachability _state;

  @override
  BackendReachability build() => _state;
}

class _FakeAuth extends AuthController {
  _FakeAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

Widget _app(Set<LizmoProfile> profiles) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(AuthSignedIn(Session(
            userId: 'u1',
            name: 'Ana Reyes',
            profiles: profiles,
            accessToken: 'token',
          ))),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        // Pinned so the bell renders a known state. Left alone it depends
        // on a real request failing, which is not a thing to rest a golden on.
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        // Pinned for the same reason as the bell: left alone the dashboard
        // would render whatever a failed request produced.
        collectionsProvider.overrideWith((ref) async => CollectionsSummary(
              dueThisMonth: 5000,
              collectedThisMonth: 2500,
              outstandingAllTime: 7500,
              awaitingConfirmation: 1,
              tenanciesInArrears: 1,
              inArrears: [
                ArrearsRow(
                  leaseId: 'l1',
                  tenantName: 'Ana Reyes',
                  propertyName: 'Sunrise Apartments',
                  unitNumber: '2B',
                  bedLabel: 'Bed 1',
                  outstanding: 5000,
                  monthsLate: 2,
                  oldestDueDate: DateTime.utc(2026, 8, 5),
                ),
              ],
            )),
        // Fixed data so the golden is stable, matching the seeded landlord.
        propertiesProvider.overrideWith((ref) async => [
              PropertyResponse(
                id: 'p1',
                name: 'Sunrise Apartments',
                address: '12 Mabini St, Quezon City',
                type: PropertyResponseTypeEnum.BOARDING_HOUSE,
                unitCount: 2,
                potentialMonthlyRent: 17000,
              ),
              PropertyResponse(
                id: 'p2',
                name: 'Sunset Residences',
                address: '48 Rizal Ave, Caloocan',
                type: PropertyResponseTypeEnum.APARTMENT,
                unitCount: 1,
                potentialMonthlyRent: 9500,
              ),
            ]),
      ],
      child: const LizmoApp(),
    );

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(375 * 2, 812 * 2)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _detailApp() => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(AuthSignedIn(Session(
            userId: 'u1',
            name: 'Ana Reyes',
            profiles: {LizmoProfile.landlord},
            accessToken: 'token',
          ))),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        // Pinned so the bell renders a known state. Left alone it depends
        // on a real request failing, which is not a thing to rest a golden on.
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        // Pinned for the same reason as the bell: left alone the dashboard
        // would render whatever a failed request produced.
        collectionsProvider.overrideWith((ref) async => CollectionsSummary(
              dueThisMonth: 5000,
              collectedThisMonth: 2500,
              outstandingAllTime: 7500,
              awaitingConfirmation: 1,
              tenanciesInArrears: 1,
              inArrears: [
                ArrearsRow(
                  leaseId: 'l1',
                  tenantName: 'Ana Reyes',
                  propertyName: 'Sunrise Apartments',
                  unitNumber: '2B',
                  bedLabel: 'Bed 1',
                  outstanding: 5000,
                  monthsLate: 2,
                  oldestDueDate: DateTime.utc(2026, 8, 5),
                ),
              ],
            )),
        propertiesProvider.overrideWith((ref) async => [
              PropertyResponse(
                id: 'p1',
                name: 'Sunrise Apartments',
                address: '12 Mabini St, Quezon City',
                type: PropertyResponseTypeEnum.BOARDING_HOUSE,
                unitCount: 2,
              ),
            ]),
        unitsProvider('p1').overrideWith((ref) async => [
              UnitResponse(
                id: 'u1',
                propertyId: 'p1',
                unitNumber: '2B',
                floor: '2',
                rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
                capacity: 4,
                bedCount: 4,
                rent: 2500,
                // Four beds at the unit rate.
                potentialMonthlyRent: 10000,
                status: UnitResponseStatusEnum.VACANT,
              ),
              UnitResponse(
                id: 'u2',
                propertyId: 'p1',
                unitNumber: '1A',
                floor: '1',
                rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
                capacity: 1,
                bedCount: 0,
                rent: 7000,
                potentialMonthlyRent: 7000,
                status: UnitResponseStatusEnum.VACANT,
              ),
            ]),
      ],
      child: const LizmoApp(),
    );

void main() {
  testWidgets('tenant home', (tester) async {
    _phone(tester);

    await tester.pumpWidget(_app({LizmoProfile.tenant}));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoApp),
      matchesGoldenFile('goldens/tenant_home.png'),
    );
  });

  testWidgets('landlord rent roll with role switcher', (tester) async {
    _phone(tester);

    // Both profiles, so the switcher renders.
    await tester.pumpWidget(_app({LizmoProfile.tenant, LizmoProfile.landlord}));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoApp),
      matchesGoldenFile('goldens/landlord_home.png'),
    );

    // And the properties tab behind it.
    await tester.tap(find.byKey(const ValueKey('tab-properties')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoApp),
      matchesGoldenFile('goldens/rent_roll_switcher.png'),
    );
  });

  testWidgets('property detail', (tester) async {
    _phone(tester);

    await tester.pumpWidget(_detailApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tab-properties')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunrise Apartments'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoApp),
      matchesGoldenFile('goldens/property_detail.png'),
    );
  });

  testWidgets('splash', (tester) async {
    _phone(tester);

    // Rendered directly rather than through the router: the router holds the
    // splash on a timer, and pumpAndSettle would run that timer out and land
    // on login before anything could be captured.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Pinned reachable: the golden is of the normal launch, not the
        // offline state, and an unpinned probe would decide for itself.
        backendHealthProvider.overrideWith(
            () => _PinnedHealth(BackendReachability.reachable)),
      ],
      child: const MaterialApp(home: SplashScreen()),
    ));
    // Not pumpAndSettle: the progress indicator animates forever, so nothing
    // ever settles. Two frames is enough to lay out and load the mark.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash.png'),
    );
  });

  testWidgets('splash offline', (tester) async {
    _phone(tester);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        backendHealthProvider.overrideWith(
            () => _PinnedHealth(BackendReachability.unreachable)),
      ],
      child: const MaterialApp(home: SplashScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_offline.png'),
    );
  });
}
