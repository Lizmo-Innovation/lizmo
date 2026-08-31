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


/// tests for RequestsToAnswerApi
void main() {
  // final instance = RequestsToAnswerApi();

  group('tests for RequestsToAnswerApi', () {
    // Say yes, and create the lease
    //
    // Terms are optional and default to the asking rent, today, and the day of the month the tenant moves in. Everyone else still waiting on the same bed or unit is superseded.
    //
    //Future<LeaseResponse> acceptRentalRequest(String id, { AcceptRequest acceptRequest }) async
    test('test acceptRentalRequest', () async {
      // TODO
    });

    // Say no
    //
    // Frees nothing, because a request never held anything.
    //
    //Future<RentalRequestForLandlord> declineRentalRequest(String id) async
    test('test declineRentalRequest', () async {
      // TODO
    });

    // One request in full
    //
    //Future<RentalRequestForLandlord> getRentalRequest(String id) async
    test('test getRentalRequest', () async {
      // TODO
    });

    // Who has asked about this property
    //
    // Pending only by default, oldest first: a queue is answered in the order people joined it.
    //
    //Future<List<RentalRequestForLandlord>> listRentalRequestsForProperty(String propertyId, { bool pendingOnly }) async
    test('test listRentalRequestsForProperty', () async {
      // TODO
    });

  });
}
