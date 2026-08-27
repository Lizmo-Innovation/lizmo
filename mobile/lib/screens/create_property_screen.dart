import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';

/// Adds or edits a property.
///
/// One screen for both: the fields, validation and error handling are
/// identical, and two copies would drift the moment one gained a field.
/// Passing a [propertyId] switches it to editing.
///
/// A full screen rather than a sheet: the address is a real typing task on a
/// phone, and a sheet fighting the keyboard for room makes it worse.
class CreatePropertyScreen extends ConsumerStatefulWidget {
  const CreatePropertyScreen({super.key, this.propertyId});

  /// Null when creating.
  final String? propertyId;

  bool get isEditing => propertyId != null;

  @override
  ConsumerState<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends ConsumerState<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();

  PropertyRequestUsageEnum _usage = PropertyRequestUsageEnum.RESIDENTIAL;
  PropertyRequestTypeEnum _type = PropertyRequestTypeEnum.BOARDING_HOUSE;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  /// Units in this property. The API refuses to delete one that still holds
  /// any, so the form says so instead of offering a button that cannot work.
  int _units = 0;
  Map<String, String> _fieldErrors = const {};

  /// Prefill happens once. Rebuilding must not overwrite what the landlord has
  /// typed while the fetch was in flight, or an edit would silently revert.
  bool _prefilled = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
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
      final request = PropertyRequest(
        name: _name.text.trim(),
        address: _address.text.trim(),
        // Blank means no description, not an empty one — the API stores null
        // either way, and sending null says what is meant.
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        type: _type,
        usage: _usage,
      );

      final api = ref.read(propertiesApiProvider);
      if (widget.isEditing) {
        await api.updateProperty(widget.propertyId!, request);
        ref.invalidate(propertyProvider(widget.propertyId!));
      } else {
        await api.createProperty(request);
      }

      // The list is autoDispose, but it may still be alive behind this screen —
      // invalidating makes the change appear rather than waiting for a manual
      // refresh.
      ref.invalidate(propertiesProvider);

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

  /// Deletes the property, after asking.
  ///
  /// Lands on the property list rather than popping: the screen underneath
  /// this one is the property's own, which is about to stop existing.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LizmoColors.white,
        title: Text('Delete ${_name.text.trim()}?',
            style: LizmoType.rowName.copyWith(fontSize: 16)),
        content: Text('This cannot be undone.', style: LizmoType.rowSub),
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
      await ref.read(propertiesApiProvider).deleteProperty(widget.propertyId!);
      ref.invalidate(propertiesProvider);

      // The properties tab, not the section root: /landlord now lands on
      // Today, and deleting a property should leave you looking at the list it
      // came from rather than the dashboard.
      if (mounted) context.go(Routes.properties);
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Editing waits for the property before showing fields, so the landlord
    // never types into a form that is about to be overwritten by the fetch.
    if (widget.isEditing && !_prefilled) {
      final existing = ref.watch(propertyProvider(widget.propertyId!));
      switch (existing) {
        case AsyncData(:final value):
          _name.text = value.name ?? '';
          _address.text = value.address ?? '';
          _description.text = value.description ?? '';
          _type = PropertyRequestTypeEnum.fromJson(value.type?.toJson()) ?? _type;
          _usage = PropertyRequestUsageEnum.fromJson(value.usage?.toJson()) ?? _usage;
          _units = value.unitCount ?? 0;
          _prefilled = true;
        case AsyncError(:final error):
          return _LoadFailed(failure: ApiFailure.from(error));
        default:
          return const _LoadingScaffold();
      }
    }

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(widget.isEditing ? 'Edit property' : 'Add a property',
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
                _Label('Property name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('Sunrise Apartments'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Give the property a name'
                      : _fieldErrors['name'],
                ),
                const SizedBox(height: 18),

                _Label('Address'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  // Addresses wrap; a single line would hide most of it.
                  maxLines: 2,
                  minLines: 2,
                  decoration: _decoration('12 Mabini St, Quezon City'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Add an address'
                      : _fieldErrors['address'],
                ),
                const SizedBox(height: 18),

                _Label('Description (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  // Room to write a few sentences without becoming a page.
                  maxLines: 4,
                  minLines: 4,
                  maxLength: 2000,
                  decoration: _decoration(
                    'Quiet street, five minutes from the LRT. Curfew at 11pm.',
                  ),
                  validator: (value) => _fieldErrors['description'],
                ),
                const SizedBox(height: 6),

                _Label('Used for'),
                const SizedBox(height: 6),
                _UsagePicker(
                  value: _usage,
                  onChanged: (next) => setState(() {
                    _usage = next;
                    // The type sets do not overlap, so a type carried across
                    // would be one the API refuses. Falling back to the first
                    // of the new set keeps the form in a state that can save.
                    if (!typesFor(next).contains(_type)) {
                      _type = typesFor(next).first;
                    }
                  }),
                ),
                const SizedBox(height: 18),

                _Label('Type'),
                const SizedBox(height: 6),
                _TypePicker(
                  types: typesFor(_usage),
                  value: _type,
                  onChanged: (next) => setState(() => _type = next),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: _error!),
                ],

                const SizedBox(height: 28),
                _saving
                    ? const _SavingButton()
                    : PrimaryActionButton(
                        label: widget.isEditing ? 'Save changes' : 'Save property',
                        onPressed: _save,
                      ),

                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  _DeleteSection(
                    blockedByUnits: _units,
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

/// Which types a usage allows. Mirrors PropertyUsage on the server, which is
/// the authority — this copy exists so the form can offer only valid types
/// rather than letting the landlord pick a combination the API will refuse.
const _typesByUsage = {
  PropertyRequestUsageEnum.RESIDENTIAL: [
    PropertyRequestTypeEnum.BOARDING_HOUSE,
    PropertyRequestTypeEnum.APARTMENT,
    PropertyRequestTypeEnum.CONDO,
    PropertyRequestTypeEnum.SINGLE_HOUSE,
  ],
  PropertyRequestUsageEnum.COMMERCIAL: [
    PropertyRequestTypeEnum.OFFICE,
    PropertyRequestTypeEnum.RETAIL_SPACE,
    PropertyRequestTypeEnum.WAREHOUSE,
    PropertyRequestTypeEnum.STALL,
  ],
};

List<PropertyRequestTypeEnum> typesFor(PropertyRequestUsageEnum usage) =>
    _typesByUsage[usage] ?? _typesByUsage[PropertyRequestUsageEnum.RESIDENTIAL]!;

/// Residential or commercial. Asked before the type, because it decides which
/// types are on offer.
class _UsagePicker extends StatelessWidget {
  const _UsagePicker({required this.value, required this.onChanged});

  final PropertyRequestUsageEnum value;
  final ValueChanged<PropertyRequestUsageEnum> onChanged;

  static const _labels = {
    PropertyRequestUsageEnum.RESIDENTIAL: 'Residential',
    PropertyRequestUsageEnum.COMMERCIAL: 'Commercial',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in _labels.entries)
          _TypeChip(
            label: entry.value,
            selected: entry.key == value,
            onTap: () => onChanged(entry.key),
          ),
      ],
    );
  }
}

/// Property type as tappable chips rather than a dropdown.
///
/// Four options fit on screen, so showing them costs nothing and saves a tap.
/// A dropdown would also hide the choice behind a control whose default the
/// landlord might never question.
class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.types,
    required this.value,
    required this.onChanged,
  });

  /// Only the types the chosen usage allows.
  final List<PropertyRequestTypeEnum> types;
  final PropertyRequestTypeEnum value;
  final ValueChanged<PropertyRequestTypeEnum> onChanged;

  static const _labels = {
    PropertyRequestTypeEnum.BOARDING_HOUSE: 'Boarding house',
    PropertyRequestTypeEnum.APARTMENT: 'Apartment',
    PropertyRequestTypeEnum.CONDO: 'Condo',
    PropertyRequestTypeEnum.SINGLE_HOUSE: 'Single house',
    PropertyRequestTypeEnum.OFFICE: 'Office',
    PropertyRequestTypeEnum.RETAIL_SPACE: 'Retail space',
    PropertyRequestTypeEnum.WAREHOUSE: 'Warehouse',
    PropertyRequestTypeEnum.STALL: 'Stall',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in types)
          _TypeChip(
            label: _labels[type] ?? '',
            selected: type == value,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

/// The property could not be loaded, so there is nothing to edit.
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
          title: failure.isNetwork ? "Can't reach Lizmo" : "Can't open this property",
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
/// A property with units cannot be deleted: it is the root of their leases and
/// billing history, and removing it would either cascade that away or orphan
/// it. Unlike the bed case, there is a way out — units can be deleted — so this
/// names the obstacle rather than being a dead end.
class _DeleteSection extends StatelessWidget {
  const _DeleteSection({
    required this.blockedByUnits,
    required this.deleting,
    required this.onDelete,
  });

  final int blockedByUnits;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (blockedByUnits > 0) {
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
                blockedByUnits == 1
                    ? 'This property has 1 unit. Delete it before deleting the property.'
                    : 'This property has $blockedByUnits units. Delete them before '
                        'deleting the property.',
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
        'Delete this property',
        // Red, not coral: coral is the action accent and belongs to Save.
        style: LizmoType.rowName.copyWith(color: LizmoColors.red),
      ),
    );
  }
}
