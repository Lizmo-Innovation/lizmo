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


/// tests for AskingAboutAPlaceApi
void main() {
  // final instance = AskingAboutAPlaceApi();

  group('tests for AskingAboutAPlaceApi', () {
    // End it
    //
    // From either side. Asking about the place again reopens it.
    //
    //Future<InquirySummary> closeInquiry(String id) async
    test('test closeInquiry', () async {
      // TODO
    });

    // My conversations
    //
    // Both sides: threads I started, and threads about places I let. Most recently spoken in first.
    //
    //Future<List<InquirySummary>> listMyInquiries() async
    test('test listMyInquiries', () async {
      // TODO
    });

    // Mark it seen
    //
    // For a list the reader has been through without opening every thread.
    //
    //Future markInquiryRead(String id) async
    test('test markInquiryRead', () async {
      // TODO
    });

    // One conversation
    //
    // Everything said in it. Reading it marks it seen for whoever asked.
    //
    //Future<InquiryThread> readInquiry(String id) async
    test('test readInquiry', () async {
      // TODO
    });

    // Say something
    //
    //Future<InquiryMessageResponse> sendInquiryMessage(String id, NewMessage newMessage) async
    test('test sendInquiryMessage', () async {
      // TODO
    });

    // Ask about a place
    //
    // Starts the conversation, or reopens the one that already exists with this landlord about this property. Needs a contact number, so they can ring back.
    //
    //Future<InquiryThread> startInquiry(StartInquiry startInquiry) async
    test('test startInquiry', () async {
      // TODO
    });

    // Write the tenancy they agreed on
    //
    // The landlord, from inside the conversation. The room has to be named here: the tenant was never shown which rooms exist. Everything else defaults to the asking rent, today, and the day of the month they move in.
    //
    //Future<LeaseResponse> startLeaseFromInquiry(String id, { AcceptRequest acceptRequest }) async
    test('test startLeaseFromInquiry', () async {
      // TODO
    });

  });
}
