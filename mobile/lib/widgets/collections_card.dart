import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// How rent is going this month, across everything a landlord owns.
///
/// Replaces a placeholder that read "Collections — Needs leases and billing"
/// from the first day the dashboard existed. Both now exist.
///
/// Figures only. The people behind them -- a payment to confirm, a tenant
/// behind -- are their own cards at the top of Today, because they are things
/// to do and these are things to know.
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
        // Said here, and only here. The two cards above that read the same
        // figures stay out of the way rather than repeat the failure three
        // times.
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

    // Nothing let at all. Said plainly rather than as zeroes, which read as a
    // broken screen rather than an empty portfolio.
    if (due == 0 && outstanding == 0) {
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
                value: LizmoMoney.peso(due),
                ink: LizmoColors.ink,
              ),
            ),
            Expanded(
              child: _Figure(
                label: 'Collected',
                value: LizmoMoney.peso(collected),
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
                value: LizmoMoney.peso(outstanding),
                ink: outstanding > 0 ? LizmoColors.ink : LizmoColors.teal900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Payments tenants say they have made, waiting on the landlord.
///
/// The one thing on Today about the landlord's own behaviour rather than
/// their tenants': somebody who said they paid three days ago and has heard
/// nothing is the failure the whole payments feature exists to avoid.
///
/// Nothing at all when nothing is waiting, or while the figures are loading
/// or failed -- [CollectionsCard] says that.
class ConfirmPaymentsCard extends ConsumerWidget {
  const ConfirmPaymentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rent = ref.watch(collectionsProvider).valueOrNull;
    final waiting = rent?.awaitingConfirmation ?? 0;
    if (rent == null || waiting == 0) return const SizedBox.shrink();

    return _TodoCard(
      key: const ValueKey('confirm-card'),
      title: 'Payments',
      count: waiting == 1
          ? '1 waiting for you to confirm'
          : '$waiting waiting for you to confirm',
      countInk: LizmoColors.amberText,
      rows: [for (final row in rent.awaiting) _WaitingRow(row: row)],
    );
  }
}

/// Tenants who are behind on rent, worst first.
class ArrearsCard extends ConsumerWidget {
  const ArrearsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rent = ref.watch(collectionsProvider).valueOrNull;
    final arrears = rent?.inArrears ?? const <ArrearsRow>[];
    if (arrears.isEmpty) return const SizedBox.shrink();

    return _TodoCard(
      key: const ValueKey('arrears-card'),
      title: 'Behind on rent',
      count: arrears.length == 1 ? 'One tenant' : '${arrears.length} tenants',
      countInk: LizmoColors.red,
      rows: [for (final row in arrears) _ArrearsRow(row: row)],
    );
  }
}

/// A card of things to do: a heading, how many, and a row for each.
///
/// Carries its own space below, so a card with nothing to say leaves no gap.
class _TodoCard extends StatelessWidget {
  const _TodoCard({
    super.key,
    required this.title,
    required this.count,
    required this.countInk,
    required this.rows,
  });

  final String title;
  final String count;
  final Color countInk;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
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
                  child: Text(title, style: LizmoType.sectionHeading),
                ),
                Text(
                  count,
                  style: LizmoType.rowSub.copyWith(
                    color: countInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...rows,
            ],
          ],
        ),
      ),
    );
  }
}

/// One payment a tenant says they have made, waiting on the landlord.
class _WaitingRow extends StatelessWidget {
  const _WaitingRow({required this.row});

  final AwaitingRow row;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final where = row.bedLabel == null
        ? 'Unit ${row.unitNumber}'
        : '${row.bedLabel}, ${row.unitNumber}';
    final paidOn = row.paidOn;
    final when = paidOn == null
        ? ''
        : ' · paid ${paidOn.day} ${_months[paidOn.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('awaiting-${row.paymentId}'),
        // To the tenant, where Confirm is. Opens inside Today, so Back comes
        // straight back here to the next one.
        onTap: () => context.openInTab(Detail.tenancy(row.leaseId!)),
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
                      row.tenantName ?? 'A tenant',
                      style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$where$when',
                      style: LizmoType.rowSub.copyWith(fontSize: 11),
                    ),
                    if (row.sentTo case final sentTo?) ...[
                      const SizedBox(height: 2),
                      // Which account to open before confirming.
                      Text(
                        'Sent to $sentTo',
                        style: LizmoType.rowSub.copyWith(
                            fontSize: 11, color: LizmoColors.amberText),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                LizmoMoney.peso((row.amount ?? 0)),
                style: LizmoType.dataMedium
                    .copyWith(color: LizmoColors.amberText),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: LizmoColors.slate),
            ],
          ),
        ),
      ),
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
        onTap: () => context.openInTab(Detail.tenancy(row.leaseId!)),
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
                LizmoMoney.peso((row.outstanding ?? 0)),
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
