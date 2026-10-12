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


/// tests for AnnouncementsApi
void main() {
  // final instance = AnnouncementsApi();

  group('tests for AnnouncementsApi', () {
    // Announcements where I live
    //
    // Everything up in the buildings, and units, I rent in now, newest first.
    //
    //Future<List<MyNoticeResponse>> listMyNotices() async
    test('test listMyNotices', () async {
      // TODO
    });

    // Announcements up on a building
    //
    // Newest first, with how many of the people each is for have opened it. Taken-down ones are not listed.
    //
    //Future<List<NoticeResponse>> listPropertyNotices(String propertyId) async
    test('test listPropertyNotices', () async {
      // TODO
    });

    // I have read this announcement
    //
    //Future markNoticeRead(String id) async
    test('test markNoticeRead', () async {
      // TODO
    });

    // Post an announcement
    //
    // To everybody renting in the building, or in one unit. Those living there now are notified; anybody who moves in while it is up sees it too. Cannot be edited: take it down and post again.
    //
    //Future<NoticeResponse> postNotice(String propertyId, PostNotice postNotice) async
    test('test postNotice', () async {
      // TODO
    });

    // Take an announcement down
    //
    // Gone from every tenant's screen. Nobody is told.
    //
    //Future takeDownNotice(String id) async
    test('test takeDownNotice', () async {
      // TODO
    });

  });
}
