import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../maintenance/maintenance_providers.dart';
import '../router.dart';
import '../widgets/account_sheet.dart';
import '../widgets/maintenance_status_chip.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';

/// Everything tenants have reported, across every property.
///
/// Grouped by whose move it is, because that is the question a landlord opens
/// this with: what needs me, what am I already dealing with, what am I waiting
/// for a tenant to confirm. Finished reports sit at the bottom, still there to
/// find when a tenant says "the tap again".
class MaintenanceInboxScreen extends ConsumerWidget {
  const MaintenanceInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };
    final reports = ref.watch(maintenanceToHandleProvider);
    final value = reports.valueOrNull;

    List<MaintenanceReportResponse> inStatus(Set<String> statuses) =>
        (value ?? const <MaintenanceReportResponse>[])
            .where((report) => statuses.contains(report.status?.toJson()))
            .toList();

    final fresh = inStatus({'SUBMITTED'});
    final underway = inStatus({'IN_PROGRESS'});
    final waiting = inStatus({'RESOLVED'});
    final done = inStatus({'CLOSED', 'WITHDRAWN'});

    String count(List<MaintenanceReportResponse> rows) =>
        value == null ? '—' : '${rows.length}';

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'Maintenance',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            stats: [
              LatticeHeaderStat(value: count(fresh), label: 'New'),
              LatticeHeaderStat(value: count(underway), label: 'In progress'),
              LatticeHeaderStat(value: count(waiting), label: 'To confirm'),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(maintenanceToHandleProvider),
              child: reports.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    LizmoMessageState(
                      tone: LizmoMessageTone.problem,
                      icon: Icons.error_outline,
                      title: 'Could not load maintenance',
                      detail: ApiFailure.from(error).message,
                    ),
                  ],
                ),
                data: (rows) => rows.isEmpty
                    ? ListView(
                        children: const [
                          LizmoMessageState(
                            tone: LizmoMessageTone.neutral,
                            icon: Icons.build_outlined,
                            title: 'Nothing reported',
                            detail: 'When a tenant reports something broken, it '
                                'appears here.',
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _Section(title: 'Needs you', rows: fresh),
                          _Section(title: 'In progress', rows: underway),
                          _Section(
                              title: 'Waiting for the tenant to confirm',
                              rows: waiting),
                          _Section(title: 'Done', rows: done),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A heading and its rows, or nothing at all when there are none.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<MaintenanceReportResponse> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 0, 8),
          child: Text(title, style: LizmoType.sectionHeading),
        ),
        for (final report in rows) _Row(report: report),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.report});

  final MaintenanceReportResponse report;

  @override
  Widget build(BuildContext context) {
    final who = [
      maintenanceWhere(report),
      if (report.propertyName != null) report.propertyName!,
      if (report.tenantName != null) report.tenantName!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('maintenance-${report.id}'),
        // Opens inside this tab, so Back comes straight back to the list.
        onTap: () => context.openInTab(Detail.maintenance(report.id!)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LizmoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8E6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          LizmoType.rowName.copyWith(color: LizmoColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LizmoType.rowSub.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MaintenanceStatusChip(report: report, forTenant: false),
                  // Under the chip rather than at the end of the line above,
                  // where a long tenant name pushed it onto a line of its own
                  // and split the date in half.
                  const SizedBox(height: 6),
                  Text(
                    maintenanceDay(report.submittedAt),
                    style: LizmoType.rowSub.copyWith(fontSize: 11),
                  ),
                  if (report.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_outlined,
                            size: 14, color: LizmoColors.slate),
                        const SizedBox(width: 2),
                        Text('${report.photoUrls.length}',
                            style: LizmoType.rowSub.copyWith(fontSize: 11)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
