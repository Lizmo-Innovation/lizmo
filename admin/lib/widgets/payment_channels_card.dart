import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';
import 'payment_channel_dialog.dart';

/// The ways landlords pay Lizmo, on the Settings screen.
///
/// Landlords see the channels switched on, in this order. Switching one off
/// keeps it here for later -- a wallet at its limit for the month -- while
/// Delete is for good, and asks first.
class PaymentChannelsCard extends ConsumerStatefulWidget {
  const PaymentChannelsCard({super.key});

  @override
  ConsumerState<PaymentChannelsCard> createState() => _PaymentChannelsCardState();
}

class _PaymentChannelsCardState extends ConsumerState<PaymentChannelsCard> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function(AdminApi api) call) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await call(ref.read(adminApiProvider));
    } on Object catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      ref.invalidate(paymentChannelsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([PaymentChannelResponse? channel]) async {
    final saved = await PaymentChannelDialog.show(context, existing: channel);
    if (saved == true) ref.invalidate(paymentChannelsProvider);
  }

  Future<void> _show(PaymentChannelResponse channel, bool shown) => _run(
        (api) => api.updatePaymentChannel(
          channel.id!,
          // The details go back unchanged: the endpoint takes the whole channel.
          PaymentChannelRequest(
            channel: channel.channel ?? '',
            accountName: channel.accountName ?? '',
            accountNumber: channel.accountNumber ?? '',
            visible: shown,
          ),
        ),
      );

  Future<void> _move(List<PaymentChannelResponse> rows, int from, int to) {
    final ids = [for (final row in rows) row.id!];
    ids.insert(to, ids.removeAt(from));
    return _run((api) => api.reorderPaymentChannels(PaymentChannelOrder(ids: ids)));
  }

  Future<void> _delete(PaymentChannelResponse channel) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${channel.channel}?', style: LizmoType.sectionHeading),
        content: Text(
          'Landlords stop seeing it straight away, and its QR is deleted too. '
          'To keep it for later, switch it off instead.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-delete-channel'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: LizmoColors.red)),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await _run((api) => api.deletePaymentChannel(channel.id!));
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(paymentChannelsProvider);

    return Container(
      key: const ValueKey('payment-channels-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('How landlords pay Lizmo', style: LizmoType.sectionHeading),
              ),
              OutlinedButton.icon(
                key: const ValueKey('add-payment-channel'),
                onPressed: _busy ? null : () => _edit(),
                icon: const Icon(Icons.add, size: 18, color: LizmoColors.teal900),
                label: Text('Add channel',
                    style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.teal900)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Landlords see the channels switched on, in this order, beside '
            'every Lizmo statement. Switch one off to keep it for later.',
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 12),
          channels.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => Text(ApiFailure.from(error).message,
                style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No channels yet. Until you add one, landlords see only '
                      'the note below.',
                      style: LizmoType.rowSub,
                    ),
                  )
                : Column(
                    children: [
                      for (final (index, channel) in rows.indexed)
                        _Row(
                          channel: channel,
                          first: index == 0,
                          last: index == rows.length - 1,
                          busy: _busy,
                          onShow: (shown) => _show(channel, shown),
                          onUp: () => _move(rows, index, index - 1),
                          onDown: () => _move(rows, index, index + 1),
                          onEdit: () => _edit(channel),
                          onDelete: () => _delete(channel),
                        ),
                    ],
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.channel,
    required this.first,
    required this.last,
    required this.busy,
    required this.onShow,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentChannelResponse channel;
  final bool first;
  final bool last;
  final bool busy;
  final ValueChanged<bool> onShow;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final id = channel.id;
    final shown = channel.visible ?? true;

    return Container(
      key: ValueKey('payment-channel-$id'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDF1EF))),
      ),
      child: Row(
        children: [
          QrThumbnail(url: channel.qrUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(channel.channel ?? '', style: LizmoType.rowName),
                    ),
                    if (!shown) ...[
                      const SizedBox(width: 8),
                      const StatusChip(status: LizmoStatus.vacant, label: 'Hidden'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${channel.accountName ?? ''} · ${channel.accountNumber ?? ''}',
                    style: LizmoType.rowSub),
              ],
            ),
          ),
          Tooltip(
            message: shown ? 'Shown to landlords' : 'Hidden from landlords',
            child: Switch(
              key: ValueKey('channel-visible-$id'),
              value: shown,
              onChanged: busy ? null : onShow,
            ),
          ),
          IconButton(
            key: ValueKey('channel-up-$id'),
            tooltip: 'Move up',
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: busy || first ? null : onUp,
          ),
          IconButton(
            key: ValueKey('channel-down-$id'),
            tooltip: 'Move down',
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: busy || last ? null : onDown,
          ),
          TextButton(
            key: ValueKey('edit-channel-$id'),
            onPressed: busy ? null : onEdit,
            child: Text('Edit',
                style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.teal900)),
          ),
          TextButton(
            key: ValueKey('delete-channel-$id'),
            onPressed: busy ? null : onDelete,
            child: Text('Delete',
                style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.red)),
          ),
        ],
      ),
    );
  }
}
