//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BillingPeriodResponse {
  /// Returns a new [BillingPeriodResponse] instance.
  BillingPeriodResponse({
    this.id,
    this.label,
    this.periodStart,
    this.periodEnd,
    this.dueDate,
    this.amountDue,
    this.amountPaid,
    this.outstanding,
    this.status,
    this.overdue,
    this.kind,
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
  DateTime? periodStart;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? periodEnd;

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

  BillingPeriodResponseStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? overdue;

  BillingPeriodResponseKindEnum? kind;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BillingPeriodResponse &&
    other.id == id &&
    other.label == label &&
    other.periodStart == periodStart &&
    other.periodEnd == periodEnd &&
    other.dueDate == dueDate &&
    other.amountDue == amountDue &&
    other.amountPaid == amountPaid &&
    other.outstanding == outstanding &&
    other.status == status &&
    other.overdue == overdue &&
    other.kind == kind;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (periodStart == null ? 0 : periodStart!.hashCode) +
    (periodEnd == null ? 0 : periodEnd!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (amountDue == null ? 0 : amountDue!.hashCode) +
    (amountPaid == null ? 0 : amountPaid!.hashCode) +
    (outstanding == null ? 0 : outstanding!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (overdue == null ? 0 : overdue!.hashCode) +
    (kind == null ? 0 : kind!.hashCode);

  @override
  String toString() => 'BillingPeriodResponse[id=$id, label=$label, periodStart=$periodStart, periodEnd=$periodEnd, dueDate=$dueDate, amountDue=$amountDue, amountPaid=$amountPaid, outstanding=$outstanding, status=$status, overdue=$overdue, kind=$kind]';

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
    if (this.periodStart != null) {
      json[r'periodStart'] = _dateFormatter.format(this.periodStart!);
    } else {
      json[r'periodStart'] = null;
    }
    if (this.periodEnd != null) {
      json[r'periodEnd'] = _dateFormatter.format(this.periodEnd!);
    } else {
      json[r'periodEnd'] = null;
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
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    return json;
  }

  /// Returns a new [BillingPeriodResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BillingPeriodResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return BillingPeriodResponse(
        id: mapValueOfType<String>(json, r'id'),
        label: mapValueOfType<String>(json, r'label'),
        periodStart: mapDateTime(json, r'periodStart', r''),
        periodEnd: mapDateTime(json, r'periodEnd', r''),
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
        status: BillingPeriodResponseStatusEnum.fromJson(json[r'status']),
        overdue: mapValueOfType<bool>(json, r'overdue'),
        kind: BillingPeriodResponseKindEnum.fromJson(json[r'kind']),
      );
    }
    return null;
  }

  static List<BillingPeriodResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BillingPeriodResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BillingPeriodResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BillingPeriodResponse> mapFromJson(dynamic json) {
    final map = <String, BillingPeriodResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BillingPeriodResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BillingPeriodResponse-objects as value to a dart map
  static Map<String, List<BillingPeriodResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BillingPeriodResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BillingPeriodResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum BillingPeriodResponseStatusEnum {
  UNPAID._(r'UNPAID'),
  PARTIALLY_PAID._(r'PARTIALLY_PAID'),
  PAID._(r'PAID'),
  ;

  /// Instantiate a new enum with the provided value.
  const BillingPeriodResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [BillingPeriodResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static BillingPeriodResponseStatusEnum? fromJson(dynamic value) => BillingPeriodResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [BillingPeriodResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<BillingPeriodResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BillingPeriodResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BillingPeriodResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BillingPeriodResponseStatusEnum] to String,
/// and [decode] dynamic data back to [BillingPeriodResponseStatusEnum].
class BillingPeriodResponseStatusEnumTypeTransformer {
  factory BillingPeriodResponseStatusEnumTypeTransformer() => _instance ??= const BillingPeriodResponseStatusEnumTypeTransformer._();

  const BillingPeriodResponseStatusEnumTypeTransformer._();

  String encode(BillingPeriodResponseStatusEnum data) => data._value;

  /// Returns the instance of [BillingPeriodResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BillingPeriodResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is BillingPeriodResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'UNPAID': return BillingPeriodResponseStatusEnum.UNPAID;
        case r'PARTIALLY_PAID': return BillingPeriodResponseStatusEnum.PARTIALLY_PAID;
        case r'PAID': return BillingPeriodResponseStatusEnum.PAID;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static BillingPeriodResponseStatusEnumTypeTransformer? _instance;
}



enum BillingPeriodResponseKindEnum {
  RENT._(r'RENT'),
  DEPOSIT._(r'DEPOSIT'),
  ;

  /// Instantiate a new enum with the provided value.
  const BillingPeriodResponseKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [BillingPeriodResponseKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static BillingPeriodResponseKindEnum? fromJson(dynamic value) => BillingPeriodResponseKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [BillingPeriodResponseKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<BillingPeriodResponseKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BillingPeriodResponseKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BillingPeriodResponseKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BillingPeriodResponseKindEnum] to String,
/// and [decode] dynamic data back to [BillingPeriodResponseKindEnum].
class BillingPeriodResponseKindEnumTypeTransformer {
  factory BillingPeriodResponseKindEnumTypeTransformer() => _instance ??= const BillingPeriodResponseKindEnumTypeTransformer._();

  const BillingPeriodResponseKindEnumTypeTransformer._();

  String encode(BillingPeriodResponseKindEnum data) => data._value;

  /// Returns the instance of [BillingPeriodResponseKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BillingPeriodResponseKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is BillingPeriodResponseKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RENT': return BillingPeriodResponseKindEnum.RENT;
        case r'DEPOSIT': return BillingPeriodResponseKindEnum.DEPOSIT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static BillingPeriodResponseKindEnumTypeTransformer? _instance;
}


