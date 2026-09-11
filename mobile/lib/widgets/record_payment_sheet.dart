import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// A landlord writing down money they received themselves.
///
/// Cash handed over at the door had nowhere to go: the backend could record
/// it, and no screen asked. Unlike a tenant's claim this counts straight away
/// -- the landlord is the one who would otherwise confirm it -- and the sheet
/// says so, along with the fact that the tenant is told.
class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.billingPeriodId,
    required this.tenantName,
    required this.periodLabel,
    required this.outstanding,
  });

  final String billingPeriodId;
  final String tenantName;
  final String periodLabel;

  /// Prefilled, because receiving exactly what is left is the ordinary case.
  final num outstanding;

  /// The payment to record, or null if the landlord backed out.
  static Future<RecordPaymentRequest?> show(
    BuildContext context, {
    required String billingPeriodId,
    required String tenantName,
    required String periodLabel,
    required num outstanding,
  }) {
    return showModalBottomSheet<RecordPaymentRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RecordPaymentSheet(
        billingPeriodId: billingPeriodId,
        tenantName: tenantName,
        periodLabel: periodLabel,
        outstanding: outstanding,
      ),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: widget.outstanding.toStringAsFixed(0));
  final _note = TextEditingController();

  // Cash first: it is the payment with no other way into the app. A GCash
  // payment usually arrives as the tenant's own claim.
  RecordPaymentRequestPaymentMethodEnum _method =
      RecordPaymentRequestPaymentMethodEnum.CASH;

  late DateTime _receivedOn = _today();

  static const _methods = {
    RecordPaymentRequestPaymentMethodEnum.CASH: 'Cash',
    RecordPaymentRequestPaymentMethodEnum.GCASH: 'GCash',
    RecordPaymentRequestPaymentMethodEnum.MAYA: 'Maya',
    RecordPaymentRequestPaymentMethodEnum.BANK_TRANSFER: 'Bank transfer',
    RecordPaymentRequestPaymentMethodEnum.OTHER: 'Something else',
  };

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      // A landlord writes down on Monday the cash they were handed on
      // Saturday, and sometimes much later. Never in the future.
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
    );
    if (picked != null) setState(() => _receivedOn = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final note = _note.text.trim();

    Navigator.of(context).pop(RecordPaymentRequest(
      billingPeriodId: widget.billingPeriodId,
      amountPaid: num.parse(_amount.text.trim()),
      // Built as UTC midnight by hand. The generated client serialises the
      // date as it is given, and a local midnight in UTC+8 is the day before.
      paymentDate:
          DateTime.utc(_receivedOn.year, _receivedOn.month, _receivedOn.day),
      paymentMethod: _method,
      remarks: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _receivedOn == _today();

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
                'Record a payment',
                style: LizmoType.screenTitle
                    .copyWith(fontSize: 20, color: LizmoColors.teal900),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.tenantName}, for ${widget.periodLabel}. It counts '
                'straight away, and ${widget.tenantName} is told.',
                style: LizmoType.rowSub,
              ),

              const SizedBox(height: 20),
              const _Label('How much'),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('record-amount'),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                decoration: _field('2500').copyWith(prefixText: '₱ '),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'How much did you receive?';
                  final amount = num.tryParse(text);
                  if (amount == null) return 'Enter an amount';
                  if (amount <= 0) return 'That has to be more than nothing';
                  return null;
                },
              ),

              const SizedBox(height: 18),
              const _Label('Received on'),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const ValueKey('record-date'),
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(
                  isToday
                      ? 'Today'
                      : '${_receivedOn.day} ${_months[_receivedOn.month - 1]} '
                          '${_receivedOn.year}',
                  style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LizmoColors.teal900,
                  side: const BorderSide(color: Color(0xFFE3E8E6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 18),
              const _Label('How they paid'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _methods.entries)
                    ChoiceChip(
                      key: ValueKey('record-method-${entry.key.toJson()}'),
                      label: Text(entry.value,
                          style: LizmoType.rowSub
                              .copyWith(color: LizmoColors.ink)),
                      selected: _method == entry.key,
                      onSelected: (_) => setState(() => _method = entry.key),
                    ),
                ],
              ),

              const SizedBox(height: 18),
              const _Label('Note'),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('record-note'),
                controller: _note,
                maxLines: 2,
                maxLength: 500,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.ink),
                decoration: _field('Handed over at the door').copyWith(
                  counterText: '',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional. Your tenant sees this.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),

              const SizedBox(height: 22),
              PrimaryActionButton(
                key: const ValueKey('record-submit'),
                label: 'Record payment',
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: LizmoType.rowName.copyWith(fontSize: 13),
      );
}
