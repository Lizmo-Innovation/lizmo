import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../platform/lizmo_billing_providers.dart';
import '../widgets/lizmo_payment_channels.dart';
import '../widgets/lizmo_statement_card.dart';
import '../widgets/pay_lizmo_sheet.dart';

/// What this landlord owes Lizmo, how to pay it, and what was paid.
///
/// One statement a month for the whole account, counted on the 1st: P50 for
/// each let bed and P150 for each let whole unit, nothing for anything empty.
/// It breaks down by property, because a number a landlord cannot check is a
/// number they telephone about -- and once it is paid each property gets an
/// invoice of its own, numbered and dated, to file against that building.
class LizmoBillingScreen extends ConsumerWidget {
  const LizmoBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statements = ref.watch(myLizmoStatementsProvider);
    final payment = ref.watch(lizmoPaymentDetailsProvider);

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
          ref.invalidate(myLizmoStatementsProvider);
          ref.invalidate(lizmoPaymentDetailsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HowToPay(details: payment),
            const SizedBox(height: 16),
            ...switch (statements) {
              AsyncError(:final error) => [
                  LizmoMessageState(
                    tone: LizmoMessageTone.problem,
                    icon: Icons.error_outline,
                    title: 'Could not load your statements',
                    detail: ApiFailure.from(error).message,
                  ),
                ],
              AsyncData(:final value) when value.isEmpty => [
                  const LizmoMessageState(
                    tone: LizmoMessageTone.neutral,
                    icon: Icons.receipt_long_outlined,
                    title: 'No statements yet',
                    detail: 'Lizmo bills you on the 1st of each month for the '
                        'beds and units let that day, across all your '
                        'properties. Anything empty costs nothing.',
                  ),
                ],
              AsyncData(:final value) => [
                  for (final statement in value) _Statement(statement: statement),
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
  const _HowToPay({required this.details});

  final AsyncValue<PaymentDetails> details;

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (details) {
      AsyncData(:final value) => LizmoPaymentChannels(details: value),
      // Unknown is not "none": a failed load saying Lizmo has no details
      // would send somebody to support over a bad connection.
      AsyncError() => Text('Could not load how to pay. Pull down to try again.',
          style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
      _ => const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
    };

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
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

class _Statement extends ConsumerStatefulWidget {
  const _Statement({required this.statement});

  final PlatformStatementResponse statement;

  @override
  ConsumerState<_Statement> createState() => _StatementState();
}

class _StatementState extends ConsumerState<_Statement> {
  bool _sending = false;

  PlatformStatementResponse get statement => widget.statement;

  Future<void> _pay() async {
    final paid = await PayLizmoSheet.show(
      context,
      label: statement.label ?? 'this month',
      covers: lizmoProperties(statement),
      outstanding: statement.outstanding ?? 0,
      // Already loaded for the screen behind; null while it still loads or if
      // it failed, and the sheet then simply leaves the list out.
      payment: ref.read(lizmoPaymentDetailsProvider).valueOrNull,
    );
    if (paid == null || !mounted) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lizmoBillingApiProvider).payPlatformStatement(
            statement.id!,
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
      ref.invalidate(myLizmoStatementsProvider);
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('statement-${statement.id}'),
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
                    Text(statement.label ?? 'This month',
                        style:
                            LizmoType.rowName.copyWith(color: LizmoColors.ink)),
                    const SizedBox(height: 2),
                    Text(lizmoProperties(statement),
                        style: LizmoType.rowSub.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              _Chip(statement: statement),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Figure('Due', statement.amountDue)),
              Expanded(child: _Figure('Paid', statement.amountPaid)),
              Expanded(child: _Figure('Still owed', statement.outstanding)),
            ],
          ),
          if ((statement.outstanding ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              lizmoStatementStanding(statement),
              style: LizmoType.rowSub.copyWith(
                fontSize: 11,
                color: statement.overdue == true ? LizmoColors.red : null,
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final line in statement.lines) _Line(line: line),
          for (final payment in statement.payments) _Sent(payment: payment),
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (lizmoStatementNeedsPaying(statement)) ...[
            const SizedBox(height: 12),
            // Full width: in a start-aligned column it shrank to its label,
            // with the text pressed against its own border.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: ValueKey('pay-statement-${statement.id}'),
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

/// One property's share of the month, and its invoice once the statement is paid.
class _Line extends StatelessWidget {
  const _Line({required this.line});

  final PlatformInvoiceLine line;

  @override
  Widget build(BuildContext context) {
    final beds = line.occupiedBeds ?? 0;
    final units = line.occupiedUnits ?? 0;
    final counted = [
      if (beds > 0)
        '$beds ${beds == 1 ? 'bed' : 'beds'} × ₱${(line.bedRate ?? 0).toStringAsFixed(0)}',
      if (units > 0)
        '$units ${units == 1 ? 'unit' : 'units'} × ₱${(line.unitRate ?? 0).toStringAsFixed(0)}',
    ].join(' + ');
    final invoice = line.invoiceNumber;

    return Container(
      key: ValueKey('statement-line-${line.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LizmoColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(line.propertyName ?? 'A property',
                    style: LizmoType.rowName
                        .copyWith(fontSize: 13, color: LizmoColors.ink)),
              ),
              Text('₱${(line.amountDue ?? 0).toStringAsFixed(0)}',
                  style: LizmoType.dataMedium.copyWith(color: LizmoColors.ink)),
            ],
          ),
          const SizedBox(height: 2),
          Text(counted, style: LizmoType.rowSub.copyWith(fontSize: 11)),
          // Only once the statement is paid: until then there is no invoice to
          // name, and a blank number would read as one gone missing.
          if (invoice != null) ...[
            const SizedBox(height: 2),
            Text(
              'Invoice $invoice · issued ${lizmoDay(line.issuedAt)}',
              style: LizmoType.rowSub
                  .copyWith(fontSize: 11, color: LizmoColors.teal900),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.statement});

  final PlatformStatementResponse statement;

  @override
  Widget build(BuildContext context) {
    final status = statement.status?.toJson();
    if (status == 'PAID') {
      return const StatusChip(status: LizmoStatus.paid, label: 'Paid');
    }
    if (lizmoStatementAwaitingLizmo(statement)) {
      return const StatusChip(status: LizmoStatus.pending, label: 'Checking');
    }
    if (statement.locked == true) {
      return const StatusChip(status: LizmoStatus.overdue, label: 'Locked');
    }
    if (statement.overdue == true) {
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

/// A payment sent against the statement, and what Lizmo made of it.
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
      margin: const EdgeInsets.only(bottom: 8),
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
