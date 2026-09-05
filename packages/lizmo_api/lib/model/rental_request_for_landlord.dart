//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentalRequestForLandlord {
  /// Returns a new [RentalRequestForLandlord] instance.
  RentalRequestForLandlord({
    this.id,
    this.propertyId,
    this.unitId,
    this.unitNumber,
    this.bedId,
    this.bedLabel,
    this.status,
    this.createdAt,
    this.decidedAt,
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.birthdate,
    this.occupation,
    this.permanentAddress,
    this.age,
    this.idType,
    this.askingRent,
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
  String? unitId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedLabel;

  RentalRequestForLandlordStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? decidedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantPhone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? birthdate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? occupation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? permanentAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? age;

  RentalRequestForLandlordIdTypeEnum? idType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? askingRent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentalRequestForLandlord &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.unitId == unitId &&
    other.unitNumber == unitNumber &&
    other.bedId == bedId &&
    other.bedLabel == bedLabel &&
    other.status == status &&
    other.createdAt == createdAt &&
    other.decidedAt == decidedAt &&
    other.tenantId == tenantId &&
    other.tenantName == tenantName &&
    other.tenantPhone == tenantPhone &&
    other.birthdate == birthdate &&
    other.occupation == occupation &&
    other.permanentAddress == permanentAddress &&
    other.age == age &&
    other.idType == idType &&
    other.askingRent == askingRent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedId == null ? 0 : bedId!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (decidedAt == null ? 0 : decidedAt!.hashCode) +
    (tenantId == null ? 0 : tenantId!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (tenantPhone == null ? 0 : tenantPhone!.hashCode) +
    (birthdate == null ? 0 : birthdate!.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (permanentAddress == null ? 0 : permanentAddress!.hashCode) +
    (age == null ? 0 : age!.hashCode) +
    (idType == null ? 0 : idType!.hashCode) +
    (askingRent == null ? 0 : askingRent!.hashCode);

  @override
  String toString() => 'RentalRequestForLandlord[id=$id, propertyId=$propertyId, unitId=$unitId, unitNumber=$unitNumber, bedId=$bedId, bedLabel=$bedLabel, status=$status, createdAt=$createdAt, decidedAt=$decidedAt, tenantId=$tenantId, tenantName=$tenantName, tenantPhone=$tenantPhone, birthdate=$birthdate, occupation=$occupation, permanentAddress=$permanentAddress, age=$age, idType=$idType, askingRent=$askingRent]';

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
    if (this.unitId != null) {
      json[r'unitId'] = this.unitId;
    } else {
      json[r'unitId'] = null;
    }
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.bedId != null) {
      json[r'bedId'] = this.bedId;
    } else {
      json[r'bedId'] = null;
    }
    if (this.bedLabel != null) {
      json[r'bedLabel'] = this.bedLabel;
    } else {
      json[r'bedLabel'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.decidedAt != null) {
      json[r'decidedAt'] = this.decidedAt!.toUtc().toIso8601String();
    } else {
      json[r'decidedAt'] = null;
    }
    if (this.tenantId != null) {
      json[r'tenantId'] = this.tenantId;
    } else {
      json[r'tenantId'] = null;
    }
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
    }
    if (this.tenantPhone != null) {
      json[r'tenantPhone'] = this.tenantPhone;
    } else {
      json[r'tenantPhone'] = null;
    }
    if (this.birthdate != null) {
      json[r'birthdate'] = _dateFormatter.format(this.birthdate!.toUtc());
    } else {
      json[r'birthdate'] = null;
    }
    if (this.occupation != null) {
      json[r'occupation'] = this.occupation;
    } else {
      json[r'occupation'] = null;
    }
    if (this.permanentAddress != null) {
      json[r'permanentAddress'] = this.permanentAddress;
    } else {
      json[r'permanentAddress'] = null;
    }
    if (this.age != null) {
      json[r'age'] = this.age;
    } else {
      json[r'age'] = null;
    }
    if (this.idType != null) {
      json[r'idType'] = this.idType;
    } else {
      json[r'idType'] = null;
    }
    if (this.askingRent != null) {
      json[r'askingRent'] = this.askingRent;
    } else {
      json[r'askingRent'] = null;
    }
    return json;
  }

  /// Returns a new [RentalRequestForLandlord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentalRequestForLandlord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return RentalRequestForLandlord(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        unitId: mapValueOfType<String>(json, r'unitId'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedId: mapValueOfType<String>(json, r'bedId'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        status: RentalRequestForLandlordStatusEnum.fromJson(json[r'status']),
        createdAt: mapDateTime(json, r'createdAt', r''),
        decidedAt: mapDateTime(json, r'decidedAt', r''),
        tenantId: mapValueOfType<String>(json, r'tenantId'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        tenantPhone: mapValueOfType<String>(json, r'tenantPhone'),
        birthdate: mapDateTime(json, r'birthdate', r''),
        occupation: mapValueOfType<String>(json, r'occupation'),
        permanentAddress: mapValueOfType<String>(json, r'permanentAddress'),
        age: mapValueOfType<int>(json, r'age'),
        idType: RentalRequestForLandlordIdTypeEnum.fromJson(json[r'idType']),
        askingRent: json[r'askingRent'] == null
            ? null
            : num.parse('${json[r'askingRent']}'),
      );
    }
    return null;
  }

  static List<RentalRequestForLandlord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentalRequestForLandlord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentalRequestForLandlord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentalRequestForLandlord> mapFromJson(dynamic json) {
    final map = <String, RentalRequestForLandlord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentalRequestForLandlord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentalRequestForLandlord-objects as value to a dart map
  static Map<String, List<RentalRequestForLandlord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentalRequestForLandlord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentalRequestForLandlord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum RentalRequestForLandlordStatusEnum {
  PENDING._(r'PENDING'),
  ACCEPTED._(r'ACCEPTED'),
  DECLINED._(r'DECLINED'),
  WITHDRAWN._(r'WITHDRAWN'),
  SUPERSEDED._(r'SUPERSEDED'),
  ;

  /// Instantiate a new enum with the provided value.
  const RentalRequestForLandlordStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RentalRequestForLandlordStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RentalRequestForLandlordStatusEnum? fromJson(dynamic value) => RentalRequestForLandlordStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RentalRequestForLandlordStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RentalRequestForLandlordStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentalRequestForLandlordStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentalRequestForLandlordStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RentalRequestForLandlordStatusEnum] to String,
/// and [decode] dynamic data back to [RentalRequestForLandlordStatusEnum].
class RentalRequestForLandlordStatusEnumTypeTransformer {
  factory RentalRequestForLandlordStatusEnumTypeTransformer() => _instance ??= const RentalRequestForLandlordStatusEnumTypeTransformer._();

  const RentalRequestForLandlordStatusEnumTypeTransformer._();

  String encode(RentalRequestForLandlordStatusEnum data) => data._value;

  /// Returns the instance of [RentalRequestForLandlordStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RentalRequestForLandlordStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RentalRequestForLandlordStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PENDING': return RentalRequestForLandlordStatusEnum.PENDING;
        case r'ACCEPTED': return RentalRequestForLandlordStatusEnum.ACCEPTED;
        case r'DECLINED': return RentalRequestForLandlordStatusEnum.DECLINED;
        case r'WITHDRAWN': return RentalRequestForLandlordStatusEnum.WITHDRAWN;
        case r'SUPERSEDED': return RentalRequestForLandlordStatusEnum.SUPERSEDED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RentalRequestForLandlordStatusEnumTypeTransformer? _instance;
}



enum RentalRequestForLandlordIdTypeEnum {
  PHILSYS._(r'PHILSYS'),
  UMID._(r'UMID'),
  SSS._(r'SSS'),
  GSIS._(r'GSIS'),
  DRIVERS_LICENSE._(r'DRIVERS_LICENSE'),
  PASSPORT._(r'PASSPORT'),
  PHILHEALTH._(r'PHILHEALTH'),
  POSTAL._(r'POSTAL'),
  VOTERS._(r'VOTERS'),
  TIN._(r'TIN'),
  PRC._(r'PRC'),
  OTHER._(r'OTHER'),
  ;

  /// Instantiate a new enum with the provided value.
  const RentalRequestForLandlordIdTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RentalRequestForLandlordIdTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RentalRequestForLandlordIdTypeEnum? fromJson(dynamic value) => RentalRequestForLandlordIdTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RentalRequestForLandlordIdTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RentalRequestForLandlordIdTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentalRequestForLandlordIdTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentalRequestForLandlordIdTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RentalRequestForLandlordIdTypeEnum] to String,
/// and [decode] dynamic data back to [RentalRequestForLandlordIdTypeEnum].
class RentalRequestForLandlordIdTypeEnumTypeTransformer {
  factory RentalRequestForLandlordIdTypeEnumTypeTransformer() => _instance ??= const RentalRequestForLandlordIdTypeEnumTypeTransformer._();

  const RentalRequestForLandlordIdTypeEnumTypeTransformer._();

  String encode(RentalRequestForLandlordIdTypeEnum data) => data._value;

  /// Returns the instance of [RentalRequestForLandlordIdTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RentalRequestForLandlordIdTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RentalRequestForLandlordIdTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHILSYS': return RentalRequestForLandlordIdTypeEnum.PHILSYS;
        case r'UMID': return RentalRequestForLandlordIdTypeEnum.UMID;
        case r'SSS': return RentalRequestForLandlordIdTypeEnum.SSS;
        case r'GSIS': return RentalRequestForLandlordIdTypeEnum.GSIS;
        case r'DRIVERS_LICENSE': return RentalRequestForLandlordIdTypeEnum.DRIVERS_LICENSE;
        case r'PASSPORT': return RentalRequestForLandlordIdTypeEnum.PASSPORT;
        case r'PHILHEALTH': return RentalRequestForLandlordIdTypeEnum.PHILHEALTH;
        case r'POSTAL': return RentalRequestForLandlordIdTypeEnum.POSTAL;
        case r'VOTERS': return RentalRequestForLandlordIdTypeEnum.VOTERS;
        case r'TIN': return RentalRequestForLandlordIdTypeEnum.TIN;
        case r'PRC': return RentalRequestForLandlordIdTypeEnum.PRC;
        case r'OTHER': return RentalRequestForLandlordIdTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RentalRequestForLandlordIdTypeEnumTypeTransformer? _instance;
}


