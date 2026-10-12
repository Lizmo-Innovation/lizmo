//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReceiptResponse {
  /// Returns a new [ReceiptResponse] instance.
  ReceiptResponse({
    this.id,
    this.paymentId,
    this.leaseId,
    this.number,
    this.issuedAt,
    this.receivedFrom,
    this.receivedBy,
    this.propertyName,
    this.place,
    this.periodLabel,
    this.kind,
    this.amount,
    this.paymentMethod,
    this.sentTo,
    this.paidOn,
    this.stillOwed,
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
  String? paymentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? leaseId;

  /// Numbered per landlord, per year, in the order issued
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? number;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? issuedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? receivedFrom;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? receivedBy;

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
  String? place;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? periodLabel;

  ReceiptResponseKindEnum? kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? amount;

  ReceiptResponsePaymentMethodEnum? paymentMethod;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? sentTo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paidOn;

  /// What was left of that month, or the deposit, once this was counted. Zero when it settled it.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? stillOwed;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReceiptResponse &&
    other.id == id &&
    other.paymentId == paymentId &&
    other.leaseId == leaseId &&
    other.number == number &&
    other.issuedAt == issuedAt &&
    other.receivedFrom == receivedFrom &&
    other.receivedBy == receivedBy &&
    other.propertyName == propertyName &&
    other.place == place &&
    other.periodLabel == periodLabel &&
    other.kind == kind &&
    other.amount == amount &&
    other.paymentMethod == paymentMethod &&
    other.sentTo == sentTo &&
    other.paidOn == paidOn &&
    other.stillOwed == stillOwed;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (paymentId == null ? 0 : paymentId!.hashCode) +
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (number == null ? 0 : number!.hashCode) +
    (issuedAt == null ? 0 : issuedAt!.hashCode) +
    (receivedFrom == null ? 0 : receivedFrom!.hashCode) +
    (receivedBy == null ? 0 : receivedBy!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (place == null ? 0 : place!.hashCode) +
    (periodLabel == null ? 0 : periodLabel!.hashCode) +
    (kind == null ? 0 : kind!.hashCode) +
    (amount == null ? 0 : amount!.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (sentTo == null ? 0 : sentTo!.hashCode) +
    (paidOn == null ? 0 : paidOn!.hashCode) +
    (stillOwed == null ? 0 : stillOwed!.hashCode);

  @override
  String toString() => 'ReceiptResponse[id=$id, paymentId=$paymentId, leaseId=$leaseId, number=$number, issuedAt=$issuedAt, receivedFrom=$receivedFrom, receivedBy=$receivedBy, propertyName=$propertyName, place=$place, periodLabel=$periodLabel, kind=$kind, amount=$amount, paymentMethod=$paymentMethod, sentTo=$sentTo, paidOn=$paidOn, stillOwed=$stillOwed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.paymentId != null) {
      json[r'paymentId'] = this.paymentId;
    } else {
      json[r'paymentId'] = null;
    }
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.number != null) {
      json[r'number'] = this.number;
    } else {
      json[r'number'] = null;
    }
    if (this.issuedAt != null) {
      json[r'issuedAt'] = this.issuedAt!.toUtc().toIso8601String();
    } else {
      json[r'issuedAt'] = null;
    }
    if (this.receivedFrom != null) {
      json[r'receivedFrom'] = this.receivedFrom;
    } else {
      json[r'receivedFrom'] = null;
    }
    if (this.receivedBy != null) {
      json[r'receivedBy'] = this.receivedBy;
    } else {
      json[r'receivedBy'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
    }
    if (this.periodLabel != null) {
      json[r'periodLabel'] = this.periodLabel;
    } else {
      json[r'periodLabel'] = null;
    }
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    if (this.paymentMethod != null) {
      json[r'paymentMethod'] = this.paymentMethod;
    } else {
      json[r'paymentMethod'] = null;
    }
    if (this.sentTo != null) {
      json[r'sentTo'] = this.sentTo;
    } else {
      json[r'sentTo'] = null;
    }
    if (this.paidOn != null) {
      json[r'paidOn'] = _dateFormatter.format(this.paidOn!);
    } else {
      json[r'paidOn'] = null;
    }
    if (this.stillOwed != null) {
      json[r'stillOwed'] = this.stillOwed;
    } else {
      json[r'stillOwed'] = null;
    }
    return json;
  }

  /// Returns a new [ReceiptResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReceiptResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ReceiptResponse(
        id: mapValueOfType<String>(json, r'id'),
        paymentId: mapValueOfType<String>(json, r'paymentId'),
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        number: mapValueOfType<String>(json, r'number'),
        issuedAt: mapDateTime(json, r'issuedAt', r''),
        receivedFrom: mapValueOfType<String>(json, r'receivedFrom'),
        receivedBy: mapValueOfType<String>(json, r'receivedBy'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        place: mapValueOfType<String>(json, r'place'),
        periodLabel: mapValueOfType<String>(json, r'periodLabel'),
        kind: ReceiptResponseKindEnum.fromJson(json[r'kind']),
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
        paymentMethod: ReceiptResponsePaymentMethodEnum.fromJson(json[r'paymentMethod']),
        sentTo: mapValueOfType<String>(json, r'sentTo'),
        paidOn: mapDateTime(json, r'paidOn', r''),
        stillOwed: json[r'stillOwed'] == null
            ? null
            : num.parse('${json[r'stillOwed']}'),
      );
    }
    return null;
  }

  static List<ReceiptResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReceiptResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReceiptResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReceiptResponse> mapFromJson(dynamic json) {
    final map = <String, ReceiptResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReceiptResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReceiptResponse-objects as value to a dart map
  static Map<String, List<ReceiptResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReceiptResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReceiptResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum ReceiptResponseKindEnum {
  RENT._(r'RENT'),
  DEPOSIT._(r'DEPOSIT'),
  ;

  /// Instantiate a new enum with the provided value.
  const ReceiptResponseKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ReceiptResponseKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ReceiptResponseKindEnum? fromJson(dynamic value) => ReceiptResponseKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ReceiptResponseKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ReceiptResponseKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReceiptResponseKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReceiptResponseKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ReceiptResponseKindEnum] to String,
/// and [decode] dynamic data back to [ReceiptResponseKindEnum].
class ReceiptResponseKindEnumTypeTransformer {
  factory ReceiptResponseKindEnumTypeTransformer() => _instance ??= const ReceiptResponseKindEnumTypeTransformer._();

  const ReceiptResponseKindEnumTypeTransformer._();

  String encode(ReceiptResponseKindEnum data) => data._value;

  /// Returns the instance of [ReceiptResponseKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ReceiptResponseKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ReceiptResponseKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RENT': return ReceiptResponseKindEnum.RENT;
        case r'DEPOSIT': return ReceiptResponseKindEnum.DEPOSIT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ReceiptResponseKindEnumTypeTransformer? _instance;
}



enum ReceiptResponsePaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const ReceiptResponsePaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ReceiptResponsePaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ReceiptResponsePaymentMethodEnum? fromJson(dynamic value) => ReceiptResponsePaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ReceiptResponsePaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ReceiptResponsePaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReceiptResponsePaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReceiptResponsePaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ReceiptResponsePaymentMethodEnum] to String,
/// and [decode] dynamic data back to [ReceiptResponsePaymentMethodEnum].
class ReceiptResponsePaymentMethodEnumTypeTransformer {
  factory ReceiptResponsePaymentMethodEnumTypeTransformer() => _instance ??= const ReceiptResponsePaymentMethodEnumTypeTransformer._();

  const ReceiptResponsePaymentMethodEnumTypeTransformer._();

  String encode(ReceiptResponsePaymentMethodEnum data) => data._value;

  /// Returns the instance of [ReceiptResponsePaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ReceiptResponsePaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ReceiptResponsePaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return ReceiptResponsePaymentMethodEnum.CASH;
        case r'GCASH': return ReceiptResponsePaymentMethodEnum.GCASH;
        case r'MAYA': return ReceiptResponsePaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return ReceiptResponsePaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return ReceiptResponsePaymentMethodEnum.OTHER;
        case r'ADVANCE': return ReceiptResponsePaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ReceiptResponsePaymentMethodEnumTypeTransformer? _instance;
}


