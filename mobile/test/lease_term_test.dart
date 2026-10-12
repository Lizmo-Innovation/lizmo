import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/inquiry/inquiry_providers.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/tenant_detail_screen.dart';
import 'package:lizmo/tenant/tenant_providers.dart';
import 'package:lizmo/widgets/accept_terms_sheet.dart';
import 'package:lizmo/widgets/lease_ending_notice.dart';
import 'package:lizmo/widgets/lease_term.dart';
import 'package:lizmo/widgets/leases_ending_card.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// When a lease is meant to end, from the landlord's side: choosing it when
/// the lease is written, seeing it on the tenancy, and changing it.
void main() {
  group('the dates', () {
    test('a year from the 15th ends on the 14th', () {
      expect(termEnd(DateTime(2026, 1, 15), 12), DateTime(2027, 1, 14));
    });

    test('six months runs across a year end', () {
      expect(termEnd(DateTime(2026, 10, 1), 6), DateTime(2027, 3, 31));
    });

    /// There is no 31 February: the term runs to the end of the shorter month.
    test('a start on the 31st does not overflow a short month', () {
      expect(termEnd(DateTime(2026, 8, 31), 6), DateTime(2027, 2, 27));
      expect(termEnd(DateTime(2027, 8, 31), 6), DateTime(2028, 2, 28));
    });

    test('are said the way people say them', () {
      expect(termDate(DateTime(2027, 8, 31)), '31 August 2027');
      expect(inDays(0), 'today');
      expect(inDays(1), 'tomorrow');
      expect(inDays(23), 'in 23 days');
    });
  });

  group('writing a lease', () {
    Future<AcceptRequest?> accept(
      WidgetTester tester,
      Future<void> Function() choose,
    ) async {
      AcceptRequest? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await AcceptTermsSheet.show(
                context,
                tenantName: 'Ana Reyes',
                slot: 'Bed 1, 2B',
                askingRent: 2500,
              ),
              child: const Text('Accept'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      await choose();
      await tapShown(tester, find.byKey(const ValueKey('accept-and-create')));
      return result;
    }

    Widget sheetAt({List<FreeRoom>? rooms}) => MaterialApp(
          home: Scaffold(
            body: AcceptTermsSheet(
              tenantName: 'Ana Reyes',
              slot: rooms == null ? 'Bed 1, 2B' : 'Sunrise Apartments',
              askingRent: 2500,
              rooms: rooms,
            ),
          ),
        );

    /// The words the thread's button uses, and nothing it does not do: it
    /// once promised anybody else waiting would be told the room had gone.
    testWidgets('says what starting the lease does, and who sees it',
        (tester) async {
      await tester.pumpWidget(sheetAt(rooms: [
        FreeRoom(unitId: 'u1', bedId: 'b1', label: 'Bed 1, 2B', rent: 2500),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('A lease for Ana Reyes'), findsOneWidget);
      expect(
          find.text('At Sunrise Apartments. Choose the room and set what you '
              'agreed. Ana sees these terms in the app once the lease starts.'),
          findsOneWidget);
      expect(find.textContaining('told it has gone'), findsNothing);
      expect(find.textContaining('Accept'), findsNothing);
    });

    /// A button that is off says what it is waiting for.
    testWidgets('the button says what it is waiting for', (tester) async {
      await tester.pumpWidget(sheetAt(rooms: [
        FreeRoom(unitId: 'u1', bedId: 'b1', label: 'Bed 1, 2B', rent: 2500),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Choose a room first'), findsOneWidget);

      await tapShown(tester, find.byKey(const ValueKey('room-b1')));
      expect(find.text('Start the lease'), findsOneWidget);

      await tapShown(tester, find.byKey(const ValueKey('term-own')));
      expect(find.text('Choose the end date first'), findsOneWidget);
    });

    testWidgets('with nothing vacant, says what to do instead', (tester) async {
      await tester.pumpWidget(sheetAt(rooms: const []));
      await tester.pumpAndSettle();

      expect(
          find.text('Nothing is vacant here right now. Free a room first, or '
              'let Ana know in the conversation.'),
          findsOneWidget);
      expect(find.text('No room to give'), findsOneWidget);
    });

    testWidgets('is month to month unless they say otherwise', (tester) async {
      final terms = await accept(tester, () async {
        expect(find.text('Month to month, until one of you ends it.'),
            findsOneWidget);
      });

      expect(terms, isNotNull);
      expect(terms!.endsOn, isNull);
    });

    testWidgets('a year is a year from the start, shown before it is sent',
        (tester) async {
      final start = DateTime.now();
      final ends = termEnd(start, 12);

      final terms = await accept(tester, () async {
        await tapShown(tester, find.byKey(const ValueKey('term-year')));
        expect(find.text(termDate(ends)), findsOneWidget);
        expect(find.textContaining('Nothing ends on its own'), findsOneWidget);
      });

      expect(terms!.endsOn, DateTime.utc(ends.year, ends.month, ends.day));
    });

    /// Asked for a date of their own, the lease waits for one.
    testWidgets('a date of their own has to be given', (tester) async {
      final terms = await accept(tester, () async {
        await tapShown(tester, find.byKey(const ValueKey('term-own')));
        expect(find.byKey(const ValueKey('term-own-date')), findsOneWidget);
      });

      expect(terms, isNull);
      expect(find.byType(AcceptTermsSheet), findsOneWidget);
    });
  });

  group('on the tenancy', () {
    late _FakeLeases api;
    final today = DateTime(2026, 10, 12);

    setUp(() => api = _FakeLeases());

    LeaseResponse lease({DateTime? ends}) => LeaseResponse(
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
          dueDateDay: 1,
          startDate: DateTime.utc(2026, 4, 1),
          status: LeaseResponseStatusEnum.ACTIVE,
          termEndsOn: ends,
        );

    Widget screen(LeaseResponse tenancy) => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _Landlord()),
            todayProvider.overrideWithValue(today),
            myTenantsProvider.overrideWith((ref) async => [tenancy]),
            leasesApiProvider.overrideWithValue(api),
            leaseBillingProvider('l1')
                .overrideWith((ref) async => const <BillingPeriodResponse>[]),
            leasePaymentsProvider('l1')
                .overrideWith((ref) async => const <PaymentResponse>[]),
            leaseTenantProvider('l1').overrideWith((ref) async =>
                TenantForLandlord(leaseId: 'l1', tenantId: 't1', name: 'Ana Reyes')),
            leaseTenantDocumentsProvider('l1')
                .overrideWith((ref) async => const <TenantDocumentResponse>[]),
            leaseDocumentsProvider('l1')
                .overrideWith((ref) async => const <LeaseDocumentResponse>[]),
          ],
          child: const MaterialApp(home: TenantDetailScreen(leaseId: 'l1')),
        );

    /// Month to month is the usual arrangement, not a missing detail.
    testWidgets('no end date is said plainly, with a way to set one',
        (tester) async {
      await tester.pumpWidget(screen(lease()));
      await tester.pumpAndSettle();

      expect(find.text('The lease'), findsOneWidget);
      expect(find.text('1 April 2026'), findsOneWidget);
      expect(find.text('No end date'), findsOneWidget);
      expect(find.text('Set an end date'), findsOneWidget);
      expect(find.byKey(const ValueKey('lease-term-says')), findsNothing);
    });

    testWidgets('far from its end, it is only a date', (tester) async {
      await tester.pumpWidget(screen(lease(ends: DateTime.utc(2027, 3, 31))));
      await tester.pumpAndSettle();

      expect(find.text('31 March 2027'), findsOneWidget);
      expect(find.text('Extend or change'), findsOneWidget);
      expect(find.byKey(const ValueKey('lease-term-says')), findsNothing);
    });

    testWidgets('within a month, it says how near', (tester) async {
      await tester.pumpWidget(screen(lease(ends: DateTime.utc(2026, 11, 4))));
      await tester.pumpAndSettle();

      expect(find.text('Ends in 23 days. Extend it if they are staying.'),
          findsOneWidget);
    });

    /// Nothing ends on its own; past the date, what is left is theirs to do.
    testWidgets('past its end, it says what is left to do', (tester) async {
      await tester.pumpWidget(screen(lease(ends: DateTime.utc(2026, 10, 1))));
      await tester.pumpAndSettle();

      expect(find.textContaining('It reached its end on 1 October 2026.'),
          findsOneWidget);
      expect(find.textContaining('end the tenancy so the room can be let again'),
          findsOneWidget);
    });

    testWidgets('a year from the start is set, and the tenant told',
        (tester) async {
      await tester.pumpWidget(screen(lease()));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('change-lease-term')));
      expect(find.text('Set an end date'), findsWidgets);
      await tapShown(tester, find.byKey(const ValueKey('term-year')));
      await tapShown(tester, find.byKey(const ValueKey('save-term')));

      expect(api.changed, [DateTime.utc(2027, 3, 31)]);
      expect(find.text('Ends on 31 March 2027. Ana has been told.'),
          findsOneWidget);
    });

    /// Six months from an April start has already gone: not offered.
    testWidgets('a term that has already run out is not offered',
        (tester) async {
      await tester.pumpWidget(screen(lease()));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('change-lease-term')));

      expect(find.byKey(const ValueKey('term-six')), findsNothing);
      expect(find.byKey(const ValueKey('term-year')), findsOneWidget);
    });

    /// "Another year" means a year more than they have.
    testWidgets('extending counts from the end already agreed', (tester) async {
      await tester.pumpWidget(screen(lease(ends: DateTime.utc(2026, 11, 4))));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('change-lease-term')));
      expect(find.text('5 November 2027'), findsNothing);
      await tapShown(tester, find.byKey(const ValueKey('term-year')));
      await tapShown(tester, find.byKey(const ValueKey('save-term')));

      expect(api.changed, [DateTime.utc(2027, 11, 4)]);
    });

    testWidgets('the end date can be taken away', (tester) async {
      await tester.pumpWidget(screen(lease(ends: DateTime.utc(2027, 3, 31))));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('change-lease-term')));
      await tapShown(tester, find.byKey(const ValueKey('remove-term')));

      expect(api.changed, [null]);
      expect(find.text('No end date now. Ana has been told.'), findsOneWidget);
    });

    testWidgets('backing out changes nothing', (tester) async {
      await tester.pumpWidget(screen(lease(ends: DateTime.utc(2027, 3, 31))));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('change-lease-term')));
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(api.changed, isEmpty);
    });
  });

  _tenantSide();

  group('on Today', () {
    final today = DateTime(2026, 10, 12);

    LeaseResponse renting(String id, DateTime? ends) => LeaseResponse(
          id: id,
          tenantName: 'Tenant $id',
          unitNumber: '2B',
          bedLabel: 'Bed $id',
          startDate: DateTime.utc(2026, 1, 1),
          termEndsOn: ends,
        );

    Widget card(List<LeaseResponse> tenants) => ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(today),
            myTenantsProvider.overrideWith((ref) async => tenants),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LeasesEndingCard()),
          ),
        );

    testWidgets('lists what ends within a month, soonest first',
        (tester) async {
      await tester.pumpWidget(card([
        renting('far', DateTime.utc(2027, 6, 1)),
        renting('none', null),
        renting('soon', DateTime.utc(2026, 11, 4)),
        renting('past', DateTime.utc(2026, 10, 1)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Leases ending'), findsOneWidget);
      expect(find.text('2 tenants'), findsOneWidget);
      expect(find.text('Ends in 23 days'), findsOneWidget);
      expect(find.text('Past its end'), findsOneWidget);
      expect(find.text('Tenant far'), findsNothing);
      expect(find.text('Tenant none'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Tenant past')).dy,
        lessThan(tester.getTopLeft(find.text('Tenant soon')).dy),
      );
    });

    testWidgets('says nothing when nothing is ending', (tester) async {
      await tester.pumpWidget(card([renting('far', DateTime.utc(2027, 6, 1))]));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leases-ending-card')), findsNothing);
    });
  });
}

void _tenantSide() {
  group("on the tenant's side", () {
    final today = DateTime(2026, 10, 12);

    LeaseResponse renting({DateTime? ends, bool active = true}) => LeaseResponse(
          id: 'l1',
          propertyId: 'p1',
          propertyName: 'Sunrise Apartments',
          unitNumber: '2B',
          bedLabel: 'Bed 1',
          startDate: DateTime.utc(2026, 4, 1),
          status: active
              ? LeaseResponseStatusEnum.ACTIVE
              : LeaseResponseStatusEnum.ENDED,
          termEndsOn: ends,
        );

    Widget notice(LeaseResponse lease, {String? landlord = 'Elena Bautista'}) =>
        ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(today),
            myInquiriesProvider.overrideWith((ref) async => [
                  if (landlord != null)
                    InquirySummary(
                      id: 'i1',
                      propertyId: 'p1',
                      withName: landlord,
                      status: InquirySummaryStatusEnum.LEASED,
                      tenancy: Tenancy(leaseId: 'l1'),
                    ),
                ]),
          ],
          child: MaterialApp(
            home: Scaffold(body: LeaseEndingNotice(lease: lease)),
          ),
        );

    testWidgets('within a month, says when and who to ask', (tester) async {
      await tester.pumpWidget(notice(renting(ends: DateTime.utc(2026, 11, 4))));
      await tester.pumpAndSettle();

      expect(find.text('Your lease ends in 23 days'), findsOneWidget);
      expect(
          find.text('On 4 November 2026. If you want to stay, ask Elena to '
              'extend it.'),
          findsOneWidget);
      expect(find.text('Message Elena'), findsOneWidget);
    });

    /// Calm: nothing has ended, the landlord just has not said.
    testWidgets('past its end, says nothing has changed', (tester) async {
      await tester.pumpWidget(notice(renting(ends: DateTime.utc(2026, 10, 1))));
      await tester.pumpAndSettle();

      expect(find.text('Your lease has reached its end date'), findsOneWidget);
      expect(find.textContaining('so nothing has changed'), findsOneWidget);
    });

    testWidgets('with no conversation yet, it is "your landlord"',
        (tester) async {
      await tester.pumpWidget(
          notice(renting(ends: DateTime.utc(2026, 11, 4)), landlord: null));
      await tester.pumpAndSettle();

      expect(find.text('Message your landlord'), findsOneWidget);
    });

    for (final (name, lease) in [
      ('month to month', renting()),
      ('far off', renting(ends: DateTime.utc(2027, 3, 31))),
      ('already ended', renting(ends: DateTime.utc(2026, 11, 4), active: false)),
    ]) {
      testWidgets('says nothing when $name', (tester) async {
        await tester.pumpWidget(notice(lease));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('lease-ending')), findsNothing);
      });
    }
  });
}

Future<void> tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _Landlord extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(Session(
        userId: 'u1',
        name: 'Elena Bautista',
        profiles: {LizmoProfile.landlord},
        accessToken: 'token',
      ));
}

class _FakeLeases extends LeasesApi {
  final changed = <DateTime?>[];

  @override
  Future<LeaseResponse?> changeLeaseTerm(
    String id,
    LeaseTermRequest leaseTermRequest, {
    Future<void>? abortTrigger,
  }) async {
    changed.add(leaseTermRequest.endsOn);
    return null;
  }
}
