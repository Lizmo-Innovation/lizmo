//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AcceptRequest {
  /// Returns a new [AcceptRequest] instance.
  AcceptRequest({
    this.rentAmount,
    this.dueDateDay,
    this.startDate,
  });

  /// Defaults to the asking rent
  ///
  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rentAmount;

  /// Defaults to the start date's day
  ///
  /// Minimum value: 1
  /// Maximum value: 31
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? dueDateDay;

  /// Defaults to today
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startDate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AcceptRequest &&
    other.rentAmount == rentAmount &&
    other.dueDateDay == dueDateDay &&
    other.startDate == startDate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rentAmount == null ? 0 : rentAmount!.hashCode) +
    (dueDateDay == null ? 0 : dueDateDay!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode);

  @override
  String toString() => 'AcceptRequest[rentAmount=$rentAmount, dueDateDay=$dueDateDay, startDate=$startDate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.rentAmount != null) {
      json[r'rentAmount'] = this.rentAmount;
    } else {
      json[r'rentAmount'] = null;
    }
    if (this.dueDateDay != null) {
      json[r'dueDateDay'] = this.dueDateDay;
    } else {
      json[r'dueDateDay'] = null;
    }
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!);
    } else {
      json[r'startDate'] = null;
    }
    return json;
  }

  /// Returns a new [AcceptRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AcceptRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AcceptRequest(
        rentAmount: json[r'rentAmount'] == null
            ? null
            : num.parse('${json[r'rentAmount']}'),
        dueDateDay: mapValueOfType<int>(json, r'dueDateDay'),
        startDate: mapDateTime(json, r'startDate', r''),
      );
    }
    return null;
  }

  static List<AcceptRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AcceptRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AcceptRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AcceptRequest> mapFromJson(dynamic json) {
    final map = <String, AcceptRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AcceptRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AcceptRequest-objects as value to a dart map
  static Map<String, List<AcceptRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AcceptRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AcceptRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

