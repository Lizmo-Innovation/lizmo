@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/main.dart';

/// Renders the admin console at desktop size for visual review.
/// Regenerate with `flutter test --update-goldens`.
///
/// Renders with real type now that the fonts are bundled in lizmo_ui, so a
/// typography regression shows up here.
void main() {
  testWidgets('platform payments golden', (tester) async {
    tester.view
      ..physicalSize = const Size(1100, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LizmoAdminApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoAdminApp),
      matchesGoldenFile('goldens/platform_payments.png'),
    );
  });
}
