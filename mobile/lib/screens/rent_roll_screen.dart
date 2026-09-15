import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../widgets/account_sheet.dart';
import '../widgets/not_received_dialog.dart';
import '../widgets/notification_bell.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/role_switcher.dart';

/// Rent, month by month, for every room a landlord lets.
///
/// Collecting rent is the job a landlord does every month, and it had no home:
/// a banner on Today and a card inside each tenant. This is the notebook it
/// replaces -- every room, what it owed, whether it came in -- with the
/// answering done on the row: confirm what a tenant says they paid, refuse it
/// with a reason, or write down cash that was handed over.
///
/// This file used to hold a screen of four invented tenants, built to prove the
/// design language before any of this existed. Nothing routed to it.
class RentRollScreen extends ConsumerStatefulWidget {
  const RentRollScreen({super.key});

  @override
  ConsumerState<RentRollScreen> createState() => _RentRollScreenState();
}

class _RentRollScreenState extends ConsumerState<RentRollScreen> {
  /// The first of the month on screen. Opens on this month, which is the one
  /// somebody opens the tab to check.
  late DateTime _month = _thisMonth();

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  String get _key => monthKey(_month);

  void _move(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };
    final roll = ref.watch(rentRollProvider(_key));
    final value = roll.valueOrNull;

    final earliest = value?.earliestMonth;
    final canGoBack = earliest != null && _key.compareTo(earliest) > 0;
    // Not past this month: a month that has not begun has no rent in it yet.
    final canGoForward = _month.isBefore(_thisMonth());

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'Rent',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            stats: [
              LatticeHeaderStat(value: _peso(value?.due), label: 'Due'),
              LatticeHeaderStat(
                  value: _peso(value?.collected), label: 'Collected'),
              LatticeHeaderStat(
                  value: _peso(value?.outstanding), label: 'Still owed'),
            ],
          ),
          _MonthBar(
            label: monthName(_month),
            onBack: canGoBack ? () => _move(-1) : null,
            onForward: canGoForward ? () => _move(1) : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(rentRollProvider(_key)),
              child: roll.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    LizmoMessageState(
                      tone: LizmoMessageTone.problem,
                      icon: Icons.error_outline,
                      title: 'Could not load the rent',
                      detail: ApiFailure.from(error).message,
                    ),
                  ],
                ),
                data: (roll) => roll.rows.isEmpty
                    ? ListView(
                        children: [
                          LizmoMessageState(
                            tone: LizmoMessageTone.neutral,
                            icon: Icons.receipt_long_outlined,
                            title: 'No rent due in ${monthName(_month)}',
                            detail: roll.earliestMonth == null
                                ? 'Rent appears here once somebody is renting '
                                    'from you.'
                                : 'Nobody’s rent fell due this month.',
                          ),
                        ],
                      )
                    : _Rows(roll: roll, month: _key),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A figure, or a dash while it is not known.
  static String _peso(num? amount) =>
      amount == null ? '—' : '₱${amount.toStringAsFixed(0)}';
}

/// `2026-09`, the way the API names a month.
String monthKey(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

/// "September 2026".
String monthName(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.label, this.onBack, this.onForward});

  final String label;

  /// Null when there is nothing further that way, which disables the arrow
  /// rather than leading to an empty month.
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('month-back'),
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left),
            color: LizmoColors.teal900,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
            ),
          ),
          IconButton(
            key: const ValueKey('month-forward'),
            onPressed: onForward,
            icon: const Icon(Icons.chevron_right),
            color: LizmoColors.teal900,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}

/// The month's rows, a section per property.
///
/// Grouped because a landlord with more than one building thinks of them one
/// at a time; the API already sends them by property, then unit, then bed.
class _Rows extends StatelessWidget {
  const _Rows({required this.roll, required this.month});

  final RentRoll roll;
  final String month;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<RentRollRow>>{};
    for (final row in roll.rows) {
      groups.putIfAbsent(row.propertyId ?? '', () => []).add(row);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final group in groups.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 0, 8),
            child: Text(
              group.first.propertyName ?? 'A property',
              style: LizmoType.sectionHeading,
            ),
          ),
          for (final row in group) _RentRow(row: row, month: month),
        ],
      ],
    );
  }
}

/// One tenancy's rent for the month, and whatever there is to do about it.
class _RentRow extends ConsumerStatefulWidget {
  const _RentRow({required this.row, required this.month});

  final RentRollRow row;
  final String month;

  @override
  ConsumerState<_RentRow> createState() => _RentRowState();
}

class _RentRowState extends ConsumerState<_RentRow> {
  bool _working = false;

  RentRollRow get row => widget.row;
  String get _leaseId => row.leaseId!;

  Future<void> _confirm(WaitingPayment payment) => _send(
        () => ref.read(rentApiProvider).confirmPayment(_leaseId, payment.paymentId!),
        done: 'Confirmed.',
      );

  Future<void> _refuse(WaitingPayment payment) async {
    final why = await NotReceivedDialog.ask(context);
    // Null means they backed out of the dialog, which is not a refusal.
    if (why == null || !mounted) return;
    await _send(
      () => ref.read(rentApiProvider).rejectPayment(
            _leaseId,
            payment.paymentId!,
            remarks: why.isEmpty ? null : why,
          ),
      done: 'Marked as not received.',
    );
  }

  Future<void> _record() async {
    final period = row.period!;
    final request = await RecordPaymentSheet.show(
      context,
      billingPeriodId: period.id!,
      tenantName: row.tenantName ?? 'Your tenant',
      periodLabel: period.label ?? 'this month',
      outstanding: period.outstanding ?? 0,
    );
    if (request == null || !mounted) return;
    await _send(
      () => ref.read(rentApiProvider).recordPayment(_leaseId, request),
      done: 'Recorded.',
    );
  }

  Future<void> _send(Future<void> Function() call, {required String done}) async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      // The month, the dashboard's figures, and the tenant's own screen all
      // read these same rows.
      ref.invalidate(rentRollProvider(widget.month));
      ref.invalidate(collectionsProvider);
      ref.invalidate(leaseBillingProvider(_leaseId));
      ref.invalidate(leasePaymentsProvider(_leaseId));
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = row.period!;
    final current = row.current == true;
    final outstanding = period.outstanding ?? 0;
    final slot = row.bedLabel == null
        ? 'Unit ${row.unitNumber}'
        : '${row.bedLabel}, ${row.unitNumber}';

    final summary = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.tenantName ?? 'A tenant',
                style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  slot,
                  if (period.dueDate != null) 'due ${_day(period.dueDate!)}',
                  // Still listed for the month they owed, and said so, so a
                  // landlord does not go looking for them in Tenants.
                  if (!current) 'moved out',
                ].join(' · '),
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Chip(period: period),
            const SizedBox(height: 4),
            Text(
              _amountLine(period),
              style: LizmoType.rowSub.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        key: ValueKey('rent-${period.id}'),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Opens the tenant while they still live there. Somebody who has
            // moved out has no screen to open -- it answers not-found once the
            // tenancy ends -- so their row is not made to look tappable.
            InkWell(
              onTap: current
                  ? () => context.openInTab(Detail.tenancy(_leaseId))
                  : null,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: summary,
              ),
            ),

            for (final payment in row.waiting)
              _Waiting(
                payment: payment,
                busy: _working,
                onConfirm: () => _confirm(payment),
                onRefuse: () => _refuse(payment),
              ),

            if (_working && row.waiting.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            // Anything still owed can be written down, including by somebody
            // who has moved out: a debt settled after the keys are handed back
            // is still a debt settled.
            else if (outstanding > 0 && row.waiting.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: ValueKey('record-${period.id}'),
                    onPressed: _record,
                    icon: const Icon(Icons.add, size: 16),
                    // Styled here rather than left to the button's default,
                    // which is the platform font rather than Lizmo's own.
                    label: Text('Record payment',
                        style: LizmoType.rowName
                            .copyWith(color: LizmoColors.teal900)),
                    style: TextButton.styleFrom(
                      foregroundColor: LizmoColors.teal900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _amountLine(BillingPeriodResponse period) {
    final due = period.amountDue ?? 0;
    final left = period.outstanding ?? 0;
    if (left <= 0 || left == due) return '₱${due.toStringAsFixed(0)}';
    return '₱${left.toStringAsFixed(0)} of ₱${due.toStringAsFixed(0)} left';
  }
}

/// What state the month is in, in the words a landlord uses.
class _Chip extends StatelessWidget {
  const _Chip({required this.period});

  final BillingPeriodResponse period;

  @override
  Widget build(BuildContext context) {
    final status = period.status?.toJson();

    // Paid wins over late: a month settled after its due date is settled.
    if (status == 'PAID') {
      return const StatusChip(status: LizmoStatus.paid, label: 'Paid');
    }
    if (period.overdue == true) {
      return const StatusChip(status: LizmoStatus.overdue, label: 'Late');
    }
    if (status == 'PARTIALLY_PAID') {
      return const StatusChip(status: LizmoStatus.pending, label: 'Partly paid');
    }
    // Grey, not a warning: rent that is not due yet is not a problem.
    return const StatusChip(status: LizmoStatus.vacant, label: 'Unpaid');
  }
}

/// A payment the tenant says they made, answered where it is read.
class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.payment,
    required this.busy,
    required this.onConfirm,
    required this.onRefuse,
  });

  final WaitingPayment payment;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onRefuse;

  static const _methods = {
    'GCASH': 'GCash',
    'MAYA': 'Maya',
    'BANK_TRANSFER': 'bank transfer',
    'CASH': 'cash',
  };

  @override
  Widget build(BuildContext context) {
    final how = _methods[payment.method?.toJson()] ?? 'some other way';
    final paidOn = payment.paidOn;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Says they paid ₱${(payment.amount ?? 0).toStringAsFixed(0)} by $how'
            '${paidOn == null ? '' : ' on ${_day(paidOn)}'}',
            style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
          ),
          if (payment.sentTo case final sentTo?) ...[
            const SizedBox(height: 2),
            Text(
              'Sent to $sentTo',
              style: LizmoType.rowSub
                  .copyWith(fontSize: 12, color: LizmoColors.amberText),
            ),
          ],
          if ((payment.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              payment.note!,
              style: LizmoType.rowSub.copyWith(color: LizmoColors.ink),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: ValueKey('reject-${payment.paymentId}'),
                onPressed: busy ? null : onRefuse,
                child: Text('Not received',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
              ),
              TextButton(
                key: ValueKey('confirm-${payment.paymentId}'),
                onPressed: busy ? null : onConfirm,
                child: Text('Confirm',
                    style: LizmoType.rowName
                        .copyWith(color: LizmoColors.teal900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "5 Sep".
String _day(DateTime date) => '${date.day} ${_shortMonths[date.month - 1]}';
