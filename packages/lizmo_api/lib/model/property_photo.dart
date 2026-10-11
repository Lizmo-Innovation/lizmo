//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PropertyPhoto {
  /// Returns a new [PropertyPhoto] instance.
  PropertyPhoto({
    this.id,
    this.url,
    this.urlExpiresInSeconds,
    this.position,
    this.uploadedAt,
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
  String? url;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? urlExpiresInSeconds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? position;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? uploadedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyPhoto &&
    other.id == id &&
    other.url == url &&
    other.urlExpiresInSeconds == urlExpiresInSeconds &&
    other.position == position &&
    other.uploadedAt == uploadedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (url == null ? 0 : url!.hashCode) +
    (urlExpiresInSeconds == null ? 0 : urlExpiresInSeconds!.hashCode) +
    (position == null ? 0 : position!.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode);

  @override
  String toString() => 'PropertyPhoto[id=$id, url=$url, urlExpiresInSeconds=$urlExpiresInSeconds, position=$position, uploadedAt=$uploadedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    if (this.urlExpiresInSeconds != null) {
      json[r'urlExpiresInSeconds'] = this.urlExpiresInSeconds;
    } else {
      json[r'urlExpiresInSeconds'] = null;
    }
    if (this.position != null) {
      json[r'position'] = this.position;
    } else {
      json[r'position'] = null;
    }
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'uploadedAt'] = null;
    }
    return json;
  }

  /// Returns a new [PropertyPhoto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyPhoto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PropertyPhoto(
        id: mapValueOfType<String>(json, r'id'),
        url: mapValueOfType<String>(json, r'url'),
        urlExpiresInSeconds: mapValueOfType<int>(json, r'urlExpiresInSeconds'),
        position: mapValueOfType<int>(json, r'position'),
        uploadedAt: mapDateTime(json, r'uploadedAt', r''),
      );
    }
    return null;
  }

  static List<PropertyPhoto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyPhoto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyPhoto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyPhoto> mapFromJson(dynamic json) {
    final map = <String, PropertyPhoto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyPhoto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyPhoto-objects as value to a dart map
  static Map<String, List<PropertyPhoto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyPhoto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyPhoto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

