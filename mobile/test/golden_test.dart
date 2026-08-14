@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// Renders each role's home screen for visual review.
/// Regenerate with `flutter test test/golden_test.dart --update-goldens`.
///
/// Renders with real type now that the fonts are bundled in lizmo_ui, so a
/// typography regression is visible here. Tagged `golden` and excluded from CI:
/// they are generated on Windows and rasterise differently on Linux.
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
      ],
      child: const LizmoApp(),
    );

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(375 * 2, 812 * 2)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

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
      matchesGoldenFile('goldens/rent_roll_switcher.png'),
    );
  });
}
