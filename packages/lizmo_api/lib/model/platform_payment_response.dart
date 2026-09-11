//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformPaymentResponse {
  /// Returns a new [PlatformPaymentResponse] instance.
  PlatformPaymentResponse({
    this.id,
    this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.status,
    this.remarks,
    this.proofUrl,
    this.proofUrlExpiresInSeconds,
    this.submittedAt,
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
  num? amountPaid;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paymentDate;

  PlatformPaymentResponsePaymentMethodEnum? paymentMethod;

  PlatformPaymentResponseStatusEnum? status;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? submittedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlatformPaymentResponse &&
    other.id == id &&
    other.amountPaid == amountPaid &&
    other.paymentDate == paymentDate &&
    other.paymentMethod == paymentMethod &&
    other.status == status &&
    other.remarks == remarks &&
    other.proofUrl == proofUrl &&
    other.proofUrlExpiresInSeconds == proofUrlExpiresInSeconds &&
    other.submittedAt == submittedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (amountPaid == null ? 0 : amountPaid!.hashCode) +
    (paymentDate == null ? 0 : paymentDate!.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofUrl == null ? 0 : proofUrl!.hashCode) +
    (proofUrlExpiresInSeconds == null ? 0 : proofUrlExpiresInSeconds!.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode);

  @override
  String toString() => 'PlatformPaymentResponse[id=$id, amountPaid=$amountPaid, paymentDate=$paymentDate, paymentMethod=$paymentMethod, status=$status, remarks=$remarks, proofUrl=$proofUrl, proofUrlExpiresInSeconds=$proofUrlExpiresInSeconds, submittedAt=$submittedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
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
    if (this.submittedAt != null) {
      json[r'submittedAt'] = this.submittedAt!.toUtc().toIso8601String();
    } else {
      json[r'submittedAt'] = null;
    }
    return json;
  }

  /// Returns a new [PlatformPaymentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformPaymentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PlatformPaymentResponse(
        id: mapValueOfType<String>(json, r'id'),
        amountPaid: json[r'amountPaid'] == null
            ? null
            : num.parse('${json[r'amountPaid']}'),
        paymentDate: mapDateTime(json, r'paymentDate', r''),
        paymentMethod: PlatformPaymentResponsePaymentMethodEnum.fromJson(json[r'paymentMethod']),
        status: PlatformPaymentResponseStatusEnum.fromJson(json[r'status']),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofUrl: mapValueOfType<String>(json, r'proofUrl'),
        proofUrlExpiresInSeconds: mapValueOfType<int>(json, r'proofUrlExpiresInSeconds'),
        submittedAt: mapDateTime(json, r'submittedAt', r''),
      );
    }
    return null;
  }

  static List<PlatformPaymentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformPaymentResponse> mapFromJson(dynamic json) {
    final map = <String, PlatformPaymentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformPaymentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformPaymentResponse-objects as value to a dart map
  static Map<String, List<PlatformPaymentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformPaymentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformPaymentResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PlatformPaymentResponsePaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformPaymentResponsePaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformPaymentResponsePaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformPaymentResponsePaymentMethodEnum? fromJson(dynamic value) => PlatformPaymentResponsePaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformPaymentResponsePaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformPaymentResponsePaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentResponsePaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentResponsePaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformPaymentResponsePaymentMethodEnum] to String,
/// and [decode] dynamic data back to [PlatformPaymentResponsePaymentMethodEnum].
class PlatformPaymentResponsePaymentMethodEnumTypeTransformer {
  factory PlatformPaymentResponsePaymentMethodEnumTypeTransformer() => _instance ??= const PlatformPaymentResponsePaymentMethodEnumTypeTransformer._();

  const PlatformPaymentResponsePaymentMethodEnumTypeTransformer._();

  String encode(PlatformPaymentResponsePaymentMethodEnum data) => data._value;

  /// Returns the instance of [PlatformPaymentResponsePaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformPaymentResponsePaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformPaymentResponsePaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return PlatformPaymentResponsePaymentMethodEnum.CASH;
        case r'GCASH': return PlatformPaymentResponsePaymentMethodEnum.GCASH;
        case r'MAYA': return PlatformPaymentResponsePaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return PlatformPaymentResponsePaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return PlatformPaymentResponsePaymentMethodEnum.OTHER;
        case r'ADVANCE': return PlatformPaymentResponsePaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformPaymentResponsePaymentMethodEnumTypeTransformer? _instance;
}



enum PlatformPaymentResponseStatusEnum {
  PENDING_VERIFICATION._(r'PENDING_VERIFICATION'),
  CONFIRMED._(r'CONFIRMED'),
  REJECTED._(r'REJECTED'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformPaymentResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformPaymentResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformPaymentResponseStatusEnum? fromJson(dynamic value) => PlatformPaymentResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformPaymentResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformPaymentResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformPaymentResponseStatusEnum] to String,
/// and [decode] dynamic data back to [PlatformPaymentResponseStatusEnum].
class PlatformPaymentResponseStatusEnumTypeTransformer {
  factory PlatformPaymentResponseStatusEnumTypeTransformer() => _instance ??= const PlatformPaymentResponseStatusEnumTypeTransformer._();

  const PlatformPaymentResponseStatusEnumTypeTransformer._();

  String encode(PlatformPaymentResponseStatusEnum data) => data._value;

  /// Returns the instance of [PlatformPaymentResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformPaymentResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformPaymentResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PENDING_VERIFICATION': return PlatformPaymentResponseStatusEnum.PENDING_VERIFICATION;
        case r'CONFIRMED': return PlatformPaymentResponseStatusEnum.CONFIRMED;
        case r'REJECTED': return PlatformPaymentResponseStatusEnum.REJECTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformPaymentResponseStatusEnumTypeTransformer? _instance;
}


