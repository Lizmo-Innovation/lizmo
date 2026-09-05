import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';
import '../router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/console_table.dart';

/// Who Lizmo's landlords are, and which of them needs chasing.
///
/// The console's home, rather than the payment queue: payments are a task you
/// sit down to do, landlords are the thing the business is made of. Somebody
/// opening the console is usually asking "how is this landlord doing" or "who
/// has not paid", and both start here.
///
/// A table rather than a list of cards, because this is a desktop tool and the
/// question is comparative — scanning twenty landlords for the one in trouble
/// means columns you can read down.
class LandlordsScreen extends ConsumerWidget {
  const LandlordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landlords = ref.watch(landlordsProvider);

    return AdminShell(
      title: 'Landlords',
      actions: [
        TextButton.icon(
          onPressed: () => context.go(Routes.invitations),
          icon: const Icon(Icons.add, size: 18),
          label: Text('Invite', style: LizmoType.rowName.copyWith(
            fontSize: 13, color: LizmoColors.teal900)),
          style: TextButton.styleFrom(foregroundColor: LizmoColors.teal900),
        ),
      ],
      child: landlords.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => _Failed(failure: ApiFailure.from(error), ref: ref),
        data: (rows) => rows.isEmpty
            ? const LizmoMessageState(
                icon: Icons.apartment_outlined,
                title: 'No landlords yet',
                detail: 'Landlords appear here once they accept an invitation.',
              )
            : _LandlordTable(rows: rows),
      ),
    );
  }
}

class _LandlordTable extends StatelessWidget {
  const _LandlordTable({required this.rows});

  final List<LandlordSummary> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        _Totals(rows: rows),
        const SizedBox(height: 18),
        ConsoleTable(
          columns: const [
            ConsoleColumn('Landlord'),
            ConsoleColumn('Properties', width: 96),
            ConsoleColumn('Let units', width: 88),
            ConsoleColumn('Let beds', width: 88),
            ConsoleColumn('Standing', width: 128),
          ],
          rows: [
            for (final landlord in rows)
              ConsoleRow(
                onTap: () => context.go('${Routes.landlords}/${landlord.userId}'),
                cells: [
                  _Person(landlord: landlord),
                  Text('${landlord.properties ?? 0}', style: LizmoType.rowName),
                  Text('${landlord.occupiedUnits ?? 0}', style: LizmoType.rowName),
                  Text('${landlord.occupiedBeds ?? 0}', style: LizmoType.rowName),
                  _Standing(landlord: landlord),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.landlord});

  final LandlordSummary landlord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(landlord.name ?? '', style: LizmoType.rowName),
        const SizedBox(height: 2),
        Text(
          landlord.email ?? landlord.phone ?? '',
          style: LizmoType.rowSub,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// How this landlord stands with Lizmo.
///
/// "1 of 3 locked" rather than "Locked", because the lock is per property: a
/// landlord with three buildings and one unpaid invoice is not simply locked,
/// and telling an admin otherwise would have them chasing the wrong thing.
class _Standing extends StatelessWidget {
  const _Standing({required this.landlord});

  final LandlordSummary landlord;

  @override
  Widget build(BuildContext context) {
    final locked = landlord.lockedProperties ?? 0;
    if (locked == 0) {
      return const StatusChip(status: LizmoStatus.paid, label: 'Active');
    }
    return StatusChip(
      status: LizmoStatus.overdue,
      label: locked == (landlord.properties ?? 0)
          ? 'All locked'
          : '$locked of ${landlord.properties ?? 0} locked',
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.rows});

  final List<LandlordSummary> rows;

  @override
  Widget build(BuildContext context) {
    final beds = rows.fold<int>(0, (sum, row) => sum + (row.occupiedBeds ?? 0));
    final units = rows.fold<int>(0, (sum, row) => sum + (row.occupiedUnits ?? 0));
    final locked = rows.fold<int>(0, (sum, row) => sum + (row.lockedProperties ?? 0));

    // Slots rather than money: nothing raises an invoice yet, and a total of
    // zero pesos would read as "everybody has paid" rather than "no invoice
    // has ever been raised".
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Metric(value: '${rows.length}', label: 'Landlords'),
        _Metric(value: '${units + beds}', label: 'Billable slots'),
        _Metric(value: '$locked', label: 'Locked properties'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LizmoType.rowSub),
          const SizedBox(height: 4),
          Text(
            value,
            style: LizmoType.screenTitle.copyWith(
              fontSize: 24,
              color: LizmoColors.teal900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.ref});

  final ApiFailure failure;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return LizmoMessageState(
      icon: Icons.cloud_off_outlined,
      tone: LizmoMessageTone.problem,
      title: failure.isNetwork ? 'Cannot reach Lizmo' : 'Could not load landlords',
      detail: failure.message,
      actionLabel: 'Try again',
      onAction: () => ref.invalidate(landlordsProvider),
    );
  }
}
