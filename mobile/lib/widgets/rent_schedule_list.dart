import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Rent, month by month.
///
/// The same list on both sides of the app. What a tenant owes and what a
/// landlord is owed are the same rows read from different ends, and two
/// renderings of one ledger is how the two sides start disagreeing about the
/// same money.
///
/// Overdue months on top, oldest first: they are what needs doing, in the
/// order it should be done. Everything else newest first, though the server
/// sends oldest first, because the month somebody opens this to check is
/// almost always the current one.
///
/// It was newest first throughout, which held until a month went unpaid --
/// then the one card that needed acting on sat below a month already paid.
class RentScheduleList extends StatelessWidget {
  const RentScheduleList({
    super.key,
    required this.periods,
    this.emptyDetail,
    this.onTap,
    this.header,
    this.payments = const [],
    this.confirmer,
  });

  /// What the tenant has said they paid, so a month already declared says
  /// it is waiting rather than offering "I have paid" a second time.
  final List<PaymentResponse> payments;

  /// Who has to confirm it, by name when known: "Waiting for Maria".
  final String? confirmer;

  /// Shown above the months, scrolling with them: how to pay, on the tenant's
  /// Rent tab.
  final Widget? header;

  final List<BillingPeriodResponse> periods;

  /// What tapping a month does, if anything. Null on a read-only list rather
  /// than a no-op callback: a row that looks tappable and is not is worse than
  /// one that plainly is not.
  final void Function(BillingPeriodResponse)? onTap;

  /// What to say when a tenancy has no months yet, which happens for a lease
  /// that starts in the future.
  final String? emptyDetail;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return LizmoMessageState(
        icon: Icons.receipt_long_outlined,
        title: 'Nothing due yet',
        detail: emptyDetail ??
            'The first month appears once the tenancy has started.',
      );
    }

    bool late(BillingPeriodResponse period) =>
        period.overdue == true &&
        period.status != BillingPeriodResponseStatusEnum.PAID;
    final newestFirst = [
      ...periods.where(late),
      ...periods.reversed.where((period) => !late(period)),
    ];

    final top = header;
    final offset = top == null ? 0 : 1;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: newestFirst.length + offset,
      separatorBuilder: (_, index) =>
          SizedBox(height: top != null && index == 0 ? 16 : 8),
      itemBuilder: (_, index) => top != null && index == 0
          ? top
          : _MonthRow(
              period: newestFirst[index - offset],
              onTap: onTap,
              waiting: [
                for (final payment in payments)
                  if (payment.billingPeriodId == newestFirst[index - offset].id &&
                      payment.status ==
                          PaymentResponseStatusEnum.PENDING_VERIFICATION)
                    payment,
              ],
              confirmer: confirmer,
            ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.period,
    this.onTap,
    this.waiting = const [],
    this.confirmer,
  });

  final BillingPeriodResponse period;
  final void Function(BillingPeriodResponse)? onTap;

  /// Declared towards this month and not yet answered.
  final List<PaymentResponse> waiting;
  final String? confirmer;

  @override
  Widget build(BuildContext context) {
    final paid = period.status == BillingPeriodResponseStatusEnum.PAID;
    final overdue = period.overdue == true;

    // Late is louder than unpaid. Rent that is merely not yet due is the
    // ordinary state of the current month and should not look like a problem.
    final (Color background, Color ink, String label) = paid
        ? (LizmoColors.tealBg, LizmoColors.teal900, 'Paid')
        : overdue
            ? (LizmoColors.redBg, LizmoColors.red, 'Overdue')
            : (LizmoColors.white, LizmoColors.ink, 'Due');

    // What the tenant has said they paid towards this month. Covering it,
    // the month waits on the landlord, and offering "I have paid" again only
    // invites the same money to be declared twice.
    final declared =
        waiting.fold<num>(0, (sum, payment) => sum + (payment.amountPaid ?? 0));
    final covered = declared > 0 && declared >= (period.outstanding ?? 0);

    // A settled month has nothing to declare against it.
    final declarable = onTap != null && !paid && !covered;

    // Paid is one line. The three figures were the same 2,500 three ways
    // plus "Settled" underneath, which made a month with nothing left to do
    // the tallest thing on the screen.
    if (paid) {
      return Container(
        key: ValueKey('paid-${period.id}'),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                period.label ?? '',
                style: LizmoType.rowName.copyWith(color: ink),
              ),
            ),
            Text(
              LizmoMoney.peso(period.amountPaid),
              style: LizmoType.dataMedium.copyWith(color: ink),
            ),
            const SizedBox(width: 10),
            StatusChip(label: label, status: _status(paid, overdue)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: background == LizmoColors.white
            ? Border.all(color: const Color(0xFFE3E8E6))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  period.label ?? '',
                  style: LizmoType.rowName.copyWith(color: ink),
                ),
              ),
              StatusChip(label: label, status: _status(paid, overdue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Due',
                  value: LizmoMoney.peso(period.amountDue),
                  ink: ink,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Paid',
                  value: LizmoMoney.peso(period.amountPaid),
                  ink: ink,
                ),
              ),
              Expanded(
                child: _Figure(
                  // The number somebody actually came to find, so no screen
                  // has to do the subtraction and none can get it wrong.
                  label: 'Outstanding',
                  value: LizmoMoney.peso(period.outstanding),
                  ink: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due ${_readable(period.dueDate)}',
                  style: LizmoType.rowSub.copyWith(fontSize: 11, color: ink),
                ),
              ),
              if (declared > 0)
                Text(
                  _waitingFor(declared, covered),
                  key: ValueKey('waiting-${period.id}'),
                  style: LizmoType.rowSub.copyWith(
                    fontSize: 11,
                    color: LizmoColors.teal900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              // A button, as on Home. It was "Tap if you have paid" in 11px
              // under the figures, on the screen that exists for rent, while
              // Home gave the same action a coral button.
              if (declarable)
                Material(
                  color: LizmoColors.coral,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    key: ValueKey('i-paid-${period.id}'),
                    onTap: () => onTap!(period),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text('I have paid',
                          style: LizmoType.buttonLabel.copyWith(fontSize: 13)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Waiting for Maria · 4 days", or with how much when it is only part.
  String _waitingFor(num declared, bool covered) {
    final who = confirmer ?? 'your landlord';
    final since = waiting
        .map((payment) => payment.declaredAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (oldest, at) =>
            oldest == null || at.isBefore(oldest) ? at : oldest);
    final age = since == null ? '' : ' · ${waitedFor(since)}';
    return covered
        ? 'Waiting for $who$age'
        : '${LizmoMoney.peso(declared)} waiting for $who$age';
  }

  /// The design system already has the vocabulary for this: paid, overdue, and
  /// a deliberately grey "nothing is happening here" for rent that is simply
  /// not due yet.
  static LizmoStatus _status(bool paid, bool overdue) {
    if (paid) return LizmoStatus.paid;
    return overdue ? LizmoStatus.overdue : LizmoStatus.vacant;
  }


  static String _readable(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
        Text(label,
            style: LizmoType.rowSub.copyWith(fontSize: 11, color: ink)),
        const SizedBox(height: 2),
        Text(value, style: LizmoType.dataMedium.copyWith(color: ink)),
      ],
    );
  }
}

/// How long something has been waiting, in days: "today", "1 day", "4 days".
///
/// Whole days, because the reminders it sits beside are daily and "3 days
/// 4 hours" is precision nobody acts on.
String waitedFor(DateTime since, {DateTime? now}) {
  final days = (now ?? DateTime.now()).difference(since.toLocal()).inDays;
  if (days <= 0) return 'today';
  return days == 1 ? '1 day' : '$days days';
}
