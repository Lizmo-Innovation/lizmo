//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminPropertyUnit {
  /// Returns a new [AdminPropertyUnit] instance.
  AdminPropertyUnit({
    this.id,
    this.unitNumber,
    this.floor,
    this.rentalMode,
    this.capacity,
    this.rent,
    this.occupancy,
    this.tenancy,
    this.beds = const [],
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
  String? unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? floor;

  AdminPropertyUnitRentalModeEnum? rentalMode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? capacity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rent;

  AdminPropertyUnitOccupancyEnum? occupancy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AdminPropertyTenancy? tenancy;

  List<AdminPropertyBed> beds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminPropertyUnit &&
    other.id == id &&
    other.unitNumber == unitNumber &&
    other.floor == floor &&
    other.rentalMode == rentalMode &&
    other.capacity == capacity &&
    other.rent == rent &&
    other.occupancy == occupancy &&
    other.tenancy == tenancy &&
    _deepEquality.equals(other.beds, beds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (rentalMode == null ? 0 : rentalMode!.hashCode) +
    (capacity == null ? 0 : capacity!.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (occupancy == null ? 0 : occupancy!.hashCode) +
    (tenancy == null ? 0 : tenancy!.hashCode) +
    (beds.hashCode);

  @override
  String toString() => 'AdminPropertyUnit[id=$id, unitNumber=$unitNumber, floor=$floor, rentalMode=$rentalMode, capacity=$capacity, rent=$rent, occupancy=$occupancy, tenancy=$tenancy, beds=$beds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.floor != null) {
      json[r'floor'] = this.floor;
    } else {
      json[r'floor'] = null;
    }
    if (this.rentalMode != null) {
      json[r'rentalMode'] = this.rentalMode;
    } else {
      json[r'rentalMode'] = null;
    }
    if (this.capacity != null) {
      json[r'capacity'] = this.capacity;
    } else {
      json[r'capacity'] = null;
    }
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
    if (this.occupancy != null) {
      json[r'occupancy'] = this.occupancy;
    } else {
      json[r'occupancy'] = null;
    }
    if (this.tenancy != null) {
      json[r'tenancy'] = this.tenancy;
    } else {
      json[r'tenancy'] = null;
    }
      json[r'beds'] = this.beds;
    return json;
  }

  /// Returns a new [AdminPropertyUnit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminPropertyUnit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AdminPropertyUnit(
        id: mapValueOfType<String>(json, r'id'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        floor: mapValueOfType<String>(json, r'floor'),
        rentalMode: AdminPropertyUnitRentalModeEnum.fromJson(json[r'rentalMode']),
        capacity: mapValueOfType<int>(json, r'capacity'),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
        occupancy: AdminPropertyUnitOccupancyEnum.fromJson(json[r'occupancy']),
        tenancy: AdminPropertyTenancy.fromJson(json[r'tenancy']),
        beds: AdminPropertyBed.listFromJson(json[r'beds']),
      );
    }
    return null;
  }

  static List<AdminPropertyUnit> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyUnit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyUnit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminPropertyUnit> mapFromJson(dynamic json) {
    final map = <String, AdminPropertyUnit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminPropertyUnit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminPropertyUnit-objects as value to a dart map
  static Map<String, List<AdminPropertyUnit>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminPropertyUnit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminPropertyUnit.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum AdminPropertyUnitRentalModeEnum {
  WHOLE_UNIT._(r'WHOLE_UNIT'),
  BEDSPACE._(r'BEDSPACE'),
  ;

  /// Instantiate a new enum with the provided value.
  const AdminPropertyUnitRentalModeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AdminPropertyUnitRentalModeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AdminPropertyUnitRentalModeEnum? fromJson(dynamic value) => AdminPropertyUnitRentalModeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AdminPropertyUnitRentalModeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AdminPropertyUnitRentalModeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyUnitRentalModeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyUnitRentalModeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AdminPropertyUnitRentalModeEnum] to String,
/// and [decode] dynamic data back to [AdminPropertyUnitRentalModeEnum].
class AdminPropertyUnitRentalModeEnumTypeTransformer {
  factory AdminPropertyUnitRentalModeEnumTypeTransformer() => _instance ??= const AdminPropertyUnitRentalModeEnumTypeTransformer._();

  const AdminPropertyUnitRentalModeEnumTypeTransformer._();

  String encode(AdminPropertyUnitRentalModeEnum data) => data._value;

  /// Returns the instance of [AdminPropertyUnitRentalModeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AdminPropertyUnitRentalModeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AdminPropertyUnitRentalModeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WHOLE_UNIT': return AdminPropertyUnitRentalModeEnum.WHOLE_UNIT;
        case r'BEDSPACE': return AdminPropertyUnitRentalModeEnum.BEDSPACE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AdminPropertyUnitRentalModeEnumTypeTransformer? _instance;
}



enum AdminPropertyUnitOccupancyEnum {
  LEASED._(r'LEASED'),
  PARTLY_LEASED._(r'PARTLY_LEASED'),
  VACANT._(r'VACANT'),
  OUT_OF_SERVICE._(r'OUT_OF_SERVICE'),
  ;

  /// Instantiate a new enum with the provided value.
  const AdminPropertyUnitOccupancyEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AdminPropertyUnitOccupancyEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AdminPropertyUnitOccupancyEnum? fromJson(dynamic value) => AdminPropertyUnitOccupancyEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AdminPropertyUnitOccupancyEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AdminPropertyUnitOccupancyEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyUnitOccupancyEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyUnitOccupancyEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AdminPropertyUnitOccupancyEnum] to String,
/// and [decode] dynamic data back to [AdminPropertyUnitOccupancyEnum].
class AdminPropertyUnitOccupancyEnumTypeTransformer {
  factory AdminPropertyUnitOccupancyEnumTypeTransformer() => _instance ??= const AdminPropertyUnitOccupancyEnumTypeTransformer._();

  const AdminPropertyUnitOccupancyEnumTypeTransformer._();

  String encode(AdminPropertyUnitOccupancyEnum data) => data._value;

  /// Returns the instance of [AdminPropertyUnitOccupancyEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AdminPropertyUnitOccupancyEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AdminPropertyUnitOccupancyEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'LEASED': return AdminPropertyUnitOccupancyEnum.LEASED;
        case r'PARTLY_LEASED': return AdminPropertyUnitOccupancyEnum.PARTLY_LEASED;
        case r'VACANT': return AdminPropertyUnitOccupancyEnum.VACANT;
        case r'OUT_OF_SERVICE': return AdminPropertyUnitOccupancyEnum.OUT_OF_SERVICE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AdminPropertyUnitOccupancyEnumTypeTransformer? _instance;
}


