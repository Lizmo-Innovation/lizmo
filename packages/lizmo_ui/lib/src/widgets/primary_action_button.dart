import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';

/// Full-width coral action button.
///
/// Coral is the action accent and appears **once per screen**, on the single
/// most important action. Everything secondary is a text button or plain row.
///
/// A null [onPressed] renders it visibly disabled. It used to only stop
/// responding: full coral, unchanged, and inert — a button that looks tappable
/// and does nothing, which reads as the app being broken rather than as the
/// action not being available yet.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      child: Material(
        // Faded rather than greyed: it stays recognisably the same button, so
        // it is obvious what will light up once the form is complete.
        color: enabled
            ? LizmoColors.coral
            : LizmoColors.coral.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: enabled
                  ? LizmoType.buttonLabel
                  : LizmoType.buttonLabel.copyWith(
                      color: LizmoColors.white.withValues(alpha: 0.75),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
