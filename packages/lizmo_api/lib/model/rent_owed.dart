//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentOwed {
  /// Returns a new [RentOwed] instance.
  RentOwed({
    this.billingPeriodId,
    this.label,
    this.outstanding,
    this.dueDate,
    this.overdue,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? billingPeriodId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? label;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? outstanding;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? dueDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? overdue;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentOwed &&
    other.billingPeriodId == billingPeriodId &&
    other.label == label &&
    other.outstanding == outstanding &&
    other.dueDate == dueDate &&
    other.overdue == overdue;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billingPeriodId == null ? 0 : billingPeriodId!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (outstanding == null ? 0 : outstanding!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (overdue == null ? 0 : overdue!.hashCode);

  @override
  String toString() => 'RentOwed[billingPeriodId=$billingPeriodId, label=$label, outstanding=$outstanding, dueDate=$dueDate, overdue=$overdue]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.billingPeriodId != null) {
      json[r'billingPeriodId'] = this.billingPeriodId;
    } else {
      json[r'billingPeriodId'] = null;
    }
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    if (this.outstanding != null) {
      json[r'outstanding'] = this.outstanding;
    } else {
      json[r'outstanding'] = null;
    }
    if (this.dueDate != null) {
      json[r'dueDate'] = _dateFormatter.format(this.dueDate!);
    } else {
      json[r'dueDate'] = null;
    }
    if (this.overdue != null) {
      json[r'overdue'] = this.overdue;
    } else {
      json[r'overdue'] = null;
    }
    return json;
  }

  /// Returns a new [RentOwed] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentOwed? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return RentOwed(
        billingPeriodId: mapValueOfType<String>(json, r'billingPeriodId'),
        label: mapValueOfType<String>(json, r'label'),
        outstanding: json[r'outstanding'] == null
            ? null
            : num.parse('${json[r'outstanding']}'),
        dueDate: mapDateTime(json, r'dueDate', r''),
        overdue: mapValueOfType<bool>(json, r'overdue'),
      );
    }
    return null;
  }

  static List<RentOwed> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentOwed>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentOwed.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentOwed> mapFromJson(dynamic json) {
    final map = <String, RentOwed>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentOwed.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentOwed-objects as value to a dart map
  static Map<String, List<RentOwed>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentOwed>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentOwed.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

