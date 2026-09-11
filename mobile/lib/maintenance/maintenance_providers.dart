import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

/// The tenant's side: reporting, and following what they reported.
final maintenanceApiProvider = Provider<MaintenanceApi>((ref) {
  return MaintenanceApi(ref.watch(apiClientProvider));
});

/// The landlord's side: everything reported on their properties.
final maintenanceToHandleApiProvider = Provider<MaintenanceToHandleApi>((ref) {
  return MaintenanceToHandleApi(ref.watch(apiClientProvider));
});

/// What this tenant has reported, newest first.
///
/// autoDispose: a landlord may have moved one along since it was last read.
final myMaintenanceProvider =
    FutureProvider.autoDispose<List<MaintenanceReportResponse>>((ref) async {
  try {
    return await ref.watch(maintenanceApiProvider).listMyMaintenanceReports() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// Every report on this landlord's properties, newest first.
final maintenanceToHandleProvider =
    FutureProvider.autoDispose<List<MaintenanceReportResponse>>((ref) async {
  try {
    return await ref.watch(maintenanceToHandleApiProvider).listMaintenanceReports() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// One report, as the landlord opens it.
final maintenanceReportProvider = FutureProvider.autoDispose
    .family<MaintenanceReportResponse, String>((ref, reportId) async {
  try {
    final report =
        await ref.watch(maintenanceToHandleApiProvider).getMaintenanceReport(reportId);
    if (report == null) {
      throw const ApiFailure(code: 'NOT_FOUND', message: 'No such report.');
    }
    return report;
  } catch (error) {
    throw ApiFailure.from(error);
  }
});
