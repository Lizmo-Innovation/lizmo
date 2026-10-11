import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/widgets/poller.dart';

/// Re-reading on a timer, which is how a conversation stays current without
/// a live connection.
void main() {
  int ticks = 0;

  Widget poller({
    Duration interval = const Duration(seconds: 5),
    Duration? slowAfter,
    Duration? slowInterval,
    GlobalKey<PollerState>? key,
  }) =>
      MaterialApp(
        home: Poller(
          key: key,
          interval: interval,
          slowAfter: slowAfter,
          slowInterval: slowInterval,
          onTick: () => ticks++,
          child: const SizedBox.shrink(),
        ),
      );

  setUp(() => ticks = 0);

  testWidgets('reads again on every interval', (tester) async {
    await tester.pumpWidget(poller());

    // Nothing immediately: the screen has just read it.
    await tester.pump(const Duration(seconds: 4));
    expect(ticks, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(ticks, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 2);

    // Settle the timer, or the test ends with one pending.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  /// A thread left open on a desk should not keep a server awake all
  /// afternoon, and Cloud Run scales to zero when nobody is asking.
  testWidgets('slows down once nothing is happening', (tester) async {
    await tester.pumpWidget(poller(
      interval: const Duration(seconds: 5),
      slowAfter: const Duration(seconds: 20),
      slowInterval: const Duration(seconds: 15),
    ));

    // Four reads in the first twenty seconds, at five apiece.
    await tester.pump(const Duration(seconds: 20));
    expect(ticks, 4);

    // Then one every fifteen, not every five.
    await tester.pump(const Duration(seconds: 14));
    expect(ticks, 4);
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, 5);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('something happening puts the pace back', (tester) async {
    final key = GlobalKey<PollerState>();
    await tester.pumpWidget(poller(
      key: key,
      interval: const Duration(seconds: 5),
      slowAfter: const Duration(seconds: 20),
      slowInterval: const Duration(seconds: 15),
    ));

    await tester.pump(const Duration(seconds: 25));
    final slow = ticks;

    // A message arrived, or somebody wrote one.
    key.currentState!.stirred();

    await tester.pump(const Duration(seconds: 5));
    expect(ticks, slow + 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  /// A timer running behind a locked screen is a battery complaint, and the
  /// thing it would be waiting for arrives as a push notification instead.
  testWidgets('nothing is read while the app is in the background',
      (tester) async {
    await tester.pumpWidget(poller());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  /// Coming back is where staleness is actually noticed, so it does not wait
  /// for the next tick.
  testWidgets('coming back reads at once', (tester) async {
    await tester.pumpWidget(poller());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(ticks, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving the screen stops it', (tester) async {
    await tester.pumpWidget(poller());
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 1);
  });
}
