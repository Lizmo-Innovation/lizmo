//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NoticeResponse {
  /// Returns a new [NoticeResponse] instance.
  NoticeResponse({
    this.id,
    this.propertyId,
    this.propertyName,
    this.unitId,
    this.unitNumber,
    this.title,
    this.message,
    this.postedAt,
    this.until,
    this.live,
    this.seenBy,
    this.audience,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyName;

  /// Set when it went to one unit only
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? postedAt;

  /// The last day it is shown, if it has one
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? until;

  /// False once past its last day
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? live;

  /// How many of the people it is for have opened it
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? seenBy;

  /// How many people it is for: everybody renting there now
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? audience;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NoticeResponse &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.unitId == unitId &&
    other.unitNumber == unitNumber &&
    other.title == title &&
    other.message == message &&
    other.postedAt == postedAt &&
    other.until == until &&
    other.live == live &&
    other.seenBy == seenBy &&
    other.audience == audience;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (postedAt == null ? 0 : postedAt!.hashCode) +
    (until == null ? 0 : until!.hashCode) +
    (live == null ? 0 : live!.hashCode) +
    (seenBy == null ? 0 : seenBy!.hashCode) +
    (audience == null ? 0 : audience!.hashCode);

  @override
  String toString() => 'NoticeResponse[id=$id, propertyId=$propertyId, propertyName=$propertyName, unitId=$unitId, unitNumber=$unitNumber, title=$title, message=$message, postedAt=$postedAt, until=$until, live=$live, seenBy=$seenBy, audience=$audience]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.propertyId != null) {
      json[r'propertyId'] = this.propertyId;
    } else {
      json[r'propertyId'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.unitId != null) {
      json[r'unitId'] = this.unitId;
    } else {
      json[r'unitId'] = null;
    }
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
    if (this.postedAt != null) {
      json[r'postedAt'] = this.postedAt!.toUtc().toIso8601String();
    } else {
      json[r'postedAt'] = null;
    }
    if (this.until != null) {
      json[r'until'] = _dateFormatter.format(this.until!);
    } else {
      json[r'until'] = null;
    }
    if (this.live != null) {
      json[r'live'] = this.live;
    } else {
      json[r'live'] = null;
    }
    if (this.seenBy != null) {
      json[r'seenBy'] = this.seenBy;
    } else {
      json[r'seenBy'] = null;
    }
    if (this.audience != null) {
      json[r'audience'] = this.audience;
    } else {
      json[r'audience'] = null;
    }
    return json;
  }

  /// Returns a new [NoticeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NoticeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return NoticeResponse(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitId: mapValueOfType<String>(json, r'unitId'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        title: mapValueOfType<String>(json, r'title'),
        message: mapValueOfType<String>(json, r'message'),
        postedAt: mapDateTime(json, r'postedAt', r''),
        until: mapDateTime(json, r'until', r''),
        live: mapValueOfType<bool>(json, r'live'),
        seenBy: mapValueOfType<int>(json, r'seenBy'),
        audience: mapValueOfType<int>(json, r'audience'),
      );
    }
    return null;
  }

  static List<NoticeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NoticeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NoticeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NoticeResponse> mapFromJson(dynamic json) {
    final map = <String, NoticeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NoticeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NoticeResponse-objects as value to a dart map
  static Map<String, List<NoticeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NoticeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NoticeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

