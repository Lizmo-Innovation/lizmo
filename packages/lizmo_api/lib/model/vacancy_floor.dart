//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VacancyFloor {
  /// Returns a new [VacancyFloor] instance.
  VacancyFloor({
    this.floor,
    this.wholeUnits = const [],
    this.bedspaces = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? floor;

  List<VacantUnit> wholeUnits;

  List<VacantBed> bedspaces;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VacancyFloor &&
    other.floor == floor &&
    _deepEquality.equals(other.wholeUnits, wholeUnits) &&
    _deepEquality.equals(other.bedspaces, bedspaces);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (floor == null ? 0 : floor!.hashCode) +
    (wholeUnits.hashCode) +
    (bedspaces.hashCode);

  @override
  String toString() => 'VacancyFloor[floor=$floor, wholeUnits=$wholeUnits, bedspaces=$bedspaces]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.floor != null) {
      json[r'floor'] = this.floor;
    } else {
      json[r'floor'] = null;
    }
      json[r'wholeUnits'] = this.wholeUnits;
      json[r'bedspaces'] = this.bedspaces;
    return json;
  }

  /// Returns a new [VacancyFloor] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VacancyFloor? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return VacancyFloor(
        floor: mapValueOfType<String>(json, r'floor'),
        wholeUnits: VacantUnit.listFromJson(json[r'wholeUnits']),
        bedspaces: VacantBed.listFromJson(json[r'bedspaces']),
      );
    }
    return null;
  }

  static List<VacancyFloor> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VacancyFloor>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VacancyFloor.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VacancyFloor> mapFromJson(dynamic json) {
    final map = <String, VacancyFloor>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VacancyFloor.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VacancyFloor-objects as value to a dart map
  static Map<String, List<VacancyFloor>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VacancyFloor>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VacancyFloor.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

