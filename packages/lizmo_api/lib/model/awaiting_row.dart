//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AwaitingRow {
  /// Returns a new [AwaitingRow] instance.
  AwaitingRow({
    this.leaseId,
    this.paymentId,
    this.tenantName,
    this.propertyName,
    this.unitNumber,
    this.bedLabel,
    this.amount,
    this.paidOn,
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
  String? paymentId;

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
  num? amount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paidOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AwaitingRow &&
    other.leaseId == leaseId &&
    other.paymentId == paymentId &&
    other.tenantName == tenantName &&
    other.propertyName == propertyName &&
    other.unitNumber == unitNumber &&
    other.bedLabel == bedLabel &&
    other.amount == amount &&
    other.paidOn == paidOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (paymentId == null ? 0 : paymentId!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (amount == null ? 0 : amount!.hashCode) +
    (paidOn == null ? 0 : paidOn!.hashCode);

  @override
  String toString() => 'AwaitingRow[leaseId=$leaseId, paymentId=$paymentId, tenantName=$tenantName, propertyName=$propertyName, unitNumber=$unitNumber, bedLabel=$bedLabel, amount=$amount, paidOn=$paidOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.paymentId != null) {
      json[r'paymentId'] = this.paymentId;
    } else {
      json[r'paymentId'] = null;
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
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    if (this.paidOn != null) {
      json[r'paidOn'] = _dateFormatter.format(this.paidOn!);
    } else {
      json[r'paidOn'] = null;
    }
    return json;
  }

  /// Returns a new [AwaitingRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AwaitingRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AwaitingRow(
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        paymentId: mapValueOfType<String>(json, r'paymentId'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
        paidOn: mapDateTime(json, r'paidOn', r''),
      );
    }
    return null;
  }

  static List<AwaitingRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AwaitingRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AwaitingRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AwaitingRow> mapFromJson(dynamic json) {
    final map = <String, AwaitingRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AwaitingRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AwaitingRow-objects as value to a dart map
  static Map<String, List<AwaitingRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AwaitingRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AwaitingRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

