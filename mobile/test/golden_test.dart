@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo/maintenance/maintenance_providers.dart';
import 'package:lizmo/billing/payment_channel_providers.dart';
import 'package:lizmo/screens/payment_channels_screen.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo/notifications/notification_providers.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/splash_screen.dart';
import 'package:lizmo/tenant/tenant_providers.dart';

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
        requestsToAnswerProvider.overrideWith((ref) async => [
              RentalRequestForLandlord(
                id: 'r1',
                propertyId: 'p1',
                propertyName: 'Sunrise Apartments',
                unitId: 'u1',
                unitNumber: '2B',
                bedLabel: 'Bed 3',
                tenantName: 'Miguel Cruz',
                createdAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ]),
        // Pinned so the bell renders a known state. Left alone it depends
        // on a real request failing, which is not a thing to rest a golden on.
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        // One repair waiting, so Today shows its Repairs card.
        maintenanceToHandleProvider.overrideWith((ref) async => [
              MaintenanceReportResponse(
                id: 'm1',
                propertyName: 'Sunrise Apartments',
                unitNumber: '2B',
                bedLabel: 'Bed 1',
                tenantName: 'Ana Reyes',
                description: 'The ceiling fan grinds and stops',
                status: MaintenanceReportResponseStatusEnum.SUBMITTED,
                submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
            ]),
        occupancyProvider.overrideWith((ref) async => OccupancySummary(
              lettable: 4,
              occupied: 1,
              empty: 3,
              outOfService: 0,
              earningRent: 2500,
              emptyRent: 7500,
              vacancies: [
                VacancyRow(
                  propertyId: 'p1',
                  propertyName: 'Sunrise Apartments',
                  lettable: 4,
                  occupied: 1,
                  empty: 3,
                  emptyRent: 7500,
                ),
              ],
            )),
        // Pinned for the same reason as the bell: left alone the dashboard
        // would render whatever a failed request produced.
        collectionsProvider.overrideWith((ref) async => CollectionsSummary(
              dueThisMonth: 5000,
              collectedThisMonth: 2500,
              outstandingAllTime: 7500,
              awaitingConfirmation: 1,
              tenanciesInArrears: 1,
              awaiting: [
                AwaitingRow(
                  leaseId: 'l2',
                  paymentId: 'pay1',
                  tenantName: 'Jhun Santos',
                  unitNumber: '2B',
                  bedLabel: 'Bed 2',
                  amount: 2500,
                  paidOn: DateTime.utc(2026, 9, 3),
                ),
              ],
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
        requestsToAnswerProvider.overrideWith((ref) async => [
              RentalRequestForLandlord(
                id: 'r1',
                propertyId: 'p1',
                propertyName: 'Sunrise Apartments',
                unitId: 'u1',
                unitNumber: '2B',
                bedLabel: 'Bed 3',
                tenantName: 'Miguel Cruz',
                createdAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ]),
        // Pinned so the bell renders a known state. Left alone it depends
        // on a real request failing, which is not a thing to rest a golden on.
        myNotificationsProvider.overrideWith(
          (ref) async => const <NotificationResponse>[],
        ),
        occupancyProvider.overrideWith((ref) async => OccupancySummary(
              lettable: 4,
              occupied: 1,
              empty: 3,
              outOfService: 0,
              earningRent: 2500,
              emptyRent: 7500,
              vacancies: [
                VacancyRow(
                  propertyId: 'p1',
                  propertyName: 'Sunrise Apartments',
                  lettable: 4,
                  occupied: 1,
                  empty: 3,
                  emptyRent: 7500,
                ),
              ],
            )),
        // Pinned for the same reason as the bell: left alone the dashboard
        // would render whatever a failed request produced.
        collectionsProvider.overrideWith((ref) async => CollectionsSummary(
              dueThisMonth: 5000,
              collectedThisMonth: 2500,
              outstandingAllTime: 7500,
              awaitingConfirmation: 1,
              tenanciesInArrears: 1,
              awaiting: [
                AwaitingRow(
                  leaseId: 'l2',
                  paymentId: 'pay1',
                  tenantName: 'Jhun Santos',
                  unitNumber: '2B',
                  bedLabel: 'Bed 2',
                  amount: 2500,
                  paidOn: DateTime.utc(2026, 9, 3),
                ),
              ],
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

  // ---- The rent card on a tenant's Home, one per state ----------------------

  BillingPeriodResponse month(String id, String label, int m,
          {num paid = 0, bool overdue = false}) =>
      BillingPeriodResponse(
        id: id,
        label: label,
        periodStart: DateTime.utc(2026, m, 1),
        periodEnd: DateTime.utc(2026, m + 1, 0),
        dueDate: DateTime.utc(2026, m, 5),
        amountDue: 2500,
        amountPaid: paid,
        outstanding: 2500 - paid,
        status: paid >= 2500
            ? BillingPeriodResponseStatusEnum.PAID
            : BillingPeriodResponseStatusEnum.UNPAID,
        overdue: overdue,
      );

  PaymentResponse payment(PaymentResponseStatusEnum status, {String? reason}) =>
      PaymentResponse(
        id: 'p1',
        billingPeriodId: 'oct',
        amountPaid: 2500,
        paymentDate: DateTime.utc(2026, 10, 3),
        sentTo: 'GCash · Elena Bautista · 0917 111 2222',
        status: status,
        rejectionReason: reason,
      );

  Widget tenantHome(
    List<BillingPeriodResponse> months, {
    List<PaymentResponse> payments = const [],
    required DateTime today,
  }) =>
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuth(AuthSignedIn(Session(
              userId: 'u1',
              name: 'Ana Reyes',
              profiles: {LizmoProfile.tenant},
              accessToken: 'token',
            ))),
          ),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          myNotificationsProvider.overrideWith(
            (ref) async => const <NotificationResponse>[],
          ),
          todayProvider.overrideWithValue(today),
          myTenantProfileProvider.overrideWith(
            (ref) async => TenantProfileResponse(readyForALease: true),
          ),
          myTenantDocumentsProvider.overrideWith(
            (ref) async => const <TenantDocumentResponse>[],
          ),
          myRentalRequestsProvider.overrideWith(
            (ref) async => const <RentalRequestResponse>[],
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
                  startDate: DateTime.utc(2026, 8, 1),
                  status: LeaseResponseStatusEnum.ACTIVE,
                ),
              ]),
          myLeaseDocumentsProvider('l1').overrideWith(
            (ref) async => const <LeaseDocumentResponse>[],
          ),
          myBillingProvider('l1').overrideWith((ref) async => months),
          myPaymentsProvider('l1').overrideWith((ref) async => payments),
          leasePaymentDetailsProvider('l1').overrideWith((ref) async => PaymentDetails(
                channels: [
                  PaymentChannelView(
                    id: 'c1',
                    channel: 'GCash',
                    accountName: 'Elena Bautista',
                    accountNumber: '0917 111 2222',
                    qrUrlExpiresInSeconds: 600,
                  ),
                ],
              )),
        ],
        child: const LizmoApp(),
      );

  final sep = month('sep', 'September 2026', 9, paid: 2500);
  final oct = month('oct', 'October 2026', 10);
  final states = <String, Widget>{
    'paid': tenantHome([sep], today: DateTime(2026, 9, 20)),
    'due_soon': tenantHome([sep, oct], today: DateTime(2026, 10, 2)),
    'waiting': tenantHome([sep, oct],
        payments: [payment(PaymentResponseStatusEnum.PENDING_VERIFICATION)],
        today: DateTime(2026, 10, 3)),
    'not_received': tenantHome([sep, oct],
        payments: [
          payment(PaymentResponseStatusEnum.REJECTED,
              reason: 'No GCash transfer on 3 Oct. Please send the reference number.'),
        ],
        today: DateTime(2026, 10, 4)),
    'late': tenantHome([
      month('sep', 'September 2026', 9, overdue: true),
      month('oct', 'October 2026', 10, overdue: true),
    ], today: DateTime(2026, 10, 12)),
  };

  for (final entry in states.entries) {
    testWidgets('tenant home rent: ${entry.key}', (tester) async {
      _phone(tester);
      await tester.pumpWidget(entry.value);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LizmoApp),
        matchesGoldenFile('goldens/tenant_rent_${entry.key}.png'),
      );
    });
  }

  /// How tenants pay me, with an account used at one property and another
  /// left out, so the warning shows too.
  testWidgets('payment channels', (tester) async {
    _phone(tester);

    PaymentChannelResponse channel(
      String id,
      String name,
      String number, {
      List<String> properties = const [],
      bool visible = true,
    }) =>
        PaymentChannelResponse(
          id: id,
          channel: name,
          accountName: 'Elena Bautista',
          accountNumber: number,
          visible: visible,
          sortOrder: 0,
          qrUrlExpiresInSeconds: 600,
          propertyIds: properties,
        );

    PropertyResponse property(String id, String name) => PropertyResponse(
          id: id,
          name: name,
          address: '12 Mabini St, Quezon City',
          type: PropertyResponseTypeEnum.BOARDING_HOUSE,
          unitCount: 3,
        );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _FakeAuth(AuthSignedIn(Session(
            userId: 'u1',
            name: 'Elena Bautista',
            profiles: {LizmoProfile.landlord},
            accessToken: 'token',
          ))),
        ),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        propertiesProvider.overrideWith((ref) async => [
              property('p1', 'Sunrise Apartments'),
              property('p2', 'Sunset Residences'),
            ]),
        myPaymentChannelsProvider.overrideWith((ref) async => [
              channel('c1', 'GCash', '0917 111 2222', properties: ['p1']),
              channel('c2', 'BPI', '1234 5678 90', properties: ['p1']),
              channel('c3', 'Maya', '0917 333 4444'),
            ]),
        myPaymentNoteProvider.overrideWith(
            (ref) async => 'Cash to Aling Nena at unit 1A, before the 5th.'),
      ],
      child: const MaterialApp(home: PaymentChannelsScreen()),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PaymentChannelsScreen),
      matchesGoldenFile('goldens/payment_channels.png'),
    );
  });
}
