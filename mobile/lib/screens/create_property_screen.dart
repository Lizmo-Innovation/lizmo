import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';

/// Adds a property.
///
/// A full screen rather than a sheet: the address is a real typing task on a
/// phone, and a sheet fighting the keyboard for room makes it worse.
class CreatePropertyScreen extends ConsumerStatefulWidget {
  const CreatePropertyScreen({super.key});

  @override
  ConsumerState<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends ConsumerState<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();

  PropertyRequestTypeEnum _type = PropertyRequestTypeEnum.BOARDING_HOUSE;
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
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
      await ref.read(propertiesApiProvider).createProperty(
            PropertyRequest(
              name: _name.text.trim(),
              address: _address.text.trim(),
              type: _type,
            ),
          );

      // The list is autoDispose, but it may still be alive behind this screen —
      // invalidating makes the new property appear rather than waiting for a
      // manual refresh.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Add a property',
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

                _Label('Type'),
                const SizedBox(height: 6),
                _TypePicker(
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
                    : PrimaryActionButton(label: 'Save property', onPressed: _save),
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

/// Property type as tappable chips rather than a dropdown.
///
/// Four options fit on screen, so showing them costs nothing and saves a tap.
/// A dropdown would also hide the choice behind a control whose default the
/// landlord might never question.
class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.value, required this.onChanged});

  final PropertyRequestTypeEnum value;
  final ValueChanged<PropertyRequestTypeEnum> onChanged;

  static const _labels = {
    PropertyRequestTypeEnum.BOARDING_HOUSE: 'Boarding house',
    PropertyRequestTypeEnum.APARTMENT: 'Apartment',
    PropertyRequestTypeEnum.CONDO: 'Condo',
    PropertyRequestTypeEnum.SINGLE_HOUSE: 'Single house',
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
