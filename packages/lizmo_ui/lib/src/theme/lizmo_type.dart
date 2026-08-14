import 'package:flutter/material.dart';

import 'lizmo_colors.dart';

/// Type roles from `docs/lizmo_design_language_v2.html`.
///
/// Three families, each with one job:
/// - **Space Grotesk** — display: screen titles, section labels
/// - **Manrope** — body: everything else in the interface
/// - **IBM Plex Mono** — data: every peso amount, date and figure
///
/// The mono rule is not decorative. Any number a landlord reads as a value
/// (amounts, dates, counts) renders in [dataMedium]/[dataLarge], never in
/// Manrope — that is what makes a column of figures scannable.
///
/// Fonts are bundled with this package, so every style names
/// `package: 'lizmo_ui'`. Without it Flutter looks for the family in the
/// *consuming* app and silently falls back.
abstract final class LizmoType {
  static const _package = 'lizmo_ui';

  static const _display = 'Space Grotesk';
  static const _body = 'Manrope';
  static const _data = 'IBM Plex Mono';

  /// Space Grotesk and Manrope ship only as variable fonts. Flutter maps
  /// [TextStyle.fontWeight] onto the `wght` axis, but that mapping has been
  /// inconsistent across platforms, so the axis is also set explicitly. Both
  /// are given: `fontWeight` still drives layout and fallback.
  static List<FontVariation> _wght(double weight) => [FontVariation('wght', weight)];

  // ---- Display (Space Grotesk) ----

  /// Screen title inside the lattice header, 22/700.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: _display,
    package: _package,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    color: LizmoColors.white,
    height: 1.2,
  );

  /// List/section heading, 14/500.
  static const TextStyle sectionHeading = TextStyle(
    fontFamily: _display,
    package: _package,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    color: LizmoColors.ink,
  );

  // ---- Body (Manrope) ----

  /// Primary row text (tenant name, unit), 14/600.
  static const TextStyle rowName = TextStyle(
    fontFamily: _body,
    package: _package,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    color: LizmoColors.ink,
  );

  /// Secondary row metadata, 12/400.
  static const TextStyle rowSub = TextStyle(
    fontFamily: _body,
    package: _package,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    color: LizmoColors.slate,
  );

  /// Chip label, 11/600. Colour is set per status by the chip itself.
  static const TextStyle chipLabel = TextStyle(
    fontFamily: _body,
    package: _package,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  /// Stat card caption on the teal header, 11/400.
  static TextStyle get statLabel => TextStyle(
        fontFamily: _body,
        package: _package,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        fontVariations: _wght(400),
        color: LizmoColors.white.withValues(alpha: 0.65),
      );

  /// Primary action button label, 14/700.
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _body,
    package: _package,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    color: LizmoColors.white,
  );

  // ---- Data (IBM Plex Mono) ----
  // Static weights, so no axis to set.

  /// Eyebrow above a screen title, 11, uppercase, +1 tracking.
  static TextStyle get eyebrow => TextStyle(
        fontFamily: _data,
        package: _package,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
        color: LizmoColors.white.withValues(alpha: 0.7),
      );

  /// Stat card figure on the teal header, 19/600.
  static const TextStyle dataLarge = TextStyle(
    fontFamily: _data,
    package: _package,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: LizmoColors.white,
  );

  /// Row amount, 15/600.
  static const TextStyle dataMedium = TextStyle(
    fontFamily: _data,
    package: _package,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: LizmoColors.ink,
  );
}
