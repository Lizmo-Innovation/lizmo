//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ArrearsRow {
  /// Returns a new [ArrearsRow] instance.
  ArrearsRow({
    this.leaseId,
    this.tenantName,
    this.propertyName,
    this.unitNumber,
    this.bedLabel,
    this.outstanding,
    this.monthsLate,
    this.oldestDueDate,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? leaseId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantName;

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
  String? unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedLabel;

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
  int? monthsLate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? oldestDueDate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ArrearsRow &&
    other.leaseId == leaseId &&
    other.tenantName == tenantName &&
    other.propertyName == propertyName &&
    other.unitNumber == unitNumber &&
    other.bedLabel == bedLabel &&
    other.outstanding == outstanding &&
    other.monthsLate == monthsLate &&
    other.oldestDueDate == oldestDueDate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (outstanding == null ? 0 : outstanding!.hashCode) +
    (monthsLate == null ? 0 : monthsLate!.hashCode) +
    (oldestDueDate == null ? 0 : oldestDueDate!.hashCode);

  @override
  String toString() => 'ArrearsRow[leaseId=$leaseId, tenantName=$tenantName, propertyName=$propertyName, unitNumber=$unitNumber, bedLabel=$bedLabel, outstanding=$outstanding, monthsLate=$monthsLate, oldestDueDate=$oldestDueDate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.bedLabel != null) {
      json[r'bedLabel'] = this.bedLabel;
    } else {
      json[r'bedLabel'] = null;
    }
    if (this.outstanding != null) {
      json[r'outstanding'] = this.outstanding;
    } else {
      json[r'outstanding'] = null;
    }
    if (this.monthsLate != null) {
      json[r'monthsLate'] = this.monthsLate;
    } else {
      json[r'monthsLate'] = null;
    }
    if (this.oldestDueDate != null) {
      json[r'oldestDueDate'] = _dateFormatter.format(this.oldestDueDate!);
    } else {
      json[r'oldestDueDate'] = null;
    }
    return json;
  }

  /// Returns a new [ArrearsRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ArrearsRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ArrearsRow(
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        outstanding: json[r'outstanding'] == null
            ? null
            : num.parse('${json[r'outstanding']}'),
        monthsLate: mapValueOfType<int>(json, r'monthsLate'),
        oldestDueDate: mapDateTime(json, r'oldestDueDate', r''),
      );
    }
    return null;
  }

  static List<ArrearsRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ArrearsRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ArrearsRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ArrearsRow> mapFromJson(dynamic json) {
    final map = <String, ArrearsRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ArrearsRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ArrearsRow-objects as value to a dart map
  static Map<String, List<ArrearsRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ArrearsRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ArrearsRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

