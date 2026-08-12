import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// One landlord's platform payment awaiting review by a Lizmo admin.
///
/// Unlike the tenant-facing cards in the mobile app, this one carries the two
/// decisions directly on the row — an admin working through a queue shouldn't
/// need to open each item to act on it.
class PlatformPaymentCard extends StatelessWidget {
  const PlatformPaymentCard({
    super.key,
    required this.landlord,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.statusLabel,
    this.onConfirm,
    this.onReject,
    this.onViewProof,
  });

  final String landlord;

  /// Method and date, e.g. "GCash · paid Aug 10".
  final String subtitle;

  /// Pre-formatted peso amount — rendered in mono.
  final String amount;

  final LizmoStatus status;
  final String statusLabel;

  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onViewProof;

  bool get _isActionable => status == LizmoStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(landlord, style: LizmoType.rowName),
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
          if (_isActionable) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _AdminAction(
                  label: 'View proof',
                  colour: LizmoColors.slate,
                  onPressed: onViewProof,
                ),
                const Spacer(),
                _AdminAction(
                  label: 'Reject',
                  colour: LizmoColors.red,
                  onPressed: onReject,
                ),
                const SizedBox(width: 8),
                _AdminAction(
                  label: 'Confirm',
                  colour: LizmoColors.teal900,
                  filled: true,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.label,
    required this.colour,
    this.filled = false,
    this.onPressed,
  });

  final String label;
  final Color colour;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? colour : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: LizmoType.chipLabel.copyWith(
              color: filled ? LizmoColors.white : colour,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
