import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/role_switcher.dart';

/// Rent: what is coming, and what has been paid.
///
/// Empty, and says so. Nothing raises a rent period yet — billing_periods and
/// payments exist in the schema and no endpoint writes to either — so there is
/// no history to show and no balance to compute.
///
/// This screen used to be three invented rows on the home screen saying 2,500
/// pesos was overdue. A tenant who had just signed up was told they owed money
/// on a property they had never heard of, which is worse than an empty screen
/// in every way: it is wrong, it is alarming, and it is convincing.
class TenantPaymentsScreen extends ConsumerWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lease = ref.watch(myLeasesProvider).valueOrNull?.firstOrNull;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          const LatticeHeader(
            eyebrow: 'Lizmo',
            title: 'Payments',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [RoleSwitcher(), SizedBox(width: 4), AccountButton()],
            ),
          ),
          Expanded(
            child: lease == null
                ? const LizmoMessageState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No rent to track yet',
                    detail: 'Once you are renting through Lizmo, what you owe '
                        'and what you have paid will be recorded here.',
                  )
                : LizmoMessageState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No bills yet',
                    detail: 'Your rent is ₱'
                        '${(lease.rentAmount ?? 0).toStringAsFixed(0)} a month. '
                        'Lizmo cannot record payments yet, so nothing you pay '
                        'your landlord shows up here — keep your own receipts '
                        'for now.',
                  ),
          ),
        ],
      ),
    );
  }
}
