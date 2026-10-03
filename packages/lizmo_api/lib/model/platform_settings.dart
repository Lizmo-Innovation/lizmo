//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformSettings {
  /// Returns a new [PlatformSettings] instance.
  PlatformSettings({
    required this.supportEmail,
    this.paymentInstructions,
    this.minimumAndroidVersion,
    this.minimumIosVersion,
    this.androidUpdateUrl,
    this.iosUpdateUrl,
  });

  String supportEmail;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? paymentInstructions;

  /// The oldest Android version allowed in. Raising it locks out everybody on an older one, so it is left alone when not sent; blank stops Android being checked.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? minimumAndroidVersion;

  /// The same for iOS, separately: releases drift apart.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? minimumIosVersion;

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
  bool operator ==(Object other) => identical(this, other) || other is PlatformSettings &&
    other.supportEmail == supportEmail &&
    other.paymentInstructions == paymentInstructions &&
    other.minimumAndroidVersion == minimumAndroidVersion &&
    other.minimumIosVersion == minimumIosVersion &&
    other.androidUpdateUrl == androidUpdateUrl &&
    other.iosUpdateUrl == iosUpdateUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (supportEmail.hashCode) +
    (paymentInstructions == null ? 0 : paymentInstructions!.hashCode) +
    (minimumAndroidVersion == null ? 0 : minimumAndroidVersion!.hashCode) +
    (minimumIosVersion == null ? 0 : minimumIosVersion!.hashCode) +
    (androidUpdateUrl == null ? 0 : androidUpdateUrl!.hashCode) +
    (iosUpdateUrl == null ? 0 : iosUpdateUrl!.hashCode);

  @override
  String toString() => 'PlatformSettings[supportEmail=$supportEmail, paymentInstructions=$paymentInstructions, minimumAndroidVersion=$minimumAndroidVersion, minimumIosVersion=$minimumIosVersion, androidUpdateUrl=$androidUpdateUrl, iosUpdateUrl=$iosUpdateUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'supportEmail'] = this.supportEmail;
    if (this.paymentInstructions != null) {
      json[r'paymentInstructions'] = this.paymentInstructions;
    } else {
      json[r'paymentInstructions'] = null;
    }
    if (this.minimumAndroidVersion != null) {
      json[r'minimumAndroidVersion'] = this.minimumAndroidVersion;
    } else {
      json[r'minimumAndroidVersion'] = null;
    }
    if (this.minimumIosVersion != null) {
      json[r'minimumIosVersion'] = this.minimumIosVersion;
    } else {
      json[r'minimumIosVersion'] = null;
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

  /// Returns a new [PlatformSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'supportEmail'), 'Required key "PlatformSettings[supportEmail]" is missing from JSON.');
        assert(json[r'supportEmail'] != null, 'Required key "PlatformSettings[supportEmail]" has a null value in JSON.');
        return true;
      }());

      return PlatformSettings(
        supportEmail: mapValueOfType<String>(json, r'supportEmail')!,
        paymentInstructions: mapValueOfType<String>(json, r'paymentInstructions'),
        minimumAndroidVersion: mapValueOfType<String>(json, r'minimumAndroidVersion'),
        minimumIosVersion: mapValueOfType<String>(json, r'minimumIosVersion'),
        androidUpdateUrl: mapValueOfType<String>(json, r'androidUpdateUrl'),
        iosUpdateUrl: mapValueOfType<String>(json, r'iosUpdateUrl'),
      );
    }
    return null;
  }

  static List<PlatformSettings> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformSettings> mapFromJson(dynamic json) {
    final map = <String, PlatformSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformSettings-objects as value to a dart map
  static Map<String, List<PlatformSettings>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformSettings.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'supportEmail',
  };
}

