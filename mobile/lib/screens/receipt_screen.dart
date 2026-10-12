import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../billing/receipt_providers.dart';
import '../router.dart';
import '../widgets/lease_term.dart';
import '../widgets/receipt_card.dart';
import 'property_share_screen.dart' show captureBoundaryPng;

/// One receipt, and sending it on.
///
/// Found by its own id, or by the payment it acknowledges -- which is what a
/// "your payment was confirmed" notification knows.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.leaseId,
    required this.landlord,
    this.receiptId,
    this.paymentId,
  });

  final String leaseId;
  final bool landlord;
  final String? receiptId;
  final String? paymentId;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  /// Around the receipt alone, so the image is the receipt and nothing else.
  final _paper = GlobalKey();
  bool _sharing = false;

  ReceiptResponse? _find(List<ReceiptResponse> receipts) {
    for (final receipt in receipts) {
      if (widget.receiptId != null && receipt.id == widget.receiptId) return receipt;
      if (widget.paymentId != null && receipt.paymentId == widget.paymentId) {
        return receipt;
      }
    }
    return null;
  }

  Future<void> _share(ReceiptResponse receipt) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await captureBoundaryPng(_paper);
      if (png == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't make the image. Try again.")),
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              // Named by its number, so it can be found in a gallery later.
              name: 'lizmo-receipt-${receipt.number}.png',
            ),
          ],
          // Alongside, for a chat that compresses the picture past reading.
          text: 'Receipt ${receipt.number}: ${LizmoMoney.peso(receipt.amount)} '
              'for ${receiptFor(receipt)}',
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open sharing. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(
        receiptsProvider((leaseId: widget.leaseId, landlord: widget.landlord)));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Receipt',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: receipts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LizmoMessageState(
          icon: Icons.error_outline,
          title: 'Could not load the receipt',
          detail: ApiFailure.from(error).message,
        ),
        data: (all) {
          final receipt = _find(all);
          if (receipt == null) {
            return LizmoMessageState(
              icon: Icons.receipt_long_outlined,
              title: 'No receipt yet',
              detail: widget.landlord
                  ? 'One is issued when you confirm the payment.'
                  : 'One is issued when your landlord confirms the payment.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              RepaintBoundary(
                key: _paper,
                // Canvas behind it, so the shared image has a margin rather
                // than a receipt cut off at its own border.
                child: Container(
                  color: LizmoColors.canvas,
                  padding: const EdgeInsets.all(8),
                  child: ReceiptCard(receipt: receipt),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryActionButton(
                key: const ValueKey('share-receipt'),
                label: _sharing ? 'Getting it ready…' : 'Share receipt',
                onPressed: _sharing ? null : () => _share(receipt),
              ),
              const SizedBox(height: 8),
              Text(
                widget.landlord
                    ? 'Your tenant has this receipt in their app too.'
                    : 'As a picture, for Messenger, Viber, email or your files.',
                textAlign: TextAlign.center,
                style: LizmoType.rowSub,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Every receipt on a tenancy, by year, newest first.
class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({
    super.key,
    required this.leaseId,
    required this.landlord,
  });

  final String leaseId;
  final bool landlord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts =
        ref.watch(receiptsProvider((leaseId: leaseId, landlord: landlord)));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Receipts',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: receipts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LizmoMessageState(
          icon: Icons.error_outline,
          title: 'Could not load receipts',
          detail: ApiFailure.from(error).message,
        ),
        data: (all) {
          if (all.isEmpty) {
            return LizmoMessageState(
              icon: Icons.receipt_long_outlined,
              title: 'No receipts yet',
              detail: landlord
                  ? 'One is issued each time you confirm or record a payment.'
                  : 'One appears each time your landlord confirms a payment.',
            );
          }
          final years = <int, List<ReceiptResponse>>{};
          for (final receipt in all) {
            final year = receipt.issuedAt?.toLocal().year ?? 0;
            years.putIfAbsent(year, () => []).add(receipt);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
                receiptsProvider((leaseId: leaseId, landlord: landlord))),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                for (final MapEntry(key: year, value: ofYear) in years.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
                    child: Text(
                      '$year',
                      style: LizmoType.rowSub.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final receipt in ofYear) _ReceiptRow(receipt: receipt),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt});

  final ReceiptResponse receipt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: LizmoColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE3E8E6)),
        ),
        child: InkWell(
          key: ValueKey('receipt-${receipt.id}'),
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: () => context.openInTab(
              Detail.receipt(receipt.leaseId!, receipt.id!)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 20, color: LizmoColors.teal900),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(receiptFor(receipt), style: LizmoType.rowName),
                      const SizedBox(height: 2),
                      Text(
                        [
                          'No. ${receipt.number}',
                          if (receipt.issuedAt case final at?)
                            termDate(at.toLocal()),
                        ].join(' · '),
                        style: LizmoType.rowSub.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  LizmoMoney.peso(receipt.amount),
                  style: LizmoType.dataMedium.copyWith(color: LizmoColors.ink),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: LizmoColors.slate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
