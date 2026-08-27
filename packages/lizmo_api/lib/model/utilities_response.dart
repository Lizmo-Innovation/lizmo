//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UtilitiesResponse {
  /// Returns a new [UtilitiesResponse] instance.
  UtilitiesResponse({
    this.billing,
    this.utilities = const [],
  });

  UtilitiesResponseBillingEnum? billing;

  List<UtilityResponse> utilities;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UtilitiesResponse &&
    other.billing == billing &&
    _deepEquality.equals(other.utilities, utilities);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billing == null ? 0 : billing!.hashCode) +
    (utilities.hashCode);

  @override
  String toString() => 'UtilitiesResponse[billing=$billing, utilities=$utilities]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.billing != null) {
      json[r'billing'] = this.billing;
    } else {
      json[r'billing'] = null;
    }
      json[r'utilities'] = this.utilities;
    return json;
  }

  /// Returns a new [UtilitiesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UtilitiesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UtilitiesResponse(
        billing: UtilitiesResponseBillingEnum.fromJson(json[r'billing']),
        utilities: UtilityResponse.listFromJson(json[r'utilities']),
      );
    }
    return null;
  }

  static List<UtilitiesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilitiesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilitiesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UtilitiesResponse> mapFromJson(dynamic json) {
    final map = <String, UtilitiesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UtilitiesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UtilitiesResponse-objects as value to a dart map
  static Map<String, List<UtilitiesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UtilitiesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UtilitiesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum UtilitiesResponseBillingEnum {
  COMBINED._(r'COMBINED'),
  SEPARATE._(r'SEPARATE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UtilitiesResponseBillingEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UtilitiesResponseBillingEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UtilitiesResponseBillingEnum? fromJson(dynamic value) => UtilitiesResponseBillingEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UtilitiesResponseBillingEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UtilitiesResponseBillingEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UtilitiesResponseBillingEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UtilitiesResponseBillingEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UtilitiesResponseBillingEnum] to String,
/// and [decode] dynamic data back to [UtilitiesResponseBillingEnum].
class UtilitiesResponseBillingEnumTypeTransformer {
  factory UtilitiesResponseBillingEnumTypeTransformer() => _instance ??= const UtilitiesResponseBillingEnumTypeTransformer._();

  const UtilitiesResponseBillingEnumTypeTransformer._();

  String encode(UtilitiesResponseBillingEnum data) => data._value;

  /// Returns the instance of [UtilitiesResponseBillingEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UtilitiesResponseBillingEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is UtilitiesResponseBillingEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'COMBINED': return UtilitiesResponseBillingEnum.COMBINED;
        case r'SEPARATE': return UtilitiesResponseBillingEnum.SEPARATE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UtilitiesResponseBillingEnumTypeTransformer? _instance;
}


