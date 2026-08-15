import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';

/// The one status indicator in the app: a tinted pill with a leading dot.
///
/// Never substitute a badge, stamp, border or bare icon — a landlord scanning a
/// long list relies on these reading identically everywhere.
enum LizmoStatus {
  /// Paid, confirmed, active.
  paid(LizmoColors.tealBg, LizmoColors.teal900, LizmoColors.teal900),

  /// Awaiting verification.
  pending(LizmoColors.amberBg, LizmoColors.amberText, LizmoColors.amber),

  /// Overdue, rejected.
  overdue(LizmoColors.redBg, LizmoColors.red, LizmoColors.red),

  /// Nothing is happening here: a vacant bed, an inactive assignment.
  ///
  /// Deliberately grey rather than a colour. Vacancy is not good news or bad —
  /// giving it teal would read as healthy and red as a problem, when it is
  /// simply an empty slot. It also keeps the three meaningful colours scarce,
  /// which is what makes them scannable in a long list.
  vacant(Color(0xFFEFF2F1), LizmoColors.slate, LizmoColors.slate);

  const LizmoStatus(this.background, this.foreground, this.dot);

  final Color background;
  final Color foreground;

  /// The dot may differ from the text colour: on amber the text is darkened for
  /// contrast, while the dot keeps the true amber.
  final Color dot;
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.label});

  final LizmoStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: status.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: LizmoType.chipLabel.copyWith(color: status.foreground)),
        ],
      ),
    );
  }
}
