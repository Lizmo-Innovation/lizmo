import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';
import '../widgets/admin_shell.dart';
import '../widgets/platform_payment_card.dart';

/// Payments landlords have made to Lizmo, waiting to be verified.
///
/// A queue across every landlord rather than something you hunt for one at a
/// time: checking proofs of payment is a batch job done at one sitting. Oldest
/// first, so whoever has waited longest is answered first.
///
/// A payment is against a statement, never one property: the landlord pays once
/// for the month. Confirming the last of it issues an invoice for each property
/// on it, which is why the row says how many there are.
///
/// This screen once rendered five hardcoded rows with buttons wired to nothing,
/// and then said honestly that nothing could arrive. Statements are raised now,
/// so payments do.
class PlatformPaymentsScreen extends ConsumerWidget {
  const PlatformPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(platformPaymentsProvider);

    return AdminShell(
      title: 'Payments',
      child: payments.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => LizmoMessageState(
          icon: Icons.cloud_off_outlined,
          tone: LizmoMessageTone.problem,
          title: 'Could not load payments',
          detail: ApiFailure.from(error).message,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(platformPaymentsProvider),
        ),
        data: (rows) => rows.isEmpty
            ? const LizmoMessageState(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing to review',
                detail: 'Payments appear here when a landlord sends proof '
                    'against a Lizmo statement.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                children: [for (final row in rows) _Review(payment: row)],
              ),
      ),
    );
  }
}

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.payment});

  final PlatformPaymentForAdmin payment;

  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  bool _busy = false;

  PlatformPaymentForAdmin get payment => widget.payment;

  static const _methods = {
    'GCASH': 'GCash',
    'MAYA': 'Maya',
    'BANK_TRANSFER': 'Bank transfer',
    'CASH': 'Cash',
  };

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<void> _answer(Future<void> Function() call, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      ref.invalidate(platformPaymentsProvider);
      final landlord = payment.landlordId;
      if (landlord != null) {
        ref.invalidate(landlordStatementsProvider(landlord));
        ref.invalidate(landlordProvider(landlord));
      }
      ref.invalidate(landlordsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final why = await _NotReceived.ask(context);
    if (why == null || !mounted) return;
    await _answer(
      () => ref.read(adminApiProvider).rejectPlatformPayment(
            payment.id!,
            platformPaymentRejection:
                PlatformPaymentRejection(remarks: why.isEmpty ? null : why),
          ),
      'Marked as not received. The landlord is told why.',
    );
  }

  void _viewProof() {
    final url = payment.proofUrl;
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'The proof could not be loaded. The link lasts ten '
                        'minutes; reload the queue for a fresh one.',
                        style: LizmoType.rowSub,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = payment.paymentDate;
    final paid = date == null ? '' : ' · paid ${date.day} ${_months[date.month - 1]}';
    final method = _methods[payment.paymentMethod?.toJson()] ?? 'Other';
    final note = payment.remarks;
    // How many properties the statement covers, which is why the figure is
    // what it is -- and how many invoices confirming it will issue.
    final properties = payment.properties ?? 0;
    final covers = properties == 1 ? '1 property' : '$properties properties';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformPaymentCard(
          key: ValueKey('platform-payment-${payment.id}'),
          landlord: '${payment.landlordName ?? 'A landlord'} · $covers',
          subtitle: '$method$paid · for ${payment.statementLabel ?? 'a statement'}, '
              '${LizmoMoney.peso((payment.statementOutstanding ?? 0))} owed'
              '${note == null || note.isEmpty ? '' : ' · "$note"'}',
          amount: LizmoMoney.peso((payment.amountPaid ?? 0)),
          status: LizmoStatus.pending,
          statusLabel: 'To check',
          onConfirm: _busy
              ? null
              : () => _answer(
                    () => ref
                        .read(adminApiProvider)
                        .confirmPlatformPayment(payment.id!),
                    'Confirmed. The landlord is told.',
                  ),
          onReject: _busy ? null : _reject,
          onViewProof: payment.proofUrl == null ? null : _viewProof,
        ),
      ],
    );
  }
}

/// Why it was refused. The landlord reads this, so a line saves a conversation.
class _NotReceived extends StatefulWidget {
  const _NotReceived();

  static Future<String?> ask(BuildContext context) =>
      showDialog<String>(context: context, builder: (_) => const _NotReceived());

  @override
  State<_NotReceived> createState() => _NotReceivedState();
}

class _NotReceivedState extends State<_NotReceived> {
  final _why = TextEditingController();

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as not received?'),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const ValueKey('reject-platform-reason'),
          controller: _why,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Nothing arrived under that reference.',
            helperText: 'The landlord sees this.',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('reject-platform-confirm'),
          onPressed: () => Navigator.of(context).pop(_why.text.trim()),
          child: Text('Not received',
              style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
        ),
      ],
    );
  }
}
