//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseTermRequest {
  /// Returns a new [LeaseTermRequest] instance.
  LeaseTermRequest({
    this.endsOn,
  });

  /// The last day of the lease. Null takes the end date away, leaving it month to month. A later date is how a lease is extended.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endsOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseTermRequest &&
    other.endsOn == endsOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (endsOn == null ? 0 : endsOn!.hashCode);

  @override
  String toString() => 'LeaseTermRequest[endsOn=$endsOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.endsOn != null) {
      json[r'endsOn'] = _dateFormatter.format(this.endsOn!);
    } else {
      json[r'endsOn'] = null;
    }
    return json;
  }

  /// Returns a new [LeaseTermRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseTermRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LeaseTermRequest(
        endsOn: mapDateTime(json, r'endsOn', r''),
      );
    }
    return null;
  }

  static List<LeaseTermRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseTermRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseTermRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseTermRequest> mapFromJson(dynamic json) {
    final map = <String, LeaseTermRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseTermRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseTermRequest-objects as value to a dart map
  static Map<String, List<LeaseTermRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseTermRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseTermRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

