//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BedResponse {
  /// Returns a new [BedResponse] instance.
  BedResponse({
    this.id,
    this.unitId,
    this.bedLabel,
    this.status,
    this.rent,
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
  String? unitId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedLabel;

  BedResponseStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BedResponse &&
    other.id == id &&
    other.unitId == unitId &&
    other.bedLabel == bedLabel &&
    other.status == status &&
    other.rent == rent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (rent == null ? 0 : rent!.hashCode);

  @override
  String toString() => 'BedResponse[id=$id, unitId=$unitId, bedLabel=$bedLabel, status=$status, rent=$rent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.unitId != null) {
      json[r'unitId'] = this.unitId;
    } else {
      json[r'unitId'] = null;
    }
    if (this.bedLabel != null) {
      json[r'bedLabel'] = this.bedLabel;
    } else {
      json[r'bedLabel'] = null;
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
    return json;
  }

  /// Returns a new [BedResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BedResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return BedResponse(
        id: mapValueOfType<String>(json, r'id'),
        unitId: mapValueOfType<String>(json, r'unitId'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        status: BedResponseStatusEnum.fromJson(json[r'status']),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
      );
    }
    return null;
  }

  static List<BedResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BedResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BedResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BedResponse> mapFromJson(dynamic json) {
    final map = <String, BedResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BedResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BedResponse-objects as value to a dart map
  static Map<String, List<BedResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BedResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BedResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum BedResponseStatusEnum {
  VACANT._(r'VACANT'),
  OCCUPIED._(r'OCCUPIED'),
  MAINTENANCE._(r'MAINTENANCE'),
  ;

  /// Instantiate a new enum with the provided value.
  const BedResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [BedResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static BedResponseStatusEnum? fromJson(dynamic value) => BedResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [BedResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<BedResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BedResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BedResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BedResponseStatusEnum] to String,
/// and [decode] dynamic data back to [BedResponseStatusEnum].
class BedResponseStatusEnumTypeTransformer {
  factory BedResponseStatusEnumTypeTransformer() => _instance ??= const BedResponseStatusEnumTypeTransformer._();

  const BedResponseStatusEnumTypeTransformer._();

  String encode(BedResponseStatusEnum data) => data._value;

  /// Returns the instance of [BedResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BedResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is BedResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'VACANT': return BedResponseStatusEnum.VACANT;
        case r'OCCUPIED': return BedResponseStatusEnum.OCCUPIED;
        case r'MAINTENANCE': return BedResponseStatusEnum.MAINTENANCE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static BedResponseStatusEnumTypeTransformer? _instance;
}


