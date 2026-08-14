@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/app_shell.dart';
import 'package:lizmo/auth/auth_controller.dart';
import 'package:lizmo/auth/auth_state.dart';

/// Renders each role's home screen for visual review.
/// Regenerate with `flutter test test/golden_test.dart --update-goldens`.
///
/// google_fonts cannot fetch under `flutter test`, so these verify layout and
/// colour only — type falls back until the fonts are bundled.
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
      ],
      child: const MaterialApp(home: AppShell()),
    );

void main() {
  setUp(() {
    // Phone-sized, matching the design language mockup.
  });

  testWidgets('tenant home', (tester) async {
    tester.view
      ..physicalSize = const Size(375 * 2, 812 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app({LizmoProfile.tenant}));
    await tester.pumpAndSettle();

    await expectLater(find.byType(AppShell), matchesGoldenFile('goldens/tenant_home.png'));
  });

  testWidgets('landlord rent roll with role switcher', (tester) async {
    tester.view
      ..physicalSize = const Size(375 * 2, 812 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    // Both profiles, so the switcher renders.
    await tester.pumpWidget(_app({LizmoProfile.tenant, LizmoProfile.landlord}));
    await tester.pumpAndSettle();

    await expectLater(find.byType(AppShell), matchesGoldenFile('goldens/rent_roll_switcher.png'));
  });
}
