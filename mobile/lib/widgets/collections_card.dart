import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../router.dart';
import '../tenant/tenant_providers.dart';
import 'receipt_card.dart';
import 'rent_schedule_list.dart';
import 'todo_card.dart';

/// How rent is going this month, across everything a landlord owns.
///
/// Replaces a placeholder that read "Collections — Needs leases and billing"
/// from the first day the dashboard existed. Both now exist.
///
/// Figures only. The people behind them -- a payment to confirm, a tenant
/// behind -- are their own cards at the top of Today, because they are things
/// to do and these are things to know.
class CollectionsCard extends ConsumerWidget {
  const CollectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(collectionsProvider);
    final today = ref.watch(todayProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: summary.when(
        loading: () => const _FiguresLoading(),
        // Said here, and only here. The two cards above that read the same
        // figures stay out of the way rather than repeat the failure three
        // times.
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collections', style: LizmoType.sectionHeading),
            const SizedBox(height: 6),
            Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
          ],
        ),
        data: (rent) =>
            _Figures(rent: rent, month: _monthNames[today.month - 1]),
      ),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class _FiguresLoading extends StatelessWidget {
  const _FiguresLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Collections', style: LizmoType.sectionHeading),
        const SizedBox(height: 12),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEEC),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures({required this.rent, required this.month});

  final CollectionsSummary rent;
  final String month;

  @override
  Widget build(BuildContext context) {
    final due = rent.dueThisMonth ?? 0;
    final collected = rent.collectedThisMonth ?? 0;
    final outstanding = rent.outstandingAllTime ?? 0;

    // Nothing let at all. Said plainly rather than as zeroes, which read as a
    // broken screen rather than an empty portfolio.
    if (due == 0 && outstanding == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collections', style: LizmoType.sectionHeading),
          const SizedBox(height: 6),
          Text(
            'Nothing is due yet. Rent appears here once somebody is renting '
            'from you.',
            style: LizmoType.rowSub,
          ),
        ],
      );
    }

    // What tenants say they have sent and the landlord has not yet looked
    // at: not paid, not behind. Never more than what is left of the month.
    final num left = math.max(0, due - collected);
    final num told = rent.awaiting.fold<num>(
      0,
      (sum, row) => sum + (row.amount ?? 0),
    );
    final num waiting = math.min(told, left);
    final num behind = left - waiting;
    final num paid = due == 0 ? collected : math.min(collected, due);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Collections', style: LizmoType.sectionHeading),
        const SizedBox(height: 4),
        Text.rich(
          key: const ValueKey('month-rent'),
          TextSpan(
            style: LizmoType.rowSub,
            children: [
              TextSpan(text: '$month rent  '),
              TextSpan(
                text: LizmoMoney.peso(collected),
                style: todoMono(LizmoColors.ink).copyWith(fontSize: 13),
              ),
              const TextSpan(text: ' of '),
              TextSpan(
                text: LizmoMoney.peso(due),
                style: todoMono(LizmoColors.ink).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        if (due > 0) ...[
          const SizedBox(height: 12),
          Semantics(
            key: const ValueKey('rent-bar'),
            label:
                '$month rent: ${LizmoMoney.peso(paid)} paid, '
                '${LizmoMoney.peso(waiting)} waiting for you to confirm, '
                '${LizmoMoney.peso(behind)} behind',
            child: ExcludeSemantics(
              child: _StackedBar(
                parts: [
                  (paid, LizmoColors.teal900),
                  (waiting, LizmoColors.amber),
                  (behind, LizmoColors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Legend(label: 'Paid', amount: paid, dot: LizmoColors.teal900),
                _Legend(
                  label: 'Waiting',
                  amount: waiting,
                  dot: LizmoColors.amber,
                ),
                _Legend(label: 'Behind', amount: behind, dot: LizmoColors.red),
              ],
            ),
          ),
        ],
        // Kept apart from the month: a landlord owed for three past months
        // and paid up for this one is not doing well, and one bar cannot say
        // both.
        if (outstanding > 0) ...[
          const SizedBox(height: 10),
          Text(
            '${LizmoMoney.peso(outstanding)} owed in all, across every month',
            key: const ValueKey('owed-in-all'),
            style: LizmoType.rowSub,
          ),
        ],
        // Apart from the rent figures, because it is not rent: money held
        // for tenants and owed back to them when they move out.
        if ((rent.depositsHeld ?? 0) > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${LizmoMoney.peso(rent.depositsHeld!)} in deposits held',
            key: const ValueKey('deposits-held'),
            style: LizmoType.rowSub,
          ),
        ],
      ],
    );
  }
}

/// Segments in proportion, 2dp apart, each in its own colour.
class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.parts});

  final List<(num, Color)> parts;

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final part in parts)
        if (part.$1 > 0) part,
    ];
    if (shown.isEmpty) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F1),
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final (i, (amount, colour)) in shown.indexed) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                // Whole thousandths: a flex is an int, and a sliver of a
                // segment still deserves to be seen.
                flex: math.max(1, (amount * 1000).round()),
                child: ColoredBox(key: ValueKey('rent-bar-$i'), color: colour),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.amount, required this.dot});

  final String label;
  final num amount;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: LizmoType.rowSub),
        const SizedBox(width: 4),
        Text(LizmoMoney.peso(amount), style: todoMono(LizmoColors.ink)),
      ],
    );
  }
}

/// Payments tenants say they have made, waiting on the landlord.
///
/// The one thing on Today about the landlord's own behaviour rather than
/// their tenants': somebody who said they paid three days ago and has heard
/// nothing is the failure the whole payments feature exists to avoid.
///
/// Confirm is on the row. Opening the tenancy to press it there was a second
/// tap for something they have already checked in their GCash app.
///
/// Nothing at all when nothing is waiting, or while the figures are loading
/// or failed -- [CollectionsCard] says that.
class ConfirmPaymentsCard extends ConsumerWidget {
  const ConfirmPaymentsCard({super.key, this.compact = false});

  /// Other kinds of to-do are on Today too.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rent = ref.watch(collectionsProvider).valueOrNull;
    final waiting = rent?.awaitingConfirmation ?? 0;
    if (rent == null || waiting == 0) return const SizedBox.shrink();
    // Oldest first: whoever has waited longest to be believed.
    final rows = [...rent.awaiting]
      ..sort(
        (a, b) => (a.declaredAt ?? DateTime(2000)).compareTo(
          b.declaredAt ?? DateTime(2000),
        ),
      );

    return TodoCard(
      key: const ValueKey('confirm-card'),
      icon: Icons.receipt_long_outlined,
      tone: TodoTone.confirm,
      title: 'Payments to confirm',
      count: waiting,
      compact: compact,
      rows: [for (final row in rows) _WaitingRow(row: row, full: !compact)],
    );
  }
}

/// Tenants who are behind on rent, the longest late first.
class ArrearsCard extends ConsumerWidget {
  const ArrearsCard({super.key, this.compact = false});

  /// Other kinds of to-do are on Today too.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rent = ref.watch(collectionsProvider).valueOrNull;
    final arrears = rent?.inArrears ?? const <ArrearsRow>[];
    if (arrears.isEmpty) return const SizedBox.shrink();

    final onlyRent = arrears.every((row) => (row.depositOwed ?? 0) <= 0);
    return TodoCard(
      key: const ValueKey('arrears-card'),
      icon: Icons.schedule,
      tone: TodoTone.behind,
      title: onlyRent ? 'Behind on rent' : 'Behind on rent or deposit',
      count: arrears.length,
      compact: compact,
      rows: [for (final row in arrears) _ArrearsRow(row: row)],
    );
  }
}

String _where(String? bed, String? unit) =>
    bed == null ? 'Unit $unit' : '$bed, $unit';

/// One payment a tenant says they have made, waiting on the landlord.
class _WaitingRow extends ConsumerStatefulWidget {
  const _WaitingRow({required this.row, required this.full});

  final AwaitingRow row;

  /// The card is alone on Today: room for the reference, the screenshot and
  /// a full-size Confirm.
  final bool full;

  @override
  ConsumerState<_WaitingRow> createState() => _WaitingRowState();
}

class _WaitingRowState extends ConsumerState<_WaitingRow> {
  bool _working = false;

  AwaitingRow get row => widget.row;

  String get _amount => LizmoMoney.peso(row.amount ?? 0);

  String get _who => row.tenantName ?? 'a tenant';

  Future<void> _confirm() async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(rentApiProvider)
          .confirmPayment(row.leaseId!, row.paymentId!);
      ref.invalidate(collectionsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Confirmed $_amount from $_who.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _screenshot() {
    final url = row.proofUrl;
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  semanticLabel: 'What $_who sent',
                  errorBuilder: (_, _, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'The screenshot could not be opened.',
                      style: LizmoType.rowSub,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = row.paymentMethod == null
        ? null
        : paymentMethodLabel(row.paymentMethod!.toJson());
    final remarks = row.remarks;
    final confirmLabel =
        'Confirm $_amount from ${row.tenantName ?? 'a tenant'}';
    final dot = Text('·', style: LizmoType.rowSub);

    final sub = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        if (!widget.full) ...[
          Text(_amount, style: todoMono(LizmoColors.ink)),
          dot,
        ],
        if (method != null) ...[Text(method, style: LizmoType.rowSub), dot],
        if (widget.full && remarks != null && remarks.isNotEmpty) ...[
          Text(remarks, style: todoMono(LizmoColors.slateText)),
          dot,
        ],
        if (row.declaredAt case final told?)
          _Waited(paymentId: row.paymentId, since: told)
        else
          Text('today', style: LizmoType.rowSub),
        // Which account to open before confirming.
        if (widget.full && row.sentTo != null)
          Text(
            '· sent to ${row.sentTo}',
            style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
          ),
      ],
    );

    return TodoRow(
      key: ValueKey('awaiting-${row.paymentId}'),
      leading: TodoAvatar(name: row.tenantName, tone: TodoTone.confirm),
      title:
          '${row.tenantName ?? 'A tenant'} · ${_where(row.bedLabel, row.unitNumber)}',
      // To the tenant, for anything more than Confirm. Opens inside Today,
      // so Back comes straight back here to the next one.
      onTap: () => context.openInTab(Detail.tenancy(row.leaseId!)),
      sub: sub,
      trailing: widget.full
          ? Text(
              _amount,
              style: LizmoType.dataMedium.copyWith(color: LizmoColors.ink),
            )
          : Semantics(
              button: true,
              label: confirmLabel,
              excludeSemantics: true,
              child: OutlinedButton(
                key: ValueKey('confirm-${row.paymentId}'),
                onPressed: _working ? null : _confirm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LizmoColors.teal900,
                  side: const BorderSide(color: LizmoColors.teal900),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Confirm'),
              ),
            ),
      below: widget.full
          // Wrapping rather than a row: at large text the two do not fit
          // side by side, and Confirm is the one that must not be cut.
          ? Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (row.proofUrl != null)
                  TextButton(
                    key: ValueKey('screenshot-${row.paymentId}'),
                    onPressed: _screenshot,
                    style: TextButton.styleFrom(
                      foregroundColor: LizmoColors.teal900,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('See screenshot'),
                  ),
                Semantics(
                  button: true,
                  label: confirmLabel,
                  excludeSemantics: true,
                  child: FilledButton(
                    key: ValueKey('confirm-${row.paymentId}'),
                    onPressed: _working ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: LizmoColors.teal900,
                      foregroundColor: LizmoColors.white,
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text('Confirm $_amount'),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

/// A tenant behind, with Remind beside them.
///
/// The reminder says what is owed and nothing else: no threats and no
/// penalties, because Lizmo does not know what the two of them have agreed.
class _ArrearsRow extends ConsumerStatefulWidget {
  const _ArrearsRow({required this.row});

  final ArrearsRow row;

  @override
  ConsumerState<_ArrearsRow> createState() => _ArrearsRowState();
}

class _ArrearsRowState extends ConsumerState<_ArrearsRow> {
  bool _working = false;

  ArrearsRow get row => widget.row;

  Future<void> _remind() async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rentApiProvider).remindTenant(row.leaseId!);
      ref.invalidate(collectionsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Reminder sent to ${row.tenantName ?? 'your tenant'}.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final deposit = row.depositOwed ?? 0;
    final rentLate = row.outstanding ?? 0;
    final days = row.oldestDueDate == null
        ? null
        : DateUtils.dateOnly(
            today,
          ).difference(DateUtils.dateOnly(row.oldestDueDate!)).inDays;
    // Rent and deposit said apart: a deposit is owed, but it is not income,
    // and "overdue 12 days" would be wrong of somebody who only owes that.
    final behind = [
      if (rentLate > 0) LizmoMoney.peso(rentLate),
      if (rentLate > 0 && days != null && days > 0)
        'overdue ${days == 1 ? '1 day' : '$days days'}',
      if (deposit > 0) 'deposit ${LizmoMoney.peso(deposit)} not received',
    ].join(' · ');
    final who = row.tenantName ?? 'A tenant';

    return TodoRow(
      key: ValueKey('arrears-${row.leaseId}'),
      leading: TodoAvatar(name: row.tenantName, tone: TodoTone.behind),
      title: '$who · ${_where(row.bedLabel, row.unitNumber)}',
      // Straight to the tenant, because seeing who is behind and then having
      // to go and find them is the half of this that wastes the time.
      onTap: () => context.openInTab(Detail.tenancy(row.leaseId!)),
      sub: Text(
        behind,
        style: LizmoType.rowSub.copyWith(color: LizmoColors.redText),
      ),
      // Only for rent: a deposit is settled between them at move-in.
      trailing: rentLate <= 0
          ? null
          : row.remindedAt != null
          ? Row(
              key: ValueKey('reminded-${row.leaseId}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 16, color: LizmoColors.slateText),
                const SizedBox(width: 4),
                Text('Reminded', style: LizmoType.rowSub),
              ],
            )
          : Semantics(
              button: true,
              label: 'Remind $who',
              excludeSemantics: true,
              child: OutlinedButton(
                key: ValueKey('remind-${row.leaseId}'),
                onPressed: _working ? null : _remind,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LizmoColors.redText,
                  side: const BorderSide(color: Color(0xFFE8B4B0)),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Remind'),
              ),
            ),
    );
  }
}

/// How long a payment has waited for the landlord.
///
/// Plain for the first two days. From the third -- when Lizmo starts
/// reminding them -- amber, because by then the tenant is the one wondering
/// whether they were believed.
class _Waited extends StatelessWidget {
  const _Waited({required this.paymentId, required this.since});

  final String? paymentId;
  final DateTime since;

  static const _reminded = 3;

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(since.toLocal()).inDays;
    final long = days >= _reminded;
    final text = waitedFor(since);

    return Container(
      key: ValueKey('awaiting-age-$paymentId'),
      padding: long
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : EdgeInsets.zero,
      decoration: long
          ? BoxDecoration(
              color: LizmoColors.amberBg,
              borderRadius: BorderRadius.circular(999),
            )
          : null,
      child: Text(
        text,
        style: LizmoType.rowSub.copyWith(
          fontSize: 11,
          color: long ? LizmoColors.amberText : LizmoColors.slateText,
          fontWeight: long ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
