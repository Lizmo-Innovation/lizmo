import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/inquiry/inquiry_providers.dart';
import 'package:lizmo/notice/notice_providers.dart';
import 'package:lizmo/property/place_details.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/screens/property_detail_screen.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// The property screen as one scroll: what it must still do on a small phone
/// with large text, and how it spreads out on a tablet.
void main() {
  void surface(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
    });
  }

  UnitResponse unit(String number, String floor) => UnitResponse(
        id: 'u-$number',
        propertyId: 'p1',
        unitNumber: number,
        floor: floor,
        rentalMode: UnitResponseRentalModeEnum.BEDSPACE,
        capacity: 4,
        bedCount: 4,
        rent: 2500,
        status: UnitResponseStatusEnum.VACANT,
      );

  final many = [
    for (var i = 1; i <= 4; i++) unit('1${String.fromCharCode(64 + i)}', '1'),
    for (var i = 1; i <= 4; i++) unit('2${String.fromCharCode(64 + i)}', '2'),
  ];

  Widget screen({
    FutureOr<List<UnitResponse>> Function()? units,
    double textScale = 1.0,
    List<PropertyPhoto> photos = const [],
  }) =>
      ProviderScope(
        overrides: [
          propertiesProvider.overrideWith((ref) async => [
                PropertyResponse(
                  id: 'p1',
                  name: 'Sunrise Apartments',
                  code: 'PHK7M4Q2',
                  address: '12 Mabini St, Naga City',
                  description: 'Two floors of bedspaces near the university. '
                      'Water and Wi-Fi included. Quiet after ten in the evening, '
                      'shoes off inside, and visitors in the common room only.',
                ),
              ]),
          unitsProvider('p1').overrideWith((ref) async => (units ?? () => many)()),
          propertyOverviewProvider('p1').overrideWith((ref) async =>
              PropertyOverview(occupied: 10, rentable: 32, vacant: 22, overdueTotal: 2500)),
          propertyPhotosProvider('p1').overrideWith((ref) async => photos),
          myInquiriesProvider.overrideWith((ref) async => const <InquirySummary>[]),
          propertyNoticesProvider('p1').overrideWith((ref) async => const <NoticeResponse>[]),
          placeDetailsProvider('p1').overrideWith((ref) async => PlaceDetailsDto()),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: const PropertyDetailScreen(propertyId: 'p1'),
          ),
        ),
      );

  Future<void> scrollToUnits(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
  }

  /// The spec's line: after scrolling, the units fill everything between the
  /// pinned chips and the bottom, and the button is still there.
  testWidgets('360 wide at 135% text: the units fill the screen once scrolled',
      (tester) async {
    surface(tester, 360, 800);
    await tester.pumpWidget(screen(textScale: 1.35));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await scrollToUnits(tester);

    final chips = tester.getRect(find.text('All'));
    expect(chips.top, lessThan(140), reason: 'chips pinned under the bar');
    final cards = find.byWidgetPredicate(
        (w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('unit-card-'));
    expect(cards, findsWidgets);
    final lowest = cards.evaluate().map((e) => tester.getRect(find.byWidget(e.widget)).bottom);
    expect(lowest.reduce((a, b) => a > b ? a : b), greaterThan(600));
    expect(find.text('+ Add a unit'), findsOneWidget);
    expect(tester.getRect(find.text('+ Add a unit')).bottom, lessThan(800));
  });

  testWidgets('the bar names the place once the hero has gone', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    final title = find.ancestor(
        of: find.text('Sunrise Apartments').first, matching: find.byType(AnimatedOpacity));
    expect(tester.widget<AnimatedOpacity>(title.first).opacity, 0);

    await scrollToUnits(tester);

    expect(
      tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).any((w) => w.opacity == 1),
      isTrue,
    );
  });

  testWidgets('the header says how full the place is', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('PROPERTY · PHK7M4Q2'), findsOneWidget);
    expect(find.text('12 Mabini St, Naga City'), findsOneWidget);
    expect(find.text('10/32'), findsWidgets);
    expect(find.text('₱2,500'), findsOneWidget);
    expect(find.text('8 units · 32 beds'), findsOneWidget);
  });

  testWidgets('the description is two lines until More', (tester) async {
    surface(tester, 360, 800);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('a skeleton while the units load', (tester) async {
    final waiting = Completer<List<UnitResponse>>();
    await tester.pumpWidget(screen(units: () => waiting.future));
    await tester.pump();

    expect(find.bySemanticsLabel('Loading units'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('photos are a row of thumbnails, the last saying how many more',
      (tester) async {
    surface(tester, 360, 800);
    await tester.pumpWidget(screen(photos: [
      for (var i = 0; i < 8; i++) PropertyPhoto(id: 'ph$i', url: null),
    ]));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-photos')), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\+\d$')), findsOneWidget);
  });

  testWidgets('on a tablet the units go two across', (tester) async {
    surface(tester, 800, 1280);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await scrollToUnits(tester);

    final a = tester.getRect(find.byKey(const ValueKey('unit-card-u-1A')));
    final b = tester.getRect(find.byKey(const ValueKey('unit-card-u-1B')));
    expect(a.top, b.top);
    expect(a.left, lessThan(b.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the add button is Ink on coral', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(fab.backgroundColor, LizmoColors.coral);
    expect(fab.foregroundColor, LizmoColors.onCoral);
  });
}
