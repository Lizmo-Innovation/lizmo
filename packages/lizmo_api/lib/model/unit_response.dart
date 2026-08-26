//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UnitResponse {
  /// Returns a new [UnitResponse] instance.
  UnitResponse({
    this.id,
    this.propertyId,
    this.unitNumber,
    this.floor,
    this.sizeSqm,
    this.rentalMode,
    this.capacity,
    this.status,
    this.bedCount,
    this.bedsUnderMaintenance,
    this.rent,
    this.potentialMonthlyRent,
    this.monthlyUtilities,
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
  String? unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? floor;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? sizeSqm;

  UnitResponseRentalModeEnum? rentalMode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? capacity;

  UnitResponseStatusEnum? status;

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
  int? bedsUnderMaintenance;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rent;

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
  num? monthlyUtilities;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnitResponse &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.unitNumber == unitNumber &&
    other.floor == floor &&
    other.sizeSqm == sizeSqm &&
    other.rentalMode == rentalMode &&
    other.capacity == capacity &&
    other.status == status &&
    other.bedCount == bedCount &&
    other.bedsUnderMaintenance == bedsUnderMaintenance &&
    other.rent == rent &&
    other.potentialMonthlyRent == potentialMonthlyRent &&
    other.monthlyUtilities == monthlyUtilities;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (sizeSqm == null ? 0 : sizeSqm!.hashCode) +
    (rentalMode == null ? 0 : rentalMode!.hashCode) +
    (capacity == null ? 0 : capacity!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (bedCount == null ? 0 : bedCount!.hashCode) +
    (bedsUnderMaintenance == null ? 0 : bedsUnderMaintenance!.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (potentialMonthlyRent == null ? 0 : potentialMonthlyRent!.hashCode) +
    (monthlyUtilities == null ? 0 : monthlyUtilities!.hashCode);

  @override
  String toString() => 'UnitResponse[id=$id, propertyId=$propertyId, unitNumber=$unitNumber, floor=$floor, sizeSqm=$sizeSqm, rentalMode=$rentalMode, capacity=$capacity, status=$status, bedCount=$bedCount, bedsUnderMaintenance=$bedsUnderMaintenance, rent=$rent, potentialMonthlyRent=$potentialMonthlyRent, monthlyUtilities=$monthlyUtilities]';

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
    if (this.sizeSqm != null) {
      json[r'sizeSqm'] = this.sizeSqm;
    } else {
      json[r'sizeSqm'] = null;
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
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.bedCount != null) {
      json[r'bedCount'] = this.bedCount;
    } else {
      json[r'bedCount'] = null;
    }
    if (this.bedsUnderMaintenance != null) {
      json[r'bedsUnderMaintenance'] = this.bedsUnderMaintenance;
    } else {
      json[r'bedsUnderMaintenance'] = null;
    }
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
    if (this.potentialMonthlyRent != null) {
      json[r'potentialMonthlyRent'] = this.potentialMonthlyRent;
    } else {
      json[r'potentialMonthlyRent'] = null;
    }
    if (this.monthlyUtilities != null) {
      json[r'monthlyUtilities'] = this.monthlyUtilities;
    } else {
      json[r'monthlyUtilities'] = null;
    }
    return json;
  }

  /// Returns a new [UnitResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnitResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UnitResponse(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        floor: mapValueOfType<String>(json, r'floor'),
        sizeSqm: json[r'sizeSqm'] == null
            ? null
            : num.parse('${json[r'sizeSqm']}'),
        rentalMode: UnitResponseRentalModeEnum.fromJson(json[r'rentalMode']),
        capacity: mapValueOfType<int>(json, r'capacity'),
        status: UnitResponseStatusEnum.fromJson(json[r'status']),
        bedCount: mapValueOfType<int>(json, r'bedCount'),
        bedsUnderMaintenance: mapValueOfType<int>(json, r'bedsUnderMaintenance'),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
        potentialMonthlyRent: json[r'potentialMonthlyRent'] == null
            ? null
            : num.parse('${json[r'potentialMonthlyRent']}'),
        monthlyUtilities: json[r'monthlyUtilities'] == null
            ? null
            : num.parse('${json[r'monthlyUtilities']}'),
      );
    }
    return null;
  }

  static List<UnitResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnitResponse> mapFromJson(dynamic json) {
    final map = <String, UnitResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnitResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnitResponse-objects as value to a dart map
  static Map<String, List<UnitResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UnitResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnitResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum UnitResponseRentalModeEnum {
  WHOLE_UNIT._(r'WHOLE_UNIT'),
  BEDSPACE._(r'BEDSPACE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UnitResponseRentalModeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UnitResponseRentalModeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UnitResponseRentalModeEnum? fromJson(dynamic value) => UnitResponseRentalModeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UnitResponseRentalModeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UnitResponseRentalModeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitResponseRentalModeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitResponseRentalModeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UnitResponseRentalModeEnum] to String,
/// and [decode] dynamic data back to [UnitResponseRentalModeEnum].
class UnitResponseRentalModeEnumTypeTransformer {
  factory UnitResponseRentalModeEnumTypeTransformer() => _instance ??= const UnitResponseRentalModeEnumTypeTransformer._();

  const UnitResponseRentalModeEnumTypeTransformer._();

  String encode(UnitResponseRentalModeEnum data) => data._value;

  /// Returns the instance of [UnitResponseRentalModeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UnitResponseRentalModeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UnitResponseRentalModeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WHOLE_UNIT': return UnitResponseRentalModeEnum.WHOLE_UNIT;
        case r'BEDSPACE': return UnitResponseRentalModeEnum.BEDSPACE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UnitResponseRentalModeEnumTypeTransformer? _instance;
}



enum UnitResponseStatusEnum {
  VACANT._(r'VACANT'),
  PARTIALLY_OCCUPIED._(r'PARTIALLY_OCCUPIED'),
  OCCUPIED._(r'OCCUPIED'),
  MAINTENANCE._(r'MAINTENANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UnitResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UnitResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UnitResponseStatusEnum? fromJson(dynamic value) => UnitResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UnitResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UnitResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UnitResponseStatusEnum] to String,
/// and [decode] dynamic data back to [UnitResponseStatusEnum].
class UnitResponseStatusEnumTypeTransformer {
  factory UnitResponseStatusEnumTypeTransformer() => _instance ??= const UnitResponseStatusEnumTypeTransformer._();

  const UnitResponseStatusEnumTypeTransformer._();

  String encode(UnitResponseStatusEnum data) => data._value;

  /// Returns the instance of [UnitResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UnitResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UnitResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'VACANT': return UnitResponseStatusEnum.VACANT;
        case r'PARTIALLY_OCCUPIED': return UnitResponseStatusEnum.PARTIALLY_OCCUPIED;
        case r'OCCUPIED': return UnitResponseStatusEnum.OCCUPIED;
        case r'MAINTENANCE': return UnitResponseStatusEnum.MAINTENANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UnitResponseStatusEnumTypeTransformer? _instance;
}


