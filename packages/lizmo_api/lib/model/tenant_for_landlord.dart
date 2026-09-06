//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TenantForLandlord {
  /// Returns a new [TenantForLandlord] instance.
  TenantForLandlord({
    this.leaseId,
    this.tenantId,
    this.name,
    this.phone,
    this.email,
    this.age,
    this.birthdate,
    this.occupation,
    this.permanentAddress,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.idType,
    this.idNumber,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? leaseId;

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
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? age;

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
  String? emergencyContactName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? emergencyContactRelationship;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? emergencyContactPhone;

  TenantForLandlordIdTypeEnum? idType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? idNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantForLandlord &&
    other.leaseId == leaseId &&
    other.tenantId == tenantId &&
    other.name == name &&
    other.phone == phone &&
    other.email == email &&
    other.age == age &&
    other.birthdate == birthdate &&
    other.occupation == occupation &&
    other.permanentAddress == permanentAddress &&
    other.emergencyContactName == emergencyContactName &&
    other.emergencyContactRelationship == emergencyContactRelationship &&
    other.emergencyContactPhone == emergencyContactPhone &&
    other.idType == idType &&
    other.idNumber == idNumber;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (tenantId == null ? 0 : tenantId!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (age == null ? 0 : age!.hashCode) +
    (birthdate == null ? 0 : birthdate!.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (permanentAddress == null ? 0 : permanentAddress!.hashCode) +
    (emergencyContactName == null ? 0 : emergencyContactName!.hashCode) +
    (emergencyContactRelationship == null ? 0 : emergencyContactRelationship!.hashCode) +
    (emergencyContactPhone == null ? 0 : emergencyContactPhone!.hashCode) +
    (idType == null ? 0 : idType!.hashCode) +
    (idNumber == null ? 0 : idNumber!.hashCode);

  @override
  String toString() => 'TenantForLandlord[leaseId=$leaseId, tenantId=$tenantId, name=$name, phone=$phone, email=$email, age=$age, birthdate=$birthdate, occupation=$occupation, permanentAddress=$permanentAddress, emergencyContactName=$emergencyContactName, emergencyContactRelationship=$emergencyContactRelationship, emergencyContactPhone=$emergencyContactPhone, idType=$idType, idNumber=$idNumber]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.tenantId != null) {
      json[r'tenantId'] = this.tenantId;
    } else {
      json[r'tenantId'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.age != null) {
      json[r'age'] = this.age;
    } else {
      json[r'age'] = null;
    }
    if (this.birthdate != null) {
      json[r'birthdate'] = _dateFormatter.format(this.birthdate!);
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
    if (this.emergencyContactName != null) {
      json[r'emergencyContactName'] = this.emergencyContactName;
    } else {
      json[r'emergencyContactName'] = null;
    }
    if (this.emergencyContactRelationship != null) {
      json[r'emergencyContactRelationship'] = this.emergencyContactRelationship;
    } else {
      json[r'emergencyContactRelationship'] = null;
    }
    if (this.emergencyContactPhone != null) {
      json[r'emergencyContactPhone'] = this.emergencyContactPhone;
    } else {
      json[r'emergencyContactPhone'] = null;
    }
    if (this.idType != null) {
      json[r'idType'] = this.idType;
    } else {
      json[r'idType'] = null;
    }
    if (this.idNumber != null) {
      json[r'idNumber'] = this.idNumber;
    } else {
      json[r'idNumber'] = null;
    }
    return json;
  }

  /// Returns a new [TenantForLandlord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantForLandlord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TenantForLandlord(
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        tenantId: mapValueOfType<String>(json, r'tenantId'),
        name: mapValueOfType<String>(json, r'name'),
        phone: mapValueOfType<String>(json, r'phone'),
        email: mapValueOfType<String>(json, r'email'),
        age: mapValueOfType<int>(json, r'age'),
        birthdate: mapDateTime(json, r'birthdate', r''),
        occupation: mapValueOfType<String>(json, r'occupation'),
        permanentAddress: mapValueOfType<String>(json, r'permanentAddress'),
        emergencyContactName: mapValueOfType<String>(json, r'emergencyContactName'),
        emergencyContactRelationship: mapValueOfType<String>(json, r'emergencyContactRelationship'),
        emergencyContactPhone: mapValueOfType<String>(json, r'emergencyContactPhone'),
        idType: TenantForLandlordIdTypeEnum.fromJson(json[r'idType']),
        idNumber: mapValueOfType<String>(json, r'idNumber'),
      );
    }
    return null;
  }

  static List<TenantForLandlord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantForLandlord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantForLandlord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantForLandlord> mapFromJson(dynamic json) {
    final map = <String, TenantForLandlord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantForLandlord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantForLandlord-objects as value to a dart map
  static Map<String, List<TenantForLandlord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantForLandlord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantForLandlord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum TenantForLandlordIdTypeEnum {
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
  const TenantForLandlordIdTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TenantForLandlordIdTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TenantForLandlordIdTypeEnum? fromJson(dynamic value) => TenantForLandlordIdTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TenantForLandlordIdTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TenantForLandlordIdTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantForLandlordIdTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantForLandlordIdTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TenantForLandlordIdTypeEnum] to String,
/// and [decode] dynamic data back to [TenantForLandlordIdTypeEnum].
class TenantForLandlordIdTypeEnumTypeTransformer {
  factory TenantForLandlordIdTypeEnumTypeTransformer() => _instance ??= const TenantForLandlordIdTypeEnumTypeTransformer._();

  const TenantForLandlordIdTypeEnumTypeTransformer._();

  String encode(TenantForLandlordIdTypeEnum data) => data._value;

  /// Returns the instance of [TenantForLandlordIdTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TenantForLandlordIdTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is TenantForLandlordIdTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHILSYS': return TenantForLandlordIdTypeEnum.PHILSYS;
        case r'UMID': return TenantForLandlordIdTypeEnum.UMID;
        case r'SSS': return TenantForLandlordIdTypeEnum.SSS;
        case r'GSIS': return TenantForLandlordIdTypeEnum.GSIS;
        case r'DRIVERS_LICENSE': return TenantForLandlordIdTypeEnum.DRIVERS_LICENSE;
        case r'PASSPORT': return TenantForLandlordIdTypeEnum.PASSPORT;
        case r'PHILHEALTH': return TenantForLandlordIdTypeEnum.PHILHEALTH;
        case r'POSTAL': return TenantForLandlordIdTypeEnum.POSTAL;
        case r'VOTERS': return TenantForLandlordIdTypeEnum.VOTERS;
        case r'TIN': return TenantForLandlordIdTypeEnum.TIN;
        case r'PRC': return TenantForLandlordIdTypeEnum.PRC;
        case r'OTHER': return TenantForLandlordIdTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TenantForLandlordIdTypeEnumTypeTransformer? _instance;
}


