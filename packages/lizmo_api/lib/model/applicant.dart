//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Applicant {
  /// Returns a new [Applicant] instance.
  Applicant({
    this.tenantId,
    this.name,
    this.phone,
    this.age,
    this.occupation,
    this.permanentAddress,
    this.idType,
    this.stillNeeds = const [],
  });

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
  int? age;

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

  ApplicantIdTypeEnum? idType;

  List<String> stillNeeds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Applicant &&
    other.tenantId == tenantId &&
    other.name == name &&
    other.phone == phone &&
    other.age == age &&
    other.occupation == occupation &&
    other.permanentAddress == permanentAddress &&
    other.idType == idType &&
    _deepEquality.equals(other.stillNeeds, stillNeeds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tenantId == null ? 0 : tenantId!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (age == null ? 0 : age!.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (permanentAddress == null ? 0 : permanentAddress!.hashCode) +
    (idType == null ? 0 : idType!.hashCode) +
    (stillNeeds.hashCode);

  @override
  String toString() => 'Applicant[tenantId=$tenantId, name=$name, phone=$phone, age=$age, occupation=$occupation, permanentAddress=$permanentAddress, idType=$idType, stillNeeds=$stillNeeds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.age != null) {
      json[r'age'] = this.age;
    } else {
      json[r'age'] = null;
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
    if (this.idType != null) {
      json[r'idType'] = this.idType;
    } else {
      json[r'idType'] = null;
    }
      json[r'stillNeeds'] = this.stillNeeds;
    return json;
  }

  /// Returns a new [Applicant] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Applicant? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Applicant(
        tenantId: mapValueOfType<String>(json, r'tenantId'),
        name: mapValueOfType<String>(json, r'name'),
        phone: mapValueOfType<String>(json, r'phone'),
        age: mapValueOfType<int>(json, r'age'),
        occupation: mapValueOfType<String>(json, r'occupation'),
        permanentAddress: mapValueOfType<String>(json, r'permanentAddress'),
        idType: ApplicantIdTypeEnum.fromJson(json[r'idType']),
        stillNeeds: json[r'stillNeeds'] is Iterable
            ? (json[r'stillNeeds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<Applicant> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Applicant>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Applicant.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Applicant> mapFromJson(dynamic json) {
    final map = <String, Applicant>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Applicant.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Applicant-objects as value to a dart map
  static Map<String, List<Applicant>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Applicant>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Applicant.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum ApplicantIdTypeEnum {
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
  const ApplicantIdTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ApplicantIdTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ApplicantIdTypeEnum? fromJson(dynamic value) => ApplicantIdTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ApplicantIdTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ApplicantIdTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicantIdTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicantIdTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApplicantIdTypeEnum] to String,
/// and [decode] dynamic data back to [ApplicantIdTypeEnum].
class ApplicantIdTypeEnumTypeTransformer {
  factory ApplicantIdTypeEnumTypeTransformer() => _instance ??= const ApplicantIdTypeEnumTypeTransformer._();

  const ApplicantIdTypeEnumTypeTransformer._();

  String encode(ApplicantIdTypeEnum data) => data._value;

  /// Returns the instance of [ApplicantIdTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApplicantIdTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ApplicantIdTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHILSYS': return ApplicantIdTypeEnum.PHILSYS;
        case r'UMID': return ApplicantIdTypeEnum.UMID;
        case r'SSS': return ApplicantIdTypeEnum.SSS;
        case r'GSIS': return ApplicantIdTypeEnum.GSIS;
        case r'DRIVERS_LICENSE': return ApplicantIdTypeEnum.DRIVERS_LICENSE;
        case r'PASSPORT': return ApplicantIdTypeEnum.PASSPORT;
        case r'PHILHEALTH': return ApplicantIdTypeEnum.PHILHEALTH;
        case r'POSTAL': return ApplicantIdTypeEnum.POSTAL;
        case r'VOTERS': return ApplicantIdTypeEnum.VOTERS;
        case r'TIN': return ApplicantIdTypeEnum.TIN;
        case r'PRC': return ApplicantIdTypeEnum.PRC;
        case r'OTHER': return ApplicantIdTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ApplicantIdTypeEnumTypeTransformer? _instance;
}


