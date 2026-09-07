import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// How rent is going, across everything a landlord owns.
///
/// Replaces a placeholder that read "Collections — Needs leases and billing"
/// from the first day the dashboard existed. Both now exist.
///
/// Three figures and a list, in the order the questions get asked: what fell
/// due this month, what has come in, and who is behind. Anything waiting on
/// the landlord themselves goes first — it is the only line here about their
/// own behaviour rather than their tenants'.
class CollectionsCard extends ConsumerWidget {
  const CollectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(collectionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: summary.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collections', style: LizmoType.sectionHeading),
            const SizedBox(height: 6),
            Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
          ],
        ),
        data: (rent) => _Figures(rent: rent),
      ),
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures({required this.rent});

  final CollectionsSummary rent;

  @override
  Widget build(BuildContext context) {
    final due = rent.dueThisMonth ?? 0;
    final collected = rent.collectedThisMonth ?? 0;
    final outstanding = rent.outstandingAllTime ?? 0;
    final waiting = rent.awaitingConfirmation ?? 0;
    final arrears = rent.inArrears;

    // Nothing let at all. Said plainly rather than as four zeroes, which read
    // as a broken screen rather than an empty portfolio.
    if (due == 0 && outstanding == 0 && arrears.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collections', style: LizmoType.sectionHeading),
          const SizedBox(height: 6),
          Text(
            'Nothing is due yet. Rent appears here once somebody is renting '
            'from you.',
            style: LizmoType.rowSub,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Collections', style: LizmoType.sectionHeading),
        const SizedBox(height: 4),
        Text('This month', style: LizmoType.rowSub),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _Figure(
                label: 'Due',
                value: '₱${due.toStringAsFixed(0)}',
                ink: LizmoColors.ink,
              ),
            ),
            Expanded(
              child: _Figure(
                label: 'Collected',
                value: '₱${collected.toStringAsFixed(0)}',
                ink: collected >= due && due > 0
                    ? LizmoColors.teal900
                    : LizmoColors.ink,
              ),
            ),
            Expanded(
              child: _Figure(
                // Kept apart from the monthly figures: a landlord owed for
                // three past months and paid up for this one is not doing
                // well, and one number cannot say both.
                label: 'Owed in all',
                value: '₱${outstanding.toStringAsFixed(0)}',
                ink: outstanding > 0 ? LizmoColors.ink : LizmoColors.teal900,
              ),
            ),
          ],
        ),

        if (waiting > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LizmoColors.amberBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty,
                    size: 18, color: LizmoColors.amberText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    waiting == 1
                        ? 'One payment is waiting for you to confirm it'
                        : '$waiting payments are waiting for you to confirm them',
                    style: LizmoType.rowSub
                        .copyWith(color: LizmoColors.amberText),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (arrears.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            arrears.length == 1 ? 'One tenant is behind' : 'Behind on rent',
            style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
          ),
          const SizedBox(height: 8),
          for (final row in arrears) _ArrearsRow(row: row),
        ],
      ],
    );
  }
}

class _ArrearsRow extends StatelessWidget {
  const _ArrearsRow({required this.row});

  final ArrearsRow row;

  @override
  Widget build(BuildContext context) {
    final months = row.monthsLate ?? 0;
    final where = row.bedLabel == null
        ? 'Unit ${row.unitNumber}'
        : '${row.bedLabel}, ${row.unitNumber}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('arrears-${row.leaseId}'),
        // Straight to the tenant, because seeing who is behind and then having
        // to go and find them is the half of this that wastes the time.
        onTap: () => context.go(Routes.tenantDetailFor(row.leaseId!)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LizmoColors.redBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.tenantName ?? 'A tenant',
                      style: LizmoType.rowName.copyWith(color: LizmoColors.red),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$where · ${months == 1 ? '1 month' : '$months months'} late',
                      style: LizmoType.rowSub
                          .copyWith(fontSize: 11, color: LizmoColors.red),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${(row.outstanding ?? 0).toStringAsFixed(0)}',
                style: LizmoType.dataMedium.copyWith(color: LizmoColors.red),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: LizmoColors.red),
            ],
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.ink});

  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LizmoType.rowSub.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: LizmoType.dataMedium.copyWith(color: ink)),
      ],
    );
  }
}
