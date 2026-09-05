@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/main.dart';
import 'package:lizmo_admin/admin_providers.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Renders the console for visual review.
/// Regenerate with `flutter test test/golden_test.dart --update-goldens`.
///
/// Renders with real type now that the fonts are bundled in lizmo_ui, so a
/// typography regression shows up here.
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
        // The console reads the admin API on every screen; the golden is about
        // how a populated list looks, not about an error state.
        landlordsProvider.overrideWith((ref) async => [
              LandlordSummary(
                userId: 'l1',
                name: 'Elena Bautista',
                email: 'elena@example.com',
                properties: 3,
                lockedProperties: 1,
                occupiedUnits: 2,
                occupiedBeds: 9,
              ),
              LandlordSummary(
                userId: 'l2',
                name: 'Rodel Cruz',
                email: 'rodel@example.com',
                properties: 1,
                lockedProperties: 0,
                occupiedUnits: 0,
                occupiedBeds: 4,
              ),
            ]),
        invitationsProvider.overrideWith((ref) async => const []),
      ],
      child: const LizmoAdminApp(),
    );

void main() {
  testWidgets('the console where an admin lands', (tester) async {
    tester.view
      ..physicalSize = const Size(1100, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const AuthSignedIn(Session(
      userId: 'u1',
      name: 'Lizmo Staff',
      profiles: {LizmoProfile.admin},
      accessToken: 'token',
    ))));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoAdminApp),
      matchesGoldenFile('goldens/console_landlords.png'),
    );
  });

  testWidgets('the invitations screen', (tester) async {
    tester.view
      ..physicalSize = const Size(1100, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const AuthSignedIn(Session(
      userId: 'u1',
      name: 'Lizmo Staff',
      profiles: {LizmoProfile.admin},
      accessToken: 'token',
    ))));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Invitations'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoAdminApp),
      matchesGoldenFile('goldens/console_invitations.png'),
    );
  });

  testWidgets('login golden', (tester) async {
    tester.view
      ..physicalSize = const Size(1100, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const AuthSignedOut()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoAdminApp),
      matchesGoldenFile('goldens/admin_login.png'),
    );
  });
}
