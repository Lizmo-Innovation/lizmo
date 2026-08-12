import 'package:flutter/material.dart';

import '../theme/lizmo_colors.dart';
import '../theme/lizmo_type.dart';
import 'status_chip.dart';

/// A flat white row card: who owes what, and where that payment stands.
///
/// Used for both bedspace tenants ("Ana Reyes — Bed 1") and whole-unit leases
/// ("Unit 2B — whole unit"); the [name] carries that distinction rather than a
/// separate badge.
class TenantCard extends StatelessWidget {
  const TenantCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.statusLabel,
    this.onTap,
  });

  final String name;

  /// Metadata line, e.g. "due Aug 5".
  final String subtitle;

  /// Peso amount, pre-formatted — rendered in mono.
  final String amount;

  final LizmoStatus status;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: LizmoType.rowName),
                      const SizedBox(height: 2),
                      Text(subtitle, style: LizmoType.rowSub),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(amount, style: LizmoType.dataMedium),
                    const SizedBox(height: 6),
                    StatusChip(status: status, label: statusLabel),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
