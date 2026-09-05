import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../admin_providers.dart';
import '../router.dart';
import '../widgets/admin_shell.dart';
import '../widgets/console_table.dart';

/// One landlord, and each of their properties.
///
/// Where locking happens, and it happens per property because that is how they
/// are billed: the thing being acted on and the thing that owes money are the
/// same object on the screen.
class LandlordDetailScreen extends ConsumerWidget {
  const LandlordDetailScreen({super.key, required this.landlordId});

  final String landlordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(landlordProvider(landlordId));

    return AdminShell(
      title: switch (detail) {
        AsyncData(:final value) => value?.landlord?.name ?? 'Landlord',
        _ => 'Landlord',
      },
      actions: [
        TextButton.icon(
          onPressed: () => context.go(Routes.landlords),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text('All landlords', style: LizmoType.rowName.copyWith(
            fontSize: 13, color: LizmoColors.teal900)),
          style: TextButton.styleFrom(foregroundColor: LizmoColors.teal900),
        ),
      ],
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => LizmoMessageState(
          icon: Icons.cloud_off_outlined,
          tone: LizmoMessageTone.problem,
          title: 'Could not load this landlord',
          detail: ApiFailure.from(error).message,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(landlordProvider(landlordId)),
        ),
        data: (value) => value == null
            ? const LizmoMessageState(
                icon: Icons.person_off_outlined,
                title: 'No such landlord',
              )
            : _Detail(detail: value),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.detail});

  final LandlordDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landlord = detail.landlord;
    if (landlord == null) {
      return const LizmoMessageState(
        icon: Icons.person_off_outlined,
        title: 'No such landlord',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        _Contact(landlord: landlord),
        const SizedBox(height: 22),
        Text('Properties', style: LizmoType.sectionHeading),
        const SizedBox(height: 10),
        if (detail.properties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'This landlord has not added a property yet.',
              style: LizmoType.rowSub,
            ),
          )
        else
          ConsoleTable(
            columns: const [
              ConsoleColumn('Property'),
              ConsoleColumn('Code', width: 108),
              ConsoleColumn('Let', width: 96),
              ConsoleColumn('Status', width: 96),
              ConsoleColumn('', width: 108),
            ],
            rows: [
              for (final property in detail.properties)
                ConsoleRow(cells: [
                  _PropertyName(property: property),
                  Text(property.code ?? '', style: LizmoType.dataMedium),
                  Text(
                    '${(property.occupiedUnits ?? 0) + (property.occupiedBeds ?? 0)}'
                    ' of ${(property.units ?? 0) + (property.beds ?? 0)}',
                    style: LizmoType.rowName,
                  ),
                  _PropertyStatus(property: property),
                  _LockButton(property: property, landlordId: landlord.userId ?? ''),
                ]),
            ],
          ),
        const SizedBox(height: 24),
        const _BillingNotYet(),
      ],
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.landlord});

  final LandlordSummary landlord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Wrap(
        spacing: 40,
        runSpacing: 12,
        children: [
          _Fact(label: 'Email', value: landlord.email),
          _Fact(label: 'Phone', value: landlord.phone),
          _Fact(label: 'Properties', value: '${landlord.properties ?? 0}'),
          _Fact(
            label: 'Billable slots',
            value: '${(landlord.occupiedUnits ?? 0) + (landlord.occupiedBeds ?? 0)}',
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: LizmoType.rowSub.copyWith(fontSize: 11)),
        const SizedBox(height: 3),
        // A dash, not an empty space and not a zero: not given is a different
        // thing from none.
        Text(value == null || value!.isEmpty ? '—' : value!, style: LizmoType.rowName),
      ],
    );
  }
}

class _PropertyName extends StatelessWidget {
  const _PropertyName({required this.property});

  final AdminPropertySummary property;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(property.name ?? '', style: LizmoType.rowName),
        const SizedBox(height: 2),
        Text(property.address ?? '', style: LizmoType.rowSub, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _PropertyStatus extends StatelessWidget {
  const _PropertyStatus({required this.property});

  final AdminPropertySummary property;

  @override
  Widget build(BuildContext context) {
    final locked = property.accountStatus == 'LOCKED';
    return StatusChip(
      status: locked ? LizmoStatus.overdue : LizmoStatus.paid,
      label: locked ? 'Locked' : 'Active',
    );
  }
}

/// Locks or unlocks one property.
///
/// Deliberately blunt about what it does. Locking stops the landlord adding
/// units, beds or tenants to this property — and never touches the people
/// already living there, who are not the ones who owe Lizmo money.
class _LockButton extends ConsumerStatefulWidget {
  const _LockButton({required this.property, required this.landlordId});

  final AdminPropertySummary property;
  final String landlordId;

  @override
  ConsumerState<_LockButton> createState() => _LockButtonState();
}

class _LockButtonState extends ConsumerState<_LockButton> {
  bool _working = false;

  Future<void> _toggle() async {
    final locked = widget.property.accountStatus == 'LOCKED';
    final id = widget.property.id ?? '';
    setState(() => _working = true);

    try {
      final api = ref.read(adminApiProvider);
      if (locked) {
        await api.unlockProperty(id);
      } else {
        await api.lockProperty(id);
      }
      ref.invalidate(landlordProvider(widget.landlordId));
      ref.invalidate(landlordsProvider);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_working) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final locked = widget.property.accountStatus == 'LOCKED';
    return TextButton(
      onPressed: _toggle,
      style: TextButton.styleFrom(
        foregroundColor: locked ? LizmoColors.teal900 : LizmoColors.red,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(locked ? 'Unlock' : 'Lock', style: LizmoType.rowName.copyWith(
        fontSize: 13,
        color: locked ? LizmoColors.teal900 : LizmoColors.red,
      )),
    );
  }
}

/// Says why there is no billing on this page yet.
///
/// An admin looking for an invoice and finding nothing should learn that none
/// exists, not conclude the page is broken.
class _BillingNotYet extends StatelessWidget {
  const _BillingNotYet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: LizmoColors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No invoices yet. Nothing raises a billing cycle, so balances and '
              'payment history will stay empty until the monthly snapshot job '
              'exists. Locking already works, and is what enforcement will use.',
              style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
            ),
          ),
        ],
      ),
    );
  }
}
