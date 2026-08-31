import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../tenant/tenant_providers.dart';
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
                // Only while something is missing. A finished profile is not
                // news, and a permanent banner is one a tenant stops seeing.
                if (ref.watch(myTenantProfileProvider).valueOrNull
                        ?.readyForALease ==
                    false) ...[
                  const _FinishYourProfile(),
                  const SizedBox(height: 18),
                ],

                const _FindAPlace(),
                const SizedBox(height: 18),

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

/// Shown until the profile carries what a lease needs.
///
/// A tenant has no reason to go looking for a profile screen, so the app asks
/// on the one screen they do open — and says why, rather than nagging.
class _FinishYourProfile extends StatelessWidget {
  const _FinishYourProfile();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LizmoColors.amberBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push(Routes.tenantProfile),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: 20, color: LizmoColors.amberText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finish your profile',
                      style: LizmoType.rowName
                          .copyWith(color: LizmoColors.amberText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your landlord needs an emergency contact and an ID '
                      'before you can sign a lease.',
                      style: LizmoType.rowSub
                          .copyWith(color: LizmoColors.amberText),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: LizmoColors.amberText),
            ],
          ),
        ),
      ),
    );
  }
}

/// The way in to finding somewhere to live.
///
/// On the home screen rather than behind a menu: a tenant with no lease yet has
/// exactly one thing to do in this app, and until leases exist that is true of
/// every tenant.
class _FindAPlace extends StatelessWidget {
  const _FindAPlace();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LizmoColors.tealBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push(Routes.findProperty),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner,
                  size: 20, color: LizmoColors.teal900),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Looking for a room?',
                      style: LizmoType.rowName
                          .copyWith(color: LizmoColors.teal900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter the code from the gate to see what is free.',
                      style: LizmoType.rowSub
                          .copyWith(color: LizmoColors.teal900),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: LizmoColors.teal900),
            ],
          ),
        ),
      ),
    );
  }
}
