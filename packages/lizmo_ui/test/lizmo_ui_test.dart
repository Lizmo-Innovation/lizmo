import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

void main() {
  group('status colour mapping', () {
    // Pinned deliberately: the mapping is fixed across both apps, and silently
    // reassigning a colour would break a landlord's ability to scan a list.
    test('paid is teal', () {
      expect(LizmoStatus.paid.background, LizmoColors.tealBg);
      expect(LizmoStatus.paid.foreground, LizmoColors.teal900);
    });

    test('pending is amber, with darkened text for contrast', () {
      expect(LizmoStatus.pending.background, LizmoColors.amberBg);
      expect(LizmoStatus.pending.foreground, LizmoColors.amberText);
      expect(LizmoStatus.pending.dot, LizmoColors.amber);
    });

    test('overdue is red', () {
      expect(LizmoStatus.overdue.background, LizmoColors.redBg);
      expect(LizmoStatus.overdue.foreground, LizmoColors.red);
    });
  });

  testWidgets('chip renders its label and dot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip(status: LizmoStatus.paid, label: 'Paid'),
        ),
      ),
    );

    expect(find.text('Paid'), findsOneWidget);
    expect(find.byType(StatusChip), findsOneWidget);
  });
}
