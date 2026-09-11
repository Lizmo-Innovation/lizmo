//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MaintenanceReportResponse {
  /// Returns a new [MaintenanceReportResponse] instance.
  MaintenanceReportResponse({
    this.id,
    this.leaseId,
    this.propertyId,
    this.propertyName,
    this.unitNumber,
    this.bedLabel,
    this.tenantName,
    this.description,
    this.status,
    this.landlordRemarks,
    this.reopened,
    this.reopenReason,
    this.submittedAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.photoUrls = const [],
    this.photoUrlsExpireInSeconds,
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
  String? leaseId;

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
  String? unitNumber;

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
  String? tenantName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  MaintenanceReportResponseStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? landlordRemarks;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? reopened;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reopenReason;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? submittedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? resolvedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? closedAt;

  List<String> photoUrls;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? photoUrlsExpireInSeconds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MaintenanceReportResponse &&
    other.id == id &&
    other.leaseId == leaseId &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.unitNumber == unitNumber &&
    other.bedLabel == bedLabel &&
    other.tenantName == tenantName &&
    other.description == description &&
    other.status == status &&
    other.landlordRemarks == landlordRemarks &&
    other.reopened == reopened &&
    other.reopenReason == reopenReason &&
    other.submittedAt == submittedAt &&
    other.updatedAt == updatedAt &&
    other.resolvedAt == resolvedAt &&
    other.closedAt == closedAt &&
    _deepEquality.equals(other.photoUrls, photoUrls) &&
    other.photoUrlsExpireInSeconds == photoUrlsExpireInSeconds;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (unitNumber == null ? 0 : unitNumber!.hashCode) +
    (bedLabel == null ? 0 : bedLabel!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (landlordRemarks == null ? 0 : landlordRemarks!.hashCode) +
    (reopened == null ? 0 : reopened!.hashCode) +
    (reopenReason == null ? 0 : reopenReason!.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (resolvedAt == null ? 0 : resolvedAt!.hashCode) +
    (closedAt == null ? 0 : closedAt!.hashCode) +
    (photoUrls.hashCode) +
    (photoUrlsExpireInSeconds == null ? 0 : photoUrlsExpireInSeconds!.hashCode);

  @override
  String toString() => 'MaintenanceReportResponse[id=$id, leaseId=$leaseId, propertyId=$propertyId, propertyName=$propertyName, unitNumber=$unitNumber, bedLabel=$bedLabel, tenantName=$tenantName, description=$description, status=$status, landlordRemarks=$landlordRemarks, reopened=$reopened, reopenReason=$reopenReason, submittedAt=$submittedAt, updatedAt=$updatedAt, resolvedAt=$resolvedAt, closedAt=$closedAt, photoUrls=$photoUrls, photoUrlsExpireInSeconds=$photoUrlsExpireInSeconds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
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
    if (this.unitNumber != null) {
      json[r'unitNumber'] = this.unitNumber;
    } else {
      json[r'unitNumber'] = null;
    }
    if (this.bedLabel != null) {
      json[r'bedLabel'] = this.bedLabel;
    } else {
      json[r'bedLabel'] = null;
    }
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.landlordRemarks != null) {
      json[r'landlordRemarks'] = this.landlordRemarks;
    } else {
      json[r'landlordRemarks'] = null;
    }
    if (this.reopened != null) {
      json[r'reopened'] = this.reopened;
    } else {
      json[r'reopened'] = null;
    }
    if (this.reopenReason != null) {
      json[r'reopenReason'] = this.reopenReason;
    } else {
      json[r'reopenReason'] = null;
    }
    if (this.submittedAt != null) {
      json[r'submittedAt'] = this.submittedAt!.toUtc().toIso8601String();
    } else {
      json[r'submittedAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    if (this.resolvedAt != null) {
      json[r'resolvedAt'] = this.resolvedAt!.toUtc().toIso8601String();
    } else {
      json[r'resolvedAt'] = null;
    }
    if (this.closedAt != null) {
      json[r'closedAt'] = this.closedAt!.toUtc().toIso8601String();
    } else {
      json[r'closedAt'] = null;
    }
      json[r'photoUrls'] = this.photoUrls;
    if (this.photoUrlsExpireInSeconds != null) {
      json[r'photoUrlsExpireInSeconds'] = this.photoUrlsExpireInSeconds;
    } else {
      json[r'photoUrlsExpireInSeconds'] = null;
    }
    return json;
  }

  /// Returns a new [MaintenanceReportResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MaintenanceReportResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MaintenanceReportResponse(
        id: mapValueOfType<String>(json, r'id'),
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        unitNumber: mapValueOfType<String>(json, r'unitNumber'),
        bedLabel: mapValueOfType<String>(json, r'bedLabel'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        description: mapValueOfType<String>(json, r'description'),
        status: MaintenanceReportResponseStatusEnum.fromJson(json[r'status']),
        landlordRemarks: mapValueOfType<String>(json, r'landlordRemarks'),
        reopened: mapValueOfType<bool>(json, r'reopened'),
        reopenReason: mapValueOfType<String>(json, r'reopenReason'),
        submittedAt: mapDateTime(json, r'submittedAt', r''),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
        resolvedAt: mapDateTime(json, r'resolvedAt', r''),
        closedAt: mapDateTime(json, r'closedAt', r''),
        photoUrls: json[r'photoUrls'] is Iterable
            ? (json[r'photoUrls'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        photoUrlsExpireInSeconds: mapValueOfType<int>(json, r'photoUrlsExpireInSeconds'),
      );
    }
    return null;
  }

  static List<MaintenanceReportResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceReportResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceReportResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MaintenanceReportResponse> mapFromJson(dynamic json) {
    final map = <String, MaintenanceReportResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MaintenanceReportResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MaintenanceReportResponse-objects as value to a dart map
  static Map<String, List<MaintenanceReportResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MaintenanceReportResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MaintenanceReportResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum MaintenanceReportResponseStatusEnum {
  SUBMITTED._(r'SUBMITTED'),
  IN_PROGRESS._(r'IN_PROGRESS'),
  RESOLVED._(r'RESOLVED'),
  CLOSED._(r'CLOSED'),
  WITHDRAWN._(r'WITHDRAWN'),
  ;

  /// Instantiate a new enum with the provided value.
  const MaintenanceReportResponseStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MaintenanceReportResponseStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MaintenanceReportResponseStatusEnum? fromJson(dynamic value) => MaintenanceReportResponseStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MaintenanceReportResponseStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MaintenanceReportResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceReportResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceReportResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MaintenanceReportResponseStatusEnum] to String,
/// and [decode] dynamic data back to [MaintenanceReportResponseStatusEnum].
class MaintenanceReportResponseStatusEnumTypeTransformer {
  factory MaintenanceReportResponseStatusEnumTypeTransformer() => _instance ??= const MaintenanceReportResponseStatusEnumTypeTransformer._();

  const MaintenanceReportResponseStatusEnumTypeTransformer._();

  String encode(MaintenanceReportResponseStatusEnum data) => data._value;

  /// Returns the instance of [MaintenanceReportResponseStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MaintenanceReportResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is MaintenanceReportResponseStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'SUBMITTED': return MaintenanceReportResponseStatusEnum.SUBMITTED;
        case r'IN_PROGRESS': return MaintenanceReportResponseStatusEnum.IN_PROGRESS;
        case r'RESOLVED': return MaintenanceReportResponseStatusEnum.RESOLVED;
        case r'CLOSED': return MaintenanceReportResponseStatusEnum.CLOSED;
        case r'WITHDRAWN': return MaintenanceReportResponseStatusEnum.WITHDRAWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MaintenanceReportResponseStatusEnumTypeTransformer? _instance;
}


