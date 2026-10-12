import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/billing/payment_channel_providers.dart';
import 'package:lizmo/inquiry/inquiry_providers.dart';
import 'package:lizmo/property/place_details.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/place_details_screen.dart';
import 'package:lizmo/screens/unit_detail_screen.dart';
import 'package:lizmo/tenant/tenant_providers.dart';
import 'package:lizmo/widgets/accept_terms_sheet.dart';
import 'package:lizmo/widgets/before_you_ask.dart';
import 'package:lizmo/widgets/getting_started_card.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Place details from the landlord's end: saying them, having the lease
/// sheet fill itself in from them, and saying when a room is ready.
void main() {
  late _FakeProperties properties;
  late _FakeUnits units;

  setUp(() {
    properties = _FakeProperties();
    units = _FakeUnits();
  });

  Future<void> tapShown(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('saying them', () {
    Widget screen(PlaceDetailsDto initial) => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _Landlord()),
            propertiesApiProvider.overrideWithValue(properties),
            placeDetailsProvider('p1').overrideWith((ref) async => initial),
          ],
          child: const MaterialApp(home: PlaceDetailsScreen(propertyId: 'p1')),
        );

    testWidgets('choices become what is saved', (tester) async {
      await tester.pumpWidget(screen(PlaceDetailsDto()));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('who-WOMEN')));
      await tapShown(tester, find.byKey(const ValueKey('visitors-DAYTIME')));
      await tapShown(tester, find.byKey(const ValueKey('pets-false')));
      await tapShown(tester, find.byKey(const ValueKey('cooking-true')));
      await tapShown(tester, find.byKey(const ValueKey('deposit-2')));
      await tapShown(tester, find.byKey(const ValueKey('advance-1')));
      await tapShown(tester, find.byKey(const ValueKey('amenity-WIFI')));
      await tester.enterText(
          find.byKey(const ValueKey('other-rules')), 'Shoes off inside.');
      await tapShown(tester, find.byKey(const ValueKey('save-place-details')));

      final saved = properties.saved.single;
      expect(saved.whoCanRent, PlaceDetailsDtoWhoCanRentEnum.WOMEN);
      expect(saved.visitors, PlaceDetailsDtoVisitorsEnum.DAYTIME);
      expect(saved.pets, isFalse);
      expect(saved.cooking, isTrue);
      expect(saved.smoking, isNull);
      expect(saved.depositMonths, 2);
      expect(saved.advanceMonths, 1);
      expect(saved.amenities, [PlaceDetailsDtoAmenitiesEnum.WIFI]);
      expect(saved.otherRules, 'Shoes off inside.');
      expect(saved.curfew, isNull);
    });

    /// Not said is a real answer, and not the same as no.
    testWidgets('tapping a choice again takes it back', (tester) async {
      await tester.pumpWidget(screen(PlaceDetailsDto(
        whoCanRent: PlaceDetailsDtoWhoCanRentEnum.MEN,
        pets: true,
        curfew: '22:00',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Doors close 10pm'), findsOneWidget);
      await tapShown(tester, find.byKey(const ValueKey('who-MEN')));
      await tapShown(tester, find.byKey(const ValueKey('pets-true')));
      await tapShown(tester, find.byKey(const ValueKey('curfew-clear')));
      await tapShown(tester, find.byKey(const ValueKey('save-place-details')));

      final saved = properties.saved.single;
      expect(saved.whoCanRent, isNull);
      expect(saved.pets, isNull);
      expect(saved.curfew, isNull);
    });
  });

  group('the lease sheet', () {
    Widget sheet({int? deposit, int? advance, List<FreeRoom>? rooms}) => MaterialApp(
          home: Scaffold(
            body: AcceptTermsSheet(
              tenantName: 'Ana Reyes',
              slot: 'Sunrise Apartments',
              askingRent: 2500,
              rooms: rooms,
              depositMonths: deposit,
              advanceMonths: advance,
            ),
          ),
        );

    String field(WidgetTester tester, String key) => tester
        .widget<TextFormField>(find.descendant(
            of: find.byKey(ValueKey(key)), matching: find.byType(TextFormField)))
        .controller!
        .text;

    testWidgets('fills in the deposit and advance from the place', (tester) async {
      await tester.pumpWidget(sheet(deposit: 2, advance: 1));
      await tester.pumpAndSettle();

      expect(field(tester, 'deposit-amount'), '5000');
      expect(field(tester, 'advance-amount'), '2500');
      expect(find.text('From your place details: 2 months.'), findsOneWidget);
      expect(find.text('From your place details: 1 month.'), findsOneWidget);
    });

    /// A ₱3,000 room's two months are not a ₱2,500 room's.
    testWidgets('follows the room chosen', (tester) async {
      await tester.pumpWidget(sheet(deposit: 2, rooms: const [
        FreeRoom(unitId: 'u1', bedId: null, label: 'Unit 3A', rent: 3000),
      ]));
      await tester.pumpAndSettle();

      await tapShown(tester, find.byKey(const ValueKey('room-u1')));
      expect(field(tester, 'deposit-amount'), '6000');
    });

    testWidgets('a figure typed over is the landlord’s own', (tester) async {
      await tester.pumpWidget(sheet(deposit: 2, rooms: const [
        FreeRoom(unitId: 'u1', bedId: null, label: 'Unit 3A', rent: 3000),
      ]));
      await tester.pumpAndSettle();

      final deposit = find.descendant(
          of: find.byKey(const ValueKey('deposit-amount')),
          matching: find.byType(TextFormField));
      await tester.ensureVisible(deposit);
      await tester.enterText(deposit, '4000');
      await tester.pumpAndSettle();
      await tapShown(tester, find.byKey(const ValueKey('room-u1')));

      expect(field(tester, 'deposit-amount'), '4000');
      expect(find.byKey(const ValueKey('deposit-from-details')), findsNothing);
    });

    testWidgets('without place details, nothing is filled in', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();

      expect(field(tester, 'deposit-amount'), '');
      expect(find.textContaining('From your place details'), findsNothing);
    });
  });

  group('before you ask', () {
    Future<void> show(WidgetTester tester, PlaceDetailsDto details,
        {num? rent = 2500}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BeforeYouAsk(details: details, cheapestRent: rent),
          ),
        ),
      ));
    }

    /// The first month is due on move-in day, paid ahead or not.
    testWidgets('no advance still means the first month on the day',
        (tester) async {
      await show(tester, PlaceDetailsDto(depositMonths: 1, advanceMonths: 0));

      expect(find.text('Deposit 1 month · No advance'), findsOneWidget);
      expect(find.text('About ₱5,000 to move in, for a ₱2,500 space'), findsOneWidget);
    });

    testWidgets('half the answer gets no total', (tester) async {
      await show(tester, PlaceDetailsDto(depositMonths: 2));

      expect(find.text('Deposit 2 months'), findsOneWidget);
      expect(find.byKey(const ValueKey('move-in-total')), findsNothing);
    });

    testWidgets('other rules are shown as written', (tester) async {
      await show(tester, PlaceDetailsDto(otherRules: 'Shoes off inside.'));

      expect(find.text('House rules'), findsOneWidget);
      expect(find.text('Shoes off inside.'), findsOneWidget);
      expect(find.text('Money up front'), findsNothing);
    });

    testWidgets('a landlord too new to say how fast they reply', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LandlordCardView(
            landlord: LandlordCard(name: 'Elena B.', since: DateTime.utc(2026, 10, 1)),
          ),
        ),
      ));

      expect(find.text('Let by Elena B.'), findsOneWidget);
      expect(find.text('On Lizmo since October 2026'), findsOneWidget);
    });
  });

  group('getting started', () {
    Widget section(PlaceDetailsDto? details) => ProviderScope(
          overrides: [
            propertiesProvider.overrideWith((ref) async =>
                [PropertyResponse(id: 'p1', name: 'Sunrise', unitCount: 2)]),
            myPaymentChannelsProvider
                .overrideWith((ref) async => const <PaymentChannelResponse>[]),
            occupancyProvider.overrideWith((ref) async => OccupancySummary()),
            myInquiriesProvider.overrideWith((ref) async => const <InquirySummary>[]),
            placeDetailsProvider('p1').overrideWith((ref) async => details),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: GettingStartedSection())),
          ),
        );

    testWidgets('asks for them while nothing is said', (tester) async {
      await tester.pumpWidget(section(PlaceDetailsDto()));
      await tester.pumpAndSettle();

      expect(find.text('Say who can rent, the rules and the deposit'), findsOneWidget);
    });

    testWidgets('until something is', (tester) async {
      await tester.pumpWidget(section(PlaceDetailsDto(depositMonths: 2)));
      await tester.pumpAndSettle();

      final step = find.text('Say who can rent, the rules and the deposit');
      expect(step, findsOneWidget);
      // Ticked: the row says it is done.
      expect(
          find.descendant(
              of: find.ancestor(of: step, matching: find.byType(Row)).first,
              matching: find.byIcon(Icons.check_circle)),
          findsOneWidget);
    });
  });

  group('a room being readied', () {
    Widget screen(UnitResponse unit) => ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(DateTime(2026, 10, 12)),
            unitsApiProvider.overrideWithValue(units),
            unitProvider('u1').overrideWith((ref) async => unit),
            bedsProvider('u1').overrideWith((ref) async => const <BedResponse>[]),
            propertiesProvider.overrideWith(
                (ref) async => [PropertyResponse(id: 'p1', name: 'Sunrise')]),
          ],
          child: const MaterialApp(
            home: UnitDetailScreen(propertyId: 'p1', unitId: 'u1'),
          ),
        );

    UnitResponse unit({UnitResponseStatusEnum? status, DateTime? readyFrom}) =>
        UnitResponse(
          id: 'u1',
          unitNumber: '2B',
          rentalMode: UnitResponseRentalModeEnum.WHOLE_UNIT,
          status: status ?? UnitResponseStatusEnum.VACANT,
          readyFrom: readyFrom,
        );

    testWidgets('a vacant room is ready now', (tester) async {
      await tester.pumpWidget(screen(unit()));
      await tester.pumpAndSettle();

      expect(find.text('Ready to move in'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('one being readied says from when', (tester) async {
      await tester.pumpWidget(screen(unit(readyFrom: DateTime.utc(2026, 11, 1))));
      await tester.pumpAndSettle();

      expect(find.text('From 1 November 2026'), findsOneWidget);
    });

    testWidgets('a full room has nothing to be ready for', (tester) async {
      await tester.pumpWidget(screen(unit(status: UnitResponseStatusEnum.OCCUPIED)));
      await tester.pumpAndSettle();

      expect(find.text('Ready to move in'), findsNothing);
    });

    testWidgets('changing it back to now clears the date', (tester) async {
      await tester.pumpWidget(screen(unit(readyFrom: DateTime.utc(2026, 11, 1))));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('unit-ready')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('term-now')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-ready')));
      await tester.pumpAndSettle();

      expect(units.readyFrom, [null]);
    });
  });
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

class _FakeProperties extends PropertiesApi {
  final saved = <PlaceDetailsDto>[];

  @override
  Future<PlaceDetailsDto?> savePlaceDetails(
    String id,
    PlaceDetailsDto placeDetailsDto, {
    Future<void>? abortTrigger,
  }) async {
    saved.add(placeDetailsDto);
    return placeDetailsDto;
  }
}

class _FakeUnits extends UnitsApi {
  final readyFrom = <DateTime?>[];

  @override
  Future<UnitResponse?> setUnitReadyFrom(
    String id,
    ReadyFromRequest readyFromRequest, {
    Future<void>? abortTrigger,
  }) async {
    readyFrom.add(readyFromRequest.readyFrom);
    return null;
  }
}
