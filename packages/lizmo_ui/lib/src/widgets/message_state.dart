import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';

/// A centred message for when a screen has nothing to show — empty, failed, or
/// not yet reachable.
///
/// One widget for all three because they are the same shape: say what happened,
/// then offer the one action that helps. Screens differ in wording, not layout.
class LizmoMessageState extends StatelessWidget {
  const LizmoMessageState({
    super.key,
    required this.title,
    this.detail,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.tone = LizmoMessageTone.neutral,
  });

  final String title;
  final String? detail;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final LizmoMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final colour = switch (tone) {
      LizmoMessageTone.neutral => LizmoColors.slate,
      LizmoMessageTone.problem => LizmoColors.red,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 32, color: colour),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: LizmoType.rowName.copyWith(fontSize: 16),
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(detail!, textAlign: TextAlign.center, style: LizmoType.rowSub),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum LizmoMessageTone {
  /// Nothing is wrong — there is simply nothing here yet.
  neutral,

  /// Something failed. Uses the red status colour, never coral: coral is the
  /// action accent, and reusing it for failure blurs both meanings.
  problem,
}
