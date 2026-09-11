import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../platform/lizmo_billing_providers.dart';
import '../router.dart';

/// Lizmo invoices waiting on the landlord, on Today.
///
/// Among the things that need them because one does: an invoice left unpaid
/// locks a property thirty days on, and a landlord who learns that from the
/// lock has learned it too late.
///
/// Nothing at all when nothing is owed, while loading, or if it failed -- the
/// billing screen in the account menu says why.
class LizmoInvoiceCard extends ConsumerWidget {
  const LizmoInvoiceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(myLizmoInvoicesProvider).valueOrNull;
    final owed = (invoices ?? const <PlatformInvoiceResponse>[])
        .where(lizmoInvoiceNeedsPaying)
        .toList();
    if (owed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('lizmo-invoice-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Lizmo invoice', style: LizmoType.sectionHeading),
                ),
                Text(
                  owed.length == 1 ? '1 to pay' : '${owed.length} to pay',
                  style: LizmoType.rowSub.copyWith(
                    color: owed.any((invoice) => invoice.overdue == true)
                        ? LizmoColors.red
                        : LizmoColors.amberText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final invoice in owed) _Row(invoice: invoice),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.invoice});

  final PlatformInvoiceResponse invoice;

  @override
  Widget build(BuildContext context) {
    final overdue = invoice.overdue == true;
    final ink = overdue ? LizmoColors.red : LizmoColors.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('lizmo-invoice-${invoice.id}'),
        onTap: () => context.openInTab(Detail.lizmoBilling),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: overdue ? LizmoColors.redBg : LizmoColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${invoice.propertyName ?? 'A property'} · ${invoice.label}',
                      style: LizmoType.rowName.copyWith(color: ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lizmoInvoiceStanding(invoice),
                      style: LizmoType.rowSub.copyWith(fontSize: 11, color: ink),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${(invoice.outstanding ?? 0).toStringAsFixed(0)}',
                style: LizmoType.dataMedium.copyWith(color: ink),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "3 Sep".
String lizmoDay(DateTime? date) =>
    date == null ? '' : '${date.day} ${_months[date.month - 1]}';

/// Where an invoice stands, in a line.
String lizmoInvoiceStanding(PlatformInvoiceResponse invoice) {
  if (invoice.lockedByThis == true) {
    return 'Locked until paid · no new units, beds or tenants';
  }
  if (invoice.overdue == true && invoice.locksOn != null) {
    return 'Overdue · locks on ${lizmoDay(invoice.locksOn)}';
  }
  return 'Due ${lizmoDay(invoice.dueDate)}';
}
