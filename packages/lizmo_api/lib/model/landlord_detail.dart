//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LandlordDetail {
  /// Returns a new [LandlordDetail] instance.
  LandlordDetail({
    this.landlord,
    this.properties = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  LandlordSummary? landlord;

  List<AdminPropertySummary> properties;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LandlordDetail &&
    other.landlord == landlord &&
    _deepEquality.equals(other.properties, properties);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (landlord == null ? 0 : landlord!.hashCode) +
    (properties.hashCode);

  @override
  String toString() => 'LandlordDetail[landlord=$landlord, properties=$properties]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.landlord != null) {
      json[r'landlord'] = this.landlord;
    } else {
      json[r'landlord'] = null;
    }
      json[r'properties'] = this.properties;
    return json;
  }

  /// Returns a new [LandlordDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LandlordDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LandlordDetail(
        landlord: LandlordSummary.fromJson(json[r'landlord']),
        properties: AdminPropertySummary.listFromJson(json[r'properties']),
      );
    }
    return null;
  }

  static List<LandlordDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LandlordDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LandlordDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LandlordDetail> mapFromJson(dynamic json) {
    final map = <String, LandlordDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LandlordDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LandlordDetail-objects as value to a dart map
  static Map<String, List<LandlordDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LandlordDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LandlordDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

