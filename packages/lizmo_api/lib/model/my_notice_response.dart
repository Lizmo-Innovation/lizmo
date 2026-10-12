//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MyNoticeResponse {
  /// Returns a new [MyNoticeResponse] instance.
  MyNoticeResponse({
    this.id,
    this.propertyName,
    this.unitNumber,
    this.fromName,
    this.title,
    this.message,
    this.postedAt,
    this.until,
    this.read,
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
  String? propertyName;

  /// Set when it went to their unit only
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
  String? fromName;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? until;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? read;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MyNoticeResponse &&
    other.id == id &&
    other.propertyName == propertyName &&
    other.unitNumber == unitNumber &&
    other.fromName == fromName &&
    other.title == title &&
    other.message == message &&
    other.postedAt == postedAt &&
    other.until == until &&
    other.read == read;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (fromName == null ? 0 : fromName!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (postedAt == null ? 0 : postedAt!.hashCode) +
    (until == null ? 0 : until!.hashCode) +
    (read == null ? 0 : read!.hashCode);

  @override
  String toString() => 'MyNoticeResponse[id=$id, propertyName=$propertyName, unitNumber=$unitNumber, fromName=$fromName, title=$title, message=$message, postedAt=$postedAt, until=$until, read=$read]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.fromName != null) {
      json[r'fromName'] = this.fromName;
    } else {
      json[r'fromName'] = null;
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
    if (this.read != null) {
      json[r'read'] = this.read;
    } else {
      json[r'read'] = null;
    }
    return json;
  }

  /// Returns a new [MyNoticeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MyNoticeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MyNoticeResponse(
        id: mapValueOfType<String>(json, r'id'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        fromName: mapValueOfType<String>(json, r'fromName'),
        title: mapValueOfType<String>(json, r'title'),
        message: mapValueOfType<String>(json, r'message'),
        postedAt: mapDateTime(json, r'postedAt', r''),
        until: mapDateTime(json, r'until', r''),
        read: mapValueOfType<bool>(json, r'read'),
      );
    }
    return null;
  }

  static List<MyNoticeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MyNoticeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MyNoticeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MyNoticeResponse> mapFromJson(dynamic json) {
    final map = <String, MyNoticeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MyNoticeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MyNoticeResponse-objects as value to a dart map
  static Map<String, List<MyNoticeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MyNoticeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MyNoticeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

