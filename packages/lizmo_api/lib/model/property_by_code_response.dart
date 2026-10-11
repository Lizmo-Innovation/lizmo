//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PropertyByCodeResponse {
  /// Returns a new [PropertyByCodeResponse] instance.
  PropertyByCodeResponse({
    this.id,
    this.code,
    this.name,
    this.address,
    this.description,
    this.type,
    this.usage,
    this.vacantWholeUnits,
    this.vacantBeds,
    this.floors = const [],
    this.photos = const [],
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
  String? code;

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
  String? address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  PropertyByCodeResponseTypeEnum? type;

  PropertyByCodeResponseUsageEnum? usage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vacantWholeUnits;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vacantBeds;

  List<VacancyFloor> floors;

  List<String> photos;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyByCodeResponse &&
    other.id == id &&
    other.code == code &&
    other.name == name &&
    other.address == address &&
    other.description == description &&
    other.type == type &&
    other.usage == usage &&
    other.vacantWholeUnits == vacantWholeUnits &&
    other.vacantBeds == vacantBeds &&
    _deepEquality.equals(other.floors, floors) &&
    _deepEquality.equals(other.photos, photos);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (usage == null ? 0 : usage!.hashCode) +
    (vacantWholeUnits == null ? 0 : vacantWholeUnits!.hashCode) +
    (vacantBeds == null ? 0 : vacantBeds!.hashCode) +
    (floors.hashCode) +
    (photos.hashCode);

  @override
  String toString() => 'PropertyByCodeResponse[id=$id, code=$code, name=$name, address=$address, description=$description, type=$type, usage=$usage, vacantWholeUnits=$vacantWholeUnits, vacantBeds=$vacantBeds, floors=$floors, photos=$photos]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.usage != null) {
      json[r'usage'] = this.usage;
    } else {
      json[r'usage'] = null;
    }
    if (this.vacantWholeUnits != null) {
      json[r'vacantWholeUnits'] = this.vacantWholeUnits;
    } else {
      json[r'vacantWholeUnits'] = null;
    }
    if (this.vacantBeds != null) {
      json[r'vacantBeds'] = this.vacantBeds;
    } else {
      json[r'vacantBeds'] = null;
    }
      json[r'floors'] = this.floors;
      json[r'photos'] = this.photos;
    return json;
  }

  /// Returns a new [PropertyByCodeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyByCodeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PropertyByCodeResponse(
        id: mapValueOfType<String>(json, r'id'),
        code: mapValueOfType<String>(json, r'code'),
        name: mapValueOfType<String>(json, r'name'),
        address: mapValueOfType<String>(json, r'address'),
        description: mapValueOfType<String>(json, r'description'),
        type: PropertyByCodeResponseTypeEnum.fromJson(json[r'type']),
        usage: PropertyByCodeResponseUsageEnum.fromJson(json[r'usage']),
        vacantWholeUnits: mapValueOfType<int>(json, r'vacantWholeUnits'),
        vacantBeds: mapValueOfType<int>(json, r'vacantBeds'),
        floors: VacancyFloor.listFromJson(json[r'floors']),
        photos: json[r'photos'] is Iterable
            ? (json[r'photos'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<PropertyByCodeResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyByCodeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyByCodeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyByCodeResponse> mapFromJson(dynamic json) {
    final map = <String, PropertyByCodeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyByCodeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyByCodeResponse-objects as value to a dart map
  static Map<String, List<PropertyByCodeResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyByCodeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyByCodeResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PropertyByCodeResponseTypeEnum {
  APARTMENT._(r'APARTMENT'),
  BOARDING_HOUSE._(r'BOARDING_HOUSE'),
  CONDO._(r'CONDO'),
  SINGLE_HOUSE._(r'SINGLE_HOUSE'),
  OFFICE._(r'OFFICE'),
  RETAIL_SPACE._(r'RETAIL_SPACE'),
  WAREHOUSE._(r'WAREHOUSE'),
  STALL._(r'STALL'),
  ;

  /// Instantiate a new enum with the provided value.
  const PropertyByCodeResponseTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PropertyByCodeResponseTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PropertyByCodeResponseTypeEnum? fromJson(dynamic value) => PropertyByCodeResponseTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PropertyByCodeResponseTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PropertyByCodeResponseTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyByCodeResponseTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyByCodeResponseTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PropertyByCodeResponseTypeEnum] to String,
/// and [decode] dynamic data back to [PropertyByCodeResponseTypeEnum].
class PropertyByCodeResponseTypeEnumTypeTransformer {
  factory PropertyByCodeResponseTypeEnumTypeTransformer() => _instance ??= const PropertyByCodeResponseTypeEnumTypeTransformer._();

  const PropertyByCodeResponseTypeEnumTypeTransformer._();

  String encode(PropertyByCodeResponseTypeEnum data) => data._value;

  /// Returns the instance of [PropertyByCodeResponseTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PropertyByCodeResponseTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PropertyByCodeResponseTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'APARTMENT': return PropertyByCodeResponseTypeEnum.APARTMENT;
        case r'BOARDING_HOUSE': return PropertyByCodeResponseTypeEnum.BOARDING_HOUSE;
        case r'CONDO': return PropertyByCodeResponseTypeEnum.CONDO;
        case r'SINGLE_HOUSE': return PropertyByCodeResponseTypeEnum.SINGLE_HOUSE;
        case r'OFFICE': return PropertyByCodeResponseTypeEnum.OFFICE;
        case r'RETAIL_SPACE': return PropertyByCodeResponseTypeEnum.RETAIL_SPACE;
        case r'WAREHOUSE': return PropertyByCodeResponseTypeEnum.WAREHOUSE;
        case r'STALL': return PropertyByCodeResponseTypeEnum.STALL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PropertyByCodeResponseTypeEnumTypeTransformer? _instance;
}



enum PropertyByCodeResponseUsageEnum {
  RESIDENTIAL._(r'RESIDENTIAL'),
  COMMERCIAL._(r'COMMERCIAL'),
  ;

  /// Instantiate a new enum with the provided value.
  const PropertyByCodeResponseUsageEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PropertyByCodeResponseUsageEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PropertyByCodeResponseUsageEnum? fromJson(dynamic value) => PropertyByCodeResponseUsageEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PropertyByCodeResponseUsageEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PropertyByCodeResponseUsageEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyByCodeResponseUsageEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyByCodeResponseUsageEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PropertyByCodeResponseUsageEnum] to String,
/// and [decode] dynamic data back to [PropertyByCodeResponseUsageEnum].
class PropertyByCodeResponseUsageEnumTypeTransformer {
  factory PropertyByCodeResponseUsageEnumTypeTransformer() => _instance ??= const PropertyByCodeResponseUsageEnumTypeTransformer._();

  const PropertyByCodeResponseUsageEnumTypeTransformer._();

  String encode(PropertyByCodeResponseUsageEnum data) => data._value;

  /// Returns the instance of [PropertyByCodeResponseUsageEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PropertyByCodeResponseUsageEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PropertyByCodeResponseUsageEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RESIDENTIAL': return PropertyByCodeResponseUsageEnum.RESIDENTIAL;
        case r'COMMERCIAL': return PropertyByCodeResponseUsageEnum.COMMERCIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PropertyByCodeResponseUsageEnumTypeTransformer? _instance;
}


