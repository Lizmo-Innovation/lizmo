import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'date_field.dart';

/// When a lease is meant to end, and choosing it.
///
/// Most rooms here are let month to month, so "no end date" is the first
/// choice and the one already picked. A term is offered the way landlords say
/// it -- six months, a year -- and the date it comes to is shown beside it,
/// because "a year from the 15th" is a date nobody should have to work out.

/// The last day of a term of [months] from [start]: a year from 15 January
/// ends on 14 January. A start on the 31st runs to the end of a shorter month.
DateTime termEnd(DateTime start, int months) {
  final year = start.year + (start.month - 1 + months) ~/ 12;
  final month = (start.month - 1 + months) % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = start.day > lastDay ? lastDay : start.day;
  final end = DateTime(year, month, day).subtract(const Duration(days: 1));
  return DateTime(end.year, end.month, end.day);
}

/// "31 August 2027".
String termDate(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Whole days from [today] to [end]; negative once it has gone by.
int daysUntil(DateTime end, DateTime today) {
  final a = DateTime.utc(today.year, today.month, today.day);
  final b = DateTime.utc(end.year, end.month, end.day);
  return b.difference(a).inDays;
}

/// "today", "tomorrow", "in 23 days".
String inDays(int days) => switch (days) {
      <= 0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };

/// One way the lease could end. A null [date] is no end date at all.
class TermChoice {
  const TermChoice(this.key, this.label, this.date);

  final String key;
  final String label;
  final DateTime? date;
}

/// The choices, one picked, and a date of their own as the last of them.
///
/// Controlled: the screen holding it keeps which is picked, so a choice made
/// relative to the start date follows the start date when that changes.
class LeaseTermChoices extends StatelessWidget {
  const LeaseTermChoices({
    super.key,
    required this.choices,
    required this.picked,
    required this.onPick,
    required this.ownDate,
    required this.onOwnDate,
    required this.firstDate,
    required this.lastDate,
  });

  static const own = 'own';

  final List<TermChoice> choices;

  /// A [TermChoice.key], or [own].
  final String picked;
  final ValueChanged<String> onPick;

  final DateTime? ownDate;
  final ValueChanged<DateTime?> onOwnDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in choices)
          _Choice(
            key: ValueKey('term-${choice.key}'),
            label: choice.label,
            detail: choice.date == null ? null : termDate(choice.date!),
            chosen: picked == choice.key,
            onTap: () => onPick(choice.key),
          ),
        _Choice(
          key: const ValueKey('term-own'),
          label: 'Pick a date',
          detail: picked == own || ownDate == null ? null : termDate(ownDate!),
          chosen: picked == own,
          onTap: () => onPick(own),
        ),
        if (picked == own) ...[
          const SizedBox(height: 2),
          LizmoDateField(
            fieldKey: const ValueKey('term-own-date'),
            value: ownDate,
            onChanged: onOwnDate,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
          const SizedBox(height: 6),
          Text(
            'The last day of the lease.',
            style: LizmoType.rowSub,
          ),
        ],
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.detail,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final String? detail;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: chosen ? LizmoColors.tealBg : LizmoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chosen ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                chosen ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18,
                color: chosen ? LizmoColors.teal900 : LizmoColors.slate,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: LizmoType.rowName.copyWith(
                    color: chosen ? LizmoColors.teal900 : LizmoColors.ink,
                  ),
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: LizmoType.rowSub.copyWith(
                    color: chosen ? LizmoColors.teal900 : LizmoColors.slate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the change sheet came back with: a new end date, or none at all.
///
/// Wrapped so that "take the end date away" and "never mind" are different
/// answers: both would otherwise be null.
class TermChange {
  const TermChange(this.endsOn);

  final DateTime? endsOn;
}

/// Setting, extending or taking away a lease's end date.
///
/// Extending counts from the end already agreed, since "another year" means a
/// year more than they have. A lease with no end yet counts from its start,
/// and only offers terms that have not already run out.
class ChangeLeaseTermSheet extends StatefulWidget {
  const ChangeLeaseTermSheet({
    super.key,
    required this.start,
    required this.endsOn,
    required this.today,
  });

  final DateTime start;
  final DateTime? endsOn;
  final DateTime today;

  static Future<TermChange?> show(
    BuildContext context, {
    required DateTime start,
    required DateTime? endsOn,
    required DateTime today,
  }) {
    return showModalBottomSheet<TermChange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LizmoColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ChangeLeaseTermSheet(start: start, endsOn: endsOn, today: today),
      ),
    );
  }

  @override
  State<ChangeLeaseTermSheet> createState() => _ChangeLeaseTermSheetState();
}

class _ChangeLeaseTermSheetState extends State<ChangeLeaseTermSheet> {
  late final List<TermChoice> _choices = _offered();
  late String _picked = _choices.isEmpty ? LeaseTermChoices.own : _choices.first.key;
  DateTime? _own;

  DateTime get _today =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  List<TermChoice> _offered() {
    final ends = widget.endsOn;
    if (ends != null) {
      // From the day after the agreed end, so a year more is a year more.
      final next = ends.add(const Duration(days: 1));
      return [
        TermChoice('six', '6 months more', termEnd(next, 6)),
        TermChoice('year', 'A year more', termEnd(next, 12)),
      ];
    }
    return [
      for (final (key, label, months) in const [
        ('six', '6 months from the start', 6),
        ('year', 'A year from the start', 12),
      ])
        if (!termEnd(widget.start, months).isBefore(_today))
          TermChoice(key, label, termEnd(widget.start, months)),
    ];
  }

  DateTime? get _chosen => _picked == LeaseTermChoices.own
      ? _own
      : _choices.firstWhere((choice) => choice.key == _picked).date;

  DateTime get _earliest {
    final dayAfterStart = widget.start.add(const Duration(days: 1));
    return dayAfterStart.isAfter(_today) ? dayAfterStart : _today;
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _chosen;
    final had = widget.endsOn;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              had == null ? 'Set an end date' : 'Extend or change the end',
              style: LizmoType.sectionHeading.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              had == null
                  ? 'You will both be told a month before, and again in the '
                      'last week. Nothing ends on its own.'
                  : 'It ends on ${termDate(had)} now. Your tenant is told '
                      'of any change.',
              style: LizmoType.rowSub,
            ),
            const SizedBox(height: 16),
            LeaseTermChoices(
              choices: _choices,
              picked: _picked,
              onPick: (key) => setState(() => _picked = key),
              ownDate: _own,
              onOwnDate: (date) => setState(() => _own = date),
              firstDate: _earliest,
              lastDate: _today.add(const Duration(days: 365 * 10)),
            ),
            const SizedBox(height: 14),
            PrimaryActionButton(
              key: const ValueKey('save-term'),
              label: chosen == null
                  ? 'Choose a date'
                  : 'End it on ${termDate(chosen)}',
              onPressed: chosen == null
                  ? null
                  : () => Navigator.of(context).pop(TermChange(chosen)),
            ),
            if (had != null) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  key: const ValueKey('remove-term'),
                  onPressed: () => Navigator.of(context).pop(const TermChange(null)),
                  child: Text(
                    'Remove the end date',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.slate),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
