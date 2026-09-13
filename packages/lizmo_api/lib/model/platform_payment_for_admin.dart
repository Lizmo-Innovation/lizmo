//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlatformPaymentForAdmin {
  /// Returns a new [PlatformPaymentForAdmin] instance.
  PlatformPaymentForAdmin({
    this.id,
    this.statementId,
    this.landlordId,
    this.landlordName,
    this.statementLabel,
    this.properties,
    this.statementAmountDue,
    this.statementOutstanding,
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
  String? statementId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? landlordId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? landlordName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? statementLabel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? properties;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? statementAmountDue;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? statementOutstanding;

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

  PlatformPaymentForAdminPaymentMethodEnum? paymentMethod;

  PlatformPaymentForAdminStatusEnum? status;

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
  bool operator ==(Object other) => identical(this, other) || other is PlatformPaymentForAdmin &&
    other.id == id &&
    other.statementId == statementId &&
    other.landlordId == landlordId &&
    other.landlordName == landlordName &&
    other.statementLabel == statementLabel &&
    other.properties == properties &&
    other.statementAmountDue == statementAmountDue &&
    other.statementOutstanding == statementOutstanding &&
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
    (statementId == null ? 0 : statementId!.hashCode) +
    (landlordId == null ? 0 : landlordId!.hashCode) +
    (landlordName == null ? 0 : landlordName!.hashCode) +
    (statementLabel == null ? 0 : statementLabel!.hashCode) +
    (properties == null ? 0 : properties!.hashCode) +
    (statementAmountDue == null ? 0 : statementAmountDue!.hashCode) +
    (statementOutstanding == null ? 0 : statementOutstanding!.hashCode) +
    (amountPaid == null ? 0 : amountPaid!.hashCode) +
    (paymentDate == null ? 0 : paymentDate!.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofUrl == null ? 0 : proofUrl!.hashCode) +
    (proofUrlExpiresInSeconds == null ? 0 : proofUrlExpiresInSeconds!.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode);

  @override
  String toString() => 'PlatformPaymentForAdmin[id=$id, statementId=$statementId, landlordId=$landlordId, landlordName=$landlordName, statementLabel=$statementLabel, properties=$properties, statementAmountDue=$statementAmountDue, statementOutstanding=$statementOutstanding, amountPaid=$amountPaid, paymentDate=$paymentDate, paymentMethod=$paymentMethod, status=$status, remarks=$remarks, proofUrl=$proofUrl, proofUrlExpiresInSeconds=$proofUrlExpiresInSeconds, submittedAt=$submittedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.statementId != null) {
      json[r'statementId'] = this.statementId;
    } else {
      json[r'statementId'] = null;
    }
    if (this.landlordId != null) {
      json[r'landlordId'] = this.landlordId;
    } else {
      json[r'landlordId'] = null;
    }
    if (this.landlordName != null) {
      json[r'landlordName'] = this.landlordName;
    } else {
      json[r'landlordName'] = null;
    }
    if (this.statementLabel != null) {
      json[r'statementLabel'] = this.statementLabel;
    } else {
      json[r'statementLabel'] = null;
    }
    if (this.properties != null) {
      json[r'properties'] = this.properties;
    } else {
      json[r'properties'] = null;
    }
    if (this.statementAmountDue != null) {
      json[r'statementAmountDue'] = this.statementAmountDue;
    } else {
      json[r'statementAmountDue'] = null;
    }
    if (this.statementOutstanding != null) {
      json[r'statementOutstanding'] = this.statementOutstanding;
    } else {
      json[r'statementOutstanding'] = null;
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

  /// Returns a new [PlatformPaymentForAdmin] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlatformPaymentForAdmin? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PlatformPaymentForAdmin(
        id: mapValueOfType<String>(json, r'id'),
        statementId: mapValueOfType<String>(json, r'statementId'),
        landlordId: mapValueOfType<String>(json, r'landlordId'),
        landlordName: mapValueOfType<String>(json, r'landlordName'),
        statementLabel: mapValueOfType<String>(json, r'statementLabel'),
        properties: mapValueOfType<int>(json, r'properties'),
        statementAmountDue: json[r'statementAmountDue'] == null
            ? null
            : num.parse('${json[r'statementAmountDue']}'),
        statementOutstanding: json[r'statementOutstanding'] == null
            ? null
            : num.parse('${json[r'statementOutstanding']}'),
        amountPaid: json[r'amountPaid'] == null
            ? null
            : num.parse('${json[r'amountPaid']}'),
        paymentDate: mapDateTime(json, r'paymentDate', r''),
        paymentMethod: PlatformPaymentForAdminPaymentMethodEnum.fromJson(json[r'paymentMethod']),
        status: PlatformPaymentForAdminStatusEnum.fromJson(json[r'status']),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofUrl: mapValueOfType<String>(json, r'proofUrl'),
        proofUrlExpiresInSeconds: mapValueOfType<int>(json, r'proofUrlExpiresInSeconds'),
        submittedAt: mapDateTime(json, r'submittedAt', r''),
      );
    }
    return null;
  }

  static List<PlatformPaymentForAdmin> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentForAdmin>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentForAdmin.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlatformPaymentForAdmin> mapFromJson(dynamic json) {
    final map = <String, PlatformPaymentForAdmin>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlatformPaymentForAdmin.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlatformPaymentForAdmin-objects as value to a dart map
  static Map<String, List<PlatformPaymentForAdmin>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlatformPaymentForAdmin>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlatformPaymentForAdmin.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PlatformPaymentForAdminPaymentMethodEnum {
  CASH._(r'CASH'),
  GCASH._(r'GCASH'),
  MAYA._(r'MAYA'),
  BANK_TRANSFER._(r'BANK_TRANSFER'),
  OTHER._(r'OTHER'),
  ADVANCE._(r'ADVANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformPaymentForAdminPaymentMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformPaymentForAdminPaymentMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformPaymentForAdminPaymentMethodEnum? fromJson(dynamic value) => PlatformPaymentForAdminPaymentMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformPaymentForAdminPaymentMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformPaymentForAdminPaymentMethodEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentForAdminPaymentMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentForAdminPaymentMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformPaymentForAdminPaymentMethodEnum] to String,
/// and [decode] dynamic data back to [PlatformPaymentForAdminPaymentMethodEnum].
class PlatformPaymentForAdminPaymentMethodEnumTypeTransformer {
  factory PlatformPaymentForAdminPaymentMethodEnumTypeTransformer() => _instance ??= const PlatformPaymentForAdminPaymentMethodEnumTypeTransformer._();

  const PlatformPaymentForAdminPaymentMethodEnumTypeTransformer._();

  String encode(PlatformPaymentForAdminPaymentMethodEnum data) => data._value;

  /// Returns the instance of [PlatformPaymentForAdminPaymentMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformPaymentForAdminPaymentMethodEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformPaymentForAdminPaymentMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CASH': return PlatformPaymentForAdminPaymentMethodEnum.CASH;
        case r'GCASH': return PlatformPaymentForAdminPaymentMethodEnum.GCASH;
        case r'MAYA': return PlatformPaymentForAdminPaymentMethodEnum.MAYA;
        case r'BANK_TRANSFER': return PlatformPaymentForAdminPaymentMethodEnum.BANK_TRANSFER;
        case r'OTHER': return PlatformPaymentForAdminPaymentMethodEnum.OTHER;
        case r'ADVANCE': return PlatformPaymentForAdminPaymentMethodEnum.ADVANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformPaymentForAdminPaymentMethodEnumTypeTransformer? _instance;
}



enum PlatformPaymentForAdminStatusEnum {
  PENDING_VERIFICATION._(r'PENDING_VERIFICATION'),
  CONFIRMED._(r'CONFIRMED'),
  REJECTED._(r'REJECTED'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlatformPaymentForAdminStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlatformPaymentForAdminStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlatformPaymentForAdminStatusEnum? fromJson(dynamic value) => PlatformPaymentForAdminStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlatformPaymentForAdminStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlatformPaymentForAdminStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlatformPaymentForAdminStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlatformPaymentForAdminStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlatformPaymentForAdminStatusEnum] to String,
/// and [decode] dynamic data back to [PlatformPaymentForAdminStatusEnum].
class PlatformPaymentForAdminStatusEnumTypeTransformer {
  factory PlatformPaymentForAdminStatusEnumTypeTransformer() => _instance ??= const PlatformPaymentForAdminStatusEnumTypeTransformer._();

  const PlatformPaymentForAdminStatusEnumTypeTransformer._();

  String encode(PlatformPaymentForAdminStatusEnum data) => data._value;

  /// Returns the instance of [PlatformPaymentForAdminStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlatformPaymentForAdminStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlatformPaymentForAdminStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PENDING_VERIFICATION': return PlatformPaymentForAdminStatusEnum.PENDING_VERIFICATION;
        case r'CONFIRMED': return PlatformPaymentForAdminStatusEnum.CONFIRMED;
        case r'REJECTED': return PlatformPaymentForAdminStatusEnum.REJECTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlatformPaymentForAdminStatusEnumTypeTransformer? _instance;
}


