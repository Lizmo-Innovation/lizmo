import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';

/// The account menu, opened from the header.
///
/// A bottom sheet rather than a dropdown: it is reachable one-handed on a
/// phone, and leaves room for the settings and profile items that will follow
/// without needing a different pattern later.
class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DEDC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(session?.name ?? 'Signed in', style: LizmoType.rowName.copyWith(fontSize: 16)),
            const SizedBox(height: 2),
            Text(_profileLabel(session), style: LizmoType.rowSub),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE3E8E6)),
            const SizedBox(height: 8),

            // Only tenants have a tenant profile to edit. A landlord-only
            // account has one in the database, but nothing that would ever be
            // read from it.
            if (session?.isTenant ?? false)
              _SheetAction(
                icon: Icons.badge_outlined,
                label: 'My profile',
                colour: LizmoColors.ink,
                onTap: () {
                  // Close first: pushing under an open sheet leaves it
                  // floating over the profile form.
                  Navigator.of(context).pop();
                  context.push(Routes.tenantProfile);
                },
              ),

            // Not buried, deliberately. An app that makes leaving hard is an
            // app people leave badly -- by uninstalling, which deletes nothing
            // and leaves their ID photographs where they were.
            _SheetAction(
              icon: Icons.delete_outline,
              label: 'Delete my account',
              colour: LizmoColors.ink,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.deleteAccount);
              },
            ),

            _SheetAction(
              icon: Icons.logout,
              label: 'Sign out',
              // Red rather than coral: coral is the action accent, and signing
              // out is a departure rather than the screen's main action.
              colour: LizmoColors.red,
              onTap: () async {
                // Close the sheet first. Signing out changes auth state, and
                // the router swaps the screen underneath — leaving the sheet
                // open would strand it over the login screen.
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Describes what the account is, in the user's terms rather than the API's.
  static String _profileLabel(Session? session) {
    if (session == null) return '';
    final parts = <String>[
      if (session.isTenant) 'Tenant',
      if (session.isLandlord) 'Landlord',
    ];
    return parts.isEmpty ? '' : parts.join(' · ');
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.colour,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color colour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colour),
              const SizedBox(width: 12),
              Text(label, style: LizmoType.rowName.copyWith(color: colour)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the account sheet. Sits in the header beside the role switcher.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => AccountSheet.show(context),
      icon: const Icon(Icons.account_circle_outlined),
      color: LizmoColors.white,
      iconSize: 24,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Account',
    );
  }
}
