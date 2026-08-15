import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// One property and the units inside it.
///
/// This is where the bedspace/whole-unit distinction becomes visible: a
/// bedspace shows how many of its beds exist and what each is worth, a whole
/// unit shows one rent and nothing else.
class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitsProvider(propertyId));
    final property = ref.watch(propertiesProvider).valueOrNull?.where(
          (p) => p.id == propertyId,
        );
    final name = property?.isNotEmpty == true ? property!.first.name : null;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: name ?? 'Property',
            title: 'Units',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BackButton(),
                _EditButton(propertyId: propertyId),
              ],
            ),
            stats: [
              LatticeHeaderStat(
                value: units.valueOrNull?.length.toString() ?? '—',
                label: 'Units',
              ),
              LatticeHeaderStat(
                // Beds across the property, which is what the platform bill is
                // ultimately counted from.
                value: units.valueOrNull
                        ?.fold<int>(0, (sum, u) => sum + (u.bedCount ?? 0))
                        .toString() ??
                    '—',
                label: 'Beds',
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: LizmoColors.teal900,
              onRefresh: () => ref.refresh(unitsProvider(propertyId).future),
              child: switch (units) {
                AsyncError(:final error) => _Failed(
                    failure: ApiFailure.from(error),
                    onRetry: () => ref.invalidate(unitsProvider(propertyId)),
                  ),
                AsyncData(:final value) when value.isEmpty => const _Empty(),
                AsyncData(:final value) => _UnitList(units: value),
                _ => const _Loading(),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryActionButton(
                label: '+ Add a unit',
                onPressed: () => context.push(Routes.unitNew(propertyId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back),
      color: LizmoColors.white,
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Back',
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(Routes.propertyEdit(propertyId)),
      icon: const Icon(Icons.edit_outlined),
      color: LizmoColors.white,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Edit property',
    );
  }
}

class _UnitList extends StatelessWidget {
  const _UnitList({required this.units});

  final List<UnitResponse> units;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      itemCount: units.length,
      itemBuilder: (context, index) => _UnitCard(unit: units[index]),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit});

  final UnitResponse unit;

  bool get _isBedspace =>
      unit.rentalMode == UnitResponseRentalModeEnum.BEDSPACE;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unit ${unit.unitNumber ?? ''}', style: LizmoType.rowName),
                    const SizedBox(height: 2),
                    Text(
                      [
                        _isBedspace ? 'Bedspace' : 'Whole unit',
                        if ((unit.floor ?? '').isNotEmpty) 'Floor ${unit.floor}',
                      ].join(' · '),
                      style: LizmoType.rowSub,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_rentLabel(), style: LizmoType.dataMedium),
                  const SizedBox(height: 2),
                  Text(
                    _isBedspace ? 'per bed' : 'per month',
                    style: LizmoType.rowSub,
                  ),
                ],
              ),
            ],
          ),
          if (_isBedspace) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                StatusChip(
                  // Grey, not teal: beds existing is neither good nor bad news,
                  // it is just how far setup has got.
                  status: (unit.bedCount ?? 0) >= (unit.capacity ?? 0)
                      ? LizmoStatus.paid
                      : LizmoStatus.vacant,
                  label: '${unit.bedCount ?? 0} of ${unit.capacity ?? 0} beds',
                ),
                const Spacer(),
                if ((unit.bedCount ?? 0) < (unit.capacity ?? 0))
                  Text('Add beds to fill it', style: LizmoType.rowSub),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "Not set" rather than ₱0, which would claim the unit is free.
  String _rentLabel() {
    final rent = unit.rent;
    if (rent == null) return '—';
    final asDouble = rent.toDouble();
    final whole = asDouble == asDouble.roundToDouble();
    return '₱${whole ? asDouble.toStringAsFixed(0) : asDouble.toStringAsFixed(2)}';
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 60),
        LizmoMessageState(
          icon: Icons.meeting_room_outlined,
          title: 'No units yet',
          detail: 'Add a unit for each space you rent out — a room, a bedspace, '
              'or the whole place.',
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 60),
        LizmoMessageState(
          tone: LizmoMessageTone.problem,
          icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
          title: failure.isNetwork ? "Can't reach Lizmo" : 'Something went wrong',
          detail: failure.message,
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ],
    );
  }
}
