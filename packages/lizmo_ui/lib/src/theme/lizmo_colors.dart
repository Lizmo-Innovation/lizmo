import 'package:flutter/material.dart';

/// Colour tokens from `docs/lizmo_design_language_v2.html`.
///
/// Status colour mapping is fixed across the app: teal = paid/confirmed,
/// amber = pending/awaiting verification, red = overdue/rejected. Coral is the
/// action accent (primary buttons), never a status.
abstract final class LizmoColors {
  static const teal900 = Color(0xFF0E5C52);
  static const tealTint = Color(0xFFDCEEE9);
  static const tealBg = Color(0xFFDEF2EC);

  static const canvas = Color(0xFFF6F8F7);
  static const ink = Color(0xFF12211E);
  static const slate = Color(0xFF6B7B77);
  static const white = Color(0xFFFFFFFF);

  static const coral = Color(0xFFFF6952);

  static const amber = Color(0xFFF5A623);
  static const amberBg = Color(0xFFFDF1DC);

  /// Darkened amber for text on [amberBg] — the raw amber fails contrast.
  static const amberText = Color(0xFF8A5A0A);

  static const red = Color(0xFFDA4A42);
  static const redBg = Color(0xFFFBE6E5);

  /// Card resting shadow: `0 1px 2px rgba(18,33,30,0.06)`.
  static const cardShadow = BoxShadow(
    color: Color(0x0F12211E),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
}
