//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformInvoiceLine {
  /// Returns a new [PlatformInvoiceLine] instance.
  PlatformInvoiceLine({
    this.id,
    this.propertyId,
    this.propertyName,
    this.occupiedUnits,
    this.occupiedBeds,
    this.unitRate,
    this.bedRate,
    this.amountDue,
    this.invoiceNumber,
    this.issuedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

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
  int? occupiedUnits;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? occupiedBeds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? unitRate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? bedRate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? amountDue;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? invoiceNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? issuedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlatformInvoiceLine &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.occupiedUnits == occupiedUnits &&
    other.occupiedBeds == occupiedBeds &&
    other.unitRate == unitRate &&
    other.bedRate == bedRate &&
    other.amountDue == amountDue &&
    other.invoiceNumber == invoiceNumber &&
    other.issuedAt == issuedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (occupiedUnits == null ? 0 : occupiedUnits!.hashCode) +
    (occupiedBeds == null ? 0 : occupiedBeds!.hashCode) +
    (unitRate == null ? 0 : unitRate!.hashCode) +
    (bedRate == null ? 0 : bedRate!.hashCode) +
    (amountDue == null ? 0 : amountDue!.hashCode) +
    (invoiceNumber == null ? 0 : invoiceNumber!.hashCode) +
    (issuedAt == null ? 0 : issuedAt!.hashCode);

  @override
  String toString() => 'PlatformInvoiceLine[id=$id, propertyId=$propertyId, propertyName=$propertyName, occupiedUnits=$occupiedUnits, occupiedBeds=$occupiedBeds, unitRate=$unitRate, bedRate=$bedRate, amountDue=$amountDue, invoiceNumber=$invoiceNumber, issuedAt=$issuedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
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
    if (this.occupiedUnits != null) {
      json[r'occupiedUnits'] = this.occupiedUnits;
    } else {
      json[r'occupiedUnits'] = null;
    }
    if (this.occupiedBeds != null) {
      json[r'occupiedBeds'] = this.occupiedBeds;
    } else {
      json[r'occupiedBeds'] = null;
    }
    if (this.unitRate != null) {
      json[r'unitRate'] = this.unitRate;
    } else {
      json[r'unitRate'] = null;
    }
    if (this.bedRate != null) {
      json[r'bedRate'] = this.bedRate;
    } else {
      json[r'bedRate'] = null;
    }
    if (this.amountDue != null) {
      json[r'amountDue'] = this.amountDue;
    } else {
      json[r'amountDue'] = null;
    }
    if (this.invoiceNumber != null) {
      json[r'invoiceNumber'] = this.invoiceNumber;
    } else {
      json[r'invoiceNumber'] = null;
    }
    if (this.issuedAt != null) {
      json[r'issuedAt'] = this.issuedAt!.toUtc().toIso8601String();
    } else {
      json[r'issuedAt'] = null;
    }
    return json;
  }

  /// Returns a new [PlatformInvoiceLine] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformInvoiceLine? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PlatformInvoiceLine(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        occupiedUnits: mapValueOfType<int>(json, r'occupiedUnits'),
        occupiedBeds: mapValueOfType<int>(json, r'occupiedBeds'),
        unitRate: json[r'unitRate'] == null
            ? null
            : num.parse('${json[r'unitRate']}'),
        bedRate: json[r'bedRate'] == null
            ? null
            : num.parse('${json[r'bedRate']}'),
        amountDue: json[r'amountDue'] == null
            ? null
            : num.parse('${json[r'amountDue']}'),
        invoiceNumber: mapValueOfType<String>(json, r'invoiceNumber'),
        issuedAt: mapDateTime(json, r'issuedAt', r''),
      );
    }
    return null;
  }

  static List<PlatformInvoiceLine> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformInvoiceLine>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformInvoiceLine.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformInvoiceLine> mapFromJson(dynamic json) {
    final map = <String, PlatformInvoiceLine>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformInvoiceLine.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformInvoiceLine-objects as value to a dart map
  static Map<String, List<PlatformInvoiceLine>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformInvoiceLine>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformInvoiceLine.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

