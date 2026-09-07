import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// A tenant saying they have paid.
///
/// A claim, not a fact: nothing about the balance moves until the landlord
/// agrees the money arrived. The sheet says so, because a tenant who taps
/// "I have paid" and watches the month stay unpaid would reasonably think the
/// app had lost it.
class DeclarePaymentSheet extends StatefulWidget {
  const DeclarePaymentSheet({
    super.key,
    required this.periodLabel,
    required this.outstanding,
  });

  final String periodLabel;

  /// Prefilled, because paying exactly what is left is the ordinary case and
  /// retyping it is a chore that invites mistakes.
  final num outstanding;

  static Future<Declared?> show(
    BuildContext context, {
    required String periodLabel,
    required num outstanding,
  }) {
    return showModalBottomSheet<Declared>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeclarePaymentSheet(
        periodLabel: periodLabel,
        outstanding: outstanding,
      ),
    );
  }

  @override
  State<DeclarePaymentSheet> createState() => _DeclarePaymentSheetState();
}

/// What the tenant said, and the screenshot if they attached one.
class Declared {
  const Declared({
    required this.amount,
    required this.method,
    this.note,
    this.proof,
  });

  final num amount;
  final RecordPaymentRequestPaymentMethodEnum method;

  /// Anything the figures cannot say: paid from somebody else's number, sent
  /// in two halves, a reference number. Null when left blank.
  final String? note;

  final XFile? proof;
}

class _DeclarePaymentSheetState extends State<DeclarePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: widget.outstanding.toStringAsFixed(0));

  RecordPaymentRequestPaymentMethodEnum _method =
      RecordPaymentRequestPaymentMethodEnum.GCASH;
  final _note = TextEditingController();
  XFile? _proof;

  static const _methods = {
    RecordPaymentRequestPaymentMethodEnum.GCASH: 'GCash',
    RecordPaymentRequestPaymentMethodEnum.MAYA: 'Maya',
    RecordPaymentRequestPaymentMethodEnum.BANK_TRANSFER: 'Bank transfer',
    RecordPaymentRequestPaymentMethodEnum.CASH: 'Cash',
    RecordPaymentRequestPaymentMethodEnum.OTHER: 'Something else',
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
      // A courtesy to the connection: the server re-encodes anyway.
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _proof = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final note = _note.text.trim();

    Navigator.of(context).pop(Declared(
      amount: num.parse(_amount.text.trim()),
      method: _method,
      // Null rather than an empty string: nothing written down and something
      // written down that says nothing are different, and only the first
      // should leave the landlord's screen uncluttered.
      note: note.isEmpty ? null : note,
      proof: _proof,
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
                'Tell your landlord you have paid',
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                // Said before anything is typed. A tenant who taps this and
                // watches the month stay unpaid would think it had been lost.
                'For ${widget.periodLabel}. Your landlord confirms it, and the '
                'month only counts as paid once they do.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 20),
              _Label('How much'),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('payment-amount'),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _field('2500').copyWith(prefixText: '₱ '),
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
              _Label('How you paid'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _methods.entries)
                    ChoiceChip(
                      key: ValueKey('method-${entry.key.toJson()}'),
                      label: Text(entry.value),
                      selected: _method == entry.key,
                      onSelected: (_) => setState(() => _method = entry.key),
                    ),
                ],
              ),

              const SizedBox(height: 18),
              _Label('Note'),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('payment-note'),
                controller: _note,
                maxLines: 2,
                maxLength: 500,
                decoration: _field('Sent from my sister’s number')
                    .copyWith(counterText: ''),
              ),
              const SizedBox(height: 4),
              Text(
                // The figures cannot say "I paid from my mother's GCash", and
                // that is exactly the thing that makes a landlord hesitate
                // before confirming.
                'Optional. Your landlord sees this when they confirm.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),

              const SizedBox(height: 18),
              _Label('Screenshot'),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const ValueKey('attach-proof'),
                onPressed: _attach,
                icon: Icon(
                  _proof == null ? Icons.image_outlined : Icons.check,
                  size: 18,
                ),
                label: Text(_proof == null ? 'Attach one' : 'Attached'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LizmoColors.teal900,
                  side: const BorderSide(color: Color(0xFFE3E8E6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // Optional on purpose: cash is real, and a required field
                // nobody can satisfy becomes one people lie in.
                'Optional. It helps if you paid by GCash or transfer.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),

              const SizedBox(height: 22),
              PrimaryActionButton(label: 'I have paid', onPressed: _submit),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Not yet', style: LizmoType.rowSub),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: LizmoType.rowName.copyWith(fontSize: 13),
      );
}
