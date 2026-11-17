import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/widgets/section_tab_bar.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// The tab bar at the text sizes people actually use.
void main() {
  const tabs = [
    SectionTab(key: ValueKey('tab-home'), icon: Icons.home_outlined, label: 'Home'),
    SectionTab(key: ValueKey('tab-rent'), icon: Icons.receipt_long_outlined, label: 'Rent'),
    SectionTab(key: ValueKey('tab-place'), icon: Icons.bed_outlined, label: 'My place'),
    SectionTab(key: ValueKey('tab-messages'), icon: Icons.forum_outlined, label: 'Messages'),
    SectionTab(
        key: ValueKey('tab-maintenance'), icon: Icons.build_outlined, label: 'Maintenance'),
  ];

  Widget bar(double textScale, {int index = 0}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            bottomNavigationBar:
                SectionTabBar(tabs: tabs, index: index, onTap: (_) {}),
          ),
        ),
      );

  testWidgets('every tab says its word at ordinary sizes', (tester) async {
    await tester.pumpWidget(bar(1.0));

    for (final word in ['Home', 'Rent', 'My place', 'Messages', 'Maintenance']) {
      expect(find.text(word), findsOneWidget);
    }
  });

  /// "Maintenance" was cut to "Maintenanc…" at 115% on a 360 phone.
  testWidgets('with large text only the chosen tab says its word', (tester) async {
    await tester.pumpWidget(bar(1.35, index: 4));

    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Messages'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('and the others still have a name for screen readers',
      (tester) async {
    await tester.pumpWidget(bar(1.35));

    expect(find.bySemanticsLabel('Messages'), findsOneWidget);
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
  });

  testWidgets('the unselected text colour meets contrast', (tester) async {
    await tester.pumpWidget(bar(1.0));

    final rent = tester.widget<Text>(find.text('Rent'));
    expect(rent.style?.color, LizmoColors.slateText);
  });
}
