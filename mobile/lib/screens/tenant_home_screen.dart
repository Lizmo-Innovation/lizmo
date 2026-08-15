import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/account_sheet.dart';
import '../widgets/role_switcher.dart';

/// What a tenant sees: what they owe, when it is due, and what they have paid.
///
/// Deliberately not a smaller rent roll. A tenant has exactly one lease in view
/// and one question — am I settled? — so the balance leads and everything else
/// is history beneath it.
///
/// Rendered from fixtures until the lease and billing endpoints exist; wiring
/// them replaces [_periods] without changing this layout.
class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  static const _periods = [
    (
      label: 'August 2026',
      due: 'due Aug 5',
      amount: '₱2,500',
      status: LizmoStatus.overdue,
      chip: 'Overdue',
    ),
    (
      label: 'July 2026',
      due: 'paid Jul 3',
      amount: '₱2,500',
      status: LizmoStatus.paid,
      chip: 'Paid',
    ),
    (
      label: 'June 2026',
      due: 'paid Jun 4',
      amount: '₱2,500',
      status: LizmoStatus.paid,
      chip: 'Paid',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          const LatticeHeader(
            eyebrow: 'Sunrise Apartments',
            title: 'Bed 2, Unit 2B',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [RoleSwitcher(), SizedBox(width: 4), AccountButton()],
            ),
            stats: [
              // The two facts a tenant opens the app for.
              LatticeHeaderStat(value: '₱2,500', label: 'Due now'),
              LatticeHeaderStat(value: 'Aug 5', label: 'Due date'),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              children: [
                Text('Billing periods', style: LizmoType.sectionHeading),
                const SizedBox(height: 10),
                for (final period in _periods)
                  TenantCard(
                    name: period.label,
                    subtitle: period.due,
                    amount: period.amount,
                    status: period.status,
                    statusLabel: period.chip,
                    onTap: () {},
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryActionButton(
                label: '+ Submit a payment',
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
