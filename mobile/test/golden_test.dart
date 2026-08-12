import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/main.dart';

/// Renders the rent roll at phone size so the design language can be reviewed
/// as an image. Regenerate with `flutter test --update-goldens`.
///
/// Note: google_fonts cannot fetch over the network under `flutter test`, so the
/// golden shows layout and colour faithfully but falls back on type. Check
/// typography in a real browser or device, not here.
void main() {
  testWidgets('rent roll golden', (tester) async {
    tester.view
      ..physicalSize = const Size(375 * 2, 812 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LizmoApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LizmoApp),
      matchesGoldenFile('goldens/rent_roll.png'),
    );
  });
}
