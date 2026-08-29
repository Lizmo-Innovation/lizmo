//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VacantBed {
  /// Returns a new [VacantBed] instance.
  VacantBed({
    this.unitId,
    this.unitNumber,
    this.bedId,
    this.bedLabel,
    this.rent,
    this.monthlyUtilities,
    this.utilitiesIncluded,
  });

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
  String? bedId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedLabel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rent;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? monthlyUtilities;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? utilitiesIncluded;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VacantBed &&
    other.unitId == unitId &&
    other.unitNumber == unitNumber &&
    other.bedId == bedId &&
    other.bedLabel == bedLabel &&
    other.rent == rent &&
    other.monthlyUtilities == monthlyUtilities &&
    other.utilitiesIncluded == utilitiesIncluded;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (unitId == null ? 0 : unitId!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedId == null ? 0 : bedId!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (monthlyUtilities == null ? 0 : monthlyUtilities!.hashCode) +
    (utilitiesIncluded == null ? 0 : utilitiesIncluded!.hashCode);

  @override
  String toString() => 'VacantBed[unitId=$unitId, unitNumber=$unitNumber, bedId=$bedId, bedLabel=$bedLabel, rent=$rent, monthlyUtilities=$monthlyUtilities, utilitiesIncluded=$utilitiesIncluded]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.bedId != null) {
      json[r'bedId'] = this.bedId;
    } else {
      json[r'bedId'] = null;
    }
    if (this.bedLabel != null) {
      json[r'bedLabel'] = this.bedLabel;
    } else {
      json[r'bedLabel'] = null;
    }
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
    if (this.monthlyUtilities != null) {
      json[r'monthlyUtilities'] = this.monthlyUtilities;
    } else {
      json[r'monthlyUtilities'] = null;
    }
    if (this.utilitiesIncluded != null) {
      json[r'utilitiesIncluded'] = this.utilitiesIncluded;
    } else {
      json[r'utilitiesIncluded'] = null;
    }
    return json;
  }

  /// Returns a new [VacantBed] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VacantBed? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return VacantBed(
        unitId: mapValueOfType<String>(json, r'unitId'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedId: mapValueOfType<String>(json, r'bedId'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
        monthlyUtilities: json[r'monthlyUtilities'] == null
            ? null
            : num.parse('${json[r'monthlyUtilities']}'),
        utilitiesIncluded: mapValueOfType<bool>(json, r'utilitiesIncluded'),
      );
    }
    return null;
  }

  static List<VacantBed> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VacantBed>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VacantBed.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VacantBed> mapFromJson(dynamic json) {
    final map = <String, VacantBed>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VacantBed.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VacantBed-objects as value to a dart map
  static Map<String, List<VacantBed>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VacantBed>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VacantBed.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

