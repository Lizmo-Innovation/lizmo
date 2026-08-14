@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/admin_shell.dart';
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
      ],
      child: const MaterialApp(home: AdminShell()),
    );

void main() {
  testWidgets('platform payments golden', (tester) async {
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
      find.byType(AdminShell),
      matchesGoldenFile('goldens/platform_payments.png'),
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
      find.byType(AdminShell),
      matchesGoldenFile('goldens/admin_login.png'),
    );
  });
}
