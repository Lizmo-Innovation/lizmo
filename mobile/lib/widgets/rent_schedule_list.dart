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
/// Newest first here, though the server sends oldest first: the month somebody
/// opens this to check is almost always the current one.
class RentScheduleList extends StatelessWidget {
  const RentScheduleList({
    super.key,
    required this.periods,
    this.emptyDetail,
    this.onTap,
    this.header,
  });

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

    final newestFirst = periods.reversed.toList();

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
            ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.period, this.onTap});

  final BillingPeriodResponse period;
  final void Function(BillingPeriodResponse)? onTap;

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

    // A settled month has nothing to declare against it.
    final tappable = onTap != null && !paid;

    final card = Container(
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
                  value: '₱${_money(period.amountDue)}',
                  ink: ink,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Paid',
                  value: '₱${_money(period.amountPaid)}',
                  ink: ink,
                ),
              ),
              Expanded(
                child: _Figure(
                  // The number somebody actually came to find, so no screen
                  // has to do the subtraction and none can get it wrong.
                  label: 'Outstanding',
                  value: '₱${_money(period.outstanding)}',
                  ink: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            paid
                ? 'Settled'
                : tappable
                    ? 'Due ${_readable(period.dueDate)} · Tap if you have paid'
                    : 'Due ${_readable(period.dueDate)}',
            style: LizmoType.rowSub.copyWith(fontSize: 11, color: ink),
          ),
        ],
      ),
    );

    if (!tappable) return card;

    return InkWell(
      key: ValueKey('month-${period.id}'),
      onTap: () => onTap!(period),
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }

  /// The design system already has the vocabulary for this: paid, overdue, and
  /// a deliberately grey "nothing is happening here" for rent that is simply
  /// not due yet.
  static LizmoStatus _status(bool paid, bool overdue) {
    if (paid) return LizmoStatus.paid;
    return overdue ? LizmoStatus.overdue : LizmoStatus.vacant;
  }

  static String _money(num? amount) => (amount ?? 0).toStringAsFixed(0);

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
