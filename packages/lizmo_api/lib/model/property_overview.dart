//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PropertyOverview {
  /// Returns a new [PropertyOverview] instance.
  PropertyOverview({
    this.occupied,
    this.rentable,
    this.vacant,
    this.overdueTotal,
    this.units = const [],
  });

  /// Spaces let: beds, and whole units counted as one
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? occupied;

  /// Spaces that can be let: out of service ones are not
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rentable;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vacant;

  /// What is owed late across every tenancy here
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? overdueTotal;

  List<UnitOverview> units;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyOverview &&
    other.occupied == occupied &&
    other.rentable == rentable &&
    other.vacant == vacant &&
    other.overdueTotal == overdueTotal &&
    _deepEquality.equals(other.units, units);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (occupied == null ? 0 : occupied!.hashCode) +
    (rentable == null ? 0 : rentable!.hashCode) +
    (vacant == null ? 0 : vacant!.hashCode) +
    (overdueTotal == null ? 0 : overdueTotal!.hashCode) +
    (units.hashCode);

  @override
  String toString() => 'PropertyOverview[occupied=$occupied, rentable=$rentable, vacant=$vacant, overdueTotal=$overdueTotal, units=$units]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.occupied != null) {
      json[r'occupied'] = this.occupied;
    } else {
      json[r'occupied'] = null;
    }
    if (this.rentable != null) {
      json[r'rentable'] = this.rentable;
    } else {
      json[r'rentable'] = null;
    }
    if (this.vacant != null) {
      json[r'vacant'] = this.vacant;
    } else {
      json[r'vacant'] = null;
    }
    if (this.overdueTotal != null) {
      json[r'overdueTotal'] = this.overdueTotal;
    } else {
      json[r'overdueTotal'] = null;
    }
      json[r'units'] = this.units;
    return json;
  }

  /// Returns a new [PropertyOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PropertyOverview(
        occupied: mapValueOfType<int>(json, r'occupied'),
        rentable: mapValueOfType<int>(json, r'rentable'),
        vacant: mapValueOfType<int>(json, r'vacant'),
        overdueTotal: json[r'overdueTotal'] == null
            ? null
            : num.parse('${json[r'overdueTotal']}'),
        units: UnitOverview.listFromJson(json[r'units']),
      );
    }
    return null;
  }

  static List<PropertyOverview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyOverview> mapFromJson(dynamic json) {
    final map = <String, PropertyOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyOverview-objects as value to a dart map
  static Map<String, List<PropertyOverview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyOverview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

