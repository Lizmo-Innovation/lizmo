import 'package:flutter/material.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'auth/active_role.dart';
import 'screens/login_screen.dart';
import 'screens/rent_roll_screen.dart';
import 'screens/tenant_home_screen.dart';

/// Decides what the app shows, from auth state and the active role.
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
      AuthSignedIn() => const _RoleHome(),
    };
  }
}

/// Routes to the home screen for whichever role is active.
class _RoleHome extends ConsumerWidget {
  const _RoleHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider);

    return switch (role) {
      LizmoProfile.landlord => const RentRollScreen(),
      LizmoProfile.tenant => const TenantHomeScreen(),
      // ADMIN is not a role this app serves — platform admins use the web
      // console. It never becomes the active role (ActiveRoleController only
      // ever selects tenant or landlord), and an admin who also rents simply
      // sees the tenant view.
      LizmoProfile.admin => const _NoProfile(),
      // Only reachable if the account somehow holds no profiles at all.
      // Registration always creates a tenant profile, so this is a guard
      // against bad data rather than an expected state.
      null => const _NoProfile(),
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

class _NoProfile extends ConsumerWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This account has no tenant or landlord profile yet.',
                  textAlign: TextAlign.center,
                  style: LizmoType.rowName,
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact your landlord, or sign in with a different account.',
                  textAlign: TextAlign.center,
                  style: LizmoType.rowSub,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  child: Text(
                    'Sign out',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
