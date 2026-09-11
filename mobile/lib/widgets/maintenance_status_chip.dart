import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// Where a report has got to, in the words of whoever is reading it.
///
/// The same state reads differently from each end. RESOLVED is the landlord
/// saying it is fixed: to them it is done and waiting on the tenant, and to
/// the tenant it is a question they have been asked.
class MaintenanceStatusChip extends StatelessWidget {
  const MaintenanceStatusChip({
    super.key,
    required this.report,
    required this.forTenant,
  });

  final MaintenanceReportResponse report;
  final bool forTenant;

  @override
  Widget build(BuildContext context) {
    final (status, label) = switch (report.status?.toJson()) {
      // A reopened report is back where it started, and must not look new.
      'SUBMITTED' when report.reopened == true =>
        (LizmoStatus.overdue, 'Reopened'),
      'SUBMITTED' => forTenant
          ? (LizmoStatus.vacant, 'Sent')
          : (LizmoStatus.pending, 'New'),
      'IN_PROGRESS' => (LizmoStatus.pending, 'In progress'),
      'RESOLVED' => forTenant
          ? (LizmoStatus.pending, 'Is it fixed?')
          : (LizmoStatus.paid, 'Marked fixed'),
      'CLOSED' => (LizmoStatus.paid, 'Fixed'),
      'WITHDRAWN' => (LizmoStatus.vacant, 'Withdrawn'),
      _ => (LizmoStatus.vacant, '—'),
    };
    return StatusChip(status: status, label: label);
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "3 Sep".
String maintenanceDay(DateTime? at) {
  if (at == null) return '';
  final local = at.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}

/// "Bed 1, 2B", or "Unit 2B".
String maintenanceWhere(MaintenanceReportResponse report) =>
    report.bedLabel == null
        ? 'Unit ${report.unitNumber}'
        : '${report.bedLabel}, ${report.unitNumber}';
