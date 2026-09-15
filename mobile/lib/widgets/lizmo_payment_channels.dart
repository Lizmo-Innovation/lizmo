import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'full_screen_image.dart';

/// "How to pay", as a panel: a heading and the channels under it.
///
/// Lizmo's billing screen and a tenant's Rent tab, the same panel pointed at
/// different people. Says so honestly while loading or when it failed, rather
/// than calling a failed load "no details".
class HowToPayPanel extends StatelessWidget {
  const HowToPayPanel({
    super.key,
    required this.title,
    required this.details,
    required this.emptyMessage,
    required this.qrUnavailable,
  });

  final String title;
  final AsyncValue<PaymentDetails> details;
  final String emptyMessage;
  final String qrUnavailable;

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (details) {
      AsyncData(:final value) => LizmoPaymentChannels(
          details: value,
          emptyMessage: emptyMessage,
          qrUnavailable: qrUnavailable,
        ),
      // Unknown is not "none": a failed load saying there are no details
      // would send somebody to ask over a bad connection.
      AsyncError() => Text('Could not load how to pay. Pull down to try again.',
          style: LizmoType.rowSub.copyWith(color: LizmoColors.red)),
      _ => const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.tealBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LizmoType.rowName.copyWith(color: LizmoColors.teal900)),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

/// Where to send money: each channel switched on, in order, then the note.
///
/// Money to Lizmo on a landlord's billing screen, money to a landlord on a
/// tenant's Rent tab, and inside both "I have paid" sheets, so a number is
/// copied where the payment is entered rather than by closing one to find it.
class LizmoPaymentChannels extends StatelessWidget {
  const LizmoPaymentChannels({
    super.key,
    required this.details,
    this.emptyMessage = _lizmoHasNone,
    this.qrUnavailable = _lizmoQrUnavailable,
  });

  final PaymentDetails details;

  /// What to say when there are no channels and no note.
  final String emptyMessage;

  /// What the full-screen QR says when its link has lapsed.
  final String qrUnavailable;

  static const _lizmoHasNone =
      'Lizmo has not added payment details yet. Contact Lizmo support before paying.';

  static const _lizmoQrUnavailable = 'That QR could not be loaded. Close this and '
      'pull down on the billing screen to refresh it.';

  @override
  Widget build(BuildContext context) {
    final teal = LizmoType.rowSub.copyWith(color: LizmoColors.teal900);
    final note = details.note?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final channel in details.channels)
          LizmoPaymentChannel(channel: channel, qrUnavailable: qrUnavailable),
        if (note != null && note.isNotEmpty)
          Text(note, key: const ValueKey('lizmo-payment-note'), style: teal)
        // Said honestly when missing, rather than leaving somebody to guess
        // where the money goes.
        else if (details.channels.isEmpty)
          Text(emptyMessage, style: teal),
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
  const LizmoPaymentChannel({
    super.key,
    required this.channel,
    this.qrUnavailable = LizmoPaymentChannels._lizmoQrUnavailable,
  });

  final PaymentChannelView channel;
  final String qrUnavailable;

  @override
  State<LizmoPaymentChannel> createState() => _LizmoPaymentChannelState();
}

class _LizmoPaymentChannelState extends State<LizmoPaymentChannel> {
  bool _copied = false;

  PaymentChannelView get channel => widget.channel;

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
                unavailable: widget.qrUnavailable,
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
