import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';
import '../widgets/shared_lease_documents.dart';

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
            ],
          ),
        ),

        if (_hasUpfrontMoney(lease)) ...[
          const SizedBox(height: 16),
          _UpfrontMoney(lease: lease),
        ],
        const SizedBox(height: 16),

        // Renders nothing until the landlord shares something, so a tenancy
        // with no paperwork looks exactly as it did before.
        SharedLeaseDocuments(leaseId: lease.id!),

        const SizedBox(height: 16),
        // No longer mentions a contract: one can be shared now, and the card
        // above is where it appears.
        Text(
          'A deposit or advance and house rules are not recorded yet.',
          style: LizmoType.rowSub,
        ),
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
class _UpfrontMoney extends StatelessWidget {
  const _UpfrontMoney({required this.lease});

  final LeaseResponse lease;

  @override
  Widget build(BuildContext context) {
    final settled = lease.depositReturned != null;

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
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Rent paid up front. It pays for your first month.',
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
