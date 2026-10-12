import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../tenant/tenant_providers.dart';
import 'lease_term.dart';

/// How close to its end a lease has to be before Today mentions it.
const leaseEndingWithinDays = 30;

/// Tenancies ending within a month, or past their end with nothing done,
/// soonest first. Null while the tenants are not known yet.
final leasesEndingProvider =
    Provider.autoDispose<List<LeaseResponse>?>((ref) {
  final tenants = ref.watch(myTenantsProvider).valueOrNull;
  if (tenants == null) return null;
  final today = ref.watch(todayProvider);

  final ending = [
    for (final lease in tenants)
      if (lease.termEndsOn case final ends?
          when daysUntil(ends, today) <= leaseEndingWithinDays)
        lease,
  ]..sort((a, b) => a.termEndsOn!.compareTo(b.termEndsOn!));
  return ending;
});

/// Leases coming to their end, on Today.
///
/// Under "Needs you" because each one is a question only the landlord can
/// answer -- are they staying? -- and the answer is a tap away: extend it, or
/// end the tenancy. Nothing here happens on its own.
class LeasesEndingCard extends ConsumerWidget {
  const LeasesEndingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ending = ref.watch(leasesEndingProvider) ?? const <LeaseResponse>[];
    if (ending.isEmpty) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('leases-ending-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Leases ending', style: LizmoType.sectionHeading),
                ),
                Text(
                  ending.length == 1 ? 'One tenant' : '${ending.length} tenants',
                  style: LizmoType.rowSub.copyWith(
                    color: LizmoColors.amberText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final lease in ending) _EndingRow(lease: lease, today: today),
          ],
        ),
      ),
    );
  }
}

class _EndingRow extends StatelessWidget {
  const _EndingRow({required this.lease, required this.today});

  final LeaseResponse lease;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ends = lease.termEndsOn!;
    final left = daysUntil(ends, today);
    final where = lease.bedLabel == null
        ? 'Unit ${lease.unitNumber}'
        : '${lease.bedLabel}, ${lease.unitNumber}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('ending-${lease.id}'),
        // To the tenancy, where Extend and End are.
        onTap: () => context.openInTab(Detail.tenancy(lease.id!)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LizmoColors.canvas,
            borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 2),
                    Text(
                      '$where · ${termDate(ends)}',
                      style: LizmoType.rowSub.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                left < 0 ? 'Past its end' : 'Ends ${inDays(left)}',
                style: LizmoType.rowSub.copyWith(
                  color: left < 0 ? LizmoColors.red : LizmoColors.amberText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: LizmoColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}
