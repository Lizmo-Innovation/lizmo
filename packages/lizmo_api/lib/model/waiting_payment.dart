//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WaitingPayment {
  /// Returns a new [WaitingPayment] instance.
  WaitingPayment({
    this.paymentId,
    this.amount,
    this.paidOn,
    this.method,
    this.note,
  });

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
  num? amount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paidOn;

  WaitingPaymentMethodEnum? method;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WaitingPayment &&
    other.paymentId == paymentId &&
    other.amount == amount &&
    other.paidOn == paidOn &&
    other.method == method &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (paymentId == null ? 0 : paymentId!.hashCode) +
    (amount == null ? 0 : amount!.hashCode) +
    (paidOn == null ? 0 : paidOn!.hashCode) +
    (method == null ? 0 : method!.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'WaitingPayment[paymentId=$paymentId, amount=$amount, paidOn=$paidOn, method=$method, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.paymentId != null) {
      json[r'paymentId'] = this.paymentId;
    } else {
      json[r'paymentId'] = null;
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
    if (this.method != null) {
      json[r'method'] = this.method;
    } else {
      json[r'method'] = null;
    }
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [WaitingPayment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WaitingPayment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return WaitingPayment(
        paymentId: mapValueOfType<String>(json, r'paymentId'),
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
        paidOn: mapDateTime(json, r'paidOn', r''),
        method: WaitingPaymentMethodEnum.fromJson(json[r'method']),
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<WaitingPayment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WaitingPayment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaitingPayment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WaitingPayment> mapFromJson(dynamic json) {
    final map = <String, WaitingPayment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WaitingPayment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WaitingPayment-objects as value to a dart map
  static Map<String, List<WaitingPayment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WaitingPayment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WaitingPayment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum WaitingPaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const WaitingPaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [WaitingPaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static WaitingPaymentMethodEnum? fromJson(dynamic value) => WaitingPaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [WaitingPaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<WaitingPaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WaitingPaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaitingPaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WaitingPaymentMethodEnum] to String,
/// and [decode] dynamic data back to [WaitingPaymentMethodEnum].
class WaitingPaymentMethodEnumTypeTransformer {
  factory WaitingPaymentMethodEnumTypeTransformer() => _instance ??= const WaitingPaymentMethodEnumTypeTransformer._();

  const WaitingPaymentMethodEnumTypeTransformer._();

  String encode(WaitingPaymentMethodEnum data) => data._value;

  /// Returns the instance of [WaitingPaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WaitingPaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is WaitingPaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return WaitingPaymentMethodEnum.CASH;
        case r'GCASH': return WaitingPaymentMethodEnum.GCASH;
        case r'MAYA': return WaitingPaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return WaitingPaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return WaitingPaymentMethodEnum.OTHER;
        case r'ADVANCE': return WaitingPaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static WaitingPaymentMethodEnumTypeTransformer? _instance;
}


