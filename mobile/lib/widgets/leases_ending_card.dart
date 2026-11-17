import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../tenant/tenant_providers.dart';
import 'lease_term.dart';
import 'todo_card.dart';

/// How close to its end a lease has to be before Today mentions it.
const leaseEndingWithinDays = 30;

/// Tenancies ending within a month, or past their end with nothing done,
/// soonest first. Null while the tenants are not known yet.
final leasesEndingProvider = Provider.autoDispose<List<LeaseResponse>?>((ref) {
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
  const LeasesEndingCard({super.key, this.compact = false});

  /// Other kinds of to-do are on Today too.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ending = ref.watch(leasesEndingProvider) ?? const <LeaseResponse>[];
    if (ending.isEmpty) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);

    return TodoCard(
      key: const ValueKey('leases-ending-card'),
      icon: Icons.event_outlined,
      tone: TodoTone.ending,
      title: 'Leases ending',
      count: ending.length,
      compact: compact,
      rows: [
        for (final lease in ending) _EndingRow(lease: lease, today: today),
      ],
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

    return TodoRow(
      key: ValueKey('ending-${lease.id}'),
      leading: TodoAvatar(name: lease.tenantName, tone: TodoTone.ending),
      title: '${lease.tenantName ?? 'A tenant'} · $where',
      onTap: () => context.openInTab(Detail.tenancy(lease.id!)),
      sub: Text(
        '${left < 0 ? 'Past its end' : 'Ends ${inDays(left)}'} · ${termDate(ends)}',
        style: LizmoType.rowSub.copyWith(
          color: left < 0 ? LizmoColors.redText : LizmoColors.slateText,
        ),
      ),
    );
  }
}
