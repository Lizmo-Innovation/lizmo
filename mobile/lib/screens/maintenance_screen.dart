import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/role_switcher.dart';

/// Reporting something broken, and what happened to what you reported.
///
/// Empty, and says so. maintenance_requests exists in the schema with the
/// status flow already sketched — SUBMITTED, IN_PROGRESS, RESOLVED, CLOSED —
/// and no endpoint writes to it.
///
/// Worth building as a pair rather than alone: a request the landlord never
/// sees is a suggestion box, and a tenant only has to be ignored once to stop
/// using it.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lease = ref.watch(myLeasesProvider).valueOrNull?.firstOrNull;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          const LatticeHeader(
            eyebrow: 'Lizmo',
            title: 'Maintenance',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [RoleSwitcher(), SizedBox(width: 4), AccountButton()],
            ),
          ),
          Expanded(
            child: lease == null
                // A maintenance request belongs to a tenancy: the schema ties
                // one to a lease, and there is nothing to report about a room
                // you do not live in.
                ? const LizmoMessageState(
                    icon: Icons.build_outlined,
                    title: 'Nothing to report yet',
                    detail: 'Once you are renting through Lizmo, you can report '
                        'anything broken here and follow what happens to it.',
                  )
                : const LizmoMessageState(
                    icon: Icons.build_outlined,
                    title: 'Not built yet',
                    detail: 'Reporting a problem through Lizmo is coming. For '
                        'now, tell your landlord the way you normally would.',
                  ),
          ),
        ],
      ),
    );
  }
}
