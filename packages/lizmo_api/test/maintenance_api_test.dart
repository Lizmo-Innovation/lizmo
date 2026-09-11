//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:lizmo_api/api.dart';
import 'package:test/test.dart';


/// tests for MaintenanceApi
void main() {
  // final instance = MaintenanceApi();

  group('tests for MaintenanceApi', () {
    // Add a photo to my report
    //
    // Up to three, while nobody has started on it. Re-encoded, so no EXIF or location leaves the phone.
    //
    //Future<MaintenanceReportResponse> addMaintenancePhoto(String id, MultipartFile photo) async
    test('test addMaintenancePhoto', () async {
      // TODO
    });

    // Say it is fixed
    //
    // Closes a report the landlord has marked resolved.
    //
    //Future<MaintenanceReportResponse> confirmMaintenanceFixed(String id) async
    test('test confirmMaintenanceFixed', () async {
      // TODO
    });

    // What I have reported
    //
    // Newest first, whatever became of each.
    //
    //Future<List<MaintenanceReportResponse>> listMyMaintenanceReports() async
    test('test listMyMaintenanceReports', () async {
      // TODO
    });

    // Say it is still broken
    //
    // On a report the landlord has marked resolved. A reason is required: it is the whole of what the landlord needs to hear.
    //
    //Future<MaintenanceReportResponse> reopenMaintenanceReport(String id, MaintenanceNote maintenanceNote) async
    test('test reopenMaintenanceReport', () async {
      // TODO
    });

    // Report something broken
    //
    // Against the tenancy the caller is living under now. The landlord is told. Photos are added afterwards, one at a time.
    //
    //Future<MaintenanceReportResponse> reportProblem(ReportProblemRequest reportProblemRequest) async
    test('test reportProblem', () async {
      // TODO
    });

    // Take my report back
    //
    // Only while nobody has started on it. Kept, not deleted.
    //
    //Future<MaintenanceReportResponse> withdrawMaintenanceReport(String id) async
    test('test withdrawMaintenanceReport', () async {
      // TODO
    });

  });
}
