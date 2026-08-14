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


/// tests for UnitsApi
void main() {
  // final instance = UnitsApi();

  group('tests for UnitsApi', () {
    // View one unit
    //
    //Future<UnitResponse> callGet(String id) async
    test('test callGet', () async {
      // TODO
    });

    // Add a bed
    //
    // Bedspace units only, and never beyond the unit's capacity.
    //
    //Future<BedResponse> createBed(String id, BedRequest bedRequest) async
    test('test createBed', () async {
      // TODO
    });

    // Delete a unit
    //
    // Refused while the unit still has beds.
    //
    //Future delete(String id) async
    test('test delete', () async {
      // TODO
    });

    // Remove a bed
    //
    // Refused while the bed is occupied.
    //
    //Future deleteBed(String id) async
    test('test deleteBed', () async {
      // TODO
    });

    // List a unit's beds
    //
    //Future<List<BedResponse>> listBeds(String id) async
    test('test listBeds', () async {
      // TODO
    });

    // Update a unit
    //
    // Rental mode cannot change, and capacity cannot drop below the beds already defined.
    //
    //Future<UnitResponse> update(String id, UnitRequest unitRequest) async
    test('test update', () async {
      // TODO
    });

  });
}
