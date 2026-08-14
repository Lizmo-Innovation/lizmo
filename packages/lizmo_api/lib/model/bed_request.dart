//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BedRequest {
  /// Returns a new [BedRequest] instance.
  BedRequest({
    required this.bedLabel,
  });

  String bedLabel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BedRequest &&
    other.bedLabel == bedLabel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bedLabel.hashCode);

  @override
  String toString() => 'BedRequest[bedLabel=$bedLabel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bedLabel'] = this.bedLabel;
    return json;
  }

  /// Returns a new [BedRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BedRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bedLabel'), 'Required key "BedRequest[bedLabel]" is missing from JSON.');
        assert(json[r'bedLabel'] != null, 'Required key "BedRequest[bedLabel]" has a null value in JSON.');
        return true;
      }());

      return BedRequest(
        bedLabel: mapValueOfType<String>(json, r'bedLabel')!,
      );
    }
    return null;
  }

  static List<BedRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BedRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BedRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BedRequest> mapFromJson(dynamic json) {
    final map = <String, BedRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BedRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BedRequest-objects as value to a dart map
  static Map<String, List<BedRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BedRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BedRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bedLabel',
  };
}

