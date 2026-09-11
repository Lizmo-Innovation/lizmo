//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformInvoiceResponse {
  /// Returns a new [PlatformInvoiceResponse] instance.
  PlatformInvoiceResponse({
    this.id,
    this.propertyId,
    this.propertyName,
    this.label,
    this.billingDate,
    this.dueDate,
    this.occupiedUnits,
    this.occupiedBeds,
    this.unitRate,
    this.bedRate,
    this.amountDue,
    this.amountPaid,
    this.outstanding,
    this.status,
    this.overdue,
    this.locksOn,
    this.lockedByThis,
    this.payments = const [],
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
  String? label;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? billingDate;

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
  num? amountPaid;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? outstanding;

  PlatformInvoiceResponseStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? overdue;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? locksOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? lockedByThis;

  List<PlatformPaymentResponse> payments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlatformInvoiceResponse &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.label == label &&
    other.billingDate == billingDate &&
    other.dueDate == dueDate &&
    other.occupiedUnits == occupiedUnits &&
    other.occupiedBeds == occupiedBeds &&
    other.unitRate == unitRate &&
    other.bedRate == bedRate &&
    other.amountDue == amountDue &&
    other.amountPaid == amountPaid &&
    other.outstanding == outstanding &&
    other.status == status &&
    other.overdue == overdue &&
    other.locksOn == locksOn &&
    other.lockedByThis == lockedByThis &&
    _deepEquality.equals(other.payments, payments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (billingDate == null ? 0 : billingDate!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (occupiedUnits == null ? 0 : occupiedUnits!.hashCode) +
    (occupiedBeds == null ? 0 : occupiedBeds!.hashCode) +
    (unitRate == null ? 0 : unitRate!.hashCode) +
    (bedRate == null ? 0 : bedRate!.hashCode) +
    (amountDue == null ? 0 : amountDue!.hashCode) +
    (amountPaid == null ? 0 : amountPaid!.hashCode) +
    (outstanding == null ? 0 : outstanding!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (overdue == null ? 0 : overdue!.hashCode) +
    (locksOn == null ? 0 : locksOn!.hashCode) +
    (lockedByThis == null ? 0 : lockedByThis!.hashCode) +
    (payments.hashCode);

  @override
  String toString() => 'PlatformInvoiceResponse[id=$id, propertyId=$propertyId, propertyName=$propertyName, label=$label, billingDate=$billingDate, dueDate=$dueDate, occupiedUnits=$occupiedUnits, occupiedBeds=$occupiedBeds, unitRate=$unitRate, bedRate=$bedRate, amountDue=$amountDue, amountPaid=$amountPaid, outstanding=$outstanding, status=$status, overdue=$overdue, locksOn=$locksOn, lockedByThis=$lockedByThis, payments=$payments]';

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
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    if (this.billingDate != null) {
      json[r'billingDate'] = _dateFormatter.format(this.billingDate!);
    } else {
      json[r'billingDate'] = null;
    }
    if (this.dueDate != null) {
      json[r'dueDate'] = _dateFormatter.format(this.dueDate!);
    } else {
      json[r'dueDate'] = null;
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
    if (this.amountPaid != null) {
      json[r'amountPaid'] = this.amountPaid;
    } else {
      json[r'amountPaid'] = null;
    }
    if (this.outstanding != null) {
      json[r'outstanding'] = this.outstanding;
    } else {
      json[r'outstanding'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.overdue != null) {
      json[r'overdue'] = this.overdue;
    } else {
      json[r'overdue'] = null;
    }
    if (this.locksOn != null) {
      json[r'locksOn'] = _dateFormatter.format(this.locksOn!);
    } else {
      json[r'locksOn'] = null;
    }
    if (this.lockedByThis != null) {
      json[r'lockedByThis'] = this.lockedByThis;
    } else {
      json[r'lockedByThis'] = null;
    }
      json[r'payments'] = this.payments;
    return json;
  }

  /// Returns a new [PlatformInvoiceResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformInvoiceResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PlatformInvoiceResponse(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        label: mapValueOfType<String>(json, r'label'),
        billingDate: mapDateTime(json, r'billingDate', r''),
        dueDate: mapDateTime(json, r'dueDate', r''),
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
        amountPaid: json[r'amountPaid'] == null
            ? null
            : num.parse('${json[r'amountPaid']}'),
        outstanding: json[r'outstanding'] == null
            ? null
            : num.parse('${json[r'outstanding']}'),
        status: PlatformInvoiceResponseStatusEnum.fromJson(json[r'status']),
        overdue: mapValueOfType<bool>(json, r'overdue'),
        locksOn: mapDateTime(json, r'locksOn', r''),
        lockedByThis: mapValueOfType<bool>(json, r'lockedByThis'),
        payments: PlatformPaymentResponse.listFromJson(json[r'payments']),
      );
    }
    return null;
  }

  static List<PlatformInvoiceResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformInvoiceResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformInvoiceResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformInvoiceResponse> mapFromJson(dynamic json) {
    final map = <String, PlatformInvoiceResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformInvoiceResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformInvoiceResponse-objects as value to a dart map
  static Map<String, List<PlatformInvoiceResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformInvoiceResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformInvoiceResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PlatformInvoiceResponseStatusEnum {
  UNPAID._(r'UNPAID'),
  PARTIALLY_PAID._(r'PARTIALLY_PAID'),
  PAID._(r'PAID'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformInvoiceResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformInvoiceResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformInvoiceResponseStatusEnum? fromJson(dynamic value) => PlatformInvoiceResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformInvoiceResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformInvoiceResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformInvoiceResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformInvoiceResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformInvoiceResponseStatusEnum] to String,
/// and [decode] dynamic data back to [PlatformInvoiceResponseStatusEnum].
class PlatformInvoiceResponseStatusEnumTypeTransformer {
  factory PlatformInvoiceResponseStatusEnumTypeTransformer() => _instance ??= const PlatformInvoiceResponseStatusEnumTypeTransformer._();

  const PlatformInvoiceResponseStatusEnumTypeTransformer._();

  String encode(PlatformInvoiceResponseStatusEnum data) => data._value;

  /// Returns the instance of [PlatformInvoiceResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformInvoiceResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformInvoiceResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'UNPAID': return PlatformInvoiceResponseStatusEnum.UNPAID;
        case r'PARTIALLY_PAID': return PlatformInvoiceResponseStatusEnum.PARTIALLY_PAID;
        case r'PAID': return PlatformInvoiceResponseStatusEnum.PAID;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformInvoiceResponseStatusEnumTypeTransformer? _instance;
}


