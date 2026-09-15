import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'full_screen_image.dart';

/// Where to send money to Lizmo: each channel an admin switched on, in order,
/// then the note.
///
/// On the billing screen and inside the "I have paid this" sheet, so a
/// landlord copying a number never has to close one to find it in the other.
class LizmoPaymentChannels extends StatelessWidget {
  const LizmoPaymentChannels({super.key, required this.details});

  final PaymentDetails details;

  @override
  Widget build(BuildContext context) {
    final teal = LizmoType.rowSub.copyWith(color: LizmoColors.teal900);
    final note = details.note?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final channel in details.channels) LizmoPaymentChannel(channel: channel),
        if (note != null && note.isNotEmpty)
          Text(note, key: const ValueKey('lizmo-payment-note'), style: teal)
        // Said honestly when missing, rather than leaving a landlord to guess
        // where the money goes.
        else if (details.channels.isEmpty)
          Text(
            'Lizmo has not added payment details yet. Contact Lizmo support '
            'before paying.',
            style: teal,
          ),
      ],
    );
  }
}

/// One way to pay: whose account, which number, and its QR when it has one.
///
/// The number copies on a tap, because it is about to be pasted into GCash or a
/// bank app, and retyped digits are how money goes to the wrong account. It
/// says "Copied" in place rather than with a snackbar, which inside a bottom
/// sheet would appear behind it.
class LizmoPaymentChannel extends StatefulWidget {
  const LizmoPaymentChannel({super.key, required this.channel});

  final PaymentChannelForLandlord channel;

  @override
  State<LizmoPaymentChannel> createState() => _LizmoPaymentChannelState();
}

class _LizmoPaymentChannelState extends State<LizmoPaymentChannel> {
  bool _copied = false;

  PaymentChannelForLandlord get channel => widget.channel;

  Future<void> _copy() async {
    final number = channel.accountNumber ?? '';
    if (number.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: number));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final id = channel.id;
    final qr = channel.qrUrl;

    return Container(
      key: ValueKey('lizmo-channel-$id'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel.channel ?? '',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
                const SizedBox(height: 2),
                Text(channel.accountName ?? '',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
                const SizedBox(height: 6),
                InkWell(
                  key: ValueKey('copy-channel-$id'),
                  onTap: _copy,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(channel.accountNumber ?? '',
                              style: LizmoType.dataMedium
                                  .copyWith(color: LizmoColors.ink)),
                        ),
                        const SizedBox(width: 6),
                        Icon(_copied ? Icons.check : Icons.copy_outlined,
                            size: 16, color: LizmoColors.teal900),
                        if (_copied) ...[
                          const SizedBox(width: 4),
                          Text('Copied',
                              style: LizmoType.rowSub
                                  .copyWith(fontSize: 11, color: LizmoColors.teal900)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (qr != null) ...[
            const SizedBox(width: 12),
            // Full screen on a tap: a QR is scanned from another phone, and a
            // thumbnail is too small for a camera to read.
            InkWell(
              key: ValueKey('qr-channel-$id'),
              onTap: () => FullScreenImage.show(
                context,
                qr,
                '${channel.channel ?? 'QR'} · ${channel.accountName ?? ''}',
                unavailable: 'That QR could not be loaded. Close this and pull '
                    'down on the billing screen to refresh it.',
              ),
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 64,
                  color: LizmoColors.canvas,
                  child: Image.network(
                    qr,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.qr_code_2, color: LizmoColors.teal900),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
