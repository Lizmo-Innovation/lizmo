import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'lizmo_payment_channels.dart';

/// What the landlord said they paid, and the proof.
class LizmoPayment {
  const LizmoPayment({
    required this.amount,
    required this.method,
    required this.proofName,
    required this.proofBytes,
    this.note,
  });

  final num amount;
  /// GCASH, MAYA, BANK_TRANSFER or OTHER, as the form field is sent.
  final String method;
  final String? note;
  final String proofName;
  final Uint8List proofBytes;
}

/// Telling Lizmo a statement has been paid.
///
/// Proof is required, unlike rent: nobody pays Lizmo in cash at the door, and
/// the person checking needs something to match the transfer against.
class PayLizmoSheet extends StatefulWidget {
  const PayLizmoSheet({
    super.key,
    required this.label,
    required this.covers,
    required this.outstanding,
    this.payment,
  });

  final String label;

  /// "2 properties", so the landlord can see what the figure is for.
  final String covers;

  final num outstanding;

  /// Where to send it, shown at the top so the number is copied here rather
  /// than by closing the sheet to find it. Left out when not known.
  final PaymentDetails? payment;

  static Future<LizmoPayment?> show(
    BuildContext context, {
    required String label,
    required String covers,
    required num outstanding,
    PaymentDetails? payment,
  }) {
    return showModalBottomSheet<LizmoPayment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PayLizmoSheet(
        label: label,
        covers: covers,
        outstanding: outstanding,
        payment: payment,
      ),
    );
  }

  @override
  State<PayLizmoSheet> createState() => _PayLizmoSheetState();
}

class _PayLizmoSheetState extends State<PayLizmoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount =
      TextEditingController(text: widget.outstanding.toStringAsFixed(0));
  final _note = TextEditingController();

  String _method = 'GCASH';
  String? _proofName;
  Uint8List? _proofBytes;
  String? _proofError;

  static const _methods = {
    'GCASH': 'GCash',
    'MAYA': 'Maya',
    'BANK_TRANSFER': 'Bank transfer',
    'OTHER': 'Something else',
  };

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _proofName = picked.name;
      _proofBytes = bytes;
      _proofError = null;
    });
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_proofBytes == null) {
      setState(() => _proofError = 'Attach a screenshot of the payment');
    }
    if (!valid || _proofBytes == null) return;

    final note = _note.text.trim();
    Navigator.of(context).pop(LizmoPayment(
      amount: num.parse(_amount.text.trim()),
      method: _method,
      note: note.isEmpty ? null : note,
      proofName: _proofName ?? 'proof.jpg',
      proofBytes: _proofBytes!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tell Lizmo you have paid',
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.label}, ${widget.covers}. Lizmo checks it, and the '
                'statement counts as paid once they do.',
                style: LizmoType.rowSub,
              ),
              const SizedBox(height: 20),
              if (widget.payment case final payment?) ...[
                Text('Send it to', style: LizmoType.rowName.copyWith(fontSize: 13)),
                const SizedBox(height: 6),
                LizmoPaymentChannels(details: payment),
                const SizedBox(height: 18),
              ],
              Text('How much', style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('lizmo-amount'),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                decoration: _field('450').copyWith(prefixText: '₱ '),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'How much did you pay?';
                  final amount = num.tryParse(text);
                  if (amount == null) return 'Enter an amount';
                  if (amount <= 0) return 'That has to be more than nothing';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text('How you paid',
                  style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _methods.entries)
                    ChoiceChip(
                      key: ValueKey('lizmo-method-${entry.key}'),
                      label: Text(entry.value,
                          style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
                      selected: _method == entry.key,
                      onSelected: (_) => setState(() => _method = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Screenshot', style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const ValueKey('lizmo-proof'),
                onPressed: _attach,
                icon: Icon(
                  _proofBytes == null ? Icons.image_outlined : Icons.check,
                  size: 18,
                ),
                label: Text(
                  _proofBytes == null ? 'Attach one' : 'Attached',
                  style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LizmoColors.teal900,
                  side: BorderSide(
                    color: _proofError == null
                        ? const Color(0xFFE3E8E6)
                        : LizmoColors.red,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _proofError ??
                    'Required. The receipt from GCash, Maya or your bank.',
                style: LizmoType.rowSub.copyWith(
                  fontSize: 11,
                  color: _proofError == null ? null : LizmoColors.red,
                ),
              ),
              const SizedBox(height: 18),
              Text('Note', style: LizmoType.rowName.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('lizmo-note'),
                controller: _note,
                maxLines: 2,
                maxLength: 500,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.ink),
                decoration:
                    _field('Reference number, or anything else').copyWith(
                  counterText: '',
                ),
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                key: const ValueKey('lizmo-send'),
                label: 'Send to Lizmo',
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: LizmoType.rowSub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _field(String hint) {
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
