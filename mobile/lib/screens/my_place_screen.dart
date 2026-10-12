import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../billing/period_kind.dart';
import '../property/property_providers.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/lease_ending_notice.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';
import '../widgets/shared_lease_documents.dart';
import '../widgets/your_landlord_card.dart';

/// Where the tenant lives, or how to find somewhere.
///
/// One tab with two states rather than two tabs, because they are the same
/// question at different times: where is my place. Called "My place" and not
/// "Lease" for that reason — somebody still looking would see a tab named for
/// a document they do not have.
class MyPlaceScreen extends ConsumerWidget {
  const MyPlaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leases = ref.watch(myLeasesProvider);
    final lease = leases.valueOrNull?.firstOrNull;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: lease == null ? 'Lizmo' : lease.propertyName ?? 'Your place',
            title: lease == null ? 'My place' : _where(lease),
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
                ? const _Looking()
                : _Tenancy(lease: lease),
          ),
        ],
      ),
    );
  }

  static String _where(LeaseResponse lease) => lease.bedLabel == null
      ? 'Unit ${lease.unitNumber}'
      : '${lease.bedLabel}, ${lease.unitNumber}';
}

/// No lease: the whole tab is about finding one.
class _Looking extends StatelessWidget {
  const _Looking();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        const Icon(Icons.bed_outlined, size: 34, color: LizmoColors.slate),
        const SizedBox(height: 14),
        Text(
          'You are not renting through Lizmo yet',
          textAlign: TextAlign.center,
          style: LizmoType.rowName.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          'Every Lizmo property has a code on its gate. Scan it or type it in '
          'to see which beds and units are vacant, and what they cost.',
          textAlign: TextAlign.center,
          style: LizmoType.rowSub,
        ),
        const SizedBox(height: 22),
        PrimaryActionButton(
          label: 'Scan a property code',
          onPressed: () => context.go(Routes.tenantScan),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => context.go(Routes.tenantFind),
            child: Text(
              'Type the code instead',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
            ),
          ),
        ),
      ],
    );
  }
}

/// A lease: what was agreed, in the words a tenant would use.
class _Tenancy extends StatelessWidget {
  const _Tenancy({required this.lease});

  final LeaseResponse lease;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        // First when there is one: where a warning about the end of the
        // lease sends them, and the thing on this page with a date on it.
        LeaseEndingNotice(lease: lease),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LizmoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8E6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What you agreed', style: LizmoType.sectionHeading),
              const SizedBox(height: 12),
              _Fact(label: 'Property', value: lease.propertyName),
              _Fact(
                label: lease.bedLabel == null ? 'Unit' : 'Bed',
                value: lease.bedLabel == null
                    ? lease.unitNumber
                    : '${lease.bedLabel} · Unit ${lease.unitNumber}',
              ),
              _Fact(
                label: 'Rent',
                value: '${LizmoMoney.peso((lease.rentAmount ?? 0))} a month',
              ),
              _Fact(label: 'Rent day', value: 'The ${_ordinal(lease.dueDateDay ?? 1)}'),
              _Fact(label: 'Started', value: _date(lease.startDate)),
              // Only when there is one. Month to month is the usual
              // arrangement, and a row saying so would read as a gap.
              if (lease.termEndsOn != null)
                _Fact(label: 'Ends', value: _date(lease.termEndsOn)),
            ],
          ),
        ),

        // Second, after what was agreed: anything to do with somebody's home
        // is looked for here first, and most of it is a word with the person
        // they rent from.
        if (lease.status == LeaseResponseStatusEnum.ACTIVE) ...[
          const SizedBox(height: 16),
          YourLandlordCard(lease: lease),
        ],

        if (_hasUpfrontMoney(lease)) ...[
          const SizedBox(height: 16),
          _UpfrontMoney(lease: lease),
        ],
        const SizedBox(height: 16),

        // Renders nothing until the landlord shares something, so a tenancy
        // with no paperwork looks exactly as it did before.
        SharedLeaseDocuments(leaseId: lease.id!),

        // Only when it is true. It used to show on every tenancy, so a tenant
        // with a deposit on record read "not recorded yet" directly under the
        // card recording it. House rules are gone from it too: there is no
        // such thing in the app, and "not recorded yet" promised there was.
        //
        // No "ask your landlord to add it": a deposit is set when the
        // tenancy starts and cannot be added afterwards.
        if (!_hasUpfrontMoney(lease)) ...[
          const SizedBox(height: 16),
          Text(
            'No deposit or advance was recorded for this tenancy. If you paid '
            'one, keep your receipt.',
            key: const ValueKey('no-upfront-money'),
            style: LizmoType.rowSub,
          ),
        ],
      ],
    );
  }

  /// Whether there is anything to say about money handed over up front.
  ///
  /// A tenancy where neither was recorded shows no card at all, rather than a
  /// panel of dashes implying somebody forgot to fill it in.
  static bool _hasUpfrontMoney(LeaseResponse lease) =>
      lease.depositAmount != null || lease.advanceAmount != null;

  static String _date(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: LizmoType.rowSub),
          ),
          Expanded(
            // A dash, not an empty space: not recorded is a fact of its own.
            child: Text(value == null || value!.isEmpty ? '—' : value!,
                style: LizmoType.rowName),
          ),
        ],
      ),
    );
  }
}

/// What the tenant handed over before moving in, and what came back.
///
/// A deposit and an advance are two different things and are shown as two,
/// with a line each saying which is which. Tenants are told "two months
/// deposit, one month advance" at the door and then have nothing in writing;
/// this is the writing.
class _UpfrontMoney extends ConsumerWidget {
  const _UpfrontMoney({required this.lease});

  final LeaseResponse lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settled = lease.depositReturned != null;
    final months = ref.watch(myBillingProvider(lease.id!)).valueOrNull ?? const [];
    final declared = ref.watch(myPaymentsProvider(lease.id!)).valueOrNull ?? const [];

    final deposit = months.where((month) => month.isDeposit).firstOrNull;
    final advance = months.where((month) => month.isAdvance).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before you moved in', style: LizmoType.sectionHeading),
          const SizedBox(height: 12),

          if (lease.depositAmount != null) ...[
            _Fact(
              label: 'Deposit',
              value: LizmoMoney.peso(lease.depositAmount!),
            ),
            if (deposit != null)
              _Received(
                key: const ValueKey('deposit-state'),
                charges: [deposit],
                declared: declared,
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Held against damage, and given back when you move out.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),
            ),
          ],

          if (lease.advanceAmount != null) ...[
            _Fact(
              label: 'Advance rent',
              value: LizmoMoney.peso(lease.advanceAmount!),
            ),
            if (advance.isNotEmpty)
              _Received(
                key: const ValueKey('advance-state'),
                charges: advance,
                declared: declared,
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                advance.length > 1
                    ? 'Rent paid up front. It pays for your first '
                        '${advance.length} months.'
                    : 'Rent paid up front. It pays for your first month.',
                style: LizmoType.rowSub.copyWith(fontSize: 11),
              ),
            ),
          ],

          if (settled) ...[
            const Divider(height: 20, color: Color(0xFFE3E8E6)),
            _Fact(
              label: 'Deposit returned',
              value: LizmoMoney.peso(lease.depositReturned!),
            ),
            if ((lease.depositSettlement ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  lease.depositSettlement!,
                  style: LizmoType.rowSub,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Whether money owed at move-in actually came in: received, waiting on the
/// landlord, part paid, or not paid yet.
///
/// The amounts on their own said what was agreed, and read as though it had
/// all been handed over -- which until move-in charges, the app assumed.
class _Received extends StatelessWidget {
  const _Received({super.key, required this.charges, required this.declared});

  final List<BillingPeriodResponse> charges;
  final List<PaymentResponse> declared;

  @override
  Widget build(BuildContext context) {
    final due = charges.fold<num>(0, (sum, c) => sum + (c.amountDue ?? 0));
    final paid = charges.fold<num>(0, (sum, c) => sum + (c.amountPaid ?? 0));
    final ids = charges.map((charge) => charge.id).toSet();
    final waiting = declared.any((payment) =>
        ids.contains(payment.billingPeriodId) &&
        payment.status == PaymentResponseStatusEnum.PENDING_VERIFICATION);

    final (String text, Color colour) = paid >= due && due > 0
        ? ('Received', LizmoColors.teal900)
        : waiting
            ? ('Waiting for your landlord to confirm it', LizmoColors.teal900)
            : paid > 0
                ? ('${LizmoMoney.peso(paid)} received, '
                        '${LizmoMoney.peso(due - paid)} still to pay',
                    LizmoColors.amberText)
                : ('Not paid yet', LizmoColors.amberText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: LizmoType.rowSub.copyWith(
          fontSize: 12,
          color: colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
