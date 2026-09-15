//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaymentResponse {
  /// Returns a new [PaymentResponse] instance.
  PaymentResponse({
    this.id,
    this.billingPeriodId,
    this.periodLabel,
    this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.sentTo,
    this.status,
    this.remarks,
    this.proofUrl,
    this.proofUrlExpiresInSeconds,
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
  String? billingPeriodId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? periodLabel;

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
  DateTime? paymentDate;

  PaymentResponsePaymentMethodEnum? paymentMethod;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? sentTo;

  PaymentResponseStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? remarks;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? proofUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? proofUrlExpiresInSeconds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentResponse &&
    other.id == id &&
    other.billingPeriodId == billingPeriodId &&
    other.periodLabel == periodLabel &&
    other.amountPaid == amountPaid &&
    other.paymentDate == paymentDate &&
    other.paymentMethod == paymentMethod &&
    other.sentTo == sentTo &&
    other.status == status &&
    other.remarks == remarks &&
    other.proofUrl == proofUrl &&
    other.proofUrlExpiresInSeconds == proofUrlExpiresInSeconds;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (billingPeriodId == null ? 0 : billingPeriodId!.hashCode) +
    (periodLabel == null ? 0 : periodLabel!.hashCode) +
    (amountPaid == null ? 0 : amountPaid!.hashCode) +
    (paymentDate == null ? 0 : paymentDate!.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (sentTo == null ? 0 : sentTo!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofUrl == null ? 0 : proofUrl!.hashCode) +
    (proofUrlExpiresInSeconds == null ? 0 : proofUrlExpiresInSeconds!.hashCode);

  @override
  String toString() => 'PaymentResponse[id=$id, billingPeriodId=$billingPeriodId, periodLabel=$periodLabel, amountPaid=$amountPaid, paymentDate=$paymentDate, paymentMethod=$paymentMethod, sentTo=$sentTo, status=$status, remarks=$remarks, proofUrl=$proofUrl, proofUrlExpiresInSeconds=$proofUrlExpiresInSeconds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.billingPeriodId != null) {
      json[r'billingPeriodId'] = this.billingPeriodId;
    } else {
      json[r'billingPeriodId'] = null;
    }
    if (this.periodLabel != null) {
      json[r'periodLabel'] = this.periodLabel;
    } else {
      json[r'periodLabel'] = null;
    }
    if (this.amountPaid != null) {
      json[r'amountPaid'] = this.amountPaid;
    } else {
      json[r'amountPaid'] = null;
    }
    if (this.paymentDate != null) {
      json[r'paymentDate'] = _dateFormatter.format(this.paymentDate!);
    } else {
      json[r'paymentDate'] = null;
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
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
    if (this.proofUrl != null) {
      json[r'proofUrl'] = this.proofUrl;
    } else {
      json[r'proofUrl'] = null;
    }
    if (this.proofUrlExpiresInSeconds != null) {
      json[r'proofUrlExpiresInSeconds'] = this.proofUrlExpiresInSeconds;
    } else {
      json[r'proofUrlExpiresInSeconds'] = null;
    }
    return json;
  }

  /// Returns a new [PaymentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PaymentResponse(
        id: mapValueOfType<String>(json, r'id'),
        billingPeriodId: mapValueOfType<String>(json, r'billingPeriodId'),
        periodLabel: mapValueOfType<String>(json, r'periodLabel'),
        amountPaid: json[r'amountPaid'] == null
            ? null
            : num.parse('${json[r'amountPaid']}'),
        paymentDate: mapDateTime(json, r'paymentDate', r''),
        paymentMethod: PaymentResponsePaymentMethodEnum.fromJson(json[r'paymentMethod']),
        sentTo: mapValueOfType<String>(json, r'sentTo'),
        status: PaymentResponseStatusEnum.fromJson(json[r'status']),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofUrl: mapValueOfType<String>(json, r'proofUrl'),
        proofUrlExpiresInSeconds: mapValueOfType<int>(json, r'proofUrlExpiresInSeconds'),
      );
    }
    return null;
  }

  static List<PaymentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentResponse> mapFromJson(dynamic json) {
    final map = <String, PaymentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentResponse-objects as value to a dart map
  static Map<String, List<PaymentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PaymentResponsePaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const PaymentResponsePaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PaymentResponsePaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PaymentResponsePaymentMethodEnum? fromJson(dynamic value) => PaymentResponsePaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PaymentResponsePaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PaymentResponsePaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentResponsePaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentResponsePaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentResponsePaymentMethodEnum] to String,
/// and [decode] dynamic data back to [PaymentResponsePaymentMethodEnum].
class PaymentResponsePaymentMethodEnumTypeTransformer {
  factory PaymentResponsePaymentMethodEnumTypeTransformer() => _instance ??= const PaymentResponsePaymentMethodEnumTypeTransformer._();

  const PaymentResponsePaymentMethodEnumTypeTransformer._();

  String encode(PaymentResponsePaymentMethodEnum data) => data._value;

  /// Returns the instance of [PaymentResponsePaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentResponsePaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PaymentResponsePaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return PaymentResponsePaymentMethodEnum.CASH;
        case r'GCASH': return PaymentResponsePaymentMethodEnum.GCASH;
        case r'MAYA': return PaymentResponsePaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return PaymentResponsePaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return PaymentResponsePaymentMethodEnum.OTHER;
        case r'ADVANCE': return PaymentResponsePaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PaymentResponsePaymentMethodEnumTypeTransformer? _instance;
}



enum PaymentResponseStatusEnum {
  PENDING_VERIFICATION._(r'PENDING_VERIFICATION'),
  CONFIRMED._(r'CONFIRMED'),
  REJECTED._(r'REJECTED'),
  ;

  /// Instantiate a new enum with the provided value.
  const PaymentResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PaymentResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PaymentResponseStatusEnum? fromJson(dynamic value) => PaymentResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PaymentResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PaymentResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentResponseStatusEnum] to String,
/// and [decode] dynamic data back to [PaymentResponseStatusEnum].
class PaymentResponseStatusEnumTypeTransformer {
  factory PaymentResponseStatusEnumTypeTransformer() => _instance ??= const PaymentResponseStatusEnumTypeTransformer._();

  const PaymentResponseStatusEnumTypeTransformer._();

  String encode(PaymentResponseStatusEnum data) => data._value;

  /// Returns the instance of [PaymentResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PaymentResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PENDING_VERIFICATION': return PaymentResponseStatusEnum.PENDING_VERIFICATION;
        case r'CONFIRMED': return PaymentResponseStatusEnum.CONFIRMED;
        case r'REJECTED': return PaymentResponseStatusEnum.REJECTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PaymentResponseStatusEnumTypeTransformer? _instance;
}


