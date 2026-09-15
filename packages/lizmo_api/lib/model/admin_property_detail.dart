//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminPropertyDetail {
  /// Returns a new [AdminPropertyDetail] instance.
  AdminPropertyDetail({
    this.id,
    this.name,
    this.address,
    this.type,
    this.usage,
    this.code,
    this.accountStatus,
    this.landlordId,
    this.landlordName,
    this.unitCount,
    this.bedCount,
    this.leased,
    this.outOfService,
    this.units = const [],
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

  AdminPropertyDetailTypeEnum? type;

  AdminPropertyDetailUsageEnum? usage;

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
  String? accountStatus;

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
  int? unitCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? bedCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? leased;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? outOfService;

  List<AdminPropertyUnit> units;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminPropertyDetail &&
    other.id == id &&
    other.name == name &&
    other.address == address &&
    other.type == type &&
    other.usage == usage &&
    other.code == code &&
    other.accountStatus == accountStatus &&
    other.landlordId == landlordId &&
    other.landlordName == landlordName &&
    other.unitCount == unitCount &&
    other.bedCount == bedCount &&
    other.leased == leased &&
    other.outOfService == outOfService &&
    _deepEquality.equals(other.units, units);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (usage == null ? 0 : usage!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (accountStatus == null ? 0 : accountStatus!.hashCode) +
    (landlordId == null ? 0 : landlordId!.hashCode) +
    (landlordName == null ? 0 : landlordName!.hashCode) +
    (unitCount == null ? 0 : unitCount!.hashCode) +
    (bedCount == null ? 0 : bedCount!.hashCode) +
    (leased == null ? 0 : leased!.hashCode) +
    (outOfService == null ? 0 : outOfService!.hashCode) +
    (units.hashCode);

  @override
  String toString() => 'AdminPropertyDetail[id=$id, name=$name, address=$address, type=$type, usage=$usage, code=$code, accountStatus=$accountStatus, landlordId=$landlordId, landlordName=$landlordName, unitCount=$unitCount, bedCount=$bedCount, leased=$leased, outOfService=$outOfService, units=$units]';

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
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
    if (this.accountStatus != null) {
      json[r'accountStatus'] = this.accountStatus;
    } else {
      json[r'accountStatus'] = null;
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
    if (this.unitCount != null) {
      json[r'unitCount'] = this.unitCount;
    } else {
      json[r'unitCount'] = null;
    }
    if (this.bedCount != null) {
      json[r'bedCount'] = this.bedCount;
    } else {
      json[r'bedCount'] = null;
    }
    if (this.leased != null) {
      json[r'leased'] = this.leased;
    } else {
      json[r'leased'] = null;
    }
    if (this.outOfService != null) {
      json[r'outOfService'] = this.outOfService;
    } else {
      json[r'outOfService'] = null;
    }
      json[r'units'] = this.units;
    return json;
  }

  /// Returns a new [AdminPropertyDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminPropertyDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AdminPropertyDetail(
        id: mapValueOfType<String>(json, r'id'),
        name: mapValueOfType<String>(json, r'name'),
        address: mapValueOfType<String>(json, r'address'),
        type: AdminPropertyDetailTypeEnum.fromJson(json[r'type']),
        usage: AdminPropertyDetailUsageEnum.fromJson(json[r'usage']),
        code: mapValueOfType<String>(json, r'code'),
        accountStatus: mapValueOfType<String>(json, r'accountStatus'),
        landlordId: mapValueOfType<String>(json, r'landlordId'),
        landlordName: mapValueOfType<String>(json, r'landlordName'),
        unitCount: mapValueOfType<int>(json, r'unitCount'),
        bedCount: mapValueOfType<int>(json, r'bedCount'),
        leased: mapValueOfType<int>(json, r'leased'),
        outOfService: mapValueOfType<int>(json, r'outOfService'),
        units: AdminPropertyUnit.listFromJson(json[r'units']),
      );
    }
    return null;
  }

  static List<AdminPropertyDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminPropertyDetail> mapFromJson(dynamic json) {
    final map = <String, AdminPropertyDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminPropertyDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminPropertyDetail-objects as value to a dart map
  static Map<String, List<AdminPropertyDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminPropertyDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminPropertyDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum AdminPropertyDetailTypeEnum {
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
  const AdminPropertyDetailTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AdminPropertyDetailTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AdminPropertyDetailTypeEnum? fromJson(dynamic value) => AdminPropertyDetailTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AdminPropertyDetailTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AdminPropertyDetailTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyDetailTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyDetailTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AdminPropertyDetailTypeEnum] to String,
/// and [decode] dynamic data back to [AdminPropertyDetailTypeEnum].
class AdminPropertyDetailTypeEnumTypeTransformer {
  factory AdminPropertyDetailTypeEnumTypeTransformer() => _instance ??= const AdminPropertyDetailTypeEnumTypeTransformer._();

  const AdminPropertyDetailTypeEnumTypeTransformer._();

  String encode(AdminPropertyDetailTypeEnum data) => data._value;

  /// Returns the instance of [AdminPropertyDetailTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AdminPropertyDetailTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AdminPropertyDetailTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'APARTMENT': return AdminPropertyDetailTypeEnum.APARTMENT;
        case r'BOARDING_HOUSE': return AdminPropertyDetailTypeEnum.BOARDING_HOUSE;
        case r'CONDO': return AdminPropertyDetailTypeEnum.CONDO;
        case r'SINGLE_HOUSE': return AdminPropertyDetailTypeEnum.SINGLE_HOUSE;
        case r'OFFICE': return AdminPropertyDetailTypeEnum.OFFICE;
        case r'RETAIL_SPACE': return AdminPropertyDetailTypeEnum.RETAIL_SPACE;
        case r'WAREHOUSE': return AdminPropertyDetailTypeEnum.WAREHOUSE;
        case r'STALL': return AdminPropertyDetailTypeEnum.STALL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AdminPropertyDetailTypeEnumTypeTransformer? _instance;
}



enum AdminPropertyDetailUsageEnum {
  RESIDENTIAL._(r'RESIDENTIAL'),
  COMMERCIAL._(r'COMMERCIAL'),
  ;

  /// Instantiate a new enum with the provided value.
  const AdminPropertyDetailUsageEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AdminPropertyDetailUsageEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AdminPropertyDetailUsageEnum? fromJson(dynamic value) => AdminPropertyDetailUsageEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AdminPropertyDetailUsageEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AdminPropertyDetailUsageEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyDetailUsageEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyDetailUsageEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AdminPropertyDetailUsageEnum] to String,
/// and [decode] dynamic data back to [AdminPropertyDetailUsageEnum].
class AdminPropertyDetailUsageEnumTypeTransformer {
  factory AdminPropertyDetailUsageEnumTypeTransformer() => _instance ??= const AdminPropertyDetailUsageEnumTypeTransformer._();

  const AdminPropertyDetailUsageEnumTypeTransformer._();

  String encode(AdminPropertyDetailUsageEnum data) => data._value;

  /// Returns the instance of [AdminPropertyDetailUsageEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AdminPropertyDetailUsageEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AdminPropertyDetailUsageEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RESIDENTIAL': return AdminPropertyDetailUsageEnum.RESIDENTIAL;
        case r'COMMERCIAL': return AdminPropertyDetailUsageEnum.COMMERCIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AdminPropertyDetailUsageEnumTypeTransformer? _instance;
}


