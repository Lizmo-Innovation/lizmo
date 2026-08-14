import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'screens/admin_login_screen.dart';
import 'screens/platform_payments_screen.dart';

/// Decides what the console shows.
///
/// Three states rather than the mobile app's two, because signing in
/// successfully is not sufficient here: the account must also be internal Lizmo
/// staff. A landlord with valid credentials gets [_NotAnAdmin], never the queue.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return switch (auth) {
      AuthUnknown() => const _Splash(),
      AuthSignedOut() => const AdminLoginScreen(),
      AuthSignedIn(:final session) => session.isPlatformAdmin
          ? const PlatformPaymentsScreen()
          : const _NotAnAdmin(),
    };
  }
}

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

/// Shown when a valid account is not a platform admin.
///
/// Says plainly that the account lacks access rather than implying the
/// credentials were wrong — the person is signed in, just not staff.
class _NotAnAdmin extends ConsumerWidget {
  const _NotAnAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This account is not a Lizmo admin.',
                  textAlign: TextAlign.center,
                  style: LizmoType.rowName.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'The console is for Lizmo staff. Landlord and tenant accounts '
                  'use the Lizmo app instead.',
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
