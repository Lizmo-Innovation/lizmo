//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UtilityRequest {
  /// Returns a new [UtilityRequest] instance.
  UtilityRequest({
    required this.kind,
    required this.enabled,
    this.amount,
  });

  UtilityRequestKindEnum kind;

  bool enabled;

  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? amount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UtilityRequest &&
    other.kind == kind &&
    other.enabled == enabled &&
    other.amount == amount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (enabled.hashCode) +
    (amount == null ? 0 : amount!.hashCode);

  @override
  String toString() => 'UtilityRequest[kind=$kind, enabled=$enabled, amount=$amount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'enabled'] = this.enabled;
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    return json;
  }

  /// Returns a new [UtilityRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UtilityRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'), 'Required key "UtilityRequest[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "UtilityRequest[kind]" has a null value in JSON.');
        assert(json.containsKey(r'enabled'), 'Required key "UtilityRequest[enabled]" is missing from JSON.');
        assert(json[r'enabled'] != null, 'Required key "UtilityRequest[enabled]" has a null value in JSON.');
        return true;
      }());

      return UtilityRequest(
        kind: UtilityRequestKindEnum.fromJson(json[r'kind'])!,
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
      );
    }
    return null;
  }

  static List<UtilityRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilityRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilityRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UtilityRequest> mapFromJson(dynamic json) {
    final map = <String, UtilityRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UtilityRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UtilityRequest-objects as value to a dart map
  static Map<String, List<UtilityRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UtilityRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UtilityRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'enabled',
  };
}


enum UtilityRequestKindEnum {
  WIFI._(r'WIFI'),
  ELECTRICITY._(r'ELECTRICITY'),
  WATER._(r'WATER'),
  ;

  /// Instantiate a new enum with the provided value.
  const UtilityRequestKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UtilityRequestKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UtilityRequestKindEnum? fromJson(dynamic value) => UtilityRequestKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UtilityRequestKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UtilityRequestKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilityRequestKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilityRequestKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UtilityRequestKindEnum] to String,
/// and [decode] dynamic data back to [UtilityRequestKindEnum].
class UtilityRequestKindEnumTypeTransformer {
  factory UtilityRequestKindEnumTypeTransformer() => _instance ??= const UtilityRequestKindEnumTypeTransformer._();

  const UtilityRequestKindEnumTypeTransformer._();

  String encode(UtilityRequestKindEnum data) => data._value;

  /// Returns the instance of [UtilityRequestKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UtilityRequestKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UtilityRequestKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WIFI': return UtilityRequestKindEnum.WIFI;
        case r'ELECTRICITY': return UtilityRequestKindEnum.ELECTRICITY;
        case r'WATER': return UtilityRequestKindEnum.WATER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UtilityRequestKindEnumTypeTransformer? _instance;
}


