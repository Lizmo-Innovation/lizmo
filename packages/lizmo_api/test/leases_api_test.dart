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


/// tests for LeasesApi
void main() {
  // final instance = LeasesApi();

  group('tests for LeasesApi', () {
    // End a tenancy
    //
    // Frees the bed or unit back to the vacancy list. Defaults to ended today; pass terminated for a tenancy stopped early.
    //
    //Future<LeaseResponse> endLease(String id, { EndLeaseRequest endLeaseRequest }) async
    test('test endLease', () async {
      // TODO
    });

    // Who is living here
    //
    //Future<List<LeaseResponse>> listLeasesForProperty(String propertyId) async
    test('test listLeasesForProperty', () async {
      // TODO
    });

    // My leases
    //
    //Future<List<LeaseResponse>> listMyLeases() async
    test('test listMyLeases', () async {
      // TODO
    });

    // The ID of the tenant living here
    //
    // Only while the lease is active. Each carries a presigned URL valid for a few minutes.
    //
    //Future<List<TenantDocumentResponse>> listTenantDocumentsForLease(String leaseId) async
    test('test listTenantDocumentsForLease', () async {
      // TODO
    });

  });
}
