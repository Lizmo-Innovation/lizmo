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

    // Taken from the list rather than fetched by id: this screen is reached
    // from the list, so it is normally loaded. On a deep link it may not be,
    // which is why the name falls back below.
    final matches = ref.watch(propertiesProvider).valueOrNull?.where(
              (p) => p.id == propertyId,
            ) ??
        const <PropertyResponse>[];
    final property = matches.isEmpty ? null : matches.first;
    final name = property?.name;

    // Commercial properties hold no bedspaces, so a bed count there is always
    // zero and reads as something the landlord has forgotten to set up.
    final isCommercial =
        property?.usage == PropertyResponseUsageEnum.COMMERCIAL;

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
              if (!isCommercial)
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
                AsyncData(:final value) =>
                  _UnitList(units: value, propertyId: propertyId),
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
  const _UnitList({required this.units, required this.propertyId});

  final List<UnitResponse> units;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      itemCount: units.length,
      itemBuilder: (context, index) =>
          _UnitCard(unit: units[index], propertyId: propertyId),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit, required this.propertyId});

  final UnitResponse unit;
  final String propertyId;

  bool get _isBedspace =>
      unit.rentalMode == UnitResponseRentalModeEnum.BEDSPACE;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: unit.id == null
              ? null
              : () => context.push(Routes.unitEdit(propertyId, unit.id!)),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
            // Its own tap target inside the card: the card opens the unit's
            // settings, this opens its beds. Nested rather than a second card,
            // because the bed count is what a landlord looks at to decide
            // whether the beds need attention at all.
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: unit.id == null
                    ? null
                    : () => context.push(Routes.unitBeds(propertyId, unit.id!)),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      StatusChip(
                        // Grey: how many beds a room has is neither good news
                        // nor bad, it is just the shape of the room.
                        status: LizmoStatus.vacant,
                        // No "3 of 4": beds are created to match the bed count,
                        // so the two halves would always be the same number.
                        label: (unit.bedCount ?? 0) == 1
                            ? '1 bed'
                            : '${unit.bedCount ?? 0} beds',
                      ),
                      const Spacer(),
                      Text(
                        'View beds',
                        style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: LizmoColors.teal900),
                    ],
                  ),
                ),
              ),
            ),
          ],
              ],
            ),
          ),
        ),
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
