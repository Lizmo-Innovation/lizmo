import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/account_sheet.dart';
import '../widgets/role_switcher.dart';

/// The people renting from this landlord.
///
/// Empty by construction rather than by accident: a tenant enters Lizmo by
/// being put on a lease, and leases do not exist yet. The empty state says so,
/// because "no tenants" and "this feature is not built" are different
/// statements and a landlord should not have to guess which one they are
/// looking at.
class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'Tenants',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [RoleSwitcher(), SizedBox(width: 4), AccountButton()],
            ),
          ),
          const Expanded(
            child: LizmoMessageState(
              icon: Icons.people_outline,
              title: 'No tenants yet',
              detail: 'A tenant appears here once you put them on a lease. '
                  'Leases are not built yet.',
            ),
          ),
        ],
      ),
    );
  }
}
