import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_admin/main.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

void main() {
  testWidgets('review queue lists payments with their statuses', (tester) async {
    tester.view
      ..physicalSize = const Size(1280 * 2, 900 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LizmoAdminApp());

    expect(find.text('LIZMO ADMIN'), findsOneWidget);
    expect(find.text('Platform payments'), findsOneWidget);
    expect(find.byType(StatusChip), findsNWidgets(4));
  });

  testWidgets('only pending payments expose confirm/reject', (tester) async {
    tester.view
      ..physicalSize = const Size(1280 * 2, 900 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LizmoAdminApp());

    // Two of the four fixtures are pending; confirmed and overdue rows must not
    // offer a decision, since there is nothing left to decide.
    expect(find.text('Confirm'), findsNWidgets(2));
    expect(find.text('Reject'), findsNWidgets(2));
  });
}
