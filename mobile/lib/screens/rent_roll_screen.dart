import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';


/// Landlord's rent roll for one property and month.
///
/// Currently rendered from the fixture below — this screen exists to prove the
/// design language in Flutter. Wiring it to `GET /properties/{id}/reports/rent-roll`
/// replaces [_fixture] only; no layout here should need to change.
class RentRollScreen extends StatelessWidget {
  const RentRollScreen({super.key});

  static const _fixture = [
    (
      name: 'Ana Reyes — Bed 1',
      subtitle: 'due Aug 5',
      amount: '₱2,500',
      status: LizmoStatus.paid,
      label: 'Paid',
    ),
    (
      name: 'Miguel Cruz — Bed 2',
      subtitle: 'due Aug 5',
      amount: '₱2,150',
      status: LizmoStatus.overdue,
      label: 'Overdue',
    ),
    (
      name: 'Unit 2B — whole unit',
      subtitle: 'due Aug 10',
      amount: '₱7,000',
      status: LizmoStatus.pending,
      label: 'Pending',
    ),
    (
      name: 'Jhun Santos — Bed 3',
      subtitle: 'due Aug 5',
      amount: '₱2,500',
      status: LizmoStatus.paid,
      label: 'Paid',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          const LatticeHeader(
            eyebrow: 'Sunrise Apartments',
            title: 'Rent roll — August',
            stats: [
              LatticeHeaderStat(value: '9/12', label: 'Slots occupied'),
              LatticeHeaderStat(value: '₱2,150', label: 'Overdue total'),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              children: [
                Text('Tenants', style: LizmoType.sectionHeading),
                const SizedBox(height: 10),
                for (final row in _fixture)
                  TenantCard(
                    name: row.name,
                    subtitle: row.subtitle,
                    amount: row.amount,
                    status: row.status,
                    statusLabel: row.label,
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
                label: '+ Record a payment',
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
