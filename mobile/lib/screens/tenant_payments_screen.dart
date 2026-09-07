import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/declare_payment_sheet.dart';
import '../widgets/rent_schedule_list.dart';
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
                : _Rent(leaseId: lease.id!),
          ),
        ],
      ),
    );
  }
}

/// The months of rent on this tenancy.
///
/// This screen used to say Lizmo could not record payments and that the tenant
/// should keep their own receipts. It can now record what is owed; recording
/// what has been handed over comes next.
class _Rent extends ConsumerStatefulWidget {
  const _Rent({required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<_Rent> createState() => _RentState();
}

class _RentState extends ConsumerState<_Rent> {
  bool _sending = false;

  Future<void> _declare(BillingPeriodResponse period) async {
    final said = await DeclarePaymentSheet.show(
      context,
      periodLabel: period.label ?? 'this month',
      outstanding: period.outstanding ?? 0,
    );
    if (said == null || !mounted) return;

    setState(() => _sending = true);
    try {
      await ref.read(rentApiProvider).declarePayment(
            widget.leaseId,
            RecordPaymentRequest(
              billingPeriodId: period.id!,
              amountPaid: said.amount,
              paymentMethod: said.method,
              remarks: said.note,
            ),
            proof: said.proof == null
                ? null
                : http.MultipartFile.fromBytes(
                    'proof',
                    await said.proof!.readAsBytes(),
                    filename: said.proof!.name,
                  ),
          );
      ref.invalidate(myBillingProvider(widget.leaseId));
      ref.invalidate(myPaymentsProvider(widget.leaseId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Told your landlord. They will confirm it.'),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiFailure.from(error).message),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(myBillingProvider(widget.leaseId));

    if (_sending) {
      return const Center(child: CircularProgressIndicator());
    }

    return billing.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => LizmoMessageState(
        icon: Icons.error_outline,
        title: 'Could not load your rent',
        detail: ApiFailure.from(error).message,
      ),
      data: (periods) => RefreshIndicator(
        // Refreshing is also how the schedule catches up: months are written
        // when somebody looks.
        onRefresh: () async => ref.invalidate(myBillingProvider(widget.leaseId)),
        child: RentScheduleList(
          periods: periods,
          emptyDetail: 'Your first month appears once the tenancy has started.',
          onTap: _declare,
        ),
      ),
    );
  }
}
