//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RecordPaymentRequest {
  /// Returns a new [RecordPaymentRequest] instance.
  RecordPaymentRequest({
    required this.billingPeriodId,
    required this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.remarks,
    this.channelId,
  });

  /// Which month this pays for
  String billingPeriodId;

  num amountPaid;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paymentDate;

  /// Defaults to OTHER
  RecordPaymentRequestPaymentMethodEnum? paymentMethod;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? remarks;

  /// Which of the landlord's payment channels it was sent to, if any. Kept as the channel read at that moment.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? channelId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RecordPaymentRequest &&
    other.billingPeriodId == billingPeriodId &&
    other.amountPaid == amountPaid &&
    other.paymentDate == paymentDate &&
    other.paymentMethod == paymentMethod &&
    other.remarks == remarks &&
    other.channelId == channelId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billingPeriodId.hashCode) +
    (amountPaid.hashCode) +
    (paymentDate == null ? 0 : paymentDate!.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (channelId == null ? 0 : channelId!.hashCode);

  @override
  String toString() => 'RecordPaymentRequest[billingPeriodId=$billingPeriodId, amountPaid=$amountPaid, paymentDate=$paymentDate, paymentMethod=$paymentMethod, remarks=$remarks, channelId=$channelId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'billingPeriodId'] = this.billingPeriodId;
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
    if (this.channelId != null) {
      json[r'channelId'] = this.channelId;
    } else {
      json[r'channelId'] = null;
    }
    return json;
  }

  /// Returns a new [RecordPaymentRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecordPaymentRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'billingPeriodId'), 'Required key "RecordPaymentRequest[billingPeriodId]" is missing from JSON.');
        assert(json[r'billingPeriodId'] != null, 'Required key "RecordPaymentRequest[billingPeriodId]" has a null value in JSON.');
        assert(json.containsKey(r'amountPaid'), 'Required key "RecordPaymentRequest[amountPaid]" is missing from JSON.');
        assert(json[r'amountPaid'] != null, 'Required key "RecordPaymentRequest[amountPaid]" has a null value in JSON.');
        return true;
      }());

      return RecordPaymentRequest(
        billingPeriodId: mapValueOfType<String>(json, r'billingPeriodId')!,
        amountPaid: num.parse('${json[r'amountPaid']}'),
        paymentDate: mapDateTime(json, r'paymentDate', r''),
        paymentMethod: RecordPaymentRequestPaymentMethodEnum.fromJson(json[r'paymentMethod']),
        remarks: mapValueOfType<String>(json, r'remarks'),
        channelId: mapValueOfType<String>(json, r'channelId'),
      );
    }
    return null;
  }

  static List<RecordPaymentRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecordPaymentRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecordPaymentRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecordPaymentRequest> mapFromJson(dynamic json) {
    final map = <String, RecordPaymentRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecordPaymentRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecordPaymentRequest-objects as value to a dart map
  static Map<String, List<RecordPaymentRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RecordPaymentRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecordPaymentRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'billingPeriodId',
    'amountPaid',
  };
}

/// Defaults to OTHER
enum RecordPaymentRequestPaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const RecordPaymentRequestPaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RecordPaymentRequestPaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RecordPaymentRequestPaymentMethodEnum? fromJson(dynamic value) => RecordPaymentRequestPaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RecordPaymentRequestPaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RecordPaymentRequestPaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RecordPaymentRequestPaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecordPaymentRequestPaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RecordPaymentRequestPaymentMethodEnum] to String,
/// and [decode] dynamic data back to [RecordPaymentRequestPaymentMethodEnum].
class RecordPaymentRequestPaymentMethodEnumTypeTransformer {
  factory RecordPaymentRequestPaymentMethodEnumTypeTransformer() => _instance ??= const RecordPaymentRequestPaymentMethodEnumTypeTransformer._();

  const RecordPaymentRequestPaymentMethodEnumTypeTransformer._();

  String encode(RecordPaymentRequestPaymentMethodEnum data) => data._value;

  /// Returns the instance of [RecordPaymentRequestPaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RecordPaymentRequestPaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RecordPaymentRequestPaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return RecordPaymentRequestPaymentMethodEnum.CASH;
        case r'GCASH': return RecordPaymentRequestPaymentMethodEnum.GCASH;
        case r'MAYA': return RecordPaymentRequestPaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return RecordPaymentRequestPaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return RecordPaymentRequestPaymentMethodEnum.OTHER;
        case r'ADVANCE': return RecordPaymentRequestPaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RecordPaymentRequestPaymentMethodEnumTypeTransformer? _instance;
}


