import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../maintenance/maintenance_providers.dart';
import '../router.dart';
import 'todo_card.dart';

/// The repairs a landlord has not picked up yet: reported, or reopened by a
/// tenant who says it is still broken. Oldest first, since whoever has waited
/// longest is the one to answer.
///
/// In progress is the landlord's own work and fixed-awaiting-the-tenant is
/// the tenant's move, so neither is here.
List<MaintenanceReportResponse> repairsNeedingYou(
  List<MaintenanceReportResponse> reports,
) {
  final waiting =
      reports
          .where(
            (report) =>
                report.status == MaintenanceReportResponseStatusEnum.SUBMITTED,
          )
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
  const RepairsCard({super.key, this.compact = false});

  /// Other kinds of to-do are on Today too.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(maintenanceToHandleProvider);

    return reports.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => TodoCard(
        key: const ValueKey('repairs-card'),
        icon: Icons.build_outlined,
        tone: TodoTone.repairs,
        title: 'Repairs',
        count: 0,
        rows: const [],
        body: Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
      ),
      data: (all) {
        final waiting = repairsNeedingYou(all);
        if (waiting.isEmpty) return const SizedBox.shrink();
        // Work already underway is one line, not a row each: nothing about
        // it is waiting on the landlord today.
        final underway = all
            .where(
              (report) =>
                  report.status ==
                  MaintenanceReportResponseStatusEnum.IN_PROGRESS,
            )
            .length;

        return TodoCard(
          key: const ValueKey('repairs-card'),
          icon: Icons.build_outlined,
          tone: TodoTone.repairs,
          title: 'Repairs',
          count: waiting.length,
          compact: compact,
          seeAll: TodoSeeAll(
            key: const ValueKey('repairs-see-all'),
            onTap: () => context.go(Routes.maintenanceInbox),
            note: underway > 0 ? '$underway in progress' : null,
            always: underway > 0,
          ),
          rows: [for (final report in waiting) _RepairRow(report: report)],
        );
      },
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
    final at = report.submittedAt;

    return TodoRow(
      key: ValueKey('repair-${report.id}'),
      leading: TodoAvatar(name: report.tenantName, tone: TodoTone.repairs),
      title: report.description ?? 'A repair',
      onTap: () => context.openInTab(Detail.maintenance(report.id!)),
      sub: Text(who, style: LizmoType.rowSub),
      trailing: reopened
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: LizmoColors.amberBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reopened',
                style: LizmoType.rowSub.copyWith(
                  fontSize: 11,
                  color: LizmoColors.amberText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : at == null
          ? null
          : Text(ageShort(at), style: todoMono(LizmoColors.slateText)),
    );
  }
}
