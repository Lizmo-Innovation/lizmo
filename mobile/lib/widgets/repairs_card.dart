import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../maintenance/maintenance_providers.dart';
import '../router.dart';

/// The repairs a landlord has not picked up yet: reported, or reopened by a
/// tenant who says it is still broken. Oldest first, since whoever has waited
/// longest is the one to answer.
///
/// In progress is the landlord's own work and fixed-awaiting-the-tenant is
/// the tenant's move, so neither is here.
List<MaintenanceReportResponse> repairsNeedingYou(
    List<MaintenanceReportResponse> reports) {
  final waiting = reports
      .where((report) => report.status == MaintenanceReportResponseStatusEnum.SUBMITTED)
      .toList()
    ..sort((a, b) => _since(a).compareTo(_since(b)));
  return waiting;
}

/// When this one started waiting on the landlord: when it was reported, or
/// when the tenant reopened it.
DateTime _since(MaintenanceReportResponse report) =>
    (report.reopened == true ? report.updatedAt : report.submittedAt) ??
    DateTime.fromMillisecondsSinceEpoch(0);

/// Repairs on Today, under Needs you.
///
/// A tenant living with a broken fan is as much somebody waiting as one asking
/// for a room, and Today used to say "Nothing needs you" over them. Nothing is
/// shown when nothing needs picking up; a failure is said, not hidden, for the
/// same reason as the other cards here.
class RepairsCard extends ConsumerWidget {
  const RepairsCard({super.key});

  /// Rows before the rest become "and N more": Today is a summary, and the
  /// Maintenance tab has them all.
  static const _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(maintenanceToHandleProvider);

    return reports.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => _Frame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repairs', style: LizmoType.sectionHeading),
            const SizedBox(height: 6),
            Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
          ],
        ),
      ),
      data: (all) {
        final waiting = repairsNeedingYou(all);
        if (waiting.isEmpty) return const SizedBox.shrink();
        final underway = all
            .where((report) =>
                report.status == MaintenanceReportResponseStatusEnum.IN_PROGRESS)
            .length;
        final hidden = waiting.length - _shown;

        return _Frame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Repairs', style: LizmoType.sectionHeading)),
                  Text(
                    '${waiting.length} new',
                    style: LizmoType.rowSub.copyWith(
                      color: LizmoColors.amberText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final report in waiting.take(_shown)) _RepairRow(report: report),
              if (hidden > 0 || underway > 0)
                InkWell(
                  key: const ValueKey('repairs-see-all'),
                  onTap: () => context.go(Routes.maintenanceInbox),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      [
                        if (hidden > 0) '$hidden more',
                        if (underway > 0) '$underway in progress',
                        'See all repairs ›',
                      ].join(' · '),
                      style: LizmoType.rowSub,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('repairs-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: child,
      ),
    );
  }
}

class _RepairRow extends StatelessWidget {
  const _RepairRow({required this.report});

  final MaintenanceReportResponse report;

  @override
  Widget build(BuildContext context) {
    final slot = report.bedLabel == null
        ? 'Unit ${report.unitNumber}'
        : '${report.bedLabel}, ${report.unitNumber}';
    final who = [
      if (report.tenantName != null) report.tenantName!,
      slot,
      if (report.propertyName != null) report.propertyName!,
    ].join(' · ');
    final reopened = report.reopened == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('repair-${report.id}'),
        // Opens inside Today, so Back comes straight back to the next one.
        onTap: () => context.openInTab(Detail.maintenance(report.id!)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LizmoColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.description ?? 'A repair',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(who, style: LizmoType.rowSub.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: LizmoColors.amberBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  // Reopened says the fix did not hold, which is worth more
                  // than how long ago.
                  reopened ? 'Reopened' : 'New · ${_waited(report.submittedAt)}',
                  style: LizmoType.rowSub.copyWith(
                    fontSize: 11,
                    color: LizmoColors.amberText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: LizmoColors.slate),
            ],
          ),
        ),
      ),
    );
  }

  /// How long it has waited: "2h", "1 day", "5 days".
  static String _waited(DateTime? at) {
    if (at == null) return 'today';
    final gap = DateTime.now().difference(at.toLocal());
    if (gap.inHours < 1) return 'just now';
    if (gap.inDays < 1) return '${gap.inHours}h';
    return gap.inDays == 1 ? '1 day' : '${gap.inDays} days';
  }
}
