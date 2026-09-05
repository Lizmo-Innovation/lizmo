//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminPropertySummary {
  /// Returns a new [AdminPropertySummary] instance.
  AdminPropertySummary({
    this.id,
    this.name,
    this.address,
    this.code,
    this.accountStatus,
    this.units,
    this.occupiedUnits,
    this.beds,
    this.occupiedBeds,
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
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? code;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? accountStatus;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? units;

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
  int? beds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? occupiedBeds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminPropertySummary &&
    other.id == id &&
    other.name == name &&
    other.address == address &&
    other.code == code &&
    other.accountStatus == accountStatus &&
    other.units == units &&
    other.occupiedUnits == occupiedUnits &&
    other.beds == beds &&
    other.occupiedBeds == occupiedBeds;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (accountStatus == null ? 0 : accountStatus!.hashCode) +
    (units == null ? 0 : units!.hashCode) +
    (occupiedUnits == null ? 0 : occupiedUnits!.hashCode) +
    (beds == null ? 0 : beds!.hashCode) +
    (occupiedBeds == null ? 0 : occupiedBeds!.hashCode);

  @override
  String toString() => 'AdminPropertySummary[id=$id, name=$name, address=$address, code=$code, accountStatus=$accountStatus, units=$units, occupiedUnits=$occupiedUnits, beds=$beds, occupiedBeds=$occupiedBeds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
    if (this.accountStatus != null) {
      json[r'accountStatus'] = this.accountStatus;
    } else {
      json[r'accountStatus'] = null;
    }
    if (this.units != null) {
      json[r'units'] = this.units;
    } else {
      json[r'units'] = null;
    }
    if (this.occupiedUnits != null) {
      json[r'occupiedUnits'] = this.occupiedUnits;
    } else {
      json[r'occupiedUnits'] = null;
    }
    if (this.beds != null) {
      json[r'beds'] = this.beds;
    } else {
      json[r'beds'] = null;
    }
    if (this.occupiedBeds != null) {
      json[r'occupiedBeds'] = this.occupiedBeds;
    } else {
      json[r'occupiedBeds'] = null;
    }
    return json;
  }

  /// Returns a new [AdminPropertySummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminPropertySummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AdminPropertySummary(
        id: mapValueOfType<String>(json, r'id'),
        name: mapValueOfType<String>(json, r'name'),
        address: mapValueOfType<String>(json, r'address'),
        code: mapValueOfType<String>(json, r'code'),
        accountStatus: mapValueOfType<String>(json, r'accountStatus'),
        units: mapValueOfType<int>(json, r'units'),
        occupiedUnits: mapValueOfType<int>(json, r'occupiedUnits'),
        beds: mapValueOfType<int>(json, r'beds'),
        occupiedBeds: mapValueOfType<int>(json, r'occupiedBeds'),
      );
    }
    return null;
  }

  static List<AdminPropertySummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertySummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertySummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminPropertySummary> mapFromJson(dynamic json) {
    final map = <String, AdminPropertySummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminPropertySummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminPropertySummary-objects as value to a dart map
  static Map<String, List<AdminPropertySummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminPropertySummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminPropertySummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

