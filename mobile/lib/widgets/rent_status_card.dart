import 'rent_schedule_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/period_kind.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../tenant/rent_status.dart';
import '../tenant/tenant_providers.dart';
import 'declare_payment_sheet.dart';

/// The first thing on a tenant's Home: where they stand with their rent.
///
/// One card, one message, picked by [rentStatus]. Its colour and first line say
/// it before anything is read -- teal done, white coming up or with the
/// landlord, amber look at this, red overdue -- and it only offers buttons when
/// there is something for the tenant to do. Paid and waiting have none: the
/// second is exactly when a tenant must not be asked to pay twice.
class RentStatusCard extends ConsumerWidget {
  const RentStatusCard({super.key, required this.lease});

  final LeaseResponse lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaseId = lease.id!;
    // No months, no card: loading or failed, "paid up" over a list that never
    // arrived would be a false all-clear. The Rent tab says why.
    final months = ref.watch(myBillingProvider(leaseId)).valueOrNull;
    // Payments that failed to load read as none -- the months alone still say
    // what is due and what is late -- but loading ones are waited for, since a
    // card that said "due" and then "waiting" a moment later would ask for a
    // payment already made.
    final paymentsState = ref.watch(myPaymentsProvider(leaseId));
    final payments =
        paymentsState.valueOrNull ?? (paymentsState.hasError ? const <PaymentResponse>[] : null);
    // Watched, not read, so the account to copy -- and the sheet behind
    // "I have paid" -- have the landlord's details by the time they are needed.
    final details = ref.watch(leasePaymentDetailsProvider(leaseId)).valueOrNull;
    if (months == null || payments == null) return const SizedBox.shrink();

    final status = rentStatus(
      months: months,
      payments: payments,
      today: ref.watch(todayProvider),
      dueDay: lease.dueDateDay ?? 1,
      rent: lease.rentAmount,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KeyedSubtree(
        key: const ValueKey('rent-due'),
        child: switch (status) {
          RentPaid() => _paid(status),
          RentDueSoon() => _dueSoon(ref, status, details),
          RentWaiting() => _waiting(status),
          RentNotReceived() => _notReceived(ref, status),
          RentLate() => _late(ref, status),
        },
      ),
    );
  }

  Widget _paid(RentPaid status) {
    final last = status.lastPaid?.label;
    final amount = status.amount;
    return _StatusCard(
      tone: _Tone.done,
      icon: Icons.check_circle_outline,
      kicker: 'Paid up',
      headline: last == null ? 'Nothing to pay yet' : 'You\'re all set for $last',
      body: amount == null
          ? 'Your next rent is due on ${_day(status.nextDue)}.'
          : 'Next rent: ${_peso(amount)} on ${_day(status.nextDue)}.',
    );
  }

  Widget _dueSoon(WidgetRef ref, RentDueSoon status, PaymentDetails? details) {
    final period = status.period;
    final days = status.daysLeft;
    // The first account the landlord listed: the one they want used. Hidden
    // ones never reach the tenant, so it is always one they can pay into.
    final account = details?.channels.firstOrNull;
    return _StatusCard(
      tone: _Tone.plain,
      icon: Icons.event_outlined,
      kicker: switch (days) {
        0 => 'Due today',
        1 => 'Due tomorrow',
        _ => 'Due in $days days',
      },
      headline: '${_peso(period.outstanding ?? 0)} due on ${_day(period.dueDate)}',
      body: '${period.whatFor}.',
      extra: account == null ? null : _CopyAccount(account: account),
      primary: _Action('I have paid', (context) => _declare(context, ref, period)),
      secondary: _Action('How to pay', _howToPay),
    );
  }

  Widget _waiting(RentWaiting status) {
    final payment = status.payment;
    final paid = _peso(payment.amountPaid ?? 0);
    final on = payment.paymentDate;
    final told = payment.declaredAt;
    return _StatusCard(
      tone: _Tone.plain,
      icon: Icons.hourglass_empty,
      // How long, so "waiting" from this morning and from a fortnight ago do
      // not read the same. Lizmo reminds the landlord after three days.
      kicker: told == null
          ? 'Waiting for your landlord'
          : 'Waiting for your landlord · ${waitedFor(told)}',
      headline: on == null ? 'You paid $paid' : 'You paid $paid on ${_day(on)}',
      body: '${payment.sentTo == null ? '' : 'Sent to ${payment.sentTo}. '}'
          '${status.period.named} counts as paid once they confirm it.',
    );
  }

  Widget _notReceived(WidgetRef ref, RentNotReceived status) {
    final payment = status.payment;
    final reason = payment.rejectionReason;
    return _StatusCard(
      tone: _Tone.attention,
      icon: Icons.error_outline,
      kicker: 'Not received',
      headline:
          'Your landlord didn\'t find your ${_peso(payment.amountPaid ?? 0)}',
      // Their words, quoted, so it is clear whose they are.
      body: reason == null
          ? 'They didn\'t say why. Check with them, or tell them again.'
          : '"$reason"',
      primary: _Action(
          'Tell them again', (context) => _declare(context, ref, status.period)),
      secondary: _Action('How to pay', _howToPay),
    );
  }

  Widget _late(WidgetRef ref, RentLate status) {
    final count = status.months.length;
    final waiting = status.waiting;
    return _StatusCard(
      tone: _Tone.late,
      icon: Icons.schedule,
      kicker: count == 1 ? 'Late' : '$count months late',
      headline: '${_peso(status.total)} overdue',
      body: count == 1
          ? '${status.oldest.named} was due on ${_day(status.oldest.dueDate)}.'
          : '$count months are unpaid, the oldest since '
              '${_day(status.oldest.dueDate)}.',
      // Still late until the landlord confirms, but not asked for twice.
      note: waiting == null
          ? null
          : 'You paid ${_peso(waiting.amountPaid ?? 0)}'
              '${waiting.paymentDate == null ? '' : ' on ${_day(waiting.paymentDate)}'}. '
              'Waiting for your landlord to confirm it.',
      primary: waiting == null
          ? _Action('I have paid', (context) => _declare(context, ref, status.oldest))
          : null,
      secondary: _Action('How to pay', _howToPay),
    );
  }

  static void _howToPay(BuildContext context) => context.go(Routes.tenantPayments);

  Future<void> _declare(
    BuildContext context,
    WidgetRef ref,
    BillingPeriodResponse period,
  ) async {
    final said = await DeclarePaymentSheet.show(
      context,
      periodLabel: period.label ?? 'this month',
      outstanding: period.outstanding ?? 0,
      payment: ref.read(leasePaymentDetailsProvider(lease.id!)).valueOrNull,
    );
    if (said == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await sendDeclaration(ref, leaseId: lease.id!, period: period, said: said);
      messenger.showSnackBar(const SnackBar(
        content: Text('Told your landlord. They will confirm it.'),
      ));
      if (context.mounted) offerPushesAfterDeclaring(context, ref);
    } on ApiFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _day(DateTime? date) =>
      date == null ? '' : '${date.day} ${_months[date.month - 1]}';

  static String _peso(num amount) => LizmoMoney.peso(amount.round());
}

enum _Tone { done, plain, attention, late }

class _Action {
  const _Action(this.label, this.onTap);

  final String label;
  final void Function(BuildContext) onTap;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.tone,
    required this.icon,
    required this.kicker,
    required this.headline,
    required this.body,
    this.note,
    this.extra,
    this.primary,
    this.secondary,
  });

  final _Tone tone;
  final IconData icon;
  final String kicker;
  final String headline;
  final String body;
  final String? note;
  final Widget? extra;
  final _Action? primary;
  final _Action? secondary;

  @override
  Widget build(BuildContext context) {
    final (background, ink, muted) = switch (tone) {
      _Tone.done => (LizmoColors.tealBg, LizmoColors.teal900, LizmoColors.teal900),
      _Tone.plain => (LizmoColors.white, LizmoColors.ink, LizmoColors.slate),
      _Tone.attention => (LizmoColors.amberBg, LizmoColors.amberText, LizmoColors.amberText),
      _Tone.late => (LizmoColors.redBg, LizmoColors.red, LizmoColors.red),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: tone == _Tone.plain ? Border.all(color: const Color(0xFFE3E8E6)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(kicker,
                    key: const ValueKey('rent-status-kicker'),
                    style: LizmoType.rowSub.copyWith(
                        color: muted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(headline,
              style: LizmoType.rowName.copyWith(fontSize: 17, color: ink)),
          const SizedBox(height: 4),
          Text(body, style: LizmoType.rowSub.copyWith(fontSize: 13, color: ink)),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note!,
                key: const ValueKey('rent-status-note'),
                style: LizmoType.rowSub.copyWith(fontSize: 13, color: ink)),
          ],
          if (extra != null) ...[
            const SizedBox(height: 12),
            extra!,
          ],
          if (primary != null || secondary != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (primary case final action?)
                  // Coral: the one action on Home that matters most.
                  Material(
                    color: LizmoColors.coral,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      key: ValueKey('rent-status-${action.label}'),
                      onTap: () => action.onTap(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(action.label,
                            style: LizmoType.buttonLabel.copyWith(fontSize: 13)),
                      ),
                    ),
                  ),
                if (secondary case final action?)
                  InkWell(
                    key: ValueKey('rent-status-${action.label}'),
                    onTap: () => action.onTap(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Text(
                        action.label,
                        style: LizmoType.rowName.copyWith(
                          fontSize: 13,
                          color: ink,
                          decoration: TextDecoration.underline,
                          decorationColor: ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The landlord's first account, with its number a tap away from the
/// clipboard: it is about to be pasted into GCash, and retyped digits are how
/// money goes to the wrong account.
class _CopyAccount extends StatefulWidget {
  const _CopyAccount({required this.account});

  final PaymentChannelView account;

  @override
  State<_CopyAccount> createState() => _CopyAccountState();
}

class _CopyAccountState extends State<_CopyAccount> {
  bool _copied = false;

  Future<void> _copy() async {
    final number = widget.account.accountNumber ?? '';
    if (number.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: number));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return InkWell(
      key: const ValueKey('rent-status-copy'),
      onTap: _copy,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: LizmoColors.canvas,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${account.channel ?? ''} · ${account.accountName ?? ''}',
                      style: LizmoType.rowSub.copyWith(color: LizmoColors.slate)),
                  const SizedBox(height: 2),
                  Text(account.accountNumber ?? '',
                      style: LizmoType.dataMedium.copyWith(color: LizmoColors.ink)),
                ],
              ),
            ),
            Icon(_copied ? Icons.check : Icons.copy_outlined,
                size: 18, color: LizmoColors.teal900),
            if (_copied) ...[
              const SizedBox(width: 4),
              Text('Copied',
                  style: LizmoType.rowSub
                      .copyWith(fontSize: 11, color: LizmoColors.teal900)),
            ],
          ],
        ),
      ),
    );
  }
}
