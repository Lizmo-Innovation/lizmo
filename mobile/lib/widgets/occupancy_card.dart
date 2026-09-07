import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// What is let, what is empty, and what the empty part is costing.
///
/// Replaces the second of the two placeholders this screen has carried since
/// it was written. It read "Needs leases", which stopped being true the day
/// leases were built.
///
/// Counted in lettable slots rather than units, because a boarding house does
/// not let units: a four-bed room with one tenant is one let and three empty.
class OccupancyCard extends ConsumerWidget {
  const OccupancyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupancy = ref.watch(occupancyProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: occupancy.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Occupancy', style: LizmoType.sectionHeading),
            const SizedBox(height: 6),
            Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
          ],
        ),
        data: (summary) => _Figures(summary: summary),
      ),
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures({required this.summary});

  final OccupancySummary summary;

  @override
  Widget build(BuildContext context) {
    final lettable = summary.lettable ?? 0;
    final occupied = summary.occupied ?? 0;
    final empty = summary.empty ?? 0;
    final outOfService = summary.outOfService ?? 0;
    final emptyRent = summary.emptyRent ?? 0;

    if (lettable == 0 && outOfService == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Occupancy', style: LizmoType.sectionHeading),
          const SizedBox(height: 6),
          Text(
            'Add a room or a unit and it will show up here as something to '
            'let.',
            style: LizmoType.rowSub,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Occupancy', style: LizmoType.sectionHeading),
            ),
            Text(
              // The headline, because it is the sentence a landlord would say
              // out loud. Slots, not units.
              '$occupied of $lettable let',
              style: LizmoType.rowSub.copyWith(
                color: empty == 0 ? LizmoColors.teal900 : LizmoColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _Bar(occupied: occupied, lettable: lettable),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _Figure(
                label: 'Empty',
                value: '$empty',
                ink: empty > 0 ? LizmoColors.ink : LizmoColors.teal900,
              ),
            ),
            Expanded(
              child: _Figure(
                // The figure that turns "three beds free" into a reason to do
                // something about it.
                label: 'Going begging',
                value: '₱${emptyRent.toStringAsFixed(0)}',
                ink: empty > 0 ? LizmoColors.ink : LizmoColors.teal900,
              ),
            ),
            if (outOfService > 0)
              Expanded(
                child: _Figure(
                  // Apart from the empties on purpose: a room taken off the
                  // market is not a vacancy anybody needs to fill.
                  label: 'Out of service',
                  value: '$outOfService',
                  ink: LizmoColors.slate,
                ),
              ),
          ],
        ),

        if (summary.vacancies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Where the space is',
              style: LizmoType.rowName.copyWith(color: LizmoColors.ink)),
          const SizedBox(height: 8),
          for (final row in summary.vacancies) _VacancyRow(row: row),
        ],
      ],
    );
  }
}

/// How full the portfolio is, at a glance.
///
/// A bar rather than a percentage: "68% occupied" is a number somebody has to
/// think about, and a mostly-full bar is one they do not.
class _Bar extends StatelessWidget {
  const _Bar({required this.occupied, required this.lettable});

  final int occupied;
  final int lettable;

  @override
  Widget build(BuildContext context) {
    final share = lettable == 0 ? 0.0 : occupied / lettable;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: share,
        minHeight: 8,
        backgroundColor: const Color(0xFFEFF2F1),
        valueColor: const AlwaysStoppedAnimation(LizmoColors.teal900),
      ),
    );
  }
}

class _VacancyRow extends StatelessWidget {
  const _VacancyRow({required this.row});

  final VacancyRow row;

  @override
  Widget build(BuildContext context) {
    final empty = row.empty ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('vacancy-${row.propertyId}'),
        // Straight to the property, because the next thing a landlord wants is
        // the room list they are about to advertise from.
        onTap: () => context.go(Routes.propertyDetail(row.propertyId!)),
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
                      row.propertyName ?? 'A property',
                      style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empty == 1 ? '1 free' : '$empty free',
                      style: LizmoType.rowSub.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${(row.emptyRent ?? 0).toStringAsFixed(0)}',
                style: LizmoType.dataMedium.copyWith(color: LizmoColors.slate),
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
