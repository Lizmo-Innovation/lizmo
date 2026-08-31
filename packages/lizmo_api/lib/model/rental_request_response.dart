//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentalRequestResponse {
  /// Returns a new [RentalRequestResponse] instance.
  RentalRequestResponse({
    this.id,
    this.propertyId,
    this.propertyName,
    this.unitId,
    this.unitNumber,
    this.bedId,
    this.bedLabel,
    this.status,
    this.createdAt,
    this.decidedAt,
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
  String? propertyId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyName;

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
  String? unitNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedLabel;

  RentalRequestResponseStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? decidedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentalRequestResponse &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.unitId == unitId &&
    other.unitNumber == unitNumber &&
    other.bedId == bedId &&
    other.bedLabel == bedLabel &&
    other.status == status &&
    other.createdAt == createdAt &&
    other.decidedAt == decidedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedId == null ? 0 : bedId!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (decidedAt == null ? 0 : decidedAt!.hashCode);

  @override
  String toString() => 'RentalRequestResponse[id=$id, propertyId=$propertyId, propertyName=$propertyName, unitId=$unitId, unitNumber=$unitNumber, bedId=$bedId, bedLabel=$bedLabel, status=$status, createdAt=$createdAt, decidedAt=$decidedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.propertyId != null) {
      json[r'propertyId'] = this.propertyId;
    } else {
      json[r'propertyId'] = null;
    }
    if (this.propertyName != null) {
      json[r'propertyName'] = this.propertyName;
    } else {
      json[r'propertyName'] = null;
    }
    if (this.unitId != null) {
      json[r'unitId'] = this.unitId;
    } else {
      json[r'unitId'] = null;
    }
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.bedId != null) {
      json[r'bedId'] = this.bedId;
    } else {
      json[r'bedId'] = null;
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
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.decidedAt != null) {
      json[r'decidedAt'] = this.decidedAt!.toUtc().toIso8601String();
    } else {
      json[r'decidedAt'] = null;
    }
    return json;
  }

  /// Returns a new [RentalRequestResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentalRequestResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return RentalRequestResponse(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitId: mapValueOfType<String>(json, r'unitId'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedId: mapValueOfType<String>(json, r'bedId'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        status: RentalRequestResponseStatusEnum.fromJson(json[r'status']),
        createdAt: mapDateTime(json, r'createdAt', r''),
        decidedAt: mapDateTime(json, r'decidedAt', r''),
      );
    }
    return null;
  }

  static List<RentalRequestResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentalRequestResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentalRequestResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentalRequestResponse> mapFromJson(dynamic json) {
    final map = <String, RentalRequestResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentalRequestResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentalRequestResponse-objects as value to a dart map
  static Map<String, List<RentalRequestResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentalRequestResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentalRequestResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum RentalRequestResponseStatusEnum {
  PENDING._(r'PENDING'),
  ACCEPTED._(r'ACCEPTED'),
  DECLINED._(r'DECLINED'),
  WITHDRAWN._(r'WITHDRAWN'),
  SUPERSEDED._(r'SUPERSEDED'),
  ;

  /// Instantiate a new enum with the provided value.
  const RentalRequestResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RentalRequestResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RentalRequestResponseStatusEnum? fromJson(dynamic value) => RentalRequestResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RentalRequestResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RentalRequestResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentalRequestResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentalRequestResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RentalRequestResponseStatusEnum] to String,
/// and [decode] dynamic data back to [RentalRequestResponseStatusEnum].
class RentalRequestResponseStatusEnumTypeTransformer {
  factory RentalRequestResponseStatusEnumTypeTransformer() => _instance ??= const RentalRequestResponseStatusEnumTypeTransformer._();

  const RentalRequestResponseStatusEnumTypeTransformer._();

  String encode(RentalRequestResponseStatusEnum data) => data._value;

  /// Returns the instance of [RentalRequestResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RentalRequestResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RentalRequestResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PENDING': return RentalRequestResponseStatusEnum.PENDING;
        case r'ACCEPTED': return RentalRequestResponseStatusEnum.ACCEPTED;
        case r'DECLINED': return RentalRequestResponseStatusEnum.DECLINED;
        case r'WITHDRAWN': return RentalRequestResponseStatusEnum.WITHDRAWN;
        case r'SUPERSEDED': return RentalRequestResponseStatusEnum.SUPERSEDED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RentalRequestResponseStatusEnumTypeTransformer? _instance;
}


