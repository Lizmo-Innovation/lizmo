//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseResponse {
  /// Returns a new [LeaseResponse] instance.
  LeaseResponse({
    this.id,
    this.tenantId,
    this.tenantName,
    this.propertyId,
    this.propertyName,
    this.unitId,
    this.unitNumber,
    this.bedId,
    this.bedLabel,
    this.rentAmount,
    this.dueDateDay,
    this.startDate,
    this.endDate,
    this.status,
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
  String? tenantId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantName;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rentAmount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? dueDateDay;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endDate;

  LeaseResponseStatusEnum? status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseResponse &&
    other.id == id &&
    other.tenantId == tenantId &&
    other.tenantName == tenantName &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.unitId == unitId &&
    other.unitNumber == unitNumber &&
    other.bedId == bedId &&
    other.bedLabel == bedLabel &&
    other.rentAmount == rentAmount &&
    other.dueDateDay == dueDateDay &&
    other.startDate == startDate &&
    other.endDate == endDate &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (tenantId == null ? 0 : tenantId!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedId == null ? 0 : bedId!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (rentAmount == null ? 0 : rentAmount!.hashCode) +
    (dueDateDay == null ? 0 : dueDateDay!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (status == null ? 0 : status!.hashCode);

  @override
  String toString() => 'LeaseResponse[id=$id, tenantId=$tenantId, tenantName=$tenantName, propertyId=$propertyId, propertyName=$propertyName, unitId=$unitId, unitNumber=$unitNumber, bedId=$bedId, bedLabel=$bedLabel, rentAmount=$rentAmount, dueDateDay=$dueDateDay, startDate=$startDate, endDate=$endDate, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.tenantId != null) {
      json[r'tenantId'] = this.tenantId;
    } else {
      json[r'tenantId'] = null;
    }
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
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
    if (this.rentAmount != null) {
      json[r'rentAmount'] = this.rentAmount;
    } else {
      json[r'rentAmount'] = null;
    }
    if (this.dueDateDay != null) {
      json[r'dueDateDay'] = this.dueDateDay;
    } else {
      json[r'dueDateDay'] = null;
    }
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!);
    } else {
      json[r'startDate'] = null;
    }
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!);
    } else {
      json[r'endDate'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    return json;
  }

  /// Returns a new [LeaseResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LeaseResponse(
        id: mapValueOfType<String>(json, r'id'),
        tenantId: mapValueOfType<String>(json, r'tenantId'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitId: mapValueOfType<String>(json, r'unitId'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedId: mapValueOfType<String>(json, r'bedId'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        rentAmount: json[r'rentAmount'] == null
            ? null
            : num.parse('${json[r'rentAmount']}'),
        dueDateDay: mapValueOfType<int>(json, r'dueDateDay'),
        startDate: mapDateTime(json, r'startDate', r''),
        endDate: mapDateTime(json, r'endDate', r''),
        status: LeaseResponseStatusEnum.fromJson(json[r'status']),
      );
    }
    return null;
  }

  static List<LeaseResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseResponse> mapFromJson(dynamic json) {
    final map = <String, LeaseResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseResponse-objects as value to a dart map
  static Map<String, List<LeaseResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum LeaseResponseStatusEnum {
  ACTIVE._(r'ACTIVE'),
  ENDED._(r'ENDED'),
  TERMINATED._(r'TERMINATED'),
  ;

  /// Instantiate a new enum with the provided value.
  const LeaseResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [LeaseResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static LeaseResponseStatusEnum? fromJson(dynamic value) => LeaseResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [LeaseResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<LeaseResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseResponseStatusEnum] to String,
/// and [decode] dynamic data back to [LeaseResponseStatusEnum].
class LeaseResponseStatusEnumTypeTransformer {
  factory LeaseResponseStatusEnumTypeTransformer() => _instance ??= const LeaseResponseStatusEnumTypeTransformer._();

  const LeaseResponseStatusEnumTypeTransformer._();

  String encode(LeaseResponseStatusEnum data) => data._value;

  /// Returns the instance of [LeaseResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is LeaseResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ACTIVE': return LeaseResponseStatusEnum.ACTIVE;
        case r'ENDED': return LeaseResponseStatusEnum.ENDED;
        case r'TERMINATED': return LeaseResponseStatusEnum.TERMINATED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static LeaseResponseStatusEnumTypeTransformer? _instance;
}


