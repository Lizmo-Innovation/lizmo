//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseDocumentResponse {
  /// Returns a new [LeaseDocumentResponse] instance.
  LeaseDocumentResponse({
    this.id,
    this.docType,
    this.label,
    this.url,
    this.urlExpiresInSeconds,
    this.contentType,
    this.byteSize,
    this.sharedWithTenant,
    this.uploadedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  LeaseDocumentResponseDocTypeEnum? docType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? label;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? url;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? urlExpiresInSeconds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contentType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? byteSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? sharedWithTenant;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? uploadedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseDocumentResponse &&
    other.id == id &&
    other.docType == docType &&
    other.label == label &&
    other.url == url &&
    other.urlExpiresInSeconds == urlExpiresInSeconds &&
    other.contentType == contentType &&
    other.byteSize == byteSize &&
    other.sharedWithTenant == sharedWithTenant &&
    other.uploadedAt == uploadedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (docType == null ? 0 : docType!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (url == null ? 0 : url!.hashCode) +
    (urlExpiresInSeconds == null ? 0 : urlExpiresInSeconds!.hashCode) +
    (contentType == null ? 0 : contentType!.hashCode) +
    (byteSize == null ? 0 : byteSize!.hashCode) +
    (sharedWithTenant == null ? 0 : sharedWithTenant!.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode);

  @override
  String toString() => 'LeaseDocumentResponse[id=$id, docType=$docType, label=$label, url=$url, urlExpiresInSeconds=$urlExpiresInSeconds, contentType=$contentType, byteSize=$byteSize, sharedWithTenant=$sharedWithTenant, uploadedAt=$uploadedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.docType != null) {
      json[r'docType'] = this.docType;
    } else {
      json[r'docType'] = null;
    }
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    if (this.urlExpiresInSeconds != null) {
      json[r'urlExpiresInSeconds'] = this.urlExpiresInSeconds;
    } else {
      json[r'urlExpiresInSeconds'] = null;
    }
    if (this.contentType != null) {
      json[r'contentType'] = this.contentType;
    } else {
      json[r'contentType'] = null;
    }
    if (this.byteSize != null) {
      json[r'byteSize'] = this.byteSize;
    } else {
      json[r'byteSize'] = null;
    }
    if (this.sharedWithTenant != null) {
      json[r'sharedWithTenant'] = this.sharedWithTenant;
    } else {
      json[r'sharedWithTenant'] = null;
    }
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'uploadedAt'] = null;
    }
    return json;
  }

  /// Returns a new [LeaseDocumentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseDocumentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LeaseDocumentResponse(
        id: mapValueOfType<String>(json, r'id'),
        docType: LeaseDocumentResponseDocTypeEnum.fromJson(json[r'docType']),
        label: mapValueOfType<String>(json, r'label'),
        url: mapValueOfType<String>(json, r'url'),
        urlExpiresInSeconds: mapValueOfType<int>(json, r'urlExpiresInSeconds'),
        contentType: mapValueOfType<String>(json, r'contentType'),
        byteSize: mapValueOfType<int>(json, r'byteSize'),
        sharedWithTenant: mapValueOfType<bool>(json, r'sharedWithTenant'),
        uploadedAt: mapDateTime(json, r'uploadedAt', r''),
      );
    }
    return null;
  }

  static List<LeaseDocumentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseDocumentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseDocumentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseDocumentResponse> mapFromJson(dynamic json) {
    final map = <String, LeaseDocumentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseDocumentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseDocumentResponse-objects as value to a dart map
  static Map<String, List<LeaseDocumentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseDocumentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseDocumentResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum LeaseDocumentResponseDocTypeEnum {
  LEASE_CONTRACT._(r'LEASE_CONTRACT'),
  VALID_ID._(r'VALID_ID'),
  RECEIPT._(r'RECEIPT'),
  TENANT_PHOTO._(r'TENANT_PHOTO'),
  OTHER._(r'OTHER'),
  ;

  /// Instantiate a new enum with the provided value.
  const LeaseDocumentResponseDocTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [LeaseDocumentResponseDocTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static LeaseDocumentResponseDocTypeEnum? fromJson(dynamic value) => LeaseDocumentResponseDocTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [LeaseDocumentResponseDocTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<LeaseDocumentResponseDocTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseDocumentResponseDocTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseDocumentResponseDocTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseDocumentResponseDocTypeEnum] to String,
/// and [decode] dynamic data back to [LeaseDocumentResponseDocTypeEnum].
class LeaseDocumentResponseDocTypeEnumTypeTransformer {
  factory LeaseDocumentResponseDocTypeEnumTypeTransformer() => _instance ??= const LeaseDocumentResponseDocTypeEnumTypeTransformer._();

  const LeaseDocumentResponseDocTypeEnumTypeTransformer._();

  String encode(LeaseDocumentResponseDocTypeEnum data) => data._value;

  /// Returns the instance of [LeaseDocumentResponseDocTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseDocumentResponseDocTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is LeaseDocumentResponseDocTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'LEASE_CONTRACT': return LeaseDocumentResponseDocTypeEnum.LEASE_CONTRACT;
        case r'VALID_ID': return LeaseDocumentResponseDocTypeEnum.VALID_ID;
        case r'RECEIPT': return LeaseDocumentResponseDocTypeEnum.RECEIPT;
        case r'TENANT_PHOTO': return LeaseDocumentResponseDocTypeEnum.TENANT_PHOTO;
        case r'OTHER': return LeaseDocumentResponseDocTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static LeaseDocumentResponseDocTypeEnumTypeTransformer? _instance;
}


