//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UtilityResponse {
  /// Returns a new [UtilityResponse] instance.
  UtilityResponse({
    this.kind,
    this.enabled,
    this.amount,
  });

  UtilityResponseKindEnum? kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enabled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? amount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UtilityResponse &&
    other.kind == kind &&
    other.enabled == enabled &&
    other.amount == amount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind == null ? 0 : kind!.hashCode) +
    (enabled == null ? 0 : enabled!.hashCode) +
    (amount == null ? 0 : amount!.hashCode);

  @override
  String toString() => 'UtilityResponse[kind=$kind, enabled=$enabled, amount=$amount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.enabled != null) {
      json[r'enabled'] = this.enabled;
    } else {
      json[r'enabled'] = null;
    }
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    return json;
  }

  /// Returns a new [UtilityResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UtilityResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UtilityResponse(
        kind: UtilityResponseKindEnum.fromJson(json[r'kind']),
        enabled: mapValueOfType<bool>(json, r'enabled'),
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
      );
    }
    return null;
  }

  static List<UtilityResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilityResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilityResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UtilityResponse> mapFromJson(dynamic json) {
    final map = <String, UtilityResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UtilityResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UtilityResponse-objects as value to a dart map
  static Map<String, List<UtilityResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UtilityResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UtilityResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum UtilityResponseKindEnum {
  WIFI._(r'WIFI'),
  ELECTRICITY._(r'ELECTRICITY'),
  WATER._(r'WATER'),
  ;

  /// Instantiate a new enum with the provided value.
  const UtilityResponseKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UtilityResponseKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UtilityResponseKindEnum? fromJson(dynamic value) => UtilityResponseKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UtilityResponseKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UtilityResponseKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilityResponseKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilityResponseKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UtilityResponseKindEnum] to String,
/// and [decode] dynamic data back to [UtilityResponseKindEnum].
class UtilityResponseKindEnumTypeTransformer {
  factory UtilityResponseKindEnumTypeTransformer() => _instance ??= const UtilityResponseKindEnumTypeTransformer._();

  const UtilityResponseKindEnumTypeTransformer._();

  String encode(UtilityResponseKindEnum data) => data._value;

  /// Returns the instance of [UtilityResponseKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UtilityResponseKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UtilityResponseKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WIFI': return UtilityResponseKindEnum.WIFI;
        case r'ELECTRICITY': return UtilityResponseKindEnum.ELECTRICITY;
        case r'WATER': return UtilityResponseKindEnum.WATER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UtilityResponseKindEnumTypeTransformer? _instance;
}


