import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Why a payment was refused.
///
/// Asked rather than assumed, because the tenant is told the answer and
/// "not confirmed" with no reason is how a disagreement becomes a row.
///
/// Shared by the tenant's screen and the Rent tab, so refusing a payment
/// asks the same question wherever it happens.
class NotReceivedDialog extends StatefulWidget {
  const NotReceivedDialog({super.key});

  /// The reason, which may be empty; null when the landlord backed out, which
  /// is not a refusal.
  static Future<String?> ask(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const NotReceivedDialog(),
    );
  }

  @override
  State<NotReceivedDialog> createState() => _NotReceivedDialogState();
}

class _NotReceivedDialogState extends State<NotReceivedDialog> {
  final _why = TextEditingController();

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Say it did not arrive?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your tenant sees this, so a line about what happened saves a '
            'conversation.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('reject-reason'),
            controller: _why,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Nothing arrived in my GCash.',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('reject-confirm'),
          onPressed: () => Navigator.of(context).pop(_why.text.trim()),
          child: Text('Not received',
              style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
        ),
      ],
    );
  }
}
