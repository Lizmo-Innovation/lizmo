import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// One column of a console table.
///
/// A null width means "take what is left", and exactly one column should be
/// that: the one carrying a name, which is the only cell whose length varies.
class ConsoleColumn {
  const ConsoleColumn(this.label, {this.width});

  final String label;
  final double? width;
}

class ConsoleRow {
  const ConsoleRow({required this.cells, this.onTap});

  final List<Widget> cells;
  final VoidCallback? onTap;
}

/// A table for a desktop console.
///
/// The mobile app uses cards, because a phone shows one thing at a time and a
/// card is a tappable object. A console is the opposite: the question is
/// comparative — which of these twenty landlords is in trouble — and that is
/// answered by reading a column down, not by scrolling through cards.
///
/// Rows are bordered rather than rounded tiles: at this density, twenty
/// floating cards is visual noise with the information spread thin.
class ConsoleTable extends StatelessWidget {
  const ConsoleTable({super.key, required this.columns, required this.rows});

  final List<ConsoleColumn> columns;
  final List<ConsoleRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                for (final column in columns)
                  _Cell(
                    width: column.width,
                    child: Text(
                      column.label,
                      style: LizmoType.rowSub.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          for (final (index, row) in rows.indexed)
            _Row(row: row, first: index == 0),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.first});

  final ConsoleRow row;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEDF1EF))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (index, cell) in row.cells.indexed)
              _Cell(width: _widthFor(context, index), child: cell),
          ],
        ),
      ),
    );
  }

  /// Widths come from the table's columns, which the row does not hold — so
  /// this is resolved by position against the enclosing table.
  double? _widthFor(BuildContext context, int index) {
    final table = context.findAncestorWidgetOfExactType<ConsoleTable>();
    if (table == null || index >= table.columns.length) return null;
    return table.columns[index].width;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    if (width == null) {
      return Expanded(child: child);
    }
    return SizedBox(width: width, child: child);
  }
}
