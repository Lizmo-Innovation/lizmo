import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../property/property_providers.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/declare_payment_sheet.dart';
import '../widgets/lizmo_payment_channels.dart';
import '../widgets/notification_bell.dart';
import '../widgets/rent_schedule_list.dart';
import '../widgets/your_landlord_card.dart';
import '../widgets/role_switcher.dart';

/// Rent: what is owed, month by month, and saying it has been paid.
///
/// Called Rent rather than Payments, as on the landlord's side: it holds what
/// is owed as much as what was paid.
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
    final months = lease == null
        ? null
        : ref.watch(myBillingProvider(lease.id!)).valueOrNull;
    // The number a tenant opens this tab to find. Home already said it; the
    // tab that exists for rent made them add up the cards themselves.
    final owed =
        months?.fold<num>(0, (sum, month) => sum + (month.outstanding ?? 0));
    final late = months
        ?.where((month) => month.overdue == true)
        .fold<num>(0, (sum, month) => sum + (month.outstanding ?? 0));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: 'Lizmo',
            title: 'Rent',
            // A dash until the months are in, rather than a zero that would
            // read as "nothing owed".
            stats: lease == null
                ? const []
                : [
                    LatticeHeaderStat(
                      value: owed == null ? '—' : LizmoMoney.peso(owed),
                      label: 'Owed',
                    ),
                    LatticeHeaderStat(
                      value: late == null ? '—' : LizmoMoney.peso(late),
                      label: 'Overdue',
                    ),
                  ],
            // With the bell, like Home. News about rent is read here as often
            // as anywhere.
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
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
                : _Rent(
                    leaseId: lease.id!,
                    // By name in "Waiting for Maria", from the conversation
                    // with them, which is where the app knows it.
                    confirmer: threadForTenancy(
                            ref.watch(myInquiriesProvider).valueOrNull ??
                                const [],
                            lease)
                        ?.withName,
                  ),
          ),
        ],
      ),
    );
  }
}

/// The months of rent on this tenancy.
///
/// This screen used to say Lizmo could not record payments and that the tenant
/// should keep their own receipts. Tapping a month that is still owed now
/// tells the landlord it has been paid.
class _Rent extends ConsumerStatefulWidget {
  const _Rent({required this.leaseId, this.confirmer});

  final String leaseId;
  final String? confirmer;

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
      // Already loaded for the panel above; null while it loads or if it
      // failed, and the sheet then leaves the list out.
      payment: ref.read(leasePaymentDetailsProvider(widget.leaseId)).valueOrNull,
    );
    if (said == null || !mounted) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sendDeclaration(ref,
          leaseId: widget.leaseId, period: period, said: said);
      messenger.showSnackBar(const SnackBar(
        content: Text('Told your landlord. They will confirm it.'),
      ));
    } on ApiFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(myBillingProvider(widget.leaseId));
    final payment = ref.watch(leasePaymentDetailsProvider(widget.leaseId));
    final declared =
        ref.watch(myPaymentsProvider(widget.leaseId)).valueOrNull ?? const [];

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
        onRefresh: () async {
          ref.invalidate(myBillingProvider(widget.leaseId));
          ref.invalidate(leasePaymentDetailsProvider(widget.leaseId));
          ref.invalidate(myPaymentsProvider(widget.leaseId));
        },
        child: RentScheduleList(
          periods: periods,
          payments: declared,
          confirmer: widget.confirmer,
          emptyDetail: 'Your first month appears once the tenancy has started.',
          onTap: _declare,
          header: HowToPayPanel(
            key: const ValueKey('landlord-how-to-pay'),
            title: 'How to pay your landlord',
            details: payment,
            emptyMessage: 'Your landlord has not added how to pay yet. Ask '
                'them before sending money.',
            qrUnavailable: 'That QR could not be loaded. Close this and pull '
                'down on the Rent tab to refresh it.',
          ),
        ),
      ),
    );
  }
}
