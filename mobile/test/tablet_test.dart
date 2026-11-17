import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo/property/property_providers.dart';
import 'package:lizmo/tenant/tenant_providers.dart';
import 'package:lizmo/widgets/account_sheet.dart';
import 'package:lizmo/widgets/section_tab_bar.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Lizmo on a tablet held upright: the sections down the side, content in a
/// readable column, sheets that stay sheet-sized, and type a little larger.
void main() {
  /// A tablet-shaped surface, put back to the phone flutter_test_config sets
  /// up -- by hand, since view.reset() would revert to 800x600 for every test
  /// after this one.
  void tablet(WidgetTester tester, {double width = 800, double height = 1280}) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
    });
  }

  group('sizes', () {
    test('the three widths', () {
      expect(LizmoWidth.of(390), LizmoWidth.compact);
      expect(LizmoWidth.of(599), LizmoWidth.compact);
      expect(LizmoWidth.of(600), LizmoWidth.medium);
      expect(LizmoWidth.of(839), LizmoWidth.medium);
      expect(LizmoWidth.of(840), LizmoWidth.expanded);
    });

    testWidgets('a phone keeps its 16 gutter', (tester) async {
      late double gutter;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          gutter = context.pageGutter;
          return const SizedBox();
        }),
      ));
      expect(gutter, 16);
    });

    /// 708 across beside the rail: a 640 column with 34 either side.
    testWidgets('a tablet centres a readable column', (tester) async {
      tablet(tester);
      late double gutter;
      await tester.pumpWidget(MaterialApp(
        home: SectionScaffold(
          tabs: const [
            SectionTab(key: ValueKey('a'), icon: Icons.home, label: 'Home'),
            SectionTab(key: ValueKey('b'), icon: Icons.bed, label: 'My place'),
          ],
          index: 0,
          onTap: (_) {},
          body: Builder(builder: (context) {
            gutter = context.pageGutter;
            return const SizedBox();
          }),
        ),
      ));
      expect(gutter, (800 - 92 - 640) / 2);
    });
  });

  group('the tenant app', () {
    Widget app() => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _SignedIn({LizmoProfile.tenant})),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            myTenantProfileProvider.overrideWith((ref) async =>
                TenantProfileResponse(contactPhone: '09170000001', readyForALease: true)),
            myTenantDocumentsProvider
                .overrideWith((ref) async => const <TenantDocumentResponse>[]),
            myLeasesProvider.overrideWith((ref) async => const <LeaseResponse>[]),
          ],
          child: const LizmoApp(),
        );

    testWidgets('a phone has the bar along the bottom', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byType(SectionTabBar), findsOneWidget);
      expect(find.byType(SectionRail), findsNothing);
    });

    testWidgets('a tablet has the rail down the side, every tab whole',
        (tester) async {
      tablet(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byType(SectionRail), findsOneWidget);
      expect(find.byType(SectionTabBar), findsNothing);
      for (final key in ['tab-home', 'tab-rent', 'tab-place', 'tab-messages', 'tab-maintenance']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key);
      }
    });

    /// Gently larger, and capped: 1.15 at most on top of the reader's own.
    testWidgets('type is a little larger on a tablet', (tester) async {
      tablet(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SectionRail));
      expect(MediaQuery.textScalerOf(context).scale(10), closeTo(11.5, 0.01));
    });

    testWidgets('a sheet stays sheet-sized', (tester) async {
      tablet(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(AccountSheet)).width, lessThanOrEqualTo(560));
    });
  });

  group('the landlord app', () {
    Widget app() => ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _SignedIn({LizmoProfile.landlord})),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
            propertiesProvider.overrideWith((ref) async => const <PropertyResponse>[]),
          ],
          child: const LizmoApp(),
        );

    testWidgets('every section opens on a tablet without overflowing',
        (tester) async {
      tablet(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      for (final key in ['tab-rent', 'tab-properties', 'tab-tenants', 'tab-maintenance', 'tab-today']) {
        final tab = find.byKey(ValueKey(key));
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key);
      }
      expect(find.byType(SectionRail), findsOneWidget);
    });
  });
}

class _SignedIn extends AuthController {
  _SignedIn(this.profiles);

  final Set<LizmoProfile> profiles;

  @override
  AuthState build() => AuthSignedIn(Session(
        userId: 'u1',
        name: 'Elena Bautista',
        profiles: profiles,
        accessToken: 'token',
      ));
}
