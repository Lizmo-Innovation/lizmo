//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterDevice {
  /// Returns a new [RegisterDevice] instance.
  RegisterDevice({
    required this.token,
    required this.platform,
  });

  String token;

  RegisterDevicePlatformEnum platform;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterDevice &&
    other.token == token &&
    other.platform == platform;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (token.hashCode) +
    (platform.hashCode);

  @override
  String toString() => 'RegisterDevice[token=$token, platform=$platform]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'token'] = this.token;
      json[r'platform'] = this.platform;
    return json;
  }

  /// Returns a new [RegisterDevice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterDevice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'token'), 'Required key "RegisterDevice[token]" is missing from JSON.');
        assert(json[r'token'] != null, 'Required key "RegisterDevice[token]" has a null value in JSON.');
        assert(json.containsKey(r'platform'), 'Required key "RegisterDevice[platform]" is missing from JSON.');
        assert(json[r'platform'] != null, 'Required key "RegisterDevice[platform]" has a null value in JSON.');
        return true;
      }());

      return RegisterDevice(
        token: mapValueOfType<String>(json, r'token')!,
        platform: RegisterDevicePlatformEnum.fromJson(json[r'platform'])!,
      );
    }
    return null;
  }

  static List<RegisterDevice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterDevice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterDevice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterDevice> mapFromJson(dynamic json) {
    final map = <String, RegisterDevice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterDevice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterDevice-objects as value to a dart map
  static Map<String, List<RegisterDevice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterDevice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterDevice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'token',
    'platform',
  };
}


enum RegisterDevicePlatformEnum {
  ANDROID._(r'ANDROID'),
  IOS._(r'IOS'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterDevicePlatformEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterDevicePlatformEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterDevicePlatformEnum? fromJson(dynamic value) => RegisterDevicePlatformEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterDevicePlatformEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterDevicePlatformEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterDevicePlatformEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterDevicePlatformEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterDevicePlatformEnum] to String,
/// and [decode] dynamic data back to [RegisterDevicePlatformEnum].
class RegisterDevicePlatformEnumTypeTransformer {
  factory RegisterDevicePlatformEnumTypeTransformer() => _instance ??= const RegisterDevicePlatformEnumTypeTransformer._();

  const RegisterDevicePlatformEnumTypeTransformer._();

  String encode(RegisterDevicePlatformEnum data) => data._value;

  /// Returns the instance of [RegisterDevicePlatformEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterDevicePlatformEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterDevicePlatformEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ANDROID': return RegisterDevicePlatformEnum.ANDROID;
        case r'IOS': return RegisterDevicePlatformEnum.IOS;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterDevicePlatformEnumTypeTransformer? _instance;
}


