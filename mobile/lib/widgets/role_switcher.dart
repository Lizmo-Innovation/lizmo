import 'package:flutter/material.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../auth/active_role.dart';
import '../router.dart';

/// Switches between the tenant and landlord views.
///
/// Renders nothing at all for the overwhelming majority of users, who hold one
/// profile — an inert control that never does anything is worse than no control.
class RoleSwitcher extends ConsumerWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn || !auth.session.hasMultipleProfiles) {
      return const SizedBox.shrink();
    }

    final active = ref.watch(activeRoleProvider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LizmoColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final role in [LizmoProfile.tenant, LizmoProfile.landlord])
            if (auth.session.profiles.contains(role))
              _RoleTab(
                label: role == LizmoProfile.tenant ? 'Tenant' : 'Landlord',
                selected: active == role,
                onTap: () {
                  ref.read(activeRoleProvider.notifier).switchTo(role);
                  // Navigate explicitly: the router redirects on *auth* changes,
                  // and switching role is not one. go() rather than push() so
                  // back does not return to the other role's screen.
                  // The section roots, not the prefixes: both sections are
                  // tab shells now, and /tenant on its own is not a screen.
                  context.go(role == LizmoProfile.tenant
                      ? Routes.tenantHome
                      : Routes.landlordHome);
                },
              ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // The selected tab sits on white so it reads against the teal
            // header; the unselected one stays part of the header.
            color: selected ? LizmoColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: LizmoType.chipLabel.copyWith(
              color: selected
                  ? LizmoColors.teal900
                  : LizmoColors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}
