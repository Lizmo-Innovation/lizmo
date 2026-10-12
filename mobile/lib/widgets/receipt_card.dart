import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/pesos_in_words.dart';
import 'lease_term.dart';

/// An acknowledgement receipt, laid out like the paper one people expect.
///
/// What it is, its number and date across the top; who paid what, in figures
/// and in words, for what; who received it at the foot. The same widget is
/// shown on screen and turned into the image that is shared, so what
/// somebody sends is exactly what they saw.
///
/// It says on its face that it is not a BIR official receipt. Lizmo cannot
/// issue those, and a landlord should not be made to look as if it had.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt});

  final ReceiptResponse receipt;

  @override
  Widget build(BuildContext context) {
    final amount = receipt.amount ?? 0;
    final owed = receipt.stillOwed ?? 0;

    return Container(
      key: const ValueKey('receipt-card'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'ACKNOWLEDGEMENT RECEIPT',
                  style: LizmoType.rowSub.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: LizmoColors.teal900,
                  ),
                ),
              ),
              Text(
                'No. ${receipt.number ?? ''}',
                key: const ValueKey('receipt-number'),
                style: LizmoType.dataMedium.copyWith(color: LizmoColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Issued ${_when(receipt.issuedAt)}',
            style: LizmoType.rowSub.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 18),

          Text('Received from', style: LizmoType.rowSub.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(receipt.receivedFrom ?? '',
              style: LizmoType.rowName.copyWith(fontSize: 16)),
          const SizedBox(height: 14),

          Text('The sum of', style: LizmoType.rowSub.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            LizmoMoney.peso(amount),
            key: const ValueKey('receipt-amount'),
            style: LizmoType.dataMedium.copyWith(
              fontSize: 28,
              color: LizmoColors.teal900,
            ),
          ),
          Text(
            pesosInWords(amount),
            key: const ValueKey('receipt-amount-words'),
            style: LizmoType.rowSub.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          const _Rule(),
          const SizedBox(height: 12),

          _Line('For', receiptFor(receipt)),
          _Line('At', '${receipt.place ?? ''} · ${receipt.propertyName ?? ''}'),
          _Line('Paid by', _paidBy(receipt)),
          if (receipt.paidOn case final on?) _Line('Paid on', termDate(on)),
          _Line(
            owed > 0 ? 'Still owed' : 'Balance',
            owed > 0
                ? '${LizmoMoney.peso(owed)} of ${_owedOn(receipt)}'
                : '${_owedOn(receipt, capital: true)} is paid in full',
          ),

          const SizedBox(height: 12),
          const _Rule(),
          const SizedBox(height: 12),
          Text('Received by', style: LizmoType.rowSub.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(receipt.receivedBy ?? '',
              style: LizmoType.rowName.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          Text(
            'Recorded in Lizmo. Not a BIR official receipt.',
            key: const ValueKey('receipt-not-bir'),
            style: LizmoType.rowSub.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// "3:42 PM, 12 October 2026", in the phone's own time.
  static String _when(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final half = local.hour < 12 ? 'AM' : 'PM';
    return '${termDate(local)}, $hour:$minute $half';
  }

  static String _paidBy(ReceiptResponse receipt) {
    final how = paymentMethodLabel(receipt.paymentMethod?.toJson());
    final to = receipt.sentTo;
    return to == null || to.isEmpty ? how : '$how, to $to';
  }

  static String _owedOn(ReceiptResponse receipt, {bool capital = false}) {
    if (receipt.kind == ReceiptResponseKindEnum.DEPOSIT) {
      return capital ? 'The deposit' : 'the deposit';
    }
    return _month(receipt.periodLabel);
  }
}

/// What the money was for, in words: "October 2026 rent", "October 2026
/// rent, paid in advance", "Security deposit, to be returned at move-out".
String receiptFor(ReceiptResponse receipt) {
  if (receipt.kind == ReceiptResponseKindEnum.DEPOSIT) {
    return 'Security deposit, to be returned at move-out';
  }
  final label = receipt.periodLabel ?? '';
  if (label.contains('advance')) return '${_month(label)} rent, paid in advance';
  return '$label rent';
}

/// "October 2026" out of "October 2026 · advance".
String _month(String? label) => (label ?? '').split(' · ').first;

/// How it was paid, as somebody would say it.
String paymentMethodLabel(String? method) => switch (method) {
      'GCASH' => 'GCash',
      'MAYA' => 'Maya',
      'BANK_TRANSFER' => 'Bank transfer',
      'CASH' => 'Cash',
      'ADVANCE' => 'Advance rent',
      _ => 'Other',
    };

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: LizmoType.rowSub.copyWith(fontSize: 12)),
          ),
          Expanded(child: Text(value, style: LizmoType.rowName)),
        ],
      ),
    );
  }
}

/// A dashed line across, the way a paper receipt divides itself.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashes = (constraints.maxWidth / 8).floor();
        return Row(
          children: [
            for (var i = 0; i < dashes; i++)
              Container(
                width: 4,
                height: 1,
                margin: const EdgeInsets.only(right: 4),
                color: const Color(0xFFD0D8D5),
              ),
          ],
        );
      },
    );
  }
}
