import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'auth/auth_state.dart';
import 'auth/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/rent_roll_screen.dart';

/// Decides what the app shows, based purely on auth state.
///
/// Screens never navigate to or from login themselves — they change auth state
/// and the shell reacts. That keeps "signed out" a single source of truth, so a
/// rejected refresh deep inside the app lands the user on login without every
/// screen needing to handle it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return switch (auth) {
      AuthUnknown() => const _Splash(),
      AuthSignedOut() => const LoginScreen(),
      // TODO: tenants should land on their own lease view, not the rent roll —
      // this shows the landlord screen to everyone until that screen exists.
      AuthSignedIn() => const RentRollScreen(),
    };
  }
}

/// Shown only while stored tokens are being checked, which is typically a few
/// hundred milliseconds.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      ),
    );
  }
}
