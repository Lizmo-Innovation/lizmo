import 'package:lizmo_api/api.dart';

import '../billing/period_kind.dart';

/// Where a tenant stands with their rent, in the one sentence Home leads with.
///
/// Worked out in one place, from the months and payments the app already
/// holds, so the card on Home and anything else that asks agree. Exactly one
/// applies at a time; [rentStatus] picks it.
sealed class RentStatus {
  const RentStatus();
}

/// Nothing is owed that needs the tenant yet.
///
/// Either every month is paid, or the next one is further off than
/// [dueSoonDays]. [nextDue] is when rent next falls due, and [amount] what
/// it will be when that is known.
final class RentPaid extends RentStatus {
  const RentPaid({required this.nextDue, this.amount, this.lastPaid});

  final DateTime nextDue;
  final num? amount;

  /// The latest month fully paid, for "You're all set for September". Null
  /// before anything has been paid.
  final BillingPeriodResponse? lastPaid;
}

/// Rent falls due within [dueSoonDays], and nothing has been said about it.
final class RentDueSoon extends RentStatus {
  const RentDueSoon({required this.period, required this.daysLeft});

  final BillingPeriodResponse period;

  /// 0 on rent day itself.
  final int daysLeft;
}

/// The tenant said they paid, and the landlord has not answered.
final class RentWaiting extends RentStatus {
  const RentWaiting({required this.period, required this.payment});

  final BillingPeriodResponse period;
  final PaymentResponse payment;
}

/// The landlord said the money did not arrive.
///
/// The payment carries the landlord's [PaymentResponse.rejectionReason], when
/// they gave one.
final class RentNotReceived extends RentStatus {
  const RentNotReceived({required this.period, required this.payment});

  final BillingPeriodResponse period;
  final PaymentResponse payment;
}

/// At least one month is past its due date.
///
/// [waiting] is a payment the tenant has declared towards it that the landlord
/// has not answered yet: still late, but the tenant should see their payment
/// was received, not be asked to pay twice.
final class RentLate extends RentStatus {
  const RentLate({
    required this.months,
    required this.total,
    this.waiting,
  });

  /// The overdue months, oldest first.
  final List<BillingPeriodResponse> months;

  /// What is owed across [months].
  final num total;
  final PaymentResponse? waiting;

  BillingPeriodResponse get oldest => months.first;
}

/// How long before rent day Home starts saying rent is due.
///
/// The same as the reminder the server sends (RentReminderService.DAYS_BEFORE),
/// so the card and the notification change on the same day.
const dueSoonDays = 5;

/// Which [RentStatus] a tenant is in today.
///
/// [months] are the tenancy's billing periods and [payments] its payments, as
/// the server sends them; [dueDay] is the lease's rent day and [rent] its
/// monthly rent, for when no month is open yet. [today] is a date; its time is
/// ignored.
///
/// In order: late, then the landlord's answer (or wait for one) on the oldest
/// month owed, then due soon, then paid.
RentStatus rentStatus({
  required List<BillingPeriodResponse> months,
  required List<PaymentResponse> payments,
  required DateTime today,
  required int dueDay,
  num? rent,
}) {
  final day = _date(today);
  final owing = months.where((month) => (month.outstanding ?? 0) > 0).toList()
    ..sort((a, b) => _due(a).compareTo(_due(b)));

  final late = owing.where((month) => month.overdue == true).toList();
  if (late.isNotEmpty) {
    return RentLate(
      months: late,
      total: late.fold<num>(0, (sum, month) => sum + (month.outstanding ?? 0)),
      waiting: _pendingFor(payments, late.map((month) => month.id).toSet()),
    );
  }

  if (owing.isNotEmpty) {
    final oldest = owing.first;
    final forIt =
        payments.where((payment) => payment.billingPeriodId == oldest.id).toList();

    // Waiting outranks a refusal: a payment the landlord has not answered was
    // made after any they refused, because refused ones cannot be answered
    // again. The list is ordered by the date the tenant says they paid, not
    // by when they said it, so order alone could not settle this.
    final pending = forIt.where(_isPending).firstOrNull;
    if (pending != null) return RentWaiting(period: oldest, payment: pending);

    // A refusal stops mattering once something for the month is confirmed:
    // the landlord has recorded cash, or agreed a later payment arrived, and
    // the tenant has moved on from "they said it didn't come".
    final refused = forIt
        .where((payment) => payment.status == PaymentResponseStatusEnum.REJECTED)
        .firstOrNull;
    final confirmed =
        forIt.any((payment) => payment.status == PaymentResponseStatusEnum.CONFIRMED);
    if (refused != null && !confirmed) {
      return RentNotReceived(period: oldest, payment: refused);
    }

    final daysLeft = _due(oldest).difference(day).inDays;
    if (daysLeft <= dueSoonDays) {
      return RentDueSoon(period: oldest, daysLeft: daysLeft < 0 ? 0 : daysLeft);
    }
    return RentPaid(
      nextDue: _due(oldest),
      amount: oldest.outstanding,
      lastPaid: _lastPaid(months),
    );
  }

  // Not simply the next rent day on the calendar: a month already billed and
  // paid -- October settled on the 3rd -- is not due on the 5th. The next one
  // is the first rent day after the last month billed.
  final calendar = _nextRentDay(day, dueDay);
  // Months of rent: a deposit falls due on move-in day, which is no guide to
  // the next rent day.
  final billed = months
      .where((month) => !month.isDeposit)
      .map(_due)
      .where((due) => due.year < 9999)
      .toList()
    ..sort();
  final afterBilled = billed.isEmpty ? null : _nextRentDay(billed.last, dueDay);
  return RentPaid(
    nextDue: afterBilled != null && afterBilled.isAfter(calendar) ? afterBilled : calendar,
    amount: rent,
    lastPaid: _lastPaid(months),
  );
}

bool _isPending(PaymentResponse payment) =>
    payment.status == PaymentResponseStatusEnum.PENDING_VERIFICATION;

PaymentResponse? _pendingFor(List<PaymentResponse> payments, Set<String?> periods) =>
    payments
        .where((payment) => periods.contains(payment.billingPeriodId) && _isPending(payment))
        .firstOrNull;

/// The latest month of rent fully paid. A deposit is not one: "You're all
/// set for the security deposit" says nothing about rent.
BillingPeriodResponse? _lastPaid(List<BillingPeriodResponse> months) {
  final paid = months
      .where((month) => !month.isDeposit && (month.outstanding ?? 0) <= 0)
      .toList()
    ..sort((a, b) => _due(a).compareTo(_due(b)));
  return paid.lastOrNull;
}

/// The next rent day after [day]: this month's if it is still ahead, otherwise
/// next month's. A rent day past the end of a short month falls on its last
/// day, the way the server's schedule does.
DateTime _nextRentDay(DateTime day, int dueDay) {
  DateTime on(int year, int month) {
    final last = DateTime.utc(year, month + 1, 0).day;
    return DateTime.utc(year, month, dueDay.clamp(1, last));
  }

  final thisMonth = on(day.year, day.month);
  return thisMonth.isAfter(day) ? thisMonth : on(day.year, day.month + 1);
}

/// A month's due date as a plain date. Months without one sort last.
DateTime _due(BillingPeriodResponse month) {
  final due = month.dueDate;
  return due == null ? DateTime.utc(9999) : _date(due);
}

DateTime _date(DateTime value) => DateTime.utc(value.year, value.month, value.day);
