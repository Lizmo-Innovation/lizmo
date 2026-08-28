//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TenantProfileRequest {
  /// Returns a new [TenantProfileRequest] instance.
  TenantProfileRequest({
    this.birthdate,
    this.permanentAddress,
    this.occupation,
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
  DateTime? birthdate;

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
  String? occupation;

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

  TenantProfileRequestIdTypeEnum? idType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? idNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantProfileRequest &&
    other.birthdate == birthdate &&
    other.permanentAddress == permanentAddress &&
    other.occupation == occupation &&
    other.emergencyContactName == emergencyContactName &&
    other.emergencyContactRelationship == emergencyContactRelationship &&
    other.emergencyContactPhone == emergencyContactPhone &&
    other.idType == idType &&
    other.idNumber == idNumber;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (birthdate == null ? 0 : birthdate!.hashCode) +
    (permanentAddress == null ? 0 : permanentAddress!.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (emergencyContactName == null ? 0 : emergencyContactName!.hashCode) +
    (emergencyContactRelationship == null ? 0 : emergencyContactRelationship!.hashCode) +
    (emergencyContactPhone == null ? 0 : emergencyContactPhone!.hashCode) +
    (idType == null ? 0 : idType!.hashCode) +
    (idNumber == null ? 0 : idNumber!.hashCode);

  @override
  String toString() => 'TenantProfileRequest[birthdate=$birthdate, permanentAddress=$permanentAddress, occupation=$occupation, emergencyContactName=$emergencyContactName, emergencyContactRelationship=$emergencyContactRelationship, emergencyContactPhone=$emergencyContactPhone, idType=$idType, idNumber=$idNumber]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.birthdate != null) {
      json[r'birthdate'] = _dateFormatter.format(this.birthdate!.toUtc());
    } else {
      json[r'birthdate'] = null;
    }
    if (this.permanentAddress != null) {
      json[r'permanentAddress'] = this.permanentAddress;
    } else {
      json[r'permanentAddress'] = null;
    }
    if (this.occupation != null) {
      json[r'occupation'] = this.occupation;
    } else {
      json[r'occupation'] = null;
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

  /// Returns a new [TenantProfileRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantProfileRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TenantProfileRequest(
        birthdate: mapDateTime(json, r'birthdate', r''),
        permanentAddress: mapValueOfType<String>(json, r'permanentAddress'),
        occupation: mapValueOfType<String>(json, r'occupation'),
        emergencyContactName: mapValueOfType<String>(json, r'emergencyContactName'),
        emergencyContactRelationship: mapValueOfType<String>(json, r'emergencyContactRelationship'),
        emergencyContactPhone: mapValueOfType<String>(json, r'emergencyContactPhone'),
        idType: TenantProfileRequestIdTypeEnum.fromJson(json[r'idType']),
        idNumber: mapValueOfType<String>(json, r'idNumber'),
      );
    }
    return null;
  }

  static List<TenantProfileRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantProfileRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantProfileRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantProfileRequest> mapFromJson(dynamic json) {
    final map = <String, TenantProfileRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantProfileRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantProfileRequest-objects as value to a dart map
  static Map<String, List<TenantProfileRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantProfileRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantProfileRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum TenantProfileRequestIdTypeEnum {
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
  const TenantProfileRequestIdTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TenantProfileRequestIdTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TenantProfileRequestIdTypeEnum? fromJson(dynamic value) => TenantProfileRequestIdTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TenantProfileRequestIdTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TenantProfileRequestIdTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantProfileRequestIdTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantProfileRequestIdTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TenantProfileRequestIdTypeEnum] to String,
/// and [decode] dynamic data back to [TenantProfileRequestIdTypeEnum].
class TenantProfileRequestIdTypeEnumTypeTransformer {
  factory TenantProfileRequestIdTypeEnumTypeTransformer() => _instance ??= const TenantProfileRequestIdTypeEnumTypeTransformer._();

  const TenantProfileRequestIdTypeEnumTypeTransformer._();

  String encode(TenantProfileRequestIdTypeEnum data) => data._value;

  /// Returns the instance of [TenantProfileRequestIdTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TenantProfileRequestIdTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is TenantProfileRequestIdTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHILSYS': return TenantProfileRequestIdTypeEnum.PHILSYS;
        case r'UMID': return TenantProfileRequestIdTypeEnum.UMID;
        case r'SSS': return TenantProfileRequestIdTypeEnum.SSS;
        case r'GSIS': return TenantProfileRequestIdTypeEnum.GSIS;
        case r'DRIVERS_LICENSE': return TenantProfileRequestIdTypeEnum.DRIVERS_LICENSE;
        case r'PASSPORT': return TenantProfileRequestIdTypeEnum.PASSPORT;
        case r'PHILHEALTH': return TenantProfileRequestIdTypeEnum.PHILHEALTH;
        case r'POSTAL': return TenantProfileRequestIdTypeEnum.POSTAL;
        case r'VOTERS': return TenantProfileRequestIdTypeEnum.VOTERS;
        case r'TIN': return TenantProfileRequestIdTypeEnum.TIN;
        case r'PRC': return TenantProfileRequestIdTypeEnum.PRC;
        case r'OTHER': return TenantProfileRequestIdTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TenantProfileRequestIdTypeEnumTypeTransformer? _instance;
}


