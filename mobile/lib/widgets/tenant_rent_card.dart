import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';

/// Rent on one tenancy, as the landlord deals with it.
///
/// Two things at once, because they are the two questions a landlord opens a
/// tenant to ask: what is outstanding, and is anybody waiting on me. The
/// second matters more — a tenant who said they paid three days ago and has
/// heard nothing is the failure this whole feature exists to avoid.
class TenantRentCard extends ConsumerStatefulWidget {
  const TenantRentCard({super.key, required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<TenantRentCard> createState() => _TenantRentCardState();
}

class _TenantRentCardState extends ConsumerState<TenantRentCard> {
  bool _working = false;

  Future<void> _answer(PaymentResponse payment, {required bool agreed}) async {
    if (!agreed) {
      final why = await _WhyNot.ask(context);
      // Null means they backed out of the dialog, which is not a rejection.
      if (why == null || !mounted) return;
      await _send(() => ref.read(rentApiProvider).rejectPayment(
            widget.leaseId,
            payment.id!,
            remarks: why.isEmpty ? null : why,
          ));
      return;
    }

    await _send(() => ref.read(rentApiProvider).confirmPayment(
          widget.leaseId,
          payment.id!,
        ));
  }

  Future<void> _send(Future<void> Function() call) async {
    setState(() => _working = true);
    try {
      await call();
      ref.invalidate(leaseBillingProvider(widget.leaseId));
      ref.invalidate(leasePaymentsProvider(widget.leaseId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiFailure.from(error).message),
        ));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(leaseBillingProvider(widget.leaseId));
    final payments = ref.watch(leasePaymentsProvider(widget.leaseId));

    final months = billing.valueOrNull ?? const <BillingPeriodResponse>[];
    final waiting = (payments.valueOrNull ?? const <PaymentResponse>[])
        .where((payment) =>
            payment.status == PaymentResponseStatusEnum.PENDING_VERIFICATION)
        .toList();

    final owed = months.fold<num>(0, (sum, month) => sum + (month.outstanding ?? 0));
    final late = months.where((month) => month.overdue == true).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rent', style: LizmoType.sectionHeading),
          const SizedBox(height: 10),

          if (billing.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (months.isEmpty)
            Text('Nothing due yet.', style: LizmoType.rowSub)
          else
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Outstanding',
                    value: '₱${owed.toStringAsFixed(0)}',
                    ink: owed > 0 ? LizmoColors.ink : LizmoColors.teal900,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: late == 1 ? 'Month late' : 'Months late',
                    value: '$late',
                    ink: late > 0 ? LizmoColors.red : LizmoColors.slate,
                  ),
                ),
              ],
            ),

          if (waiting.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE3E8E6)),
            const SizedBox(height: 12),
            Text(
              waiting.length == 1
                  ? 'One payment is waiting on you'
                  : '${waiting.length} payments are waiting on you',
              style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
            ),
            const SizedBox(height: 8),
            for (final payment in waiting)
              _Waiting(
                payment: payment,
                busy: _working,
                onAnswer: (agreed) => _answer(payment, agreed: agreed),
              ),
          ],
        ],
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.payment,
    required this.busy,
    required this.onAnswer,
  });

  final PaymentResponse payment;
  final bool busy;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LizmoColors.amberBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₱${(payment.amountPaid ?? 0).toStringAsFixed(0)} for '
              '${payment.periodLabel ?? 'rent'}',
              style: LizmoType.rowName.copyWith(color: LizmoColors.amberText),
            ),
            const SizedBox(height: 2),
            Text(
              _method(payment.paymentMethod),
              style: LizmoType.rowSub
                  .copyWith(fontSize: 11, color: LizmoColors.amberText),
            ),
            if (payment.proofUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  payment.proofUrl!,
                  height: 120,
                  fit: BoxFit.cover,
                  // The link is presigned and lapses in minutes; an expired
                  // one is an ordinary outcome, not an error worth a dialog.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('reject-${payment.id}'),
                    onPressed: busy ? null : () => onAnswer(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LizmoColors.red,
                      side: const BorderSide(color: Color(0xFFE3E8E6)),
                    ),
                    child: const Text('Not received'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('confirm-${payment.id}'),
                    onPressed: busy ? null : () => onAnswer(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: LizmoColors.teal900,
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _method(PaymentResponsePaymentMethodEnum? method) {
    return switch (method?.toJson()) {
      'GCASH' => 'Paid by GCash',
      'MAYA' => 'Paid by Maya',
      'BANK_TRANSFER' => 'Paid by bank transfer',
      'CASH' => 'Paid in cash',
      'ADVANCE' => 'Advance rent',
      _ => 'Paid some other way',
    };
  }
}

/// Why a payment was refused.
///
/// Asked rather than assumed, because the tenant is told the answer and
/// "not confirmed" with no reason is how a disagreement becomes a row.
class _WhyNot extends StatefulWidget {
  const _WhyNot();

  static Future<String?> ask(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _WhyNot(),
    );
  }

  @override
  State<_WhyNot> createState() => _WhyNotState();
}

class _WhyNotState extends State<_WhyNot> {
  final _why = TextEditingController();

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Say it did not arrive?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your tenant sees this, so a line about what happened saves a '
            'conversation.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('reject-reason'),
            controller: _why,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Nothing arrived in my GCash.',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('reject-confirm'),
          onPressed: () => Navigator.of(context).pop(_why.text.trim()),
          child: Text('Not received',
              style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.ink});

  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LizmoType.rowSub.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: LizmoType.dataMedium.copyWith(color: ink)),
      ],
    );
  }
}
