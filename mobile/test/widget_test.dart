import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/main.dart';
import 'package:lizmo/widgets/status_chip.dart';

void main() {
  testWidgets('rent roll renders header, tenants and the single action', (tester) async {
    await tester.pumpWidget(const LizmoApp());

    // Header: eyebrow is uppercased by LatticeHeader, title is verbatim.
    expect(find.text('SUNRISE APARTMENTS'), findsOneWidget);
    expect(find.text('Rent roll — August'), findsOneWidget);

    // Amounts render as given, in mono.
    expect(find.text('₱2,500'), findsNWidgets(2));
    expect(find.text('₱7,000'), findsOneWidget);

    // One chip per tenant row, covering all three statuses.
    expect(find.byType(StatusChip), findsNWidgets(4));
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Paid'), findsNWidgets(2));
  });

  test('each status maps to its fixed colour pair', () {
    // Guards the mapping in the design language: teal = paid, amber = pending,
    // red = overdue. Reassigning these breaks scannability across the app.
    expect(LizmoStatus.paid.foreground, const Color(0xFF0E5C52));
    expect(LizmoStatus.pending.foreground, const Color(0xFF8A5A0A));
    expect(LizmoStatus.overdue.foreground, const Color(0xFFDA4A42));
  });
}
