import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';

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
  });

  /// Property name shown above the title, uppercased.
  final String eyebrow;
  final String title;

  /// Summary figures rendered across the bottom of the header.
  final List<LatticeHeaderStat> stats;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: CustomPaint(
        // The painter lays down the teal fill *and* the lattice; an opaque
        // background on the child would paint straight over the grid.
        painter: _LatticePainter(),
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
              Text(eyebrow.toUpperCase(), style: LizmoType.eyebrow),
              const SizedBox(height: 6),
              Text(title, style: LizmoType.screenTitle),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final (i, stat) in stats.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: _StatCard(stat: stat)),
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
  const _StatCard({required this.stat});

  final LatticeHeaderStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LizmoColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.value, style: LizmoType.dataLarge),
          const SizedBox(height: 2),
          Text(stat.label, style: LizmoType.statLabel),
        ],
      ),
    );
  }
}

/// Paints the 18px lattice grid behind the header content.
class _LatticePainter extends CustomPainter {
  static const _cell = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = LizmoColors.teal900,
    );

    final paint = Paint()
      ..color = LizmoColors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var x = _cell; x < size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = _cell; y < size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LatticePainter oldDelegate) => false;
}
