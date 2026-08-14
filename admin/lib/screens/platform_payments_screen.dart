import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/platform_payment_card.dart';

/// Lizmo-internal review queue for landlord platform payments.
///
/// Backs `GET /admin/billing-cycles` and the confirm/reject routes. Confirming
/// the last outstanding cycle for a landlord is what lifts an `ACCOUNT_LOCKED`
/// state, so this queue is the release valve for locked-out landlords — it
/// should stay short.
///
/// Rendered from [_fixture] until the API exists.
class PlatformPaymentsScreen extends StatelessWidget {
  const PlatformPaymentsScreen({super.key});

  /// Web layout is centred and capped — full-bleed rows on a wide monitor are
  /// unreadable, and this queue is a list, not a dashboard.
  static const _maxContentWidth = 720.0;

  static const _fixture = [
    (
      landlord: 'Elena Bautista',
      subtitle: 'GCash · paid Aug 10 · 14 beds, 2 units',
      amount: '₱1,000',
      status: LizmoStatus.pending,
      label: 'Pending',
    ),
    (
      landlord: 'Rodel Mercado',
      subtitle: 'Bank transfer · paid Aug 9 · 6 beds',
      amount: '₱300',
      status: LizmoStatus.pending,
      label: 'Pending',
    ),
    (
      landlord: 'Grace Villanueva',
      subtitle: 'Unpaid since Aug 1 · account locked',
      amount: '₱750',
      status: LizmoStatus.overdue,
      label: 'Overdue',
    ),
    (
      landlord: 'Marites Ocampo',
      subtitle: 'Maya · confirmed Aug 8',
      amount: '₱450',
      status: LizmoStatus.paid,
      label: 'Confirmed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            children: [
              LatticeHeader(
                eyebrow: 'Lizmo admin',
                title: 'Platform payments',
                trailing: _SignOutButton(),
                stats: const [
                  LatticeHeaderStat(value: '2', label: 'Awaiting review'),
                  LatticeHeaderStat(value: '1', label: 'Locked accounts'),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  children: [
                    Text('Review queue', style: LizmoType.sectionHeading),
                    const SizedBox(height: 10),
                    for (final row in _fixture)
                      PlatformPaymentCard(
                        landlord: row.landlord,
                        subtitle: row.subtitle,
                        amount: row.amount,
                        status: row.status,
                        statusLabel: row.label,
                        onConfirm: () {},
                        onReject: () {},
                        onViewProof: () {},
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sign-out control in the console header.
///
/// Present because an admin session can confirm payments to Lizmo, so leaving
/// one open on a shared desk should be easy to undo.
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(authControllerProvider.notifier).logout(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Sign out',
        style: LizmoType.chipLabel.copyWith(
          color: LizmoColors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
