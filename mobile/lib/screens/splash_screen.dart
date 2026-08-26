import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// The first thing the app shows, while stored tokens are checked.
///
/// Deliberately the same teal and lattice as the native splash the OS draws
/// before Flutter boots, so the handover between the two is invisible: the
/// screen appears to hold still while the app starts, rather than flashing
/// from one design to another.
///
/// The whole screen is the lattice — everywhere else it is a header sitting
/// above content, and this is the one place it gets to be the surface itself.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  /// What Lizmo is for, in one line. Bedspaces are the part other rental apps
  /// leave out, so the wording names beds explicitly.
  static const tagline = 'Every unit and bed, accounted for.'; //Lease mo, zero-hassle!

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reachable = ref.watch(backendHealthProvider);

    return Scaffold(
      backgroundColor: LizmoColors.teal900,
      body: LatticeBackground(
        child: SafeArea(
          // Full width, or the Column shrink-wraps to its widest child and
          // centres everything within *that* rather than within the screen —
          // which left the mark, wordmark and tagline all 32px off centre.
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // The mark sits slightly above centre. Optically centred rather
                // than measured — text below the mark pulls the eye down, so a
                // true centre reads as too low.
                const Spacer(flex: 5),
                const _Mark(),
                const SizedBox(height: 22),
                const Text('Lizmo', style: LizmoType.wordmark),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: LizmoType.tagline,
                  ),
                ),
                const Spacer(flex: 6),
                if (reachable == BackendReachability.unreachable)
                  _Unreachable(
                    onRetry: () =>
                        ref.read(backendHealthProvider.notifier).check(),
                  )
                else
                  const _Waiting(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    // The adaptive-icon foreground: the mark alone, already white on
    // transparent, so it needs no tinting to sit on the teal.
    return Image.asset(
      'assets/icon/icon_foreground.png',
      width: 132,
      height: 132,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// A quiet indication that something is happening.
///
/// Restoring a session is usually quick, so this is understated: a spinner
/// large enough to notice would suggest a wait that is not coming.
class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          LizmoColors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// The backend cannot be reached, so there is nowhere to go.
///
/// Shown in place of the spinner rather than as a new screen: the app has not
/// started yet, and throwing away the splash to say so would make a temporary
/// problem look like a broken app.
class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_outlined,
            size: 20,
            color: LizmoColors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(
            "Can't reach Lizmo",
            textAlign: TextAlign.center,
            style: LizmoType.rowName.copyWith(color: LizmoColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: LizmoType.tagline,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: LizmoColors.white.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try again',
              style: LizmoType.rowName.copyWith(color: LizmoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
