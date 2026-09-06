//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class EndLeaseRequest {
  /// Returns a new [EndLeaseRequest] instance.
  EndLeaseRequest({
    this.terminated,
    this.endDate,
    this.depositReturned,
    this.depositSettlement,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? terminated;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endDate;

  /// How much of the deposit went back. Null when there was no deposit, or when the landlord has not settled it yet.
  ///
  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? depositReturned;

  /// What was withheld and why, in the landlord's own words. Free text rather than itemised deductions: withholding money is where tenancies go wrong, and an explanation somebody actually wrote beats a form nobody fills in honestly.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? depositSettlement;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EndLeaseRequest &&
    other.terminated == terminated &&
    other.endDate == endDate &&
    other.depositReturned == depositReturned &&
    other.depositSettlement == depositSettlement;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (terminated == null ? 0 : terminated!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (depositReturned == null ? 0 : depositReturned!.hashCode) +
    (depositSettlement == null ? 0 : depositSettlement!.hashCode);

  @override
  String toString() => 'EndLeaseRequest[terminated=$terminated, endDate=$endDate, depositReturned=$depositReturned, depositSettlement=$depositSettlement]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.terminated != null) {
      json[r'terminated'] = this.terminated;
    } else {
      json[r'terminated'] = null;
    }
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!);
    } else {
      json[r'endDate'] = null;
    }
    if (this.depositReturned != null) {
      json[r'depositReturned'] = this.depositReturned;
    } else {
      json[r'depositReturned'] = null;
    }
    if (this.depositSettlement != null) {
      json[r'depositSettlement'] = this.depositSettlement;
    } else {
      json[r'depositSettlement'] = null;
    }
    return json;
  }

  /// Returns a new [EndLeaseRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EndLeaseRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return EndLeaseRequest(
        terminated: mapValueOfType<bool>(json, r'terminated'),
        endDate: mapDateTime(json, r'endDate', r''),
        depositReturned: json[r'depositReturned'] == null
            ? null
            : num.parse('${json[r'depositReturned']}'),
        depositSettlement: mapValueOfType<String>(json, r'depositSettlement'),
      );
    }
    return null;
  }

  static List<EndLeaseRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EndLeaseRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EndLeaseRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EndLeaseRequest> mapFromJson(dynamic json) {
    final map = <String, EndLeaseRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EndLeaseRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EndLeaseRequest-objects as value to a dart map
  static Map<String, List<EndLeaseRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EndLeaseRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EndLeaseRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

