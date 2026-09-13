//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformStatementResponse {
  /// Returns a new [PlatformStatementResponse] instance.
  PlatformStatementResponse({
    this.id,
    this.label,
    this.billingDate,
    this.dueDate,
    this.amountDue,
    this.amountPaid,
    this.outstanding,
    this.status,
    this.overdue,
    this.locksOn,
    this.locked,
    this.lines = const [],
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

  PlatformStatementResponseStatusEnum? status;

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
  bool? locked;

  List<PlatformInvoiceLine> lines;

  List<PlatformPaymentResponse> payments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlatformStatementResponse &&
    other.id == id &&
    other.label == label &&
    other.billingDate == billingDate &&
    other.dueDate == dueDate &&
    other.amountDue == amountDue &&
    other.amountPaid == amountPaid &&
    other.outstanding == outstanding &&
    other.status == status &&
    other.overdue == overdue &&
    other.locksOn == locksOn &&
    other.locked == locked &&
    _deepEquality.equals(other.lines, lines) &&
    _deepEquality.equals(other.payments, payments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (billingDate == null ? 0 : billingDate!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (amountDue == null ? 0 : amountDue!.hashCode) +
    (amountPaid == null ? 0 : amountPaid!.hashCode) +
    (outstanding == null ? 0 : outstanding!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (overdue == null ? 0 : overdue!.hashCode) +
    (locksOn == null ? 0 : locksOn!.hashCode) +
    (locked == null ? 0 : locked!.hashCode) +
    (lines.hashCode) +
    (payments.hashCode);

  @override
  String toString() => 'PlatformStatementResponse[id=$id, label=$label, billingDate=$billingDate, dueDate=$dueDate, amountDue=$amountDue, amountPaid=$amountPaid, outstanding=$outstanding, status=$status, overdue=$overdue, locksOn=$locksOn, locked=$locked, lines=$lines, payments=$payments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
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
    if (this.locked != null) {
      json[r'locked'] = this.locked;
    } else {
      json[r'locked'] = null;
    }
      json[r'lines'] = this.lines;
      json[r'payments'] = this.payments;
    return json;
  }

  /// Returns a new [PlatformStatementResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformStatementResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PlatformStatementResponse(
        id: mapValueOfType<String>(json, r'id'),
        label: mapValueOfType<String>(json, r'label'),
        billingDate: mapDateTime(json, r'billingDate', r''),
        dueDate: mapDateTime(json, r'dueDate', r''),
        amountDue: json[r'amountDue'] == null
            ? null
            : num.parse('${json[r'amountDue']}'),
        amountPaid: json[r'amountPaid'] == null
            ? null
            : num.parse('${json[r'amountPaid']}'),
        outstanding: json[r'outstanding'] == null
            ? null
            : num.parse('${json[r'outstanding']}'),
        status: PlatformStatementResponseStatusEnum.fromJson(json[r'status']),
        overdue: mapValueOfType<bool>(json, r'overdue'),
        locksOn: mapDateTime(json, r'locksOn', r''),
        locked: mapValueOfType<bool>(json, r'locked'),
        lines: PlatformInvoiceLine.listFromJson(json[r'lines']),
        payments: PlatformPaymentResponse.listFromJson(json[r'payments']),
      );
    }
    return null;
  }

  static List<PlatformStatementResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformStatementResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformStatementResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformStatementResponse> mapFromJson(dynamic json) {
    final map = <String, PlatformStatementResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformStatementResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformStatementResponse-objects as value to a dart map
  static Map<String, List<PlatformStatementResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformStatementResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformStatementResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PlatformStatementResponseStatusEnum {
  UNPAID._(r'UNPAID'),
  PARTIALLY_PAID._(r'PARTIALLY_PAID'),
  PAID._(r'PAID'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformStatementResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformStatementResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformStatementResponseStatusEnum? fromJson(dynamic value) => PlatformStatementResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformStatementResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformStatementResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformStatementResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformStatementResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformStatementResponseStatusEnum] to String,
/// and [decode] dynamic data back to [PlatformStatementResponseStatusEnum].
class PlatformStatementResponseStatusEnumTypeTransformer {
  factory PlatformStatementResponseStatusEnumTypeTransformer() => _instance ??= const PlatformStatementResponseStatusEnumTypeTransformer._();

  const PlatformStatementResponseStatusEnumTypeTransformer._();

  String encode(PlatformStatementResponseStatusEnum data) => data._value;

  /// Returns the instance of [PlatformStatementResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformStatementResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformStatementResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'UNPAID': return PlatformStatementResponseStatusEnum.UNPAID;
        case r'PARTIALLY_PAID': return PlatformStatementResponseStatusEnum.PARTIALLY_PAID;
        case r'PAID': return PlatformStatementResponseStatusEnum.PAID;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformStatementResponseStatusEnumTypeTransformer? _instance;
}


