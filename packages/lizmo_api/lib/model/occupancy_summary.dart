//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OccupancySummary {
  /// Returns a new [OccupancySummary] instance.
  OccupancySummary({
    this.lettable,
    this.occupied,
    this.empty,
    this.outOfService,
    this.earningRent,
    this.emptyRent,
    this.vacancies = const [],
  });

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
  int? outOfService;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? earningRent;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? emptyRent;

  List<VacancyRow> vacancies;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OccupancySummary &&
    other.lettable == lettable &&
    other.occupied == occupied &&
    other.empty == empty &&
    other.outOfService == outOfService &&
    other.earningRent == earningRent &&
    other.emptyRent == emptyRent &&
    _deepEquality.equals(other.vacancies, vacancies);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lettable == null ? 0 : lettable!.hashCode) +
    (occupied == null ? 0 : occupied!.hashCode) +
    (empty == null ? 0 : empty!.hashCode) +
    (outOfService == null ? 0 : outOfService!.hashCode) +
    (earningRent == null ? 0 : earningRent!.hashCode) +
    (emptyRent == null ? 0 : emptyRent!.hashCode) +
    (vacancies.hashCode);

  @override
  String toString() => 'OccupancySummary[lettable=$lettable, occupied=$occupied, empty=$empty, outOfService=$outOfService, earningRent=$earningRent, emptyRent=$emptyRent, vacancies=$vacancies]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.outOfService != null) {
      json[r'outOfService'] = this.outOfService;
    } else {
      json[r'outOfService'] = null;
    }
    if (this.earningRent != null) {
      json[r'earningRent'] = this.earningRent;
    } else {
      json[r'earningRent'] = null;
    }
    if (this.emptyRent != null) {
      json[r'emptyRent'] = this.emptyRent;
    } else {
      json[r'emptyRent'] = null;
    }
      json[r'vacancies'] = this.vacancies;
    return json;
  }

  /// Returns a new [OccupancySummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OccupancySummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OccupancySummary(
        lettable: mapValueOfType<int>(json, r'lettable'),
        occupied: mapValueOfType<int>(json, r'occupied'),
        empty: mapValueOfType<int>(json, r'empty'),
        outOfService: mapValueOfType<int>(json, r'outOfService'),
        earningRent: json[r'earningRent'] == null
            ? null
            : num.parse('${json[r'earningRent']}'),
        emptyRent: json[r'emptyRent'] == null
            ? null
            : num.parse('${json[r'emptyRent']}'),
        vacancies: VacancyRow.listFromJson(json[r'vacancies']),
      );
    }
    return null;
  }

  static List<OccupancySummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OccupancySummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OccupancySummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OccupancySummary> mapFromJson(dynamic json) {
    final map = <String, OccupancySummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OccupancySummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OccupancySummary-objects as value to a dart map
  static Map<String, List<OccupancySummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OccupancySummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OccupancySummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

