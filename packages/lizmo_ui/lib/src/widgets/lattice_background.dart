import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';

/// The capiz-lattice texture on teal, as a surface anything can sit on.
///
/// A nod to the shell-pane windows of Philippine homes, and the one element
/// that makes a screen unmistakably Lizmo. [LatticeHeader] is the usual way to
/// meet it; this is the same texture unbounded, for a screen that is entirely
/// header — the splash.
///
/// The grid is deliberately low-contrast (8% white). It should read as texture,
/// not as a visible table; if it draws the eye before the content does, it is
/// too strong.
class LatticeBackground extends StatelessWidget {
  const LatticeBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // The painter lays down the teal fill *and* the lattice; an opaque
      // background on the child would paint straight over the grid.
      painter: const LatticePainter(),
      size: Size.infinite,
      child: child,
    );
  }
}

/// Paints the teal fill and the lattice over it.
class LatticePainter extends CustomPainter {
  const LatticePainter();

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
  bool shouldRepaint(LatticePainter oldDelegate) => false;
}
