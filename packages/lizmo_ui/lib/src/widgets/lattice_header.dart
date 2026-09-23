import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';
import 'lattice_background.dart';

/// The signature element: a teal header textured with a faint square lattice —
/// a nod to the shell-pane (capiz) windows of Philippine homes.
///
/// The grid is deliberately low-contrast (8% white). It should read as texture,
/// not as a visible table; if it draws the eye before the content does, it is
/// too strong.
class LatticeHeader extends StatelessWidget {
  const LatticeHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.stats = const [],
    this.leading,
    this.trailing,
  });

  /// Property name shown above the title, uppercased.
  final String eyebrow;
  final String title;

  /// Summary figures rendered across the bottom of the header.
  final List<LatticeHeaderStat> stats;

  /// Optional control at the top left — in practice always the back arrow,
  /// which belongs there on every screen that has one, the same place an
  /// [AppBar] would put it.
  ///
  /// Giving it its own row keeps the eyebrow and title flush with the content
  /// edge rather than indented around it.
  final Widget? leading;

  /// Optional control aligned to the title, e.g. the role switcher. Kept in the
  /// header rather than an app bar because this header *is* the app bar.
  ///
  /// Moves up beside [leading] when one is given, so the two never straddle
  /// different rows.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: CustomPaint(
        // The painter lays down the teal fill *and* the lattice; an opaque
        // background on the child would paint straight over the grid.
        painter: const LatticePainter(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            22,
            MediaQuery.paddingOf(context).top + 22,
            22,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                Row(
                  children: [
                    leading!,
                    const Spacer(),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // With no leading control the trailing one sits on the eyebrow
              // row rather than beside the title: the eyebrow is short, so the
              // title keeps the full width instead of wrapping into a narrow
              // column.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: LizmoType.eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (leading == null && trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(title, style: LizmoType.screenTitle),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final (i, stat) in stats.indexed) ...[
                      // Four across a phone is tight; the gaps and padding
                      // give a little back so the labels keep to one line.
                      if (i > 0) SizedBox(width: stats.length > 3 ? 8 : 10),
                      Expanded(
                          child: _StatCard(stat: stat, compact: stats.length > 3)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One summary figure in a [LatticeHeader].
class LatticeHeaderStat {
  const LatticeHeaderStat({required this.value, required this.label});

  /// Rendered in mono — this is a figure, not prose.
  final String value;
  final String label;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, this.compact = false});

  final LatticeHeaderStat stat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 10),
      decoration: BoxDecoration(
        color: LizmoColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shrinks rather than clips: a stat holding a count is short, but one
          // holding money grows with the portfolio, and a landlord with twenty
          // units should not lose a digit off the left of the figure.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stat.value, style: LizmoType.dataLarge, maxLines: 1),
          ),
          const SizedBox(height: 2),
          // One line, shrinking a touch if it must: a label that wraps makes
          // its card taller than its neighbours, and the row reads as broken.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stat.label, style: LizmoType.statLabel, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

