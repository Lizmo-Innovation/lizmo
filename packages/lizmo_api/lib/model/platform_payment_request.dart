//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformPaymentRequest {
  /// Returns a new [PlatformPaymentRequest] instance.
  PlatformPaymentRequest({
    required this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.remarks,
  });

  num amountPaid;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paymentDate;

  PlatformPaymentRequestPaymentMethodEnum? paymentMethod;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? remarks;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlatformPaymentRequest &&
    other.amountPaid == amountPaid &&
    other.paymentDate == paymentDate &&
    other.paymentMethod == paymentMethod &&
    other.remarks == remarks;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amountPaid.hashCode) +
    (paymentDate == null ? 0 : paymentDate!.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode);

  @override
  String toString() => 'PlatformPaymentRequest[amountPaid=$amountPaid, paymentDate=$paymentDate, paymentMethod=$paymentMethod, remarks=$remarks]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'amountPaid'] = this.amountPaid;
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
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
    return json;
  }

  /// Returns a new [PlatformPaymentRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformPaymentRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'amountPaid'), 'Required key "PlatformPaymentRequest[amountPaid]" is missing from JSON.');
        assert(json[r'amountPaid'] != null, 'Required key "PlatformPaymentRequest[amountPaid]" has a null value in JSON.');
        return true;
      }());

      return PlatformPaymentRequest(
        amountPaid: num.parse('${json[r'amountPaid']}'),
        paymentDate: mapDateTime(json, r'paymentDate', r''),
        paymentMethod: PlatformPaymentRequestPaymentMethodEnum.fromJson(json[r'paymentMethod']),
        remarks: mapValueOfType<String>(json, r'remarks'),
      );
    }
    return null;
  }

  static List<PlatformPaymentRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformPaymentRequest> mapFromJson(dynamic json) {
    final map = <String, PlatformPaymentRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformPaymentRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformPaymentRequest-objects as value to a dart map
  static Map<String, List<PlatformPaymentRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformPaymentRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformPaymentRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amountPaid',
  };
}


enum PlatformPaymentRequestPaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformPaymentRequestPaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformPaymentRequestPaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformPaymentRequestPaymentMethodEnum? fromJson(dynamic value) => PlatformPaymentRequestPaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformPaymentRequestPaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformPaymentRequestPaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentRequestPaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentRequestPaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformPaymentRequestPaymentMethodEnum] to String,
/// and [decode] dynamic data back to [PlatformPaymentRequestPaymentMethodEnum].
class PlatformPaymentRequestPaymentMethodEnumTypeTransformer {
  factory PlatformPaymentRequestPaymentMethodEnumTypeTransformer() => _instance ??= const PlatformPaymentRequestPaymentMethodEnumTypeTransformer._();

  const PlatformPaymentRequestPaymentMethodEnumTypeTransformer._();

  String encode(PlatformPaymentRequestPaymentMethodEnum data) => data._value;

  /// Returns the instance of [PlatformPaymentRequestPaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformPaymentRequestPaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformPaymentRequestPaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return PlatformPaymentRequestPaymentMethodEnum.CASH;
        case r'GCASH': return PlatformPaymentRequestPaymentMethodEnum.GCASH;
        case r'MAYA': return PlatformPaymentRequestPaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return PlatformPaymentRequestPaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return PlatformPaymentRequestPaymentMethodEnum.OTHER;
        case r'ADVANCE': return PlatformPaymentRequestPaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformPaymentRequestPaymentMethodEnumTypeTransformer? _instance;
}


