import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';

/// Adds a unit to a property.
///
/// Rental mode is the first decision on the form because everything below it
/// depends on the answer: a bedspace needs a capacity and prices per bed, a
/// whole unit has neither.
class CreateUnitScreen extends ConsumerStatefulWidget {
  const CreateUnitScreen({super.key, required this.propertyId});

  final String propertyId;

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

  bool get _isBedspace => _mode == UnitRequestRentalModeEnum.BEDSPACE;

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
      await ref.read(propertiesApiProvider).createUnit(
            widget.propertyId,
            UnitRequest(
              unitNumber: _unitNumber.text.trim(),
              floor: _floor.text.trim().isEmpty ? null : _floor.text.trim(),
              rentalMode: _mode,
              // Only meaningful for a bedspace; the API normalises a whole
              // unit to 1 regardless of what is sent.
              capacity: _isBedspace ? int.tryParse(_capacity.text.trim()) ?? 1 : 1,
              // Left null rather than zero when blank: a landlord may not have
              // decided yet, and zero would read as free.
              rent: _rent.text.trim().isEmpty ? null : num.tryParse(_rent.text.trim()),
            ),
          );

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
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Add a unit', style: LizmoType.screenTitle.copyWith(fontSize: 18)),
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
                _ModePicker(
                  value: _mode,
                  onChanged: (next) => setState(() => _mode = next),
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
                  // Stated up front because the API refuses to change it later,
                  // and discovering that after the fact is worse.
                  'This cannot be changed later.',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                ),
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
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 1) return 'Enter at least 1';
                      return _fieldErrors['capacity'];
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Beds are added afterwards, up to this many.',
                    style: LizmoType.rowSub,
                  ),
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
                    : PrimaryActionButton(label: 'Save unit', onPressed: _save),
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

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.value, required this.onChanged});

  final UnitRequestRentalModeEnum value;
  final ValueChanged<UnitRequestRentalModeEnum> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeOption(
            label: 'Bedspace',
            selected: value == UnitRequestRentalModeEnum.BEDSPACE,
            onTap: () => onChanged(UnitRequestRentalModeEnum.BEDSPACE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeOption(
            label: 'Whole unit',
            selected: value == UnitRequestRentalModeEnum.WHOLE_UNIT,
            onTap: () => onChanged(UnitRequestRentalModeEnum.WHOLE_UNIT),
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
  final VoidCallback onTap;

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
