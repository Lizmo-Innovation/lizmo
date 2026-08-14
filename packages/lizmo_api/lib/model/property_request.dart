//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PropertyRequest {
  /// Returns a new [PropertyRequest] instance.
  PropertyRequest({
    required this.name,
    required this.address,
    required this.type,
  });

  String name;

  String address;

  PropertyRequestTypeEnum type;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyRequest &&
    other.name == name &&
    other.address == address &&
    other.type == type;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (address.hashCode) +
    (type.hashCode);

  @override
  String toString() => 'PropertyRequest[name=$name, address=$address, type=$type]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'address'] = this.address;
      json[r'type'] = this.type;
    return json;
  }

  /// Returns a new [PropertyRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "PropertyRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "PropertyRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'address'), 'Required key "PropertyRequest[address]" is missing from JSON.');
        assert(json[r'address'] != null, 'Required key "PropertyRequest[address]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "PropertyRequest[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "PropertyRequest[type]" has a null value in JSON.');
        return true;
      }());

      return PropertyRequest(
        name: mapValueOfType<String>(json, r'name')!,
        address: mapValueOfType<String>(json, r'address')!,
        type: PropertyRequestTypeEnum.fromJson(json[r'type'])!,
      );
    }
    return null;
  }

  static List<PropertyRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyRequest> mapFromJson(dynamic json) {
    final map = <String, PropertyRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyRequest-objects as value to a dart map
  static Map<String, List<PropertyRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'address',
    'type',
  };
}


enum PropertyRequestTypeEnum {
  APARTMENT._(r'APARTMENT'),
  BOARDING_HOUSE._(r'BOARDING_HOUSE'),
  CONDO._(r'CONDO'),
  SINGLE_HOUSE._(r'SINGLE_HOUSE'),
  ;

  /// Instantiate a new enum with the provided value.
  const PropertyRequestTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PropertyRequestTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PropertyRequestTypeEnum? fromJson(dynamic value) => PropertyRequestTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PropertyRequestTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PropertyRequestTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyRequestTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyRequestTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PropertyRequestTypeEnum] to String,
/// and [decode] dynamic data back to [PropertyRequestTypeEnum].
class PropertyRequestTypeEnumTypeTransformer {
  factory PropertyRequestTypeEnumTypeTransformer() => _instance ??= const PropertyRequestTypeEnumTypeTransformer._();

  const PropertyRequestTypeEnumTypeTransformer._();

  String encode(PropertyRequestTypeEnum data) => data._value;

  /// Returns the instance of [PropertyRequestTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PropertyRequestTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PropertyRequestTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'APARTMENT': return PropertyRequestTypeEnum.APARTMENT;
        case r'BOARDING_HOUSE': return PropertyRequestTypeEnum.BOARDING_HOUSE;
        case r'CONDO': return PropertyRequestTypeEnum.CONDO;
        case r'SINGLE_HOUSE': return PropertyRequestTypeEnum.SINGLE_HOUSE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PropertyRequestTypeEnumTypeTransformer? _instance;
}


