import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../property/property_providers.dart';
import '../router.dart';
import 'inquiries_screen.dart';
import '../widgets/account_sheet.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';

/// Which half of the Tenants tab is showing.
///
/// Held outside the screen so the Conversations card on Today can open the
/// Asking half directly, rather than landing somebody on Renting and leaving
/// them to find the control.
final tenantsTabProvider =
    StateProvider<bool>((ref) => false); // true = Asking

/// The people renting from this landlord, and the people asking to.
///
/// Both halves are the same question — who are my tenants, now and possibly —
/// which is why they share a tab rather than taking two. Asking first when
/// somebody is waiting on an answer: a conversation is perishable in a way a
/// running tenancy is not.
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
    final threads = ref.watch(myInquiriesProvider).valueOrNull;
    final asking = threads
        ?.where((thread) => thread.status == InquirySummaryStatusEnum.OPEN)
        .length;
    final showAsking = ref.watch(tenantsTabProvider);

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
              LatticeHeaderStat(
                value: asking?.toString() ?? '—',
                label: 'Asking',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: SegmentedButton<bool>(
              key: const ValueKey('tenants-segment'),
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(asking == null ? 'Asking' : 'Asking ($asking)'),
                ),
                const ButtonSegment(value: false, label: Text('Renting')),
              ],
              selected: {showAsking},
              showSelectedIcon: false,
              onSelectionChanged: (choice) =>
                  ref.read(tenantsTabProvider.notifier).state = choice.first,
            ),
          ),
          if (showAsking)
            const Expanded(
              child: InquiriesList(
                emptyDetail: 'Somebody who scans your code and asks about the '
                    'place appears here.',
              ),
            )
          else
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
