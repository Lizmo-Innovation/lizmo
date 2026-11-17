import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../platform/lizmo_billing_providers.dart';
import '../router.dart';
import 'todo_card.dart';

/// Lizmo statements waiting on the landlord, on Today.
///
/// Among the things that need them because one does: a statement left unpaid
/// locks every property thirty days on, and a landlord who learns that from the
/// lock has learned it too late.
///
/// Nothing at all when nothing is owed, while loading, or if it failed -- the
/// billing screen in the account menu says why.
class LizmoStatementCard extends ConsumerWidget {
  const LizmoStatementCard({super.key, this.compact = false});

  /// Other kinds of to-do are on Today too.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statements = ref.watch(myLizmoStatementsProvider).valueOrNull;
    final owed = (statements ?? const <PlatformStatementResponse>[])
        .where(lizmoStatementNeedsPaying)
        .toList();
    if (owed.isEmpty) return const SizedBox.shrink();
    final overdue = owed.any((statement) => statement.overdue == true);

    return TodoCard(
      key: const ValueKey('lizmo-statement-card'),
      icon: Icons.receipt_outlined,
      tone: overdue ? TodoTone.behind : TodoTone.bill,
      title: "Lizmo's bill",
      count: owed.length,
      compact: compact,
      rows: [for (final statement in owed) _Row(statement: statement)],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.statement});

  final PlatformStatementResponse statement;

  @override
  Widget build(BuildContext context) {
    final overdue = statement.overdue == true;
    final ink = overdue ? LizmoColors.redText : LizmoColors.ink;

    return TodoRow(
      key: ValueKey('lizmo-statement-${statement.id}'),
      leading: TodoAvatar(
        icon: Icons.receipt_outlined,
        tone: overdue ? TodoTone.behind : TodoTone.bill,
      ),
      title: '${statement.label} · ${lizmoProperties(statement)}',
      onTap: () => context.openInTab(Detail.lizmoBilling),
      sub: Text(
        lizmoStatementStanding(statement),
        style: LizmoType.rowSub.copyWith(
          color: overdue ? LizmoColors.redText : LizmoColors.slateText,
        ),
      ),
      trailing: Text(
        LizmoMoney.peso((statement.outstanding ?? 0)),
        style: LizmoType.dataMedium.copyWith(fontSize: 14, color: ink),
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "3 Sep".
String lizmoDay(DateTime? date) =>
    date == null ? '' : '${date.day} ${_months[date.month - 1]}';

/// "2 properties", which is why the figure is what it is.
String lizmoProperties(PlatformStatementResponse statement) =>
    statement.lines.length == 1
    ? '1 property'
    : '${statement.lines.length} properties';

/// Where a statement stands, in a line.
String lizmoStatementStanding(PlatformStatementResponse statement) {
  if (statement.locked == true) {
    return 'Locked until paid · no new units, beds or tenants';
  }
  if (statement.overdue == true && statement.locksOn != null) {
    return 'Overdue · everything locks on ${lizmoDay(statement.locksOn)}';
  }
  return 'Due ${lizmoDay(statement.dueDate)}';
}
