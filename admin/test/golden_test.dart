import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/main.dart';

/// Renders the admin console at desktop size for visual review.
/// Regenerate with `flutter test --update-goldens`.
///
/// As with the mobile goldens, google_fonts cannot fetch under `flutter test`,
/// so type falls back — this verifies layout and colour only.
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
