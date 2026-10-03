import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// One unit and what is inside it.
///
/// Stands to a unit as the property screen stands to a property, and for the
/// same reason: tapping a thing should show it, not open a form over it. Before
/// this screen existed, tapping a unit went straight to its editable fields —
/// past a live delete button — and a whole unit had nowhere to be looked at
/// at all.
///
/// For a bedspace that means its beds. For a whole unit there is nothing inside
/// yet; the tenancy will land here once leases exist.
class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
  });

  final String propertyId;
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitProvider(unitId)).valueOrNull;
    final beds = ref.watch(bedsProvider(unitId));

    // Taken from the list rather than fetched: this screen is reached from the
    // property screen, which has it loaded.
    final matches = ref.watch(propertiesProvider).valueOrNull?.where(
              (p) => p.id == propertyId,
            ) ??
        const <PropertyResponse>[];
    final propertyName = matches.isEmpty ? null : matches.first.name;

    final isBedspace = unit?.rentalMode == UnitResponseRentalModeEnum.BEDSPACE;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: propertyName ?? 'Property',
            title: unit == null ? 'Unit' : 'Unit ${unit.unitNumber ?? ''}',
            leading: const _BackButton(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EditButton(propertyId: propertyId, unitId: unitId),
                _MoreButton(unit: unit, propertyId: propertyId, unitId: unitId),
              ],
            ),
            stats: [
              if (isBedspace)
                LatticeHeaderStat(
                  // Rentable, not total: a bed out of service is still here,
                  // but it is not one the landlord can let to anyone.
                  value: beds.valueOrNull
                          ?.where((b) => b.status != BedResponseStatusEnum.MAINTENANCE)
                          .length
                          .toString() ??
                      '—',
                  label: 'Rentable',
                )
              else
                LatticeHeaderStat(
                  value: (unit?.floor ?? '').isEmpty ? '—' : unit!.floor!,
                  label: 'Floor',
                ),
              LatticeHeaderStat(
                // What the unit brings in, not what one bed costs. "Default"
                // meant nothing out of context, and the figure a landlord
                // actually wants is the one its parent screen already shows.
                value: _rentLabel(unit?.potentialMonthlyRent),
                label: 'Per month',
              ),
            ],
          ),
          if (unit?.status == UnitResponseStatusEnum.MAINTENANCE)
            const _ClosedBanner(),
          _UtilitiesRow(
            monthly: unit?.monthlyUtilities,
            propertyId: propertyId,
            unitId: unitId,
          ),
          Expanded(
            child: isBedspace
                ? RefreshIndicator(
                    color: LizmoColors.teal900,
                    onRefresh: () => ref.refresh(bedsProvider(unitId).future),
                    child: switch (beds) {
                      AsyncError(:final error) => _Failed(
                          failure: ApiFailure.from(error),
                          onRetry: () => ref.invalidate(bedsProvider(unitId)),
                        ),
                      AsyncData(:final value) when value.isEmpty => const _Empty(),
                      AsyncData(:final value) =>
                        _BedList(
                        beds: value,
                        propertyId: propertyId,
                        unitId: unitId,
                        unitRent: unit?.rent),
                      _ => const _Loading(),
                    },
                  )
                : _WholeUnit(unit: unit),
          ),
        ],
      ),
    );
  }

  /// "Not set" rather than ₱0, which would claim the unit is free.
  static String _rentLabel(num? rent) {
    if (rent == null) return '—';
    return LizmoMoney.peso(rent);
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

/// Editing lives behind a control of its own, as it does on the property
/// screen. Tapping the unit itself no longer opens its fields.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.propertyId, required this.unitId});

  final String propertyId;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(Routes.unitEdit(propertyId, unitId)),
      icon: const Icon(Icons.edit_outlined),
      color: LizmoColors.white,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Edit unit',
    );
  }
}

/// A whole unit holds no beds, so there is nothing to list until it holds a
/// tenancy. Said plainly rather than shown as an empty list, which would read
/// as beds that failed to load.
/// A whole unit has nothing inside it to list, so it shows itself.
///
/// It used to apologise for being empty. These are the unit's own facts, which
/// were otherwise only visible by opening the edit form — and this is the
/// surface a tenancy will sit on once leases exist.
class _WholeUnit extends StatelessWidget {
  const _WholeUnit({required this.unit});

  final UnitResponse? unit;

  @override
  Widget build(BuildContext context) {
    final size = unit?.sizeSqm;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: LizmoColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [LizmoColors.cardShadow],
          ),
          child: Column(
            children: [
              _Fact(label: 'Rented as', value: 'One whole unit, one tenant'),
              if ((unit?.floor ?? '').isNotEmpty)
                _Fact(label: 'Floor', value: unit!.floor!),
              if (size != null) _Fact(label: 'Size', value: '$size sqm'),
              _Fact(
                label: 'Status',
                value: unit?.status == UnitResponseStatusEnum.MAINTENANCE
                    ? 'Out of service'
                    : 'Vacant',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One label-and-value line inside a facts card.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: LizmoType.rowSub)),
          Expanded(child: Text(value, style: LizmoType.rowName)),
        ],
      ),
    );
  }
}

class _BedList extends StatelessWidget {
  const _BedList({
    required this.beds,
    required this.propertyId,
    required this.unitId,
    required this.unitRent,
  });

  final List<BedResponse> beds;
  final String propertyId;
  final String unitId;

  /// What the unit asks, which a bed without its own rent is let at.
  final num? unitRent;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      itemCount: beds.length,
      itemBuilder: (context, index) =>
          _BedRow(
        bed: beds[index],
        propertyId: propertyId,
        unitId: unitId,
        unitRent: unitRent,
      ),
    );
  }
}

/// One bed, its name and its occupancy.
///
/// Tapping renames it. There is no remove control: beds are removed by lowering
/// the unit's bed count, which is also the only thing that can add them.
class _BedRow extends ConsumerWidget {
  const _BedRow({
    required this.bed,
    required this.propertyId,
    required this.unitId,
    required this.unitRent,
  });

  final BedResponse bed;
  final num? unitRent;

  /// Needed to refresh the property screen's rentable count.
  final String propertyId;
  final String unitId;

  bool get _isOccupied => bed.status == BedResponseStatusEnum.OCCUPIED;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onTap: bed.id == null ? null : () => _openActions(context, ref),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bed.bedLabel ?? '', style: LizmoType.rowName),
                      // Only when there is something to say. A bed on the unit
                      // rate repeated the header's own figure on every row,
                      // spending a line to report that nothing is unusual.
                      if (_priceLabel() != null) ...[
                        const SizedBox(height: 2),
                        Text(_priceLabel()!, style: LizmoType.rowSub),
                      ],
                    ],
                  ),
                ),
                StatusChip(status: _status(), label: _statusLabel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Offers what can be done to this bed.
  ///
  /// A sheet rather than a straight-to-rename tap: there are two actions now,
  /// and guessing which one a tap meant would make the more destructive of
  /// them the accident.
  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    final underMaintenance = bed.status == BedResponseStatusEnum.MAINTENANCE;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: LizmoColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(bed.bedLabel ?? '', style: LizmoType.rowName),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: LizmoColors.slate),
              title: Text('Rename bed', style: LizmoType.rowName),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _rename(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined, color: LizmoColors.slate),
              title: Text('Set price', style: LizmoType.rowName),
              subtitle: Text(
                bed.rent != null
                    ? 'Priced on its own.'
                    : 'Currently let at the unit rate.',
                style: LizmoType.rowSub,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _setPrice(context, ref);
              },
            ),
            if (_isOccupied)
              // The API refuses this while someone is in the bed, and the
              // reason is worth stating rather than leaving a dead row.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  'Occupied beds cannot be taken out of service. End the lease '
                  'first.',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                ),
              )
            else
              ListTile(
                leading: Icon(
                  underMaintenance ? Icons.build_circle_outlined : Icons.build_outlined,
                  color: LizmoColors.slate,
                ),
                title: Text(
                  underMaintenance
                      ? 'Return to service'
                      : 'Take out of service',
                  style: LizmoType.rowName,
                ),
                subtitle: Text(
                  underMaintenance
                      ? 'Counts as rentable again.'
                      : 'Stops counting as rentable.',
                  style: LizmoType.rowSub,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _setMaintenance(context, ref, !underMaintenance);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Takes the bed out of service, or puts it back.
  Future<void> _setMaintenance(
      BuildContext context, WidgetRef ref, bool underMaintenance) async {
    try {
      await ref.read(unitsApiProvider).setBedMaintenance(
            bed.id!,
            MaintenanceRequest(underMaintenance: underMaintenance),
          );
      ref.invalidate(bedsProvider(unitId));
      // The rentable count on the property screen moves with it.
      ref.invalidate(unitsProvider(propertyId));
    } catch (error) {
      if (context.mounted) _report(context, ApiFailure.from(error).message);
    }
  }

  /// Sets what this bed asks, or clears it back to the unit's rate.
  Future<void> _setPrice(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_PriceResult>(
      context: context,
      builder: (_) => _BedPriceDialog(current: bed.rent, unitRent: unitRent),
    );

    if (result == null) return;

    try {
      await ref.read(unitsApiProvider).updateBed(
            bed.id!,
            // The label goes with it: a PUT carries the whole bed, so leaving
            // it out would blank the name.
            BedRequest(bedLabel: bed.bedLabel ?? '', rent: result.rent),
          );
      ref.invalidate(bedsProvider(unitId));
      ref.invalidate(unitsProvider(propertyId));
    } catch (error) {
      if (context.mounted) _report(context, ApiFailure.from(error).message);
    }
  }

  /// Renames the bed.
  ///
  /// Allowed while occupied: the name describes the bed, not the tenancy, and
  /// a landlord may well only realise which bunk is which once someone is in it.
  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      // The dialog owns its controller — disposing one here would throw once
      // the closing animation rebuilt the field.
      builder: (_) => _RenameBedDialog(current: bed.bedLabel ?? ''),
    );

    if (label == null || label == bed.bedLabel) return;

    try {
      await ref.read(unitsApiProvider).updateBed(
            bed.id!,
            // Rent travels with the label, or renaming a bed would quietly
            // return it to the unit's rate.
            BedRequest(bedLabel: label, rent: bed.rent),
          );
      ref.invalidate(bedsProvider(unitId));
    } catch (error) {
      if (context.mounted) _report(context, ApiFailure.from(error).message);
    }
  }

  void _report(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: LizmoColors.red,
        content: Text(message,
            style: LizmoType.rowSub.copyWith(color: LizmoColors.white)),
      ),
    );
  }

  /// The exceptions only: a bed priced on its own, or one with no price at all.
  ///
  /// A bed let at the unit's rate says nothing, because the unit's rate is in
  /// the header above it. Printing it on every row made the one line that
  /// carried information look exactly like the three that did not.
  String? _priceLabel() {
    if (bed.rent != null) return _money(bed.rent!);
    if (unitRent != null) return null;
    // Neither is set. "Not set" rather than ₱0, which would claim it is free.
    return 'No rent set';
  }

  static String _money(num amount) {
    return LizmoMoney.peso(amount);
  }

  LizmoStatus _status() => switch (bed.status) {
        BedResponseStatusEnum.OCCUPIED => LizmoStatus.paid,
        BedResponseStatusEnum.MAINTENANCE => LizmoStatus.pending,
        // Grey: an empty bed is neither good news nor bad.
        _ => LizmoStatus.vacant,
      };

  String _statusLabel() => switch (bed.status) {
        BedResponseStatusEnum.OCCUPIED => 'Occupied',
        // "Out of service", as the dashboard says it. It read "Maintenance",
        // which is also the name of the tab where tenants report things
        // broken -- two unrelated ideas sharing one word on one screen.
        BedResponseStatusEnum.MAINTENANCE => 'Out of service',
        _ => 'Vacant',
      };
}

/// Asks for a new bed name, returning it via [Navigator.pop].
class _RenameBedDialog extends StatefulWidget {
  const _RenameBedDialog({required this.current});

  final String current;

  @override
  State<_RenameBedDialog> createState() => _RenameBedDialogState();
}

class _RenameBedDialogState extends State<_RenameBedDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LizmoColors.white,
      title: Text('Rename bed', style: LizmoType.rowName.copyWith(fontSize: 16)),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Bed 1 upper bunk',
            hintStyle: LizmoType.rowSub,
            errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Give the bed a name'
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: LizmoType.rowName.copyWith(color: LizmoColors.slate)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text('Save',
              style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
        ),
      ],
    );
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
          icon: Icons.bed_outlined,
          title: 'No beds yet',
          detail: "Beds are created from the unit's bed count. "
              'Raise it to add them.',
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

/// What the price dialog returns. A plain null result means cancelled, which
/// is why clearing the price needs a wrapper rather than a bare null.
class _PriceResult {
  const _PriceResult(this.rent);

  /// Null means "let at the unit's rate".
  final num? rent;
}

/// Asks what one bed should cost.
class _BedPriceDialog extends StatefulWidget {
  const _BedPriceDialog({required this.current, required this.unitRent});

  final num? current;
  final num? unitRent;

  @override
  State<_BedPriceDialog> createState() => _BedPriceDialogState();
}

class _BedPriceDialogState extends State<_BedPriceDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current?.toString() ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final text = _controller.text.trim();
    Navigator.of(context).pop(_PriceResult(text.isEmpty ? null : num.parse(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LizmoColors.white,
      title: Text('Price this bed', style: LizmoType.rowName.copyWith(fontSize: 16)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                prefixText: '₱',
                hintText: widget.unitRent?.toString() ?? '2500',
                hintStyle: LizmoType.rowSub,
                errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                // Empty is allowed and meaningful: it hands the bed back to
                // the unit's rate.
                if (text.isEmpty) return null;
                final parsed = num.tryParse(text);
                if (parsed == null) return 'Enter an amount';
                // Zero would read as free; the API refuses it too.
                if (parsed <= 0) return 'Enter more than zero';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Text(
              widget.unitRent != null
                  ? 'Leave empty to charge the unit rate of '
                      '${LizmoMoney.peso(widget.unitRent)}.'
                  : 'Leave empty to charge whatever the unit asks.',
              style: LizmoType.rowSub,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: LizmoType.rowName.copyWith(color: LizmoColors.slate)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text('Save',
              style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
        ),
      ],
    );
  }
}

/// Whether the unit is open for letting at all.
///
/// Separate from the pencil: editing changes what the unit *is*, this changes
/// whether it can be let. Mirrors the sheet on a bed row.
class _MoreButton extends ConsumerWidget {
  const _MoreButton({
    required this.unit,
    required this.propertyId,
    required this.unitId,
  });

  final UnitResponse? unit;
  final String propertyId;
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: unit == null ? null : () => _open(context, ref),
      icon: const Icon(Icons.more_horiz),
      color: LizmoColors.white,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'More',
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final closed = unit!.status == UnitResponseStatusEnum.MAINTENANCE;
    final occupied = unit!.status == UnitResponseStatusEnum.OCCUPIED ||
        unit!.status == UnitResponseStatusEnum.PARTIALLY_OCCUPIED;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: LizmoColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Unit ${unit!.unitNumber ?? ''}',
                    style: LizmoType.rowName),
              ),
            ),
            if (occupied)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  'Occupied units cannot be taken out of service. End their '
                  'leases first.',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                ),
              )
            else
              ListTile(
                leading: Icon(
                  closed ? Icons.build_circle_outlined : Icons.build_outlined,
                  color: LizmoColors.slate,
                ),
                title: Text(
                  closed ? 'Return to service' : 'Take out of service',
                  style: LizmoType.rowName,
                ),
                subtitle: Text(
                  closed
                      ? 'Counts towards the property again.'
                      : 'Stops counting as rentable, beds and all.',
                  style: LizmoType.rowSub,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _set(context, ref, !closed);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _set(BuildContext context, WidgetRef ref, bool underMaintenance) async {
    try {
      await ref.read(unitsApiProvider).setUnitMaintenance(
            unitId,
            MaintenanceRequest(underMaintenance: underMaintenance),
          );
      ref.invalidate(unitProvider(unitId));
      // The property's rentable count and monthly total both move.
      ref.invalidate(unitsProvider(propertyId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: LizmoColors.red,
            content: Text(ApiFailure.from(error).message,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.white)),
          ),
        );
      }
    }
  }
}

/// States that the unit is shut, so an empty earnings figure is explained
/// rather than looking like missing data.
class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_outlined, size: 18, color: LizmoColors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Out of service. Nothing here counts as rentable.',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the unit charges for utilities, and the way in to change it.
///
/// On the unit rather than the bed: a WiFi router serves the room, not one
/// bunk. How the charge is divided between bedspacers is a billing question,
/// and there is no billing yet.
class _UtilitiesRow extends StatelessWidget {
  const _UtilitiesRow({
    required this.monthly,
    required this.propertyId,
    required this.unitId,
  });

  final num? monthly;
  final String propertyId;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    // Deliberately not a white card: it sat directly above four white cards
    // that were beds, at the same weight, and read as one of them. A tinted
    // strip with no shadow says "this is about the unit, not its contents".
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: LizmoColors.tealBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push(Routes.unitUtilities(propertyId, unitId)),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.bolt_outlined, size: 18, color: LizmoColors.teal900),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Utilities', style: LizmoType.rowName),
                      const SizedBox(height: 2),
                      Text(
                        monthly == null
                            // Not "₱0": nothing is switched on, which is a
                            // different statement from a charge of nothing.
                            ? 'None charged'
                            : 'A fixed ${LizmoMoney.peso(monthly)} each month',
                        style: LizmoType.rowSub,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: LizmoColors.teal900),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
