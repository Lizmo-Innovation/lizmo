//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TenantProfileResponse {
  /// Returns a new [TenantProfileResponse] instance.
  TenantProfileResponse({
    this.birthdate,
    this.permanentAddress,
    this.occupation,
    this.contactPhone,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.idType,
    this.idNumber,
    this.readyForALease,
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
  String? contactPhone;

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

  TenantProfileResponseIdTypeEnum? idType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? idNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? readyForALease;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantProfileResponse &&
    other.birthdate == birthdate &&
    other.permanentAddress == permanentAddress &&
    other.occupation == occupation &&
    other.contactPhone == contactPhone &&
    other.emergencyContactName == emergencyContactName &&
    other.emergencyContactRelationship == emergencyContactRelationship &&
    other.emergencyContactPhone == emergencyContactPhone &&
    other.idType == idType &&
    other.idNumber == idNumber &&
    other.readyForALease == readyForALease;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (birthdate == null ? 0 : birthdate!.hashCode) +
    (permanentAddress == null ? 0 : permanentAddress!.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (contactPhone == null ? 0 : contactPhone!.hashCode) +
    (emergencyContactName == null ? 0 : emergencyContactName!.hashCode) +
    (emergencyContactRelationship == null ? 0 : emergencyContactRelationship!.hashCode) +
    (emergencyContactPhone == null ? 0 : emergencyContactPhone!.hashCode) +
    (idType == null ? 0 : idType!.hashCode) +
    (idNumber == null ? 0 : idNumber!.hashCode) +
    (readyForALease == null ? 0 : readyForALease!.hashCode);

  @override
  String toString() => 'TenantProfileResponse[birthdate=$birthdate, permanentAddress=$permanentAddress, occupation=$occupation, contactPhone=$contactPhone, emergencyContactName=$emergencyContactName, emergencyContactRelationship=$emergencyContactRelationship, emergencyContactPhone=$emergencyContactPhone, idType=$idType, idNumber=$idNumber, readyForALease=$readyForALease]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.birthdate != null) {
      json[r'birthdate'] = _dateFormatter.format(this.birthdate!);
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
    if (this.contactPhone != null) {
      json[r'contactPhone'] = this.contactPhone;
    } else {
      json[r'contactPhone'] = null;
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
    if (this.readyForALease != null) {
      json[r'readyForALease'] = this.readyForALease;
    } else {
      json[r'readyForALease'] = null;
    }
    return json;
  }

  /// Returns a new [TenantProfileResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantProfileResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TenantProfileResponse(
        birthdate: mapDateTime(json, r'birthdate', r''),
        permanentAddress: mapValueOfType<String>(json, r'permanentAddress'),
        occupation: mapValueOfType<String>(json, r'occupation'),
        contactPhone: mapValueOfType<String>(json, r'contactPhone'),
        emergencyContactName: mapValueOfType<String>(json, r'emergencyContactName'),
        emergencyContactRelationship: mapValueOfType<String>(json, r'emergencyContactRelationship'),
        emergencyContactPhone: mapValueOfType<String>(json, r'emergencyContactPhone'),
        idType: TenantProfileResponseIdTypeEnum.fromJson(json[r'idType']),
        idNumber: mapValueOfType<String>(json, r'idNumber'),
        readyForALease: mapValueOfType<bool>(json, r'readyForALease'),
      );
    }
    return null;
  }

  static List<TenantProfileResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantProfileResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantProfileResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantProfileResponse> mapFromJson(dynamic json) {
    final map = <String, TenantProfileResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantProfileResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantProfileResponse-objects as value to a dart map
  static Map<String, List<TenantProfileResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantProfileResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantProfileResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum TenantProfileResponseIdTypeEnum {
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
  const TenantProfileResponseIdTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TenantProfileResponseIdTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TenantProfileResponseIdTypeEnum? fromJson(dynamic value) => TenantProfileResponseIdTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TenantProfileResponseIdTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TenantProfileResponseIdTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantProfileResponseIdTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantProfileResponseIdTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TenantProfileResponseIdTypeEnum] to String,
/// and [decode] dynamic data back to [TenantProfileResponseIdTypeEnum].
class TenantProfileResponseIdTypeEnumTypeTransformer {
  factory TenantProfileResponseIdTypeEnumTypeTransformer() => _instance ??= const TenantProfileResponseIdTypeEnumTypeTransformer._();

  const TenantProfileResponseIdTypeEnumTypeTransformer._();

  String encode(TenantProfileResponseIdTypeEnum data) => data._value;

  /// Returns the instance of [TenantProfileResponseIdTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TenantProfileResponseIdTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is TenantProfileResponseIdTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHILSYS': return TenantProfileResponseIdTypeEnum.PHILSYS;
        case r'UMID': return TenantProfileResponseIdTypeEnum.UMID;
        case r'SSS': return TenantProfileResponseIdTypeEnum.SSS;
        case r'GSIS': return TenantProfileResponseIdTypeEnum.GSIS;
        case r'DRIVERS_LICENSE': return TenantProfileResponseIdTypeEnum.DRIVERS_LICENSE;
        case r'PASSPORT': return TenantProfileResponseIdTypeEnum.PASSPORT;
        case r'PHILHEALTH': return TenantProfileResponseIdTypeEnum.PHILHEALTH;
        case r'POSTAL': return TenantProfileResponseIdTypeEnum.POSTAL;
        case r'VOTERS': return TenantProfileResponseIdTypeEnum.VOTERS;
        case r'TIN': return TenantProfileResponseIdTypeEnum.TIN;
        case r'PRC': return TenantProfileResponseIdTypeEnum.PRC;
        case r'OTHER': return TenantProfileResponseIdTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TenantProfileResponseIdTypeEnumTypeTransformer? _instance;
}


