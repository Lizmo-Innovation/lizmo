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


/// tests for PaymentChannelsApi
void main() {
  // final instance = PaymentChannelsApi();

  group('tests for PaymentChannelsApi', () {
    // Add a way to pay me
    //
    // Added at the bottom, and shown to tenants unless visible is false.
    //
    //Future<PaymentChannelResponse> addMyPaymentChannel(PaymentChannelRequest paymentChannelRequest) async
    test('test addMyPaymentChannel', () async {
      // TODO
    });

    // Delete a way to pay me
    //
    // With its QR. Hide it instead to bring it back later.
    //
    //Future deleteMyPaymentChannel(String id) async
    test('test deleteMyPaymentChannel', () async {
      // TODO
    });

    // The note under my channels
    //
    //Future<PaymentNote> getMyPaymentNote() async
    test('test getMyPaymentNote', () async {
      // TODO
    });

    // How my tenants pay me
    //
    // Hidden ones included, in the order tenants see them.
    //
    //Future<List<PaymentChannelResponse>> listMyPaymentChannels() async
    test('test listMyPaymentChannels', () async {
      // TODO
    });

    // Remove a channel's QR
    //
    // The channel stays, with its name and number.
    //
    //Future<PaymentChannelResponse> removeMyPaymentChannelQr(String id) async
    test('test removeMyPaymentChannelQr', () async {
      // TODO
    });

    // Put my channels in order
    //
    // Every channel exactly once, top to bottom.
    //
    //Future<List<PaymentChannelResponse>> reorderMyPaymentChannels(PaymentChannelOrder paymentChannelOrder) async
    test('test reorderMyPaymentChannels', () async {
      // TODO
    });

    // Change a way to pay me
    //
    // Visibility is left as it is when not sent. Past payments keep the details they were sent to.
    //
    //Future<PaymentChannelResponse> updateMyPaymentChannel(String id, PaymentChannelRequest paymentChannelRequest) async
    test('test updateMyPaymentChannel', () async {
      // TODO
    });

    // Change the note under my channels
    //
    // Blank clears it.
    //
    //Future<PaymentNote> updateMyPaymentNote(PaymentNote paymentNote) async
    test('test updateMyPaymentNote', () async {
      // TODO
    });

    // Set a channel's QR
    //
    // Replaces any QR it had. Re-encoded, so no EXIF or location is kept.
    //
    //Future<PaymentChannelResponse> uploadMyPaymentChannelQr(String id, MultipartFile qr) async
    test('test uploadMyPaymentChannelQr', () async {
      // TODO
    });

  });
}
