import 'package:flutter_test/flutter_test.dart';
import 'package:lizmo/tenant/rent_status.dart';
import 'package:lizmo_api/api.dart';

/// A month of ₱2,500 rent, due on [due].
BillingPeriodResponse _month(
  String id,
  DateTime due, {
  num paid = 0,
  bool overdue = false,
  String? label,
}) =>
    BillingPeriodResponse(
      id: id,
      label: label ?? id,
      periodStart: DateTime.utc(due.year, due.month, 1),
      periodEnd: DateTime.utc(due.year, due.month + 1, 0),
      dueDate: due,
      amountDue: 2500,
      amountPaid: paid,
      outstanding: 2500 - paid,
      status: paid >= 2500
          ? BillingPeriodResponseStatusEnum.PAID
          : paid > 0
              ? BillingPeriodResponseStatusEnum.PARTIALLY_PAID
              : BillingPeriodResponseStatusEnum.UNPAID,
      overdue: overdue,
    );

PaymentResponse _payment(
  String id,
  String month,
  PaymentResponseStatusEnum status, {
  String? reason,
  DateTime? on,
}) =>
    PaymentResponse(
      id: id,
      billingPeriodId: month,
      amountPaid: 2500,
      paymentDate: on ?? DateTime.utc(2026, 10, 3),
      status: status,
      rejectionReason: reason,
    );

const _pending = PaymentResponseStatusEnum.PENDING_VERIFICATION;
const _refused = PaymentResponseStatusEnum.REJECTED;
const _confirmed = PaymentResponseStatusEnum.CONFIRMED;

RentStatus _status(
  List<BillingPeriodResponse> months, {
  List<PaymentResponse> payments = const [],
  required DateTime today,
  int dueDay = 5,
}) =>
    rentStatus(
      months: months,
      payments: payments,
      today: today,
      dueDay: dueDay,
      rent: 2500,
    );

void main() {
  final sep = _month('sep', DateTime.utc(2026, 9, 5), paid: 2500, label: 'September 2026');
  final oct = _month('oct', DateTime.utc(2026, 10, 5), label: 'October 2026');

  group('paid', () {
    test('everything paid: next rent day and what was last paid', () {
      final status = _status([sep], today: DateTime(2026, 9, 20));

      expect(status, isA<RentPaid>());
      status as RentPaid;
      expect(status.nextDue, DateTime.utc(2026, 10, 5));
      expect(status.amount, 2500);
      expect(status.lastPaid?.label, 'September 2026');
    });

    /// Ahead of the window the reminder uses, a month that is open but not
    /// close is not something to act on yet.
    test('a month owed but more than five days off is still paid', () {
      final status = _status([sep, oct], today: DateTime(2026, 9, 29));

      expect(status, isA<RentPaid>());
      expect((status as RentPaid).nextDue, DateTime.utc(2026, 10, 5));
    });

    test('before anything is billed, rent day comes from the lease', () {
      final status = _status(const [], today: DateTime(2026, 9, 20), dueDay: 1);

      expect((status as RentPaid).nextDue, DateTime.utc(2026, 10, 1));
      expect(status.lastPaid, isNull);
    });

    test('a rent day on the 31st falls on the last day of a short month', () {
      final status = _status(const [], today: DateTime(2026, 2, 3), dueDay: 31);

      expect((status as RentPaid).nextDue, DateTime.utc(2026, 2, 28));
    });

    test('on rent day itself, the next one is next month', () {
      final status = _status([sep], today: DateTime(2026, 9, 5));

      expect((status as RentPaid).nextDue, DateTime.utc(2026, 10, 5));
    });
  });

  group('due soon', () {
    test('five days before rent day', () {
      final status = _status([sep, oct], today: DateTime(2026, 9, 30));

      expect(status, isA<RentDueSoon>());
      expect((status as RentDueSoon).daysLeft, 5);
      expect(status.period.id, 'oct');
    });

    test('on rent day, with nothing left to count down', () {
      final status = _status([sep, oct], today: DateTime(2026, 10, 5));

      expect((status as RentDueSoon).daysLeft, 0);
    });

    /// Rent on the 1st means the window opens in the month before.
    test('rent on the 1st is due soon from the 27th before', () {
      final nov = _month('nov', DateTime.utc(2026, 11, 1));
      final status = _status([nov], today: DateTime(2026, 10, 27), dueDay: 1);

      expect((status as RentDueSoon).daysLeft, 5);
    });

    test('a part-paid month is due soon for what is left', () {
      final part = _month('oct', DateTime.utc(2026, 10, 5), paid: 1000);
      final status = _status([part], today: DateTime(2026, 10, 2));

      expect((status as RentDueSoon).period.outstanding, 1500);
    });

    test('the time of day does not move the count', () {
      final status = _status([oct], today: DateTime(2026, 10, 2, 23, 59));

      expect((status as RentDueSoon).daysLeft, 3);
    });
  });

  group('waiting', () {
    test('after saying they paid, the tenant is not asked again', () {
      final status = _status(
        [sep, oct],
        payments: [_payment('p1', 'oct', _pending)],
        today: DateTime(2026, 10, 3),
      );

      expect(status, isA<RentWaiting>());
      expect((status as RentWaiting).payment.id, 'p1');
    });

    test('waiting shows even before the due-soon window', () {
      final status = _status(
        [sep, oct],
        payments: [_payment('p1', 'oct', _pending)],
        today: DateTime(2026, 9, 21),
      );

      expect(status, isA<RentWaiting>());
    });

    /// A refused payment cannot be answered again, so one still waiting was
    /// made after it -- whatever dates the tenant typed.
    test('paying again after a refusal is waiting, not refused', () {
      final status = _status(
        [oct],
        payments: [
          _payment('refused', 'oct', _refused, reason: 'Nothing arrived', on: DateTime.utc(2026, 10, 3)),
          _payment('again', 'oct', _pending, on: DateTime.utc(2026, 10, 1)),
        ],
        today: DateTime(2026, 10, 4),
      );

      expect((status as RentWaiting).payment.id, 'again');
    });
  });

  group('not received', () {
    test('the landlord refused it, with their reason', () {
      final status = _status(
        [oct],
        payments: [_payment('p1', 'oct', _refused, reason: 'No GCash transfer on 3 Oct.')],
        today: DateTime(2026, 10, 4),
      );

      expect(status, isA<RentNotReceived>());
      expect((status as RentNotReceived).payment.rejectionReason, 'No GCash transfer on 3 Oct.');
    });

    test('refused without a reason still says it was not received', () {
      final status = _status(
        [oct],
        payments: [_payment('p1', 'oct', _refused)],
        today: DateTime(2026, 10, 4),
      );

      expect((status as RentNotReceived).payment.rejectionReason, isNull);
    });

    /// The landlord recorded cash for part of it afterwards: the refusal is
    /// no longer the news, what is left owing is.
    test('a refusal stops mattering once something for the month is confirmed', () {
      final part = _month('oct', DateTime.utc(2026, 10, 5), paid: 1000);
      final status = _status(
        [part],
        payments: [
          _payment('refused', 'oct', _refused, reason: 'Nothing arrived'),
          _payment('cash', 'oct', _confirmed),
        ],
        today: DateTime(2026, 10, 4),
      );

      expect(status, isA<RentDueSoon>());
    });

    test('a refusal on a month since paid in full is forgotten', () {
      final status = _status(
        [sep],
        payments: [_payment('refused', 'sep', _refused)],
        today: DateTime(2026, 9, 20),
      );

      expect(status, isA<RentPaid>());
    });
  });

  group('late', () {
    test('one month late, red from the day after rent day', () {
      final late = _month('oct', DateTime.utc(2026, 10, 5), overdue: true);
      final status = _status([sep, late], today: DateTime(2026, 10, 6));

      expect(status, isA<RentLate>());
      status as RentLate;
      expect(status.months.map((month) => month.id), ['oct']);
      expect(status.total, 2500);
      expect(status.waiting, isNull);
    });

    test('two months late adds up both, oldest first', () {
      final aug = _month('aug', DateTime.utc(2026, 8, 5), overdue: true);
      final lateSep = _month('sep', DateTime.utc(2026, 9, 5), overdue: true);
      final status = _status([lateSep, aug], today: DateTime(2026, 9, 20));

      status as RentLate;
      expect(status.oldest.id, 'aug');
      expect(status.months.length, 2);
      expect(status.total, 5000);
    });

    /// Still late until the landlord confirms, but the tenant sees their
    /// payment arrived rather than being asked for it twice.
    test('late wins over waiting, and carries the payment', () {
      final late = _month('oct', DateTime.utc(2026, 10, 5), overdue: true);
      final status = _status(
        [late],
        payments: [_payment('p1', 'oct', _pending)],
        today: DateTime(2026, 10, 8),
      );

      expect((status as RentLate).waiting?.id, 'p1');
    });

    test('late wins over a refusal', () {
      final late = _month('oct', DateTime.utc(2026, 10, 5), overdue: true);
      final status = _status(
        [late],
        payments: [_payment('p1', 'oct', _refused, reason: 'Nothing arrived')],
        today: DateTime(2026, 10, 8),
      );

      expect(status, isA<RentLate>());
    });

    /// A month that is due soon alongside one that is late: the late one is
    /// the news, and only late months count toward what is overdue.
    test('only overdue months count toward the late total', () {
      final lateSep = _month('sep', DateTime.utc(2026, 9, 5), overdue: true);
      final status = _status([lateSep, oct], today: DateTime(2026, 10, 2));

      status as RentLate;
      expect(status.total, 2500);
      expect(status.months.map((month) => month.id), ['sep']);
    });
  });
}
