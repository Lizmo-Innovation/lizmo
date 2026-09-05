//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LandlordSummary {
  /// Returns a new [LandlordSummary] instance.
  LandlordSummary({
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.properties,
    this.lockedProperties,
    this.occupiedUnits,
    this.occupiedBeds,
    this.joinedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? userId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? properties;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? lockedProperties;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? occupiedUnits;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? occupiedBeds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? joinedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LandlordSummary &&
    other.userId == userId &&
    other.name == name &&
    other.email == email &&
    other.phone == phone &&
    other.properties == properties &&
    other.lockedProperties == lockedProperties &&
    other.occupiedUnits == occupiedUnits &&
    other.occupiedBeds == occupiedBeds &&
    other.joinedAt == joinedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId == null ? 0 : userId!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (properties == null ? 0 : properties!.hashCode) +
    (lockedProperties == null ? 0 : lockedProperties!.hashCode) +
    (occupiedUnits == null ? 0 : occupiedUnits!.hashCode) +
    (occupiedBeds == null ? 0 : occupiedBeds!.hashCode) +
    (joinedAt == null ? 0 : joinedAt!.hashCode);

  @override
  String toString() => 'LandlordSummary[userId=$userId, name=$name, email=$email, phone=$phone, properties=$properties, lockedProperties=$lockedProperties, occupiedUnits=$occupiedUnits, occupiedBeds=$occupiedBeds, joinedAt=$joinedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.userId != null) {
      json[r'userId'] = this.userId;
    } else {
      json[r'userId'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    if (this.properties != null) {
      json[r'properties'] = this.properties;
    } else {
      json[r'properties'] = null;
    }
    if (this.lockedProperties != null) {
      json[r'lockedProperties'] = this.lockedProperties;
    } else {
      json[r'lockedProperties'] = null;
    }
    if (this.occupiedUnits != null) {
      json[r'occupiedUnits'] = this.occupiedUnits;
    } else {
      json[r'occupiedUnits'] = null;
    }
    if (this.occupiedBeds != null) {
      json[r'occupiedBeds'] = this.occupiedBeds;
    } else {
      json[r'occupiedBeds'] = null;
    }
    if (this.joinedAt != null) {
      json[r'joinedAt'] = this.joinedAt!.toUtc().toIso8601String();
    } else {
      json[r'joinedAt'] = null;
    }
    return json;
  }

  /// Returns a new [LandlordSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LandlordSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LandlordSummary(
        userId: mapValueOfType<String>(json, r'userId'),
        name: mapValueOfType<String>(json, r'name'),
        email: mapValueOfType<String>(json, r'email'),
        phone: mapValueOfType<String>(json, r'phone'),
        properties: mapValueOfType<int>(json, r'properties'),
        lockedProperties: mapValueOfType<int>(json, r'lockedProperties'),
        occupiedUnits: mapValueOfType<int>(json, r'occupiedUnits'),
        occupiedBeds: mapValueOfType<int>(json, r'occupiedBeds'),
        joinedAt: mapDateTime(json, r'joinedAt', r''),
      );
    }
    return null;
  }

  static List<LandlordSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LandlordSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LandlordSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LandlordSummary> mapFromJson(dynamic json) {
    final map = <String, LandlordSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LandlordSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LandlordSummary-objects as value to a dart map
  static Map<String, List<LandlordSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LandlordSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LandlordSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

