//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PropertyResponse {
  /// Returns a new [PropertyResponse] instance.
  PropertyResponse({
    this.id,
    this.name,
    this.address,
    this.type,
    this.usage,
    this.unitCount,
    this.potentialMonthlyRent,
    this.createdAt,
    this.updatedAt,
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
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  PropertyResponseTypeEnum? type;

  PropertyResponseUsageEnum? usage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? unitCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? potentialMonthlyRent;

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
  DateTime? updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyResponse &&
    other.id == id &&
    other.name == name &&
    other.address == address &&
    other.type == type &&
    other.usage == usage &&
    other.unitCount == unitCount &&
    other.potentialMonthlyRent == potentialMonthlyRent &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (usage == null ? 0 : usage!.hashCode) +
    (unitCount == null ? 0 : unitCount!.hashCode) +
    (potentialMonthlyRent == null ? 0 : potentialMonthlyRent!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode);

  @override
  String toString() => 'PropertyResponse[id=$id, name=$name, address=$address, type=$type, usage=$usage, unitCount=$unitCount, potentialMonthlyRent=$potentialMonthlyRent, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
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
    if (this.unitCount != null) {
      json[r'unitCount'] = this.unitCount;
    } else {
      json[r'unitCount'] = null;
    }
    if (this.potentialMonthlyRent != null) {
      json[r'potentialMonthlyRent'] = this.potentialMonthlyRent;
    } else {
      json[r'potentialMonthlyRent'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    return json;
  }

  /// Returns a new [PropertyResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PropertyResponse(
        id: mapValueOfType<String>(json, r'id'),
        name: mapValueOfType<String>(json, r'name'),
        address: mapValueOfType<String>(json, r'address'),
        type: PropertyResponseTypeEnum.fromJson(json[r'type']),
        usage: PropertyResponseUsageEnum.fromJson(json[r'usage']),
        unitCount: mapValueOfType<int>(json, r'unitCount'),
        potentialMonthlyRent: json[r'potentialMonthlyRent'] == null
            ? null
            : num.parse('${json[r'potentialMonthlyRent']}'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
      );
    }
    return null;
  }

  static List<PropertyResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyResponse> mapFromJson(dynamic json) {
    final map = <String, PropertyResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyResponse-objects as value to a dart map
  static Map<String, List<PropertyResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum PropertyResponseTypeEnum {
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
  const PropertyResponseTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PropertyResponseTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PropertyResponseTypeEnum? fromJson(dynamic value) => PropertyResponseTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PropertyResponseTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PropertyResponseTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyResponseTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyResponseTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PropertyResponseTypeEnum] to String,
/// and [decode] dynamic data back to [PropertyResponseTypeEnum].
class PropertyResponseTypeEnumTypeTransformer {
  factory PropertyResponseTypeEnumTypeTransformer() => _instance ??= const PropertyResponseTypeEnumTypeTransformer._();

  const PropertyResponseTypeEnumTypeTransformer._();

  String encode(PropertyResponseTypeEnum data) => data._value;

  /// Returns the instance of [PropertyResponseTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PropertyResponseTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PropertyResponseTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'APARTMENT': return PropertyResponseTypeEnum.APARTMENT;
        case r'BOARDING_HOUSE': return PropertyResponseTypeEnum.BOARDING_HOUSE;
        case r'CONDO': return PropertyResponseTypeEnum.CONDO;
        case r'SINGLE_HOUSE': return PropertyResponseTypeEnum.SINGLE_HOUSE;
        case r'OFFICE': return PropertyResponseTypeEnum.OFFICE;
        case r'RETAIL_SPACE': return PropertyResponseTypeEnum.RETAIL_SPACE;
        case r'WAREHOUSE': return PropertyResponseTypeEnum.WAREHOUSE;
        case r'STALL': return PropertyResponseTypeEnum.STALL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PropertyResponseTypeEnumTypeTransformer? _instance;
}



enum PropertyResponseUsageEnum {
  RESIDENTIAL._(r'RESIDENTIAL'),
  COMMERCIAL._(r'COMMERCIAL'),
  ;

  /// Instantiate a new enum with the provided value.
  const PropertyResponseUsageEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PropertyResponseUsageEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PropertyResponseUsageEnum? fromJson(dynamic value) => PropertyResponseUsageEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PropertyResponseUsageEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PropertyResponseUsageEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyResponseUsageEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyResponseUsageEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PropertyResponseUsageEnum] to String,
/// and [decode] dynamic data back to [PropertyResponseUsageEnum].
class PropertyResponseUsageEnumTypeTransformer {
  factory PropertyResponseUsageEnumTypeTransformer() => _instance ??= const PropertyResponseUsageEnumTypeTransformer._();

  const PropertyResponseUsageEnumTypeTransformer._();

  String encode(PropertyResponseUsageEnum data) => data._value;

  /// Returns the instance of [PropertyResponseUsageEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PropertyResponseUsageEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PropertyResponseUsageEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RESIDENTIAL': return PropertyResponseUsageEnum.RESIDENTIAL;
        case r'COMMERCIAL': return PropertyResponseUsageEnum.COMMERCIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PropertyResponseUsageEnumTypeTransformer? _instance;
}


