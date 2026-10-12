//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PostNotice {
  /// Returns a new [PostNotice] instance.
  PostNotice({
    required this.title,
    required this.message,
    this.unitId,
    this.until,
  });

  String title;

  String message;

  /// One unit only. Null for everybody in the building.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitId;

  /// The last day it is shown. Null for until taken down.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? until;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PostNotice &&
    other.title == title &&
    other.message == message &&
    other.unitId == unitId &&
    other.until == until;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title.hashCode) +
    (message.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (until == null ? 0 : until!.hashCode);

  @override
  String toString() => 'PostNotice[title=$title, message=$message, unitId=$unitId, until=$until]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'title'] = this.title;
      json[r'message'] = this.message;
    if (this.unitId != null) {
      json[r'unitId'] = this.unitId;
    } else {
      json[r'unitId'] = null;
    }
    if (this.until != null) {
      json[r'until'] = _dateFormatter.format(this.until!);
    } else {
      json[r'until'] = null;
    }
    return json;
  }

  /// Returns a new [PostNotice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PostNotice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'title'), 'Required key "PostNotice[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "PostNotice[title]" has a null value in JSON.');
        assert(json.containsKey(r'message'), 'Required key "PostNotice[message]" is missing from JSON.');
        assert(json[r'message'] != null, 'Required key "PostNotice[message]" has a null value in JSON.');
        return true;
      }());

      return PostNotice(
        title: mapValueOfType<String>(json, r'title')!,
        message: mapValueOfType<String>(json, r'message')!,
        unitId: mapValueOfType<String>(json, r'unitId'),
        until: mapDateTime(json, r'until', r''),
      );
    }
    return null;
  }

  static List<PostNotice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PostNotice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PostNotice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PostNotice> mapFromJson(dynamic json) {
    final map = <String, PostNotice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PostNotice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PostNotice-objects as value to a dart map
  static Map<String, List<PostNotice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PostNotice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PostNotice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'message',
  };
}

