//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminPropertyBed {
  /// Returns a new [AdminPropertyBed] instance.
  AdminPropertyBed({
    this.id,
    this.label,
    this.rent,
    this.occupancy,
    this.tenancy,
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
  String? label;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rent;

  AdminPropertyBedOccupancyEnum? occupancy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AdminPropertyTenancy? tenancy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminPropertyBed &&
    other.id == id &&
    other.label == label &&
    other.rent == rent &&
    other.occupancy == occupancy &&
    other.tenancy == tenancy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (occupancy == null ? 0 : occupancy!.hashCode) +
    (tenancy == null ? 0 : tenancy!.hashCode);

  @override
  String toString() => 'AdminPropertyBed[id=$id, label=$label, rent=$rent, occupancy=$occupancy, tenancy=$tenancy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
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
    return json;
  }

  /// Returns a new [AdminPropertyBed] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminPropertyBed? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AdminPropertyBed(
        id: mapValueOfType<String>(json, r'id'),
        label: mapValueOfType<String>(json, r'label'),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
        occupancy: AdminPropertyBedOccupancyEnum.fromJson(json[r'occupancy']),
        tenancy: AdminPropertyTenancy.fromJson(json[r'tenancy']),
      );
    }
    return null;
  }

  static List<AdminPropertyBed> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyBed>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyBed.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminPropertyBed> mapFromJson(dynamic json) {
    final map = <String, AdminPropertyBed>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminPropertyBed.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminPropertyBed-objects as value to a dart map
  static Map<String, List<AdminPropertyBed>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminPropertyBed>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminPropertyBed.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum AdminPropertyBedOccupancyEnum {
  LEASED._(r'LEASED'),
  PARTLY_LEASED._(r'PARTLY_LEASED'),
  VACANT._(r'VACANT'),
  OUT_OF_SERVICE._(r'OUT_OF_SERVICE'),
  ;

  /// Instantiate a new enum with the provided value.
  const AdminPropertyBedOccupancyEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AdminPropertyBedOccupancyEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AdminPropertyBedOccupancyEnum? fromJson(dynamic value) => AdminPropertyBedOccupancyEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AdminPropertyBedOccupancyEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AdminPropertyBedOccupancyEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyBedOccupancyEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyBedOccupancyEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AdminPropertyBedOccupancyEnum] to String,
/// and [decode] dynamic data back to [AdminPropertyBedOccupancyEnum].
class AdminPropertyBedOccupancyEnumTypeTransformer {
  factory AdminPropertyBedOccupancyEnumTypeTransformer() => _instance ??= const AdminPropertyBedOccupancyEnumTypeTransformer._();

  const AdminPropertyBedOccupancyEnumTypeTransformer._();

  String encode(AdminPropertyBedOccupancyEnum data) => data._value;

  /// Returns the instance of [AdminPropertyBedOccupancyEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AdminPropertyBedOccupancyEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AdminPropertyBedOccupancyEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'LEASED': return AdminPropertyBedOccupancyEnum.LEASED;
        case r'PARTLY_LEASED': return AdminPropertyBedOccupancyEnum.PARTLY_LEASED;
        case r'VACANT': return AdminPropertyBedOccupancyEnum.VACANT;
        case r'OUT_OF_SERVICE': return AdminPropertyBedOccupancyEnum.OUT_OF_SERVICE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AdminPropertyBedOccupancyEnumTypeTransformer? _instance;
}


