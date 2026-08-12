import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lizmo_colors.dart';

/// Type roles from `docs/lizmo_design_language_v2.html`.
///
/// Three families, each with one job:
/// - **Space Grotesk** — display: screen titles, section labels
/// - **Manrope** — body: everything else in the interface
/// - **IBM Plex Mono** — data: every peso amount, date and figure
///
/// The mono rule is not decorative. Any number a landlord reads as a value
/// (amounts, dates, counts) renders in [dataMedium]/[dataLarge], never in Manrope.
abstract final class LizmoType {
  // ---- Display (Space Grotesk) ----

  /// Screen title inside the lattice header, 22/700.
  static TextStyle get screenTitle => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: LizmoColors.white,
        height: 1.2,
      );

  /// List/section heading, 14/500.
  static TextStyle get sectionHeading => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: LizmoColors.ink,
      );

  // ---- Body (Manrope) ----

  /// Primary row text (tenant name, unit), 14/600.
  static TextStyle get rowName => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: LizmoColors.ink,
      );

  /// Secondary row metadata, 12/400.
  static TextStyle get rowSub => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: LizmoColors.slate,
      );

  /// Chip label, 11/600. Colour is set per status by the chip itself.
  static TextStyle get chipLabel => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  /// Stat card caption on the teal header, 11/400.
  static TextStyle get statLabel => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: LizmoColors.white.withValues(alpha: 0.65),
      );

  /// Primary action button label, 14/700.
  static TextStyle get buttonLabel => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: LizmoColors.white,
      );

  // ---- Data (IBM Plex Mono) ----

  /// Eyebrow above a screen title, 11, uppercase, +1 tracking.
  static TextStyle get eyebrow => GoogleFonts.ibmPlexMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
        color: LizmoColors.white.withValues(alpha: 0.7),
      );

  /// Stat card figure on the teal header, 19/600.
  static TextStyle get dataLarge => GoogleFonts.ibmPlexMono(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: LizmoColors.white,
      );

  /// Row amount, 15/600.
  static TextStyle get dataMedium => GoogleFonts.ibmPlexMono(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: LizmoColors.ink,
      );
}
