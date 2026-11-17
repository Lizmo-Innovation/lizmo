//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UnitOverview {
  /// Returns a new [UnitOverview] instance.
  UnitOverview({
    this.id,
    this.unitNumber,
    this.floor,
    this.rentalMode,
    this.status,
    this.rent,
    this.beds = const [],
    this.tenantName,
    this.readyFrom,
    this.overdueTenancies,
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

  UnitOverviewRentalModeEnum? rentalMode;

  UnitOverviewStatusEnum? status;

  /// Per bed for a bedspace room, for the unit otherwise
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rent;

  /// Each rentable bed, let or not. Empty for a whole unit
  List<BedState> beds;

  /// Who a whole unit is let to, when it is
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantName;

  /// When its vacant space is ready, if not now
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? readyFrom;

  /// Tenancies in it with rent owed late
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? overdueTenancies;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnitOverview &&
    other.id == id &&
    other.unitNumber == unitNumber &&
    other.floor == floor &&
    other.rentalMode == rentalMode &&
    other.status == status &&
    other.rent == rent &&
    _deepEquality.equals(other.beds, beds) &&
    other.tenantName == tenantName &&
    other.readyFrom == readyFrom &&
    other.overdueTenancies == overdueTenancies;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (rentalMode == null ? 0 : rentalMode!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (beds.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (readyFrom == null ? 0 : readyFrom!.hashCode) +
    (overdueTenancies == null ? 0 : overdueTenancies!.hashCode);

  @override
  String toString() => 'UnitOverview[id=$id, unitNumber=$unitNumber, floor=$floor, rentalMode=$rentalMode, status=$status, rent=$rent, beds=$beds, tenantName=$tenantName, readyFrom=$readyFrom, overdueTenancies=$overdueTenancies]';

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
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
      json[r'beds'] = this.beds;
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
    }
    if (this.readyFrom != null) {
      json[r'readyFrom'] = _dateFormatter.format(this.readyFrom!);
    } else {
      json[r'readyFrom'] = null;
    }
    if (this.overdueTenancies != null) {
      json[r'overdueTenancies'] = this.overdueTenancies;
    } else {
      json[r'overdueTenancies'] = null;
    }
    return json;
  }

  /// Returns a new [UnitOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnitOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UnitOverview(
        id: mapValueOfType<String>(json, r'id'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        floor: mapValueOfType<String>(json, r'floor'),
        rentalMode: UnitOverviewRentalModeEnum.fromJson(json[r'rentalMode']),
        status: UnitOverviewStatusEnum.fromJson(json[r'status']),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
        beds: BedState.listFromJson(json[r'beds']),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        readyFrom: mapDateTime(json, r'readyFrom', r''),
        overdueTenancies: mapValueOfType<int>(json, r'overdueTenancies'),
      );
    }
    return null;
  }

  static List<UnitOverview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnitOverview> mapFromJson(dynamic json) {
    final map = <String, UnitOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnitOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnitOverview-objects as value to a dart map
  static Map<String, List<UnitOverview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UnitOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnitOverview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum UnitOverviewRentalModeEnum {
  WHOLE_UNIT._(r'WHOLE_UNIT'),
  BEDSPACE._(r'BEDSPACE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UnitOverviewRentalModeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UnitOverviewRentalModeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UnitOverviewRentalModeEnum? fromJson(dynamic value) => UnitOverviewRentalModeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UnitOverviewRentalModeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UnitOverviewRentalModeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitOverviewRentalModeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitOverviewRentalModeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UnitOverviewRentalModeEnum] to String,
/// and [decode] dynamic data back to [UnitOverviewRentalModeEnum].
class UnitOverviewRentalModeEnumTypeTransformer {
  factory UnitOverviewRentalModeEnumTypeTransformer() => _instance ??= const UnitOverviewRentalModeEnumTypeTransformer._();

  const UnitOverviewRentalModeEnumTypeTransformer._();

  String encode(UnitOverviewRentalModeEnum data) => data._value;

  /// Returns the instance of [UnitOverviewRentalModeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UnitOverviewRentalModeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UnitOverviewRentalModeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WHOLE_UNIT': return UnitOverviewRentalModeEnum.WHOLE_UNIT;
        case r'BEDSPACE': return UnitOverviewRentalModeEnum.BEDSPACE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UnitOverviewRentalModeEnumTypeTransformer? _instance;
}



enum UnitOverviewStatusEnum {
  VACANT._(r'VACANT'),
  PARTIALLY_OCCUPIED._(r'PARTIALLY_OCCUPIED'),
  OCCUPIED._(r'OCCUPIED'),
  MAINTENANCE._(r'MAINTENANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UnitOverviewStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UnitOverviewStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UnitOverviewStatusEnum? fromJson(dynamic value) => UnitOverviewStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UnitOverviewStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UnitOverviewStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitOverviewStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitOverviewStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UnitOverviewStatusEnum] to String,
/// and [decode] dynamic data back to [UnitOverviewStatusEnum].
class UnitOverviewStatusEnumTypeTransformer {
  factory UnitOverviewStatusEnumTypeTransformer() => _instance ??= const UnitOverviewStatusEnumTypeTransformer._();

  const UnitOverviewStatusEnumTypeTransformer._();

  String encode(UnitOverviewStatusEnum data) => data._value;

  /// Returns the instance of [UnitOverviewStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UnitOverviewStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UnitOverviewStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'VACANT': return UnitOverviewStatusEnum.VACANT;
        case r'PARTIALLY_OCCUPIED': return UnitOverviewStatusEnum.PARTIALLY_OCCUPIED;
        case r'OCCUPIED': return UnitOverviewStatusEnum.OCCUPIED;
        case r'MAINTENANCE': return UnitOverviewStatusEnum.MAINTENANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UnitOverviewStatusEnumTypeTransformer? _instance;
}


