import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// The beds inside one bedspace unit, and who is in them.
///
/// Read-only by design. How many beds a unit has is its bed count, set on the
/// unit itself — the beds are created and removed to match. A second way to
/// change the number here would let the two disagree.
class UnitBedsScreen extends ConsumerWidget {
  const UnitBedsScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
  });

  final String propertyId;
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beds = ref.watch(bedsProvider(unitId));
    final unit = ref.watch(unitProvider(unitId)).valueOrNull;

    final capacity = unit?.capacity ?? 0;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: unit == null ? 'Unit' : 'Unit ${unit.unitNumber ?? ''}',
            title: 'Beds',
            leading: const _BackButton(),
            stats: [
              LatticeHeaderStat(
                value: beds.valueOrNull?.length.toString() ?? '—',
                label: 'Beds',
              ),
              LatticeHeaderStat(
                value: capacity == 0 ? '—' : capacity.toString(),
                label: 'Capacity',
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: LizmoColors.teal900,
              onRefresh: () => ref.refresh(bedsProvider(unitId).future),
              child: switch (beds) {
                AsyncError(:final error) => _Failed(
                    failure: ApiFailure.from(error),
                    onRetry: () => ref.invalidate(bedsProvider(unitId)),
                  ),
                AsyncData(:final value) when value.isEmpty => const _Empty(),
                AsyncData(:final value) => _BedList(beds: value, unitId: unitId),
                _ => const _Loading(),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: _CountHint(propertyId: propertyId, unitId: unitId),
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

class _BedList extends StatelessWidget {
  const _BedList({required this.beds, required this.unitId});

  final List<BedResponse> beds;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      itemCount: beds.length,
      itemBuilder: (context, index) =>
          _BedRow(bed: beds[index], unitId: unitId),
    );
  }
}

/// One bed, its name and its occupancy.
///
/// Tapping renames it. There is no remove control: beds are removed by lowering
/// the unit's bed count, which is also the only thing that can add them.
class _BedRow extends ConsumerWidget {
  const _BedRow({required this.bed, required this.unitId});

  final BedResponse bed;
  final String unitId;

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
          onTap: bed.id == null ? null : () => _rename(context, ref),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(child: Text(bed.bedLabel ?? '', style: LizmoType.rowName)),
                StatusChip(status: _status(), label: _statusLabel()),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 16, color: LizmoColors.slate),
              ],
            ),
          ),
        ),
      ),
    );
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
      await ref.read(unitsApiProvider).updateBed(bed.id!, BedRequest(bedLabel: label));
      ref.invalidate(bedsProvider(unitId));
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

  LizmoStatus _status() => switch (bed.status) {
        BedResponseStatusEnum.OCCUPIED => LizmoStatus.paid,
        BedResponseStatusEnum.MAINTENANCE => LizmoStatus.pending,
        // Grey: an empty bed is neither good news nor bad.
        _ => LizmoStatus.vacant,
      };

  String _statusLabel() => switch (bed.status) {
        BedResponseStatusEnum.OCCUPIED => 'Occupied',
        BedResponseStatusEnum.MAINTENANCE => 'Maintenance',
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

/// Points at the one place the bed count can be changed.
class _CountHint extends StatelessWidget {
  const _CountHint({required this.propertyId, required this.unitId});

  final String propertyId;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            "Beds follow the unit's bed count.",
            style: LizmoType.rowSub,
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () => context.push(Routes.unitEdit(propertyId, unitId)),
          child: Text(
            'Change it',
            style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
          ),
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
