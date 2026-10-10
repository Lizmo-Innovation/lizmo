import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/widgets/date_field.dart';

/// Typing a date, which is the way anybody enters a birthday.
///
/// The calendar is quicker for next Tuesday and miserable for 1998, and the
/// picker's own keyboard mode inserted nothing and refused anything that was
/// not already MM/DD/YYYY.
void main() {
  DateTime? captured;

  Widget field({
    DateTime? value,
    DateTime? first,
    DateTime? last,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: LizmoDateField(
            fieldKey: const ValueKey('date'),
            value: value,
            onChanged: (date) => captured = date,
            firstDate: first ?? DateTime.utc(1900),
            lastDate: last ?? DateTime.utc(2100),
          ),
        ),
      );

  String shown(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(const ValueKey('date'))).controller!.text;

  setUp(() => captured = null);

  testWidgets('the slashes appear as the digits do', (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '1');
    expect(shown(tester), '1');

    await tester.enterText(find.byKey(const ValueKey('date')), '10');
    expect(shown(tester), '10');

    await tester.enterText(find.byKey(const ValueKey('date')), '101');
    expect(shown(tester), '10/1');

    await tester.enterText(find.byKey(const ValueKey('date')), '10151998');
    expect(shown(tester), '10/15/1998');
    expect(captured, DateTime.utc(1998, 10, 15));
  });

  /// Somebody who types the separators themselves gets the same thing, not
  /// "10//15//1998".
  testWidgets('slashes typed by hand are not doubled', (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '10/15/1998');
    expect(shown(tester), '10/15/1998');
    expect(captured, DateTime.utc(1998, 10, 15));
  });

  testWidgets('a ninth digit is ignored', (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '101519987');
    expect(shown(tester), '10/15/1998');
  });

  /// Half a date is not a wrong date. Nobody should be told off mid-typing.
  testWidgets('an unfinished date says nothing and reports nothing',
      (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '1015');
    await tester.pump();

    expect(find.textContaining('no such date'), findsNothing);
    expect(captured, isNull);
  });

  /// DateTime would turn this into the 3rd of March rather than refusing it,
  /// which is how a birthday nobody has ends up on file.
  testWidgets('a date that does not exist is refused', (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '02311998');
    await tester.pump();

    expect(find.text('There is no such date'), findsOneWidget);
    expect(captured, isNull);
  });

  testWidgets('a month of 13 is refused', (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '13011998');
    await tester.pump();

    expect(find.text('There is no such date'), findsOneWidget);
  });

  testWidgets('29 February is allowed in a leap year and not otherwise',
      (tester) async {
    await tester.pumpWidget(field());

    await tester.enterText(find.byKey(const ValueKey('date')), '02292024');
    await tester.pump();
    expect(captured, DateTime.utc(2024, 2, 29));

    await tester.enterText(find.byKey(const ValueKey('date')), '02292023');
    await tester.pump();
    expect(find.text('There is no such date'), findsOneWidget);
    expect(captured, isNull);
  });

  testWidgets('a date outside what the screen allows is refused',
      (tester) async {
    await tester.pumpWidget(field(
      first: DateTime.utc(2020),
      last: DateTime.utc(2026, 10, 10),
    ));

    await tester.enterText(find.byKey(const ValueKey('date')), '01012030');
    await tester.pump();
    expect(find.text('That is too far ahead'), findsOneWidget);
    expect(captured, isNull);

    await tester.enterText(find.byKey(const ValueKey('date')), '01011999');
    await tester.pump();
    expect(find.text('That is too far back'), findsOneWidget);
  });

  testWidgets('a date already set is shown in the same shape', (tester) async {
    await tester.pumpWidget(field(value: DateTime.utc(1998, 1, 5)));

    expect(shown(tester), '01/05/1998');
  });

  /// The calendar is still there for anybody who would rather point at it.
  testWidgets('the calendar button fills the field in', (tester) async {
    await tester.pumpWidget(field(
      value: DateTime.utc(2026, 10, 10),
      first: DateTime.utc(2026, 10, 1),
      last: DateTime.utc(2026, 10, 31),
    ));

    await tester.tap(find.byKey(const ValueKey('open-calendar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(shown(tester), '10/15/2026');
    expect(captured, DateTime.utc(2026, 10, 15));
  });
}
