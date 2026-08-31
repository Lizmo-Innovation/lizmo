//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentalRequestCreate {
  /// Returns a new [RentalRequestCreate] instance.
  RentalRequestCreate({
    required this.unitId,
    this.bedId,
  });

  String unitId;

  /// Omit to ask for the whole unit
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentalRequestCreate &&
    other.unitId == unitId &&
    other.bedId == bedId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (unitId.hashCode) +
    (bedId == null ? 0 : bedId!.hashCode);

  @override
  String toString() => 'RentalRequestCreate[unitId=$unitId, bedId=$bedId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'unitId'] = this.unitId;
    if (this.bedId != null) {
      json[r'bedId'] = this.bedId;
    } else {
      json[r'bedId'] = null;
    }
    return json;
  }

  /// Returns a new [RentalRequestCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentalRequestCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'unitId'), 'Required key "RentalRequestCreate[unitId]" is missing from JSON.');
        assert(json[r'unitId'] != null, 'Required key "RentalRequestCreate[unitId]" has a null value in JSON.');
        return true;
      }());

      return RentalRequestCreate(
        unitId: mapValueOfType<String>(json, r'unitId')!,
        bedId: mapValueOfType<String>(json, r'bedId'),
      );
    }
    return null;
  }

  static List<RentalRequestCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentalRequestCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentalRequestCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentalRequestCreate> mapFromJson(dynamic json) {
    final map = <String, RentalRequestCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentalRequestCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentalRequestCreate-objects as value to a dart map
  static Map<String, List<RentalRequestCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentalRequestCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentalRequestCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'unitId',
  };
}

