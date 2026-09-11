import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../platform/lizmo_billing_providers.dart';
import '../widgets/lizmo_invoice_card.dart';
import '../widgets/pay_lizmo_sheet.dart';

/// What this landlord owes Lizmo, how to pay it, and what was paid.
///
/// One invoice per property per month, counted on the 1st: P50 for each let
/// bed and P150 for each let whole unit, nothing for anything empty. Each one
/// says how it was counted, because a number a landlord cannot check is a
/// number they telephone about.
class LizmoBillingScreen extends ConsumerWidget {
  const LizmoBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(myLizmoInvoicesProvider);
    final instructions = ref.watch(lizmoPaymentInstructionsProvider);

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Lizmo billing',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myLizmoInvoicesProvider);
          ref.invalidate(lizmoPaymentInstructionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HowToPay(text: instructions.valueOrNull),
            const SizedBox(height: 16),
            ...switch (invoices) {
              AsyncError(:final error) => [
                  LizmoMessageState(
                    tone: LizmoMessageTone.problem,
                    icon: Icons.error_outline,
                    title: 'Could not load your invoices',
                    detail: ApiFailure.from(error).message,
                  ),
                ],
              AsyncData(:final value) when value.isEmpty => [
                  const LizmoMessageState(
                    tone: LizmoMessageTone.neutral,
                    icon: Icons.receipt_long_outlined,
                    title: 'No invoices yet',
                    detail: 'Lizmo invoices a property on the 1st of each month '
                        'for the beds and units let that day. Anything empty '
                        'costs nothing.',
                  ),
                ],
              AsyncData(:final value) => [
                  for (final invoice in value) _Invoice(invoice: invoice),
                ],
              _ => [const Center(child: CircularProgressIndicator())],
            },
          ],
        ),
      ),
    );
  }
}

class _HowToPay extends StatelessWidget {
  const _HowToPay({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('lizmo-how-to-pay'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.tealBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to pay Lizmo',
              style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
          const SizedBox(height: 4),
          Text(
            // Said honestly when missing, rather than leaving a landlord to
            // guess where the money goes.
            text ??
                'Lizmo has not added payment details yet. Contact Lizmo '
                    'support before paying.',
            style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
          ),
        ],
      ),
    );
  }
}

class _Invoice extends ConsumerStatefulWidget {
  const _Invoice({required this.invoice});

  final PlatformInvoiceResponse invoice;

  @override
  ConsumerState<_Invoice> createState() => _InvoiceState();
}

class _InvoiceState extends ConsumerState<_Invoice> {
  bool _sending = false;

  PlatformInvoiceResponse get invoice => widget.invoice;

  Future<void> _pay() async {
    final paid = await PayLizmoSheet.show(
      context,
      propertyName: invoice.propertyName ?? 'This property',
      label: invoice.label ?? 'this month',
      outstanding: invoice.outstanding ?? 0,
    );
    if (paid == null || !mounted) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lizmoBillingApiProvider).payPlatformInvoice(
            invoice.id!,
            PlatformPaymentRequest(
              amountPaid: paid.amount,
              paymentMethod: paid.method,
              remarks: paid.note,
            ),
            proof: http.MultipartFile.fromBytes('proof', paid.proofBytes,
                filename: paid.proofName),
          );
      messenger.showSnackBar(const SnackBar(
        content: Text('Sent to Lizmo. They will confirm it.'),
      ));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      ref.invalidate(myLizmoInvoicesProvider);
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final beds = invoice.occupiedBeds ?? 0;
    final units = invoice.occupiedUnits ?? 0;
    final counted = [
      if (beds > 0)
        '$beds ${beds == 1 ? 'bed' : 'beds'} × ₱${(invoice.bedRate ?? 0).toStringAsFixed(0)}',
      if (units > 0)
        '$units ${units == 1 ? 'unit' : 'units'} × ₱${(invoice.unitRate ?? 0).toStringAsFixed(0)}',
    ].join(' + ');

    return Container(
      key: ValueKey('invoice-${invoice.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.propertyName ?? 'A property',
                        style:
                            LizmoType.rowName.copyWith(color: LizmoColors.ink)),
                    const SizedBox(height: 2),
                    Text('${invoice.label} · $counted',
                        style: LizmoType.rowSub.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              _Chip(invoice: invoice),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Figure('Due', invoice.amountDue)),
              Expanded(child: _Figure('Paid', invoice.amountPaid)),
              Expanded(child: _Figure('Still owed', invoice.outstanding)),
            ],
          ),
          if ((invoice.outstanding ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              lizmoInvoiceStanding(invoice),
              style: LizmoType.rowSub.copyWith(
                fontSize: 11,
                color: invoice.overdue == true ? LizmoColors.red : null,
              ),
            ),
          ],
          for (final payment in invoice.payments) _Sent(payment: payment),
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (lizmoInvoiceNeedsPaying(invoice)) ...[
            const SizedBox(height: 12),
            // Full width: in a start-aligned column it shrank to its label,
            // with the text pressed against its own border.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: ValueKey('pay-invoice-${invoice.id}'),
                onPressed: _pay,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE3E8E6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('I have paid this',
                    style: LizmoType.rowName
                        .copyWith(color: LizmoColors.teal900)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.invoice});

  final PlatformInvoiceResponse invoice;

  @override
  Widget build(BuildContext context) {
    final status = invoice.status?.toJson();
    if (status == 'PAID') {
      return const StatusChip(status: LizmoStatus.paid, label: 'Paid');
    }
    if (lizmoInvoiceAwaitingLizmo(invoice)) {
      return const StatusChip(
          status: LizmoStatus.pending, label: 'Checking');
    }
    if (invoice.lockedByThis == true) {
      return const StatusChip(status: LizmoStatus.overdue, label: 'Locked');
    }
    if (invoice.overdue == true) {
      return const StatusChip(status: LizmoStatus.overdue, label: 'Overdue');
    }
    if (status == 'PARTIALLY_PAID') {
      return const StatusChip(
          status: LizmoStatus.pending, label: 'Partly paid');
    }
    return const StatusChip(status: LizmoStatus.vacant, label: 'Unpaid');
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.amount);

  final String label;
  final num? amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LizmoType.rowSub.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text('₱${(amount ?? 0).toStringAsFixed(0)}',
            style: LizmoType.dataMedium.copyWith(color: LizmoColors.ink)),
      ],
    );
  }
}

/// A payment sent against the invoice, and what Lizmo made of it.
class _Sent extends StatelessWidget {
  const _Sent({required this.payment});

  final PlatformPaymentResponse payment;

  @override
  Widget build(BuildContext context) {
    final (what, ink) = switch (payment.status?.toJson()) {
      'CONFIRMED' => ('Confirmed', LizmoColors.teal900),
      'REJECTED' => ('Not confirmed', LizmoColors.red),
      _ => ('Waiting for Lizmo to check', LizmoColors.amberText),
    };
    final remarks = payment.remarks;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LizmoColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₱${(payment.amountPaid ?? 0).toStringAsFixed(0)} sent '
            '${lizmoDay(payment.paymentDate)} · $what',
            style: LizmoType.rowSub.copyWith(color: ink),
          ),
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(remarks,
                style: LizmoType.rowSub
                    .copyWith(fontSize: 11, color: LizmoColors.ink)),
          ],
        ],
      ),
    );
  }
}
