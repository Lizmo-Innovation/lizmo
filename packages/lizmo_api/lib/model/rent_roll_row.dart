//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentRollRow {
  /// Returns a new [RentRollRow] instance.
  RentRollRow({
    this.propertyId,
    this.propertyName,
    this.leaseId,
    this.current,
    this.tenantName,
    this.unitNumber,
    this.bedLabel,
    this.period,
    this.waiting = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyId;

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
  String? leaseId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? current;

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
  BillingPeriodResponse? period;

  List<WaitingPayment> waiting;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentRollRow &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.leaseId == leaseId &&
    other.current == current &&
    other.tenantName == tenantName &&
    other.unitNumber == unitNumber &&
    other.bedLabel == bedLabel &&
    other.period == period &&
    _deepEquality.equals(other.waiting, waiting);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (current == null ? 0 : current!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (period == null ? 0 : period!.hashCode) +
    (waiting.hashCode);

  @override
  String toString() => 'RentRollRow[propertyId=$propertyId, propertyName=$propertyName, leaseId=$leaseId, current=$current, tenantName=$tenantName, unitNumber=$unitNumber, bedLabel=$bedLabel, period=$period, waiting=$waiting]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.propertyId != null) {
      json[r'propertyId'] = this.propertyId;
    } else {
      json[r'propertyId'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.current != null) {
      json[r'current'] = this.current;
    } else {
      json[r'current'] = null;
    }
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
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
    if (this.period != null) {
      json[r'period'] = this.period;
    } else {
      json[r'period'] = null;
    }
      json[r'waiting'] = this.waiting;
    return json;
  }

  /// Returns a new [RentRollRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentRollRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return RentRollRow(
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        current: mapValueOfType<bool>(json, r'current'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        period: BillingPeriodResponse.fromJson(json[r'period']),
        waiting: WaitingPayment.listFromJson(json[r'waiting']),
      );
    }
    return null;
  }

  static List<RentRollRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentRollRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentRollRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentRollRow> mapFromJson(dynamic json) {
    final map = <String, RentRollRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentRollRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentRollRow-objects as value to a dart map
  static Map<String, List<RentRollRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentRollRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentRollRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

