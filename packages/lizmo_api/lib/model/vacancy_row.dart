//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VacancyRow {
  /// Returns a new [VacancyRow] instance.
  VacancyRow({
    this.propertyId,
    this.propertyName,
    this.lettable,
    this.occupied,
    this.empty,
    this.emptyRent,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? lettable;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? occupied;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? empty;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? emptyRent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VacancyRow &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.lettable == lettable &&
    other.occupied == occupied &&
    other.empty == empty &&
    other.emptyRent == emptyRent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (lettable == null ? 0 : lettable!.hashCode) +
    (occupied == null ? 0 : occupied!.hashCode) +
    (empty == null ? 0 : empty!.hashCode) +
    (emptyRent == null ? 0 : emptyRent!.hashCode);

  @override
  String toString() => 'VacancyRow[propertyId=$propertyId, propertyName=$propertyName, lettable=$lettable, occupied=$occupied, empty=$empty, emptyRent=$emptyRent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.propertyId != null) {
      json[r'propertyId'] = this.propertyId;
    } else {
      json[r'propertyId'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.lettable != null) {
      json[r'lettable'] = this.lettable;
    } else {
      json[r'lettable'] = null;
    }
    if (this.occupied != null) {
      json[r'occupied'] = this.occupied;
    } else {
      json[r'occupied'] = null;
    }
    if (this.empty != null) {
      json[r'empty'] = this.empty;
    } else {
      json[r'empty'] = null;
    }
    if (this.emptyRent != null) {
      json[r'emptyRent'] = this.emptyRent;
    } else {
      json[r'emptyRent'] = null;
    }
    return json;
  }

  /// Returns a new [VacancyRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VacancyRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return VacancyRow(
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        lettable: mapValueOfType<int>(json, r'lettable'),
        occupied: mapValueOfType<int>(json, r'occupied'),
        empty: mapValueOfType<int>(json, r'empty'),
        emptyRent: json[r'emptyRent'] == null
            ? null
            : num.parse('${json[r'emptyRent']}'),
      );
    }
    return null;
  }

  static List<VacancyRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VacancyRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VacancyRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VacancyRow> mapFromJson(dynamic json) {
    final map = <String, VacancyRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VacancyRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VacancyRow-objects as value to a dart map
  static Map<String, List<VacancyRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VacancyRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VacancyRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

