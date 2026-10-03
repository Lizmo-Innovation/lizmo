//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppVersion {
  /// Returns a new [AppVersion] instance.
  AppVersion({
    this.minimumBuild,
    this.androidUpdateUrl,
    this.iosUpdateUrl,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minimumBuild;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? androidUpdateUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? iosUpdateUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppVersion &&
    other.minimumBuild == minimumBuild &&
    other.androidUpdateUrl == androidUpdateUrl &&
    other.iosUpdateUrl == iosUpdateUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (minimumBuild == null ? 0 : minimumBuild!.hashCode) +
    (androidUpdateUrl == null ? 0 : androidUpdateUrl!.hashCode) +
    (iosUpdateUrl == null ? 0 : iosUpdateUrl!.hashCode);

  @override
  String toString() => 'AppVersion[minimumBuild=$minimumBuild, androidUpdateUrl=$androidUpdateUrl, iosUpdateUrl=$iosUpdateUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.minimumBuild != null) {
      json[r'minimumBuild'] = this.minimumBuild;
    } else {
      json[r'minimumBuild'] = null;
    }
    if (this.androidUpdateUrl != null) {
      json[r'androidUpdateUrl'] = this.androidUpdateUrl;
    } else {
      json[r'androidUpdateUrl'] = null;
    }
    if (this.iosUpdateUrl != null) {
      json[r'iosUpdateUrl'] = this.iosUpdateUrl;
    } else {
      json[r'iosUpdateUrl'] = null;
    }
    return json;
  }

  /// Returns a new [AppVersion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppVersion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AppVersion(
        minimumBuild: mapValueOfType<int>(json, r'minimumBuild'),
        androidUpdateUrl: mapValueOfType<String>(json, r'androidUpdateUrl'),
        iosUpdateUrl: mapValueOfType<String>(json, r'iosUpdateUrl'),
      );
    }
    return null;
  }

  static List<AppVersion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppVersion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppVersion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppVersion> mapFromJson(dynamic json) {
    final map = <String, AppVersion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppVersion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppVersion-objects as value to a dart map
  static Map<String, List<AppVersion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppVersion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppVersion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

