import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../widgets/account_sheet.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';

/// The people renting from this landlord.
///
/// This screen used to say "Leases are not built yet", which stopped being
/// true some time ago and nobody moved the copy. Worse than out of date: a
/// landlord with three tenants was being told the feature housing them did not
/// exist.
///
/// One row per live tenancy, across every property. Tapping one opens the
/// person — which is the only route in the app to their emergency contact.
class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };
    final tenants = ref.watch(myTenantsProvider);

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'Tenants',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            stats: [
              LatticeHeaderStat(
                value: tenants.valueOrNull?.length.toString() ?? '—',
                label: 'Renting now',
              ),
            ],
          ),
          Expanded(
            child: tenants.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => LizmoMessageState(
                icon: Icons.error_outline,
                title: 'Could not load your tenants',
                detail: ApiFailure.from(error).message,
              ),
              data: (rows) => rows.isEmpty
                  ? const LizmoMessageState(
                      icon: Icons.people_outline,
                      title: 'No tenants yet',
                      detail: 'Somebody appears here once you accept their '
                          'request and their tenancy begins.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(myTenantsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _TenantRow(lease: rows[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantRow extends StatelessWidget {
  const _TenantRow({required this.lease});

  final LeaseResponse lease;

  @override
  Widget build(BuildContext context) {
    final where = lease.bedLabel == null
        ? 'Unit ${lease.unitNumber}'
        : '${lease.bedLabel}, ${lease.unitNumber}';

    return InkWell(
      key: ValueKey('tenant-${lease.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.openInTab(Detail.tenancy(lease.id!)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lease.tenantName ?? 'A tenant',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$where · ${lease.propertyName ?? 'a property'}',
                    style: LizmoType.rowSub,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: LizmoColors.slate),
          ],
        ),
      ),
    );
  }
}
