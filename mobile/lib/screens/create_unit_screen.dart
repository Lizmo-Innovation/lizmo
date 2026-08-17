import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';

/// Adds or edits a unit.
///
/// Rental mode is the first decision when creating, because everything below
/// it depends on the answer: a bedspace needs a capacity and prices per bed, a
/// whole unit has neither.
///
/// When editing, that choice is shown but locked. The API refuses to change
/// it, since switching would orphan either the beds or the unit's own lease —
/// and a disabled control that explains itself is kinder than one that accepts
/// a tap and then fails.
class CreateUnitScreen extends ConsumerStatefulWidget {
  const CreateUnitScreen({super.key, required this.propertyId, this.unitId});

  final String propertyId;

  /// Null when creating.
  final String? unitId;

  bool get isEditing => unitId != null;

  @override
  ConsumerState<CreateUnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends ConsumerState<CreateUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumber = TextEditingController();
  final _floor = TextEditingController();
  final _rent = TextEditingController();
  final _capacity = TextEditingController(text: '4');

  UnitRequestRentalModeEnum _mode = UnitRequestRentalModeEnum.BEDSPACE;
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  /// Prefill once, so a rebuild never overwrites what has been typed.
  bool _prefilled = false;

  /// Beds already defined. Capacity cannot drop below this — the API refuses,
  /// and the form says so before the landlord tries.
  int _existingBeds = 0;

  bool _deleting = false;

  bool get _isBedspace => _mode == UnitRequestRentalModeEnum.BEDSPACE;

  /// How many beds saving would delete, given what is currently typed.
  ///
  /// Beds follow capacity now, so lowering it destroys the surplus. The server
  /// refuses if any of them are occupied.
  int get _bedsToRemove {
    if (!widget.isEditing || !_isBedspace) return 0;
    final wanted = int.tryParse(_capacity.text.trim());
    if (wanted == null) return 0;
    return _existingBeds > wanted ? _existingBeds - wanted : 0;
  }

  @override
  void dispose() {
    _unitNumber.dispose();
    _floor.dispose();
    _rent.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      final request = UnitRequest(
        unitNumber: _unitNumber.text.trim(),
        floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
        rentalMode: _mode,
        // Only meaningful for a bedspace; the API normalises a whole unit to 1
        // regardless of what is sent.
        capacity: _isBedspace ? int.tryParse(_capacity.text.trim()) ?? 1 : 1,
        // Left null rather than zero when blank: a landlord may not have
        // decided yet, and zero would read as free.
        rent: _rent.text.trim().isEmpty ? null : num.tryParse(_rent.text.trim()),
      );

      if (widget.isEditing) {
        await ref.read(unitsApiProvider).updateUnit(widget.unitId!, request);
        ref.invalidate(unitProvider(widget.unitId!));
      } else {
        await ref.read(propertiesApiProvider).createUnit(widget.propertyId, request);
      }

      ref.invalidate(unitsProvider(widget.propertyId));
      ref.invalidate(propertiesProvider); // the unit count on the list changes

      if (mounted) context.pop();
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (!mounted) return;
      setState(() {
        _error = failure.message;
        _fieldErrors = failure.fields;
      });
      _formKey.currentState?.validate();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_prefilled) {
      final existing = ref.watch(unitProvider(widget.unitId!));
      switch (existing) {
        case AsyncData(:final value):
          _unitNumber.text = value.unitNumber ?? '';
          _floor.text = value.floor ?? '';
          _rent.text = value.rent?.toString() ?? '';
          _capacity.text = (value.capacity ?? 1).toString();
          _mode = UnitRequestRentalModeEnum.fromJson(value.rentalMode?.toJson()) ?? _mode;
          _existingBeds = value.bedCount ?? 0;
          _prefilled = true;
        case AsyncError(:final error):
          return _LoadFailed(failure: ApiFailure.from(error));
        default:
          return const _LoadingScaffold();
      }
    }

    // Bedspace means letting individual beds in a shared room, which a shop or
    // a warehouse cannot be, so commercial properties are not asked.
    //
    // Read without blocking: if the property has not loaded, the picker is
    // shown as normal. The server coerces the mode for a commercial property
    // whatever the form sends, so guessing wrong here costs nothing worse than
    // an unnecessary question.
    final isCommercial = ref.watch(propertyProvider(widget.propertyId)).valueOrNull?.usage ==
        PropertyResponseUsageEnum.COMMERCIAL;

    if (isCommercial) {
      _mode = UnitRequestRentalModeEnum.WHOLE_UNIT;
    }

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(widget.isEditing ? 'Edit unit' : 'Add a unit',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label('How is it rented?'),
                const SizedBox(height: 6),

                if (isCommercial) ...[
                  // No mode picker: bedspace cannot apply to a commercial
                  // property, so the only answer is stated rather than asked.
                  Text(
                    'The whole unit is rented to one tenant.',
                    style: LizmoType.rowSub,
                  ),
                ] else ...[
                  _ModePicker(
                    value: _mode,
                    // Locked when editing: the API refuses a change, so
                    // offering one would only produce an error the landlord
                    // cannot act on.
                    onChanged: widget.isEditing
                        ? null
                        : (next) => setState(() => _mode = next),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isBedspace
                        ? 'Each bed is rented separately, with its own tenant and rent.'
                        : 'The whole unit is rented to one tenant.',
                    style: LizmoType.rowSub,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isEditing
                        ? 'This cannot be changed. Create a new unit instead.'
                        // Stated up front because the API refuses to change it
                        // later, and finding that out afterwards is worse.
                        : 'This cannot be changed later.',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                  ),
                ],
                const SizedBox(height: 20),

                _Label('Unit number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _unitNumber,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('2B'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Give the unit a number'
                      // The API rejects a duplicate within the property; its
                      // message is more specific than anything guessed here.
                      : _fieldErrors['unitNumber'],
                ),
                const SizedBox(height: 18),

                _Label('Floor (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _floor,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('2'),
                ),
                const SizedBox(height: 18),

                if (_isBedspace) ...[
                  _Label('How many beds?'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration('4'),
                    // Rebuilt on every keystroke so the warning below tracks
                    // what the landlord has actually typed.
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 1) return 'Enter at least 1';
                      return _fieldErrors['capacity'];
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isEditing
                        ? 'The beds in this unit follow this number.'
                        : 'Beds are created with the unit, one per bedspace.',
                    style: LizmoType.rowSub,
                  ),

                  // Lowering this deletes beds, so it is said before saving
                  // rather than discovered afterwards.
                  if (_bedsToRemove > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _bedsToRemove == 1
                          ? 'Saving will remove 1 bed.'
                          : 'Saving will remove $_bedsToRemove beds.',
                      style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                    ),
                  ],
                  const SizedBox(height: 18),
                ],

                _Label(_isBedspace ? 'Rent per bed (optional)' : 'Rent (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _rent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: _decoration('2500').copyWith(prefixText: '₱ '),
                  validator: (value) {
                    final raw = (value ?? '').trim();
                    if (raw.isEmpty) return _fieldErrors['rent'];
                    final parsed = num.tryParse(raw);
                    if (parsed == null || parsed <= 0) return 'Enter an amount above zero';
                    return _fieldErrors['rent'];
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'What you ask for it. Each lease can still differ.',
                  style: LizmoType.rowSub,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: _error!),
                ],

                const SizedBox(height: 28),
                _saving
                    ? const _SavingButton()
                    : PrimaryActionButton(
                        label: widget.isEditing ? 'Save changes' : 'Save unit',
                        onPressed: _save,
                      ),

                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  _DeleteSection(
                    blockedByBeds: _existingBeds,
                    deleting: _deleting,
                    onDelete: _confirmDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Deletes the unit, after asking.
  ///
  /// Deletion is permanent and there is no undo, so it is confirmed rather than
  /// taken on a single tap — and the dialog names the unit, because a landlord
  /// with several open screens should not have to trust that they tapped the
  /// one they meant.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LizmoColors.white,
        title: Text('Delete unit ${_unitNumber.text.trim()}?',
            style: LizmoType.rowName.copyWith(fontSize: 16)),
        content: Text(
          'This cannot be undone.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel',
                style: LizmoType.rowName.copyWith(color: LizmoColors.slate)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete',
                style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await ref.read(unitsApiProvider).deleteUnit(widget.unitId!);

      ref.invalidate(unitsProvider(widget.propertyId));
      ref.invalidate(propertiesProvider); // the unit count on the list changes

      if (mounted) context.pop();
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color colour) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colour),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: LizmoType.rowSub,
      filled: true,
      fillColor: LizmoColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(const Color(0xFFE3E8E6)),
      focusedBorder: border(LizmoColors.teal900),
      errorBorder: border(LizmoColors.red),
      focusedErrorBorder: border(LizmoColors.red),
      errorStyle: LizmoType.rowSub.copyWith(color: LizmoColors.red),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.value, required this.onChanged});

  final UnitRequestRentalModeEnum value;

  /// Null renders the picker as locked — used when editing.
  final ValueChanged<UnitRequestRentalModeEnum>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeOption(
            label: 'Bedspace',
            selected: value == UnitRequestRentalModeEnum.BEDSPACE,
            onTap: onChanged == null
                ? null
                : () => onChanged!(UnitRequestRentalModeEnum.BEDSPACE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeOption(
            label: 'Whole unit',
            selected: value == UnitRequestRentalModeEnum.WHOLE_UNIT,
            onTap: onChanged == null
                ? null
                : () => onChanged!(UnitRequestRentalModeEnum.WHOLE_UNIT),
          ),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;

  /// Null when the choice is locked.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LizmoColors.tealBg : LizmoColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
            ),
          ),
          child: Text(
            label,
            style: LizmoType.rowName.copyWith(
              color: selected ? LizmoColors.teal900 : LizmoColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LizmoType.rowName.copyWith(fontSize: 13));
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LizmoColors.redBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: LizmoColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
          ),
        ],
      ),
    );
  }
}

class _SavingButton extends StatelessWidget {
  const _SavingButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: LizmoColors.coral.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
        ),
      ),
    );
  }
}


class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: LizmoMessageState(
          tone: LizmoMessageTone.problem,
          icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
          title: failure.isNetwork ? "Can't reach Lizmo" : "Can't open this unit",
          detail: failure.message,
          actionLabel: 'Go back',
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}


/// Deletion, kept apart from the save action and styled as a departure.
///
/// The API refuses while the unit still has beds, so when it does, this
/// explains that instead of offering a button that cannot work. Bed removal is
/// not built yet, which the message deliberately does not pretend otherwise
/// about.
class _DeleteSection extends StatelessWidget {
  const _DeleteSection({
    required this.blockedByBeds,
    required this.deleting,
    required this.onDelete,
  });

  final int blockedByBeds;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (blockedByBeds > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LizmoColors.amberBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: LizmoColors.amberText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This unit has $blockedByBeds beds, so it cannot be deleted. '
                'Its beds hold the tenancy history.',
                style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
              ),
            ),
          ],
        ),
      );
    }

    if (deleting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(LizmoColors.red),
            ),
          ),
        ),
      );
    }

    return TextButton(
      onPressed: onDelete,
      child: Text(
        'Delete this unit',
        // Red, not coral: coral is the action accent and belongs to the screen's
        // main action, which this is the opposite of.
        style: LizmoType.rowName.copyWith(color: LizmoColors.red),
      ),
    );
  }
}
