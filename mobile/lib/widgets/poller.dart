import 'dart:async';

import 'package:flutter/material.dart';

/// Re-reads something on a timer, while it is on screen and the app is in
/// front.
///
/// Lizmo has no live connection: a conversation updates when somebody opens
/// it, writes in it, or pulls down. Two people typing at each other saw
/// nothing. Streaming would mean a message bus and a fan-out problem across
/// Cloud Run instances; a timer is a day's work and, for two people actually
/// talking, indistinguishable.
///
/// Never while the app is in the background. That is what a push notification
/// is for, and a timer running behind a locked screen is a battery complaint.
class Poller extends StatefulWidget {
  const Poller({
    super.key,
    required this.child,
    required this.onTick,
    required this.interval,
    this.slowAfter,
    this.slowInterval,
  });

  final Widget child;

  /// Called on each tick, and once immediately when the app comes back.
  final VoidCallback onTick;

  final Duration interval;

  /// How long without anything happening before [slowInterval] takes over.
  ///
  /// A thread left open on a desk should not bill a landlord all afternoon,
  /// and the server scales to zero when nobody is asking it anything.
  final Duration? slowAfter;
  final Duration? slowInterval;

  @override
  State<Poller> createState() => PollerState();
}

class PollerState extends State<Poller> with WidgetsBindingObserver {
  /// One beat a second, with the reading and the quiet both counted in
  /// beats. They were a counter and a wall clock, which disagree the moment
  /// anything suspends the timer -- and in a test, where the clock is faked
  /// and the timer is not, they never agreed at all.
  static const _beat = Duration(seconds: 1);

  Timer? _timer;
  int _sinceRead = 0;
  int _sinceActivity = 0;
  bool _inFront = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inFront = state == AppLifecycleState.resumed;
    if (inFront == _inFront) return;

    _inFront = inFront;
    if (!inFront) {
      _timer?.cancel();
      return;
    }

    // Coming back is where most staleness is noticed, so it is read at once
    // rather than up to a tick later.
    stirred();
    widget.onTick();
    _start();
  }

  /// Something happened — a message arrived, or somebody wrote one — so the
  /// fast interval is worth paying for again.
  void stirred() => _sinceActivity = 0;

  void _start() {
    _timer?.cancel();
    _sinceRead = 0;
    _timer = Timer.periodic(_beat, (_) {
      if (!_inFront) return;

      _sinceActivity++;
      _sinceRead++;

      // Read off the counter rather than by rescheduling, so the interval
      // can change under the timer without restarting it.
      final quiet = widget.slowAfter != null &&
          _sinceActivity > widget.slowAfter!.inSeconds;
      final every =
          quiet ? (widget.slowInterval ?? widget.interval) : widget.interval;

      if (_sinceRead >= every.inSeconds) {
        _sinceRead = 0;
        widget.onTick();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
