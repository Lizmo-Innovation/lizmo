import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';

/// Full-width coral action button.
///
/// Coral is the action accent and appears **once per screen**, on the single
/// most important action. Everything secondary is a text button or plain row.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: LizmoColors.coral,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: LizmoType.buttonLabel,
            ),
          ),
        ),
      ),
    );
  }
}
