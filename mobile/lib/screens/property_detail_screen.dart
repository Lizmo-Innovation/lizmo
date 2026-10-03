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
class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  /// The floor being shown, or null for all of them.
  ///
  /// [_noFloor] stands for the units that have no floor recorded — they need a
  /// bucket of their own, or filtering would quietly hide them.
  String? _floor;

  static const _noFloor = '\u0000none';

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.propertyId;
    final units = ref.watch(unitsProvider(propertyId));

    final all = units.valueOrNull;
    final floors = _floorsIn(all);

    // A filter over one floor is furniture, not a control.
    final showFilter = floors.length > 1;
    final selected = showFilter && floors.contains(_floor) ? _floor : null;

    final shown = selected == null
        ? all
        : all?.where((u) => _floorKey(u) == selected).toList();

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
            // Naming the floor in the title is what makes the figures below it
            // unambiguous: they describe the filtered set, not the property.
            title: selected == null
                ? 'Units'
                : (selected == _noFloor ? 'No floor set' : 'Floor $selected'),
            leading: const _BackButton(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShareButton(propertyId: propertyId),
                const SizedBox(width: 4),
                _EditButton(propertyId: propertyId),
              ],
            ),
            stats: [
              LatticeHeaderStat(
                value: shown?.length.toString() ?? '—',
                label: 'Units',
              ),
              LatticeHeaderStat(
                // The one figure a landlord opens this screen to see: what the
                // property brings in with everything let. Summed here rather
                // than fetched — every unit on this screen already carries its
                // own total.
                value: _portfolioRent(shown),
                label: 'Per month',
              ),
              if (!isCommercial)
                LatticeHeaderStat(
                  // Rentable beds, not every bed: one out of service is still
                  // there but cannot be let, and counting it here would tell
                  // the landlord they have more to fill than they do. This is
                  // also the figure the platform bill is ultimately drawn from.
                  value: shown
                          ?.fold<int>(0, (sum, u) {
                            // A unit out of service takes its beds with it:
                            // the room is shut, so none of them can be let.
                            if (u.status == UnitResponseStatusEnum.MAINTENANCE) {
                              return sum;
                            }
                            return sum +
                                (u.bedCount ?? 0) -
                                (u.bedsUnderMaintenance ?? 0);
                          })
                          .toString() ??
                      '—',
                  label: 'Rentable',
                ),
            ],
          ),
          _WaitingRequests(propertyId: propertyId),
          if ((property?.description ?? '').isNotEmpty)
            _Description(text: property!.description!),
          if (showFilter)
            _FloorFilter(
              floors: floors,
              selected: selected,
              noFloor: _noFloor,
              onChanged: (next) => setState(() => _floor = next),
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
                AsyncData() => _UnitList(
                    units: shown ?? const [],
                    propertyId: propertyId,
                  ),
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

  /// The floor a unit belongs to for filtering, with a bucket for none.
  static String _floorKey(UnitResponse unit) {
    final floor = (unit.floor ?? '').trim();
    return floor.isEmpty ? _noFloor : floor;
  }

  /// Distinct floors present, numerically where they look like numbers.
  ///
  /// "10" after "9" rather than before it, which is what plain string sorting
  /// would do — and a boarding house numbers its floors.
  static List<String> _floorsIn(List<UnitResponse>? units) {
    if (units == null) return const [];

    final keys = units.map(_floorKey).toSet().toList();
    keys.sort((a, b) {
      // Unfloored units last: they are the leftovers, not floor zero.
      if (a == _noFloor) return 1;
      if (b == _noFloor) return -1;
      final na = int.tryParse(a);
      final nb = int.tryParse(b);
      if (na != null && nb != null) return na.compareTo(nb);
      if (na != null) return -1;
      if (nb != null) return 1;
      return a.compareTo(b);
    });
    return keys;
  }

  /// What the whole property brings in per month with everything let.
  ///
  /// Units with no rent set contribute nothing rather than zero — the same
  /// distinction the unit cards make. If none of them has a rent, the total is
  /// unknown rather than free, and reads as a dash.
  static String _portfolioRent(List<UnitResponse>? units) {
    if (units == null) return '—';

    num? total;
    for (final unit in units) {
      final rent = unit.potentialMonthlyRent;
      if (rent == null) continue;
      total = (total ?? 0) + rent;
    }

    if (total == null) return '—';
    return LizmoMoney.peso(total);
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

/// People waiting for an answer about this property.
///
/// Only when somebody is. A row that permanently reads "0 requests" is one a
/// landlord learns to stop seeing, and the whole point of this strip is that it
/// is unusual enough to notice.
class _WaitingRequests extends ConsumerWidget {
  const _WaitingRequests({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(pendingRequestsProvider(propertyId)).valueOrNull;
    if (waiting == null || waiting.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = waiting.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.openInTab(Detail.requests(propertyId)),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    size: 20, color: LizmoColors.amberText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count == 1
                        ? 'Somebody is asking about a room'
                        : '$count people are asking about rooms',
                    style: LizmoType.rowName
                        .copyWith(color: LizmoColors.amberText),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: LizmoColors.amberText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the code and QR a landlord puts on the gate.
///
/// In the header rather than down with the units: it is about the property as a
/// whole, and a landlord showing it to somebody wants it in one tap rather than
/// after a scroll.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.openInTab(Detail.share(propertyId)),
      icon: const Icon(Icons.qr_code_2_outlined),
      color: LizmoColors.white,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Share this place',
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

  bool get _isClosed => unit.status == UnitResponseStatusEnum.MAINTENANCE;

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
              : () => context.openInTab(Detail.unit(propertyId, unit.id!)),
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
                    // Both figures are monthly. A bedspace used to show its
                    // per-bed rate, which was not comparable with the whole
                    // unit beside it — one was a room's income, the other a
                    // single bed's.
                    _isBedspace ? 'per month, all beds' : 'per month',
                    style: LizmoType.rowSub,
                  ),
                ],
              ),
            ],
          ),
          // Whole units reach this too: one out of service needs saying, or its
          // dash reads as a rent nobody set rather than a room that is shut.
          if (_isBedspace || _isClosed) ...[
            const SizedBox(height: 12),
            // Not its own tap target any more. The card opens the unit, and the
            // beds are already on the screen it opens — nesting a second target
            // inside a card only makes both harder to hit.
            Row(
              children: [
                if (_isBedspace)
                  StatusChip(
                    // Grey: how many beds a room has is neither good news nor
                    // bad, it is just the shape of the room.
                    status: LizmoStatus.vacant,
                    label: (unit.bedCount ?? 0) == 1
                        ? '1 bed'
                        : '${unit.bedCount ?? 0} beds',
                  ),
                if (_isClosed) ...[
                  if (_isBedspace) const SizedBox(width: 6),
                  const StatusChip(
                    status: LizmoStatus.pending,
                    label: 'Out of service',
                  ),
                ] else if ((unit.bedsUnderMaintenance ?? 0) > 0) ...[
                  const SizedBox(width: 6),
                  StatusChip(
                    status: LizmoStatus.pending,
                    label: '${unit.bedsUnderMaintenance} out of service',
                  ),
                ],
              ],
            ),
          ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What the unit brings in per month with everything let: its own rent for a
  /// whole unit, the sum of its beds for a bedspace.
  ///
  /// "Not set" rather than ₱0, which would claim the unit is free.
  String _rentLabel() {
    final rent = unit.potentialMonthlyRent;
    if (rent == null) return '—';
    return LizmoMoney.peso(rent);
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

/// Floors as chips, so a landlord can look at one at a time.
///
/// Only rendered when there is more than one: a single chip reading "All"
/// beside one floor is a control that cannot do anything.
class _FloorFilter extends StatelessWidget {
  const _FloorFilter({
    required this.floors,
    required this.selected,
    required this.noFloor,
    required this.onChanged,
  });

  final List<String> floors;
  final String? selected;
  final String noFloor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final floor in floors) ...[
            const SizedBox(width: 8),
            _Chip(
              label: floor == noFloor ? 'No floor' : 'Floor $floor',
              selected: selected == floor,
              onTap: () => onChanged(floor),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LizmoColors.tealBg : LizmoColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
            ),
          ),
          child: Text(
            label,
            style: LizmoType.chipLabel.copyWith(
              fontSize: 13,
              color: selected ? LizmoColors.teal900 : LizmoColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}

/// What the landlord wrote about the property.
///
/// Clamped to three lines with a tap to expand. A landlord may write three
/// hundred words, and this screen exists to show the units — letting the
/// description grow unbounded would push them off the phone.
class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Only offer "more" when there is more: the control is noise on a
    // one-line description.
    final overflows = _overflows(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bounded even when expanded, and scrollable within that bound.
          // Left unbounded, a three-hundred-word description grew this card
          // past the height of the screen and overflowed the column it sits
          // in — the units below it had nowhere left to go.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _expanded ? MediaQuery.sizeOf(context).height * 0.3 : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: _expanded
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: LizmoType.rowSub,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ),
          if (overflows) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Less' : 'More',
                style: LizmoType.rowName.copyWith(
                  fontSize: 13,
                  color: LizmoColors.teal900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Whether the text needs more than three lines at this width.
  bool _overflows(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32 - 28;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: LizmoType.rowSub),
      maxLines: 3,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }
}
