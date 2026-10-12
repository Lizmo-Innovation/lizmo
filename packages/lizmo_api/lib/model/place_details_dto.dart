//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlaceDetailsDto {
  /// Returns a new [PlaceDetailsDto] instance.
  PlaceDetailsDto({
    this.whoCanRent,
    this.curfew,
    this.visitors,
    this.cooking,
    this.pets,
    this.smoking,
    this.otherRules,
    this.depositMonths,
    this.advanceMonths,
    this.amenities = const [],
  });

  /// Who the place lets to
  PlaceDetailsDtoWhoCanRentEnum? whoCanRent;

  /// Null for no curfew said
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? curfew;

  PlaceDetailsDtoVisitorsEnum? visitors;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? cooking;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? pets;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? smoking;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? otherRules;

  /// The deposit, in months of the room's rent
  ///
  /// Minimum value: 0
  /// Maximum value: 6
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? depositMonths;

  /// Rent paid ahead, in months
  ///
  /// Minimum value: 0
  /// Maximum value: 6
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? advanceMonths;

  List<PlaceDetailsDtoAmenitiesEnum> amenities;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlaceDetailsDto &&
    other.whoCanRent == whoCanRent &&
    other.curfew == curfew &&
    other.visitors == visitors &&
    other.cooking == cooking &&
    other.pets == pets &&
    other.smoking == smoking &&
    other.otherRules == otherRules &&
    other.depositMonths == depositMonths &&
    other.advanceMonths == advanceMonths &&
    _deepEquality.equals(other.amenities, amenities);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (whoCanRent == null ? 0 : whoCanRent!.hashCode) +
    (curfew == null ? 0 : curfew!.hashCode) +
    (visitors == null ? 0 : visitors!.hashCode) +
    (cooking == null ? 0 : cooking!.hashCode) +
    (pets == null ? 0 : pets!.hashCode) +
    (smoking == null ? 0 : smoking!.hashCode) +
    (otherRules == null ? 0 : otherRules!.hashCode) +
    (depositMonths == null ? 0 : depositMonths!.hashCode) +
    (advanceMonths == null ? 0 : advanceMonths!.hashCode) +
    (amenities.hashCode);

  @override
  String toString() => 'PlaceDetailsDto[whoCanRent=$whoCanRent, curfew=$curfew, visitors=$visitors, cooking=$cooking, pets=$pets, smoking=$smoking, otherRules=$otherRules, depositMonths=$depositMonths, advanceMonths=$advanceMonths, amenities=$amenities]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.whoCanRent != null) {
      json[r'whoCanRent'] = this.whoCanRent;
    } else {
      json[r'whoCanRent'] = null;
    }
    if (this.curfew != null) {
      json[r'curfew'] = this.curfew;
    } else {
      json[r'curfew'] = null;
    }
    if (this.visitors != null) {
      json[r'visitors'] = this.visitors;
    } else {
      json[r'visitors'] = null;
    }
    if (this.cooking != null) {
      json[r'cooking'] = this.cooking;
    } else {
      json[r'cooking'] = null;
    }
    if (this.pets != null) {
      json[r'pets'] = this.pets;
    } else {
      json[r'pets'] = null;
    }
    if (this.smoking != null) {
      json[r'smoking'] = this.smoking;
    } else {
      json[r'smoking'] = null;
    }
    if (this.otherRules != null) {
      json[r'otherRules'] = this.otherRules;
    } else {
      json[r'otherRules'] = null;
    }
    if (this.depositMonths != null) {
      json[r'depositMonths'] = this.depositMonths;
    } else {
      json[r'depositMonths'] = null;
    }
    if (this.advanceMonths != null) {
      json[r'advanceMonths'] = this.advanceMonths;
    } else {
      json[r'advanceMonths'] = null;
    }
      json[r'amenities'] = this.amenities;
    return json;
  }

  /// Returns a new [PlaceDetailsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlaceDetailsDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PlaceDetailsDto(
        whoCanRent: PlaceDetailsDtoWhoCanRentEnum.fromJson(json[r'whoCanRent']),
        curfew: mapValueOfType<String>(json, r'curfew'),
        visitors: PlaceDetailsDtoVisitorsEnum.fromJson(json[r'visitors']),
        cooking: mapValueOfType<bool>(json, r'cooking'),
        pets: mapValueOfType<bool>(json, r'pets'),
        smoking: mapValueOfType<bool>(json, r'smoking'),
        otherRules: mapValueOfType<String>(json, r'otherRules'),
        depositMonths: mapValueOfType<int>(json, r'depositMonths'),
        advanceMonths: mapValueOfType<int>(json, r'advanceMonths'),
        amenities: PlaceDetailsDtoAmenitiesEnum.listFromJson(json[r'amenities']),
      );
    }
    return null;
  }

  static List<PlaceDetailsDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlaceDetailsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlaceDetailsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlaceDetailsDto> mapFromJson(dynamic json) {
    final map = <String, PlaceDetailsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlaceDetailsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlaceDetailsDto-objects as value to a dart map
  static Map<String, List<PlaceDetailsDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlaceDetailsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlaceDetailsDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

/// Who the place lets to
enum PlaceDetailsDtoWhoCanRentEnum {
  ANYONE._(r'ANYONE'),
  WOMEN._(r'WOMEN'),
  MEN._(r'MEN'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlaceDetailsDtoWhoCanRentEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlaceDetailsDtoWhoCanRentEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlaceDetailsDtoWhoCanRentEnum? fromJson(dynamic value) => PlaceDetailsDtoWhoCanRentEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlaceDetailsDtoWhoCanRentEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlaceDetailsDtoWhoCanRentEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlaceDetailsDtoWhoCanRentEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlaceDetailsDtoWhoCanRentEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlaceDetailsDtoWhoCanRentEnum] to String,
/// and [decode] dynamic data back to [PlaceDetailsDtoWhoCanRentEnum].
class PlaceDetailsDtoWhoCanRentEnumTypeTransformer {
  factory PlaceDetailsDtoWhoCanRentEnumTypeTransformer() => _instance ??= const PlaceDetailsDtoWhoCanRentEnumTypeTransformer._();

  const PlaceDetailsDtoWhoCanRentEnumTypeTransformer._();

  String encode(PlaceDetailsDtoWhoCanRentEnum data) => data._value;

  /// Returns the instance of [PlaceDetailsDtoWhoCanRentEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlaceDetailsDtoWhoCanRentEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlaceDetailsDtoWhoCanRentEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ANYONE': return PlaceDetailsDtoWhoCanRentEnum.ANYONE;
        case r'WOMEN': return PlaceDetailsDtoWhoCanRentEnum.WOMEN;
        case r'MEN': return PlaceDetailsDtoWhoCanRentEnum.MEN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlaceDetailsDtoWhoCanRentEnumTypeTransformer? _instance;
}



enum PlaceDetailsDtoVisitorsEnum {
  ALLOWED._(r'ALLOWED'),
  DAYTIME._(r'DAYTIME'),
  NONE._(r'NONE'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlaceDetailsDtoVisitorsEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlaceDetailsDtoVisitorsEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlaceDetailsDtoVisitorsEnum? fromJson(dynamic value) => PlaceDetailsDtoVisitorsEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlaceDetailsDtoVisitorsEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlaceDetailsDtoVisitorsEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlaceDetailsDtoVisitorsEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlaceDetailsDtoVisitorsEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlaceDetailsDtoVisitorsEnum] to String,
/// and [decode] dynamic data back to [PlaceDetailsDtoVisitorsEnum].
class PlaceDetailsDtoVisitorsEnumTypeTransformer {
  factory PlaceDetailsDtoVisitorsEnumTypeTransformer() => _instance ??= const PlaceDetailsDtoVisitorsEnumTypeTransformer._();

  const PlaceDetailsDtoVisitorsEnumTypeTransformer._();

  String encode(PlaceDetailsDtoVisitorsEnum data) => data._value;

  /// Returns the instance of [PlaceDetailsDtoVisitorsEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlaceDetailsDtoVisitorsEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlaceDetailsDtoVisitorsEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ALLOWED': return PlaceDetailsDtoVisitorsEnum.ALLOWED;
        case r'DAYTIME': return PlaceDetailsDtoVisitorsEnum.DAYTIME;
        case r'NONE': return PlaceDetailsDtoVisitorsEnum.NONE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlaceDetailsDtoVisitorsEnumTypeTransformer? _instance;
}



enum PlaceDetailsDtoAmenitiesEnum {
  WIFI._(r'WIFI'),
  AIRCON._(r'AIRCON'),
  FURNISHED._(r'FURNISHED'),
  LAUNDRY._(r'LAUNDRY'),
  PARKING._(r'PARKING'),
  CCTV._(r'CCTV'),
  ;

  /// Instantiate a new enum with the provided value.
  const PlaceDetailsDtoAmenitiesEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PlaceDetailsDtoAmenitiesEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PlaceDetailsDtoAmenitiesEnum? fromJson(dynamic value) => PlaceDetailsDtoAmenitiesEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PlaceDetailsDtoAmenitiesEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PlaceDetailsDtoAmenitiesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlaceDetailsDtoAmenitiesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlaceDetailsDtoAmenitiesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlaceDetailsDtoAmenitiesEnum] to String,
/// and [decode] dynamic data back to [PlaceDetailsDtoAmenitiesEnum].
class PlaceDetailsDtoAmenitiesEnumTypeTransformer {
  factory PlaceDetailsDtoAmenitiesEnumTypeTransformer() => _instance ??= const PlaceDetailsDtoAmenitiesEnumTypeTransformer._();

  const PlaceDetailsDtoAmenitiesEnumTypeTransformer._();

  String encode(PlaceDetailsDtoAmenitiesEnum data) => data._value;

  /// Returns the instance of [PlaceDetailsDtoAmenitiesEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlaceDetailsDtoAmenitiesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PlaceDetailsDtoAmenitiesEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WIFI': return PlaceDetailsDtoAmenitiesEnum.WIFI;
        case r'AIRCON': return PlaceDetailsDtoAmenitiesEnum.AIRCON;
        case r'FURNISHED': return PlaceDetailsDtoAmenitiesEnum.FURNISHED;
        case r'LAUNDRY': return PlaceDetailsDtoAmenitiesEnum.LAUNDRY;
        case r'PARKING': return PlaceDetailsDtoAmenitiesEnum.PARKING;
        case r'CCTV': return PlaceDetailsDtoAmenitiesEnum.CCTV;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PlaceDetailsDtoAmenitiesEnumTypeTransformer? _instance;
}


