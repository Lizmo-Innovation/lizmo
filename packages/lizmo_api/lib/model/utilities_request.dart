//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UtilitiesRequest {
  /// Returns a new [UtilitiesRequest] instance.
  UtilitiesRequest({
    this.utilities = const [],
  });

  List<UtilityRequest> utilities;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UtilitiesRequest &&
    _deepEquality.equals(other.utilities, utilities);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (utilities.hashCode);

  @override
  String toString() => 'UtilitiesRequest[utilities=$utilities]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'utilities'] = this.utilities;
    return json;
  }

  /// Returns a new [UtilitiesRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UtilitiesRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'utilities'), 'Required key "UtilitiesRequest[utilities]" is missing from JSON.');
        assert(json[r'utilities'] != null, 'Required key "UtilitiesRequest[utilities]" has a null value in JSON.');
        return true;
      }());

      return UtilitiesRequest(
        utilities: UtilityRequest.listFromJson(json[r'utilities']),
      );
    }
    return null;
  }

  static List<UtilitiesRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilitiesRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilitiesRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UtilitiesRequest> mapFromJson(dynamic json) {
    final map = <String, UtilitiesRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UtilitiesRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UtilitiesRequest-objects as value to a dart map
  static Map<String, List<UtilitiesRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UtilitiesRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UtilitiesRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'utilities',
  };
}

