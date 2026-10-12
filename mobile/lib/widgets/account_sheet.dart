import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../push/push_permission.dart';
import '../push/push_providers.dart';
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

            // Only when they are off: a menu item for a setting that is
            // already right is one more thing to read past.
            const _NotificationsOff(),

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

            // Where a landlord sees what they owe Lizmo, and pays it. On Today
            // too when something is owed; here for the history.
            if (session?.isLandlord ?? false)
              _SheetAction(
                icon: Icons.receipt_long_outlined,
                label: 'Lizmo billing',
                colour: LizmoColors.ink,
                onTap: () {
                  Navigator.of(context).pop();
                  context.openInTab(Detail.lizmoBilling);
                },
              ),

            // Where their tenants send rent. Beside Lizmo billing because it is
            // the same thing the other way round.
            if (session?.isLandlord ?? false)
              _SheetAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'How tenants pay me',
                colour: LizmoColors.ink,
                onTap: () {
                  Navigator.of(context).pop();
                  context.openInTab(Detail.paymentChannels);
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
                await ref.read(signOutProvider)();
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

/// Notifications turned off, and the way back.
///
/// Android asks twice at most. After a first "no" it can still ask again, so
/// that is tried first; after a second, only the phone's settings can turn
/// them back on, so the row goes there instead.
class _NotificationsOff extends ConsumerWidget {
  const _NotificationsOff();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(pushPermissionProvider).valueOrNull;
    if (permission == null || !permission.isOff) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('notifications-off'),
        onTap: () => _turnOn(context, ref, permission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.notifications_off_outlined,
                  size: 20, color: LizmoColors.coral),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications are off', style: LizmoType.rowName),
                    const SizedBox(height: 2),
                    Text(
                      "You won't hear about replies or payments until you "
                      'open Lizmo.',
                      style: LizmoType.rowSub,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Turn on',
                style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _turnOn(
    BuildContext context,
    WidgetRef ref,
    PushPermission permission,
  ) async {
    final channel = ref.read(pushChannelProvider);
    final navigator = Navigator.of(context);
    try {
      if (permission == PushPermission.denied &&
          await channel.askPermission() == PushPermission.granted) {
        ref.invalidate(pushPermissionProvider);
        return;
      }
      // Closed on the way out, so the menu is read afresh -- and says the
      // truth -- when they come back from settings.
      navigator.pop();
      await channel.openSettings();
    } catch (_) {
      // Nowhere to send them. The row stays, which is the truth.
    }
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
