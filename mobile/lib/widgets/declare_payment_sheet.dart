import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../push/push_offer.dart';
import 'lizmo_payment_channels.dart';

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
    this.payment,
  });

  final String periodLabel;

  /// Where to send it: the landlord's channels. Null when not known, and the
  /// sheet then asks nothing about accounts.
  final PaymentDetails? payment;

  /// Prefilled, because paying exactly what is left is the ordinary case and
  /// retyping it is a chore that invites mistakes.
  final num outstanding;

  static Future<Declared?> show(
    BuildContext context, {
    required String periodLabel,
    required num outstanding,
    PaymentDetails? payment,
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
        payment: payment,
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
    this.channelId,
  });

  final num amount;

  /// Which of the landlord's channels it went to. Null for cash, or when none
  /// was picked; the server writes out the channel's details from this.
  final String? channelId;
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
  String? _channelId;

  /// Picking an account also picks the obvious method, so nobody is asked the
  /// same thing twice. A bank is a transfer; anything unrecognised is left.
  void _sentTo(PaymentChannelView? channel) {
    setState(() {
      _channelId = channel?.id;
      final name = (channel?.channel ?? '').toLowerCase();
      if (channel == null) return;
      if (name.contains('gcash')) {
        _method = RecordPaymentRequestPaymentMethodEnum.GCASH;
      } else if (name.contains('maya')) {
        _method = RecordPaymentRequestPaymentMethodEnum.MAYA;
      } else {
        _method = RecordPaymentRequestPaymentMethodEnum.BANK_TRANSFER;
      }
    });
  }

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
      // Cash went to nobody's account, whatever was tapped before.
      channelId: _method == RecordPaymentRequestPaymentMethodEnum.CASH
          ? null
          : _channelId,
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

              if (widget.payment case final payment?) ...[
                const SizedBox(height: 18),
                _Label('Send it to'),
                const SizedBox(height: 6),
                LizmoPaymentChannels(
                  details: payment,
                  emptyMessage: 'Your landlord has not added how to pay yet. '
                      'Ask them before sending money.',
                  qrUnavailable: 'That QR could not be loaded. Close this and '
                      'pull down on the Rent tab to refresh it.',
                ),
              ],

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

              if (widget.payment?.channels case final channels?
                  when channels.isNotEmpty) ...[
                const SizedBox(height: 18),
                _Label('Which account did you send it to?'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final channel in channels)
                      ChoiceChip(
                        key: ValueKey('sent-to-${channel.id}'),
                        label: Text('${channel.channel} · ${channel.accountName}',
                            style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
                        selected: _channelId == channel.id,
                        onSelected: (_) => _sentTo(channel),
                      ),
                    ChoiceChip(
                      key: const ValueKey('sent-to-none'),
                      label: Text('None of these',
                          style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
                      selected: _channelId == null,
                      onSelected: (_) => _sentTo(null),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your landlord sees it, so they know which account to check.',
                  style: LizmoType.rowSub.copyWith(fontSize: 11),
                ),
              ],

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
                      // Lizmo's type, not Material's default, like every
                      // other label on this sheet.
                      label: Text(entry.value,
                          style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
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
              PrimaryActionButton(
                // Keyed: the month card behind the sheet now says
                // "I have paid" too, so the label alone names two buttons.
                key: const ValueKey('declare-submit'),
                label: 'I have paid',
                onPressed: _submit,
              ),
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

/// Sends what the tenant said, and refreshes everything that reads it.
///
/// Shared by Home and the Rent tab, so saying you paid is the same act from
/// either -- the same request, the same screenshot, the same refresh.
///
/// Throws [ApiFailure]; the caller says what went wrong where it was asked.
Future<void> sendDeclaration(
  WidgetRef ref, {
  required String leaseId,
  required BillingPeriodResponse period,
  required Declared said,
}) async {
  try {
    // Each field on its own, as text: the endpoint takes a form, because the
    // generated client cannot send one JSON part inside an upload.
    await ref.read(rentApiProvider).declarePayment(
          leaseId,
          period.id!,
          said.amount.toString(),
          paymentMethod: said.method.toJson(),
          remarks: said.note,
          channelId: said.channelId,
          proof: said.proof == null
              ? null
              : http.MultipartFile.fromBytes(
                  'proof',
                  await said.proof!.readAsBytes(),
                  filename: said.proof!.name,
                ),
        );
  } catch (error) {
    throw ApiFailure.from(error);
  }

  ref.invalidate(myBillingProvider(leaseId));
  ref.invalidate(myPaymentsProvider(leaseId));
}

/// After saying they paid, the one thing left is the landlord's answer --
/// the moment notifications are worth asking for.
void offerPushesAfterDeclaring(BuildContext context, WidgetRef ref) {
  unawaited(ref.read(pushOfferProvider).offer(
        context,
        title: 'Get told when your landlord confirms it?',
        body: 'Lizmo will let you know the moment they confirm your payment, '
            'or if something is wrong with it.',
      ));
}
