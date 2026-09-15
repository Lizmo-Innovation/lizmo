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


/// tests for LizmoBillingApi
void main() {
  // final instance = LizmoBillingApi();

  group('tests for LizmoBillingApi', () {
    // How to pay Lizmo
    //
    // The channels an admin has made visible, in order, each with its QR when it has one, and the note shown under them. Landlords only.
    //
    //Future<PaymentDetails> getPlatformPaymentDetails() async
    test('test getPlatformPaymentDetails', () async {
      // TODO
    });

    // My Lizmo statements
    //
    // One a month, newest first, itemised by property, with what has been sent against each. A line carries an invoice number once the statement is paid.
    //
    //Future<List<PlatformStatementResponse>> listMyPlatformStatements() async
    test('test listMyPlatformStatements', () async {
      // TODO
    });

    // Say I have paid Lizmo
    //
    // Waits for a Lizmo admin to confirm it. Proof is required. The photograph is re-encoded, so no EXIF or location leaves the phone.
    //
    //Future<PlatformStatementResponse> payPlatformStatement(String id, PlatformPaymentRequest payment, { MultipartFile proof }) async
    test('test payPlatformStatement', () async {
      // TODO
    });

  });
}
