//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UnitRequest {
  /// Returns a new [UnitRequest] instance.
  UnitRequest({
    required this.unitNumber,
    this.floor,
    this.sizeSqm,
    required this.rentalMode,
    this.capacity = 1,
  });

  String unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? floor;

  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? sizeSqm;

  UnitRequestRentalModeEnum rentalMode;

  /// Minimum value: 1
  int capacity;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnitRequest &&
    other.unitNumber == unitNumber &&
    other.floor == floor &&
    other.sizeSqm == sizeSqm &&
    other.rentalMode == rentalMode &&
    other.capacity == capacity;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (unitNumber.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (sizeSqm == null ? 0 : sizeSqm!.hashCode) +
    (rentalMode.hashCode) +
    (capacity.hashCode);

  @override
  String toString() => 'UnitRequest[unitNumber=$unitNumber, floor=$floor, sizeSqm=$sizeSqm, rentalMode=$rentalMode, capacity=$capacity]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'unitNumber'] = this.unitNumber;
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
      json[r'rentalMode'] = this.rentalMode;
      json[r'capacity'] = this.capacity;
    return json;
  }

  /// Returns a new [UnitRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnitRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'unitNumber'), 'Required key "UnitRequest[unitNumber]" is missing from JSON.');
        assert(json[r'unitNumber'] != null, 'Required key "UnitRequest[unitNumber]" has a null value in JSON.');
        assert(json.containsKey(r'rentalMode'), 'Required key "UnitRequest[rentalMode]" is missing from JSON.');
        assert(json[r'rentalMode'] != null, 'Required key "UnitRequest[rentalMode]" has a null value in JSON.');
        return true;
      }());

      return UnitRequest(
        unitNumber: mapValueOfType<String>(json, r'unitNumber')!,
        floor: mapValueOfType<String>(json, r'floor'),
        sizeSqm: json[r'sizeSqm'] == null
            ? null
            : num.parse('${json[r'sizeSqm']}'),
        rentalMode: UnitRequestRentalModeEnum.fromJson(json[r'rentalMode'])!,
        capacity: mapValueOfType<int>(json, r'capacity') ?? 1,
      );
    }
    return null;
  }

  static List<UnitRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnitRequest> mapFromJson(dynamic json) {
    final map = <String, UnitRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnitRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnitRequest-objects as value to a dart map
  static Map<String, List<UnitRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UnitRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnitRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'unitNumber',
    'rentalMode',
  };
}


enum UnitRequestRentalModeEnum {
  WHOLE_UNIT._(r'WHOLE_UNIT'),
  BEDSPACE._(r'BEDSPACE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UnitRequestRentalModeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UnitRequestRentalModeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UnitRequestRentalModeEnum? fromJson(dynamic value) => UnitRequestRentalModeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UnitRequestRentalModeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UnitRequestRentalModeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnitRequestRentalModeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnitRequestRentalModeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UnitRequestRentalModeEnum] to String,
/// and [decode] dynamic data back to [UnitRequestRentalModeEnum].
class UnitRequestRentalModeEnumTypeTransformer {
  factory UnitRequestRentalModeEnumTypeTransformer() => _instance ??= const UnitRequestRentalModeEnumTypeTransformer._();

  const UnitRequestRentalModeEnumTypeTransformer._();

  String encode(UnitRequestRentalModeEnum data) => data._value;

  /// Returns the instance of [UnitRequestRentalModeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UnitRequestRentalModeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UnitRequestRentalModeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WHOLE_UNIT': return UnitRequestRentalModeEnum.WHOLE_UNIT;
        case r'BEDSPACE': return UnitRequestRentalModeEnum.BEDSPACE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UnitRequestRentalModeEnumTypeTransformer? _instance;
}


