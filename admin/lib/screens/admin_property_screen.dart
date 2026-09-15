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

/// One property, opened up: every unit and bed, and who leases which now.
///
/// Read-only. Units, beds and tenancies are the landlord's to manage; this is
/// where support looks when a statement is questioned or a tenant needs
/// reaching. A shared room lists its beds under it, so a boarding house reads
/// room by room the way its landlord thinks of it.
class AdminPropertyScreen extends ConsumerWidget {
  const AdminPropertyScreen({
    super.key,
    required this.landlordId,
    required this.propertyId,
  });

  final String landlordId;
  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(adminPropertyProvider(propertyId));
    final landlordName = property.valueOrNull?.landlordName;

    return AdminShell(
      title: switch (property) {
        AsyncData(:final value) => value?.name ?? 'Property',
        _ => 'Property',
      },
      actions: [
        TextButton.icon(
          key: const ValueKey('back-to-landlord'),
          onPressed: () => context.go('${Routes.landlords}/$landlordId'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(
            landlordName == null ? 'Back to landlord' : 'Back to $landlordName',
            style: LizmoType.rowName.copyWith(fontSize: 13, color: LizmoColors.teal900),
          ),
          style: TextButton.styleFrom(foregroundColor: LizmoColors.teal900),
        ),
      ],
      child: property.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => LizmoMessageState(
          icon: Icons.cloud_off_outlined,
          tone: LizmoMessageTone.problem,
          title: 'Could not load this property',
          detail: ApiFailure.from(error).message,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(adminPropertyProvider(propertyId)),
        ),
        data: (value) => value == null
            ? const LizmoMessageState(
                icon: Icons.domain_disabled_outlined,
                title: 'No such property',
              )
            : _Detail(property: value),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.property});

  final AdminPropertyDetail property;

  @override
  Widget build(BuildContext context) {
    final locked = property.accountStatus == 'LOCKED';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        Wrap(
          spacing: 32,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Fact(label: 'Landlord', value: property.landlordName),
            _Fact(label: 'Address', value: property.address),
            _Fact(label: 'Type', value: _words(property.type?.toJson())),
            _Fact(label: 'Code', value: property.code, mono: true),
            StatusChip(
              status: locked ? LizmoStatus.overdue : LizmoStatus.paid,
              label: locked ? 'Locked' : 'Active',
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Units', style: LizmoType.sectionHeading),
        const SizedBox(height: 4),
        Text(
          _summary(property),
          key: const ValueKey('property-summary'),
          style: LizmoType.rowSub,
        ),
        const SizedBox(height: 10),
        if (property.units.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('This property has no units yet.', style: LizmoType.rowSub),
          )
        else
          ConsoleTable(
            columns: const [
              ConsoleColumn('Unit', width: 190),
              ConsoleColumn('Tenant'),
              ConsoleColumn('Tenancy', width: 210),
              ConsoleColumn('Rent', width: 96),
              ConsoleColumn('Status', width: 130),
            ],
            rows: [
              for (final unit in property.units) ...[
                _unitRow(unit),
                for (final bed in unit.beds) _bedRow(bed),
              ],
            ],
          ),
      ],
    );
  }

  ConsoleRow _unitRow(AdminPropertyUnit unit) {
    final bedspace = unit.rentalMode?.toJson() == 'BEDSPACE';
    final leasedBeds =
        unit.beds.where((bed) => bed.occupancy?.toJson() == 'LEASED').length;

    return ConsoleRow(cells: [
      Column(
        key: ValueKey('unit-${unit.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Unit ${unit.unitNumber ?? ''}', style: LizmoType.rowName),
          const SizedBox(height: 2),
          Text(
            [
              if ((unit.floor ?? '').isNotEmpty) 'Floor ${unit.floor}',
              bedspace
                  ? 'Bedspace · ${unit.beds.length} ${unit.beds.length == 1 ? 'bed' : 'beds'}'
                  : 'Whole unit',
            ].join(' · '),
            style: LizmoType.rowSub,
          ),
        ],
      ),
      // A shared room's tenants are on its beds, so the room says how many
      // rather than repeating them.
      bedspace
          ? Text('$leasedBeds of ${unit.beds.length} beds leased', style: LizmoType.rowSub)
          : _Tenant(tenancy: unit.tenancy),
      bedspace ? const SizedBox.shrink() : _Dates(tenancy: unit.tenancy),
      bedspace
          ? const SizedBox.shrink()
          : _Rent(amount: unit.tenancy?.rent ?? unit.rent),
      _Occupancy(value: unit.occupancy?.toJson()),
    ]);
  }

  ConsoleRow _bedRow(AdminPropertyBed bed) {
    return ConsoleRow(cells: [
      Padding(
        key: ValueKey('bed-${bed.id}'),
        // Under its room, so the table reads as rooms and their beds.
        padding: const EdgeInsets.only(left: 18),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right, size: 16, color: LizmoColors.slate),
            const SizedBox(width: 6),
            Flexible(child: Text(bed.label ?? 'Bed', style: LizmoType.rowName)),
          ],
        ),
      ),
      _Tenant(tenancy: bed.tenancy),
      _Dates(tenancy: bed.tenancy),
      _Rent(amount: bed.tenancy?.rent ?? bed.rent),
      _Occupancy(value: bed.occupancy?.toJson()),
    ]);
  }

  /// "2 units · 3 beds · 2 leased · 1 out of service".
  static String _summary(AdminPropertyDetail property) {
    String count(int? n, String one, String many) =>
        '${n ?? 0} ${(n ?? 0) == 1 ? one : many}';
    return [
      count(property.unitCount, 'unit', 'units'),
      if ((property.bedCount ?? 0) > 0) count(property.bedCount, 'bed', 'beds'),
      '${property.leased ?? 0} leased',
      if ((property.outOfService ?? 0) > 0) '${property.outOfService} out of service',
    ].join(' · ');
  }

  /// BOARDING_HOUSE -> "Boarding house".
  static String? _words(String? value) {
    if (value == null || value.isEmpty) return null;
    final spaced = value.toLowerCase().replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Who leases it, and how to reach them. A dash when nobody does.
class _Tenant extends StatelessWidget {
  const _Tenant({required this.tenancy});

  final AdminPropertyTenancy? tenancy;

  @override
  Widget build(BuildContext context) {
    final lease = tenancy;
    if (lease == null) return Text('—', style: LizmoType.rowSub);

    final contact = [
      if ((lease.tenantPhone ?? '').isNotEmpty) lease.tenantPhone!,
      if ((lease.tenantEmail ?? '').isNotEmpty) lease.tenantEmail!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lease.tenantName ?? 'A tenant', style: LizmoType.rowName),
        if (contact.isNotEmpty) ...[
          const SizedBox(height: 2),
          SelectableText(contact, style: LizmoType.rowSub),
        ],
      ],
    );
  }
}

/// "Since 15 Sep 2026", and when it ends if it has an end.
class _Dates extends StatelessWidget {
  const _Dates({required this.tenancy});

  final AdminPropertyTenancy? tenancy;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _day(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final lease = tenancy;
    final start = lease?.startDate;
    if (lease == null || start == null) return Text('—', style: LizmoType.rowSub);
    final end = lease.endDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Since ${_day(start)}', style: LizmoType.rowSub),
        if (end != null) Text('Until ${_day(end)}', style: LizmoType.rowSub),
      ],
    );
  }
}

class _Rent extends StatelessWidget {
  const _Rent({required this.amount});

  final num? amount;

  @override
  Widget build(BuildContext context) {
    final value = amount;
    return Text(
      value == null ? '—' : '₱${value.toStringAsFixed(0)}',
      style: LizmoType.dataMedium,
    );
  }
}

/// Leased and partly leased in teal, vacant in grey, out of service in amber as
/// the landlord's own app shows it.
class _Occupancy extends StatelessWidget {
  const _Occupancy({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      'LEASED' => const StatusChip(status: LizmoStatus.paid, label: 'Leased'),
      'PARTLY_LEASED' => const StatusChip(status: LizmoStatus.paid, label: 'Partly leased'),
      'OUT_OF_SERVICE' => const StatusChip(status: LizmoStatus.pending, label: 'Out of service'),
      _ => const StatusChip(status: LizmoStatus.vacant, label: 'Vacant'),
    };
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.mono = false});

  final String label;
  final String? value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final text = value == null || value!.isEmpty ? '—' : value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: LizmoType.rowSub.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(text, style: mono ? LizmoType.dataMedium : LizmoType.rowName),
      ],
    );
  }
}
