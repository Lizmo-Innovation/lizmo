//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TenantDocumentResponse {
  /// Returns a new [TenantDocumentResponse] instance.
  TenantDocumentResponse({
    this.docType,
    this.url,
    this.urlExpiresInSeconds,
    this.byteSize,
    this.uploadedAt,
  });

  TenantDocumentResponseDocTypeEnum? docType;

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
  int? byteSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? uploadedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantDocumentResponse &&
    other.docType == docType &&
    other.url == url &&
    other.urlExpiresInSeconds == urlExpiresInSeconds &&
    other.byteSize == byteSize &&
    other.uploadedAt == uploadedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (docType == null ? 0 : docType!.hashCode) +
    (url == null ? 0 : url!.hashCode) +
    (urlExpiresInSeconds == null ? 0 : urlExpiresInSeconds!.hashCode) +
    (byteSize == null ? 0 : byteSize!.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode);

  @override
  String toString() => 'TenantDocumentResponse[docType=$docType, url=$url, urlExpiresInSeconds=$urlExpiresInSeconds, byteSize=$byteSize, uploadedAt=$uploadedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.docType != null) {
      json[r'docType'] = this.docType;
    } else {
      json[r'docType'] = null;
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
    if (this.byteSize != null) {
      json[r'byteSize'] = this.byteSize;
    } else {
      json[r'byteSize'] = null;
    }
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'uploadedAt'] = null;
    }
    return json;
  }

  /// Returns a new [TenantDocumentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantDocumentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TenantDocumentResponse(
        docType: TenantDocumentResponseDocTypeEnum.fromJson(json[r'docType']),
        url: mapValueOfType<String>(json, r'url'),
        urlExpiresInSeconds: mapValueOfType<int>(json, r'urlExpiresInSeconds'),
        byteSize: mapValueOfType<int>(json, r'byteSize'),
        uploadedAt: mapDateTime(json, r'uploadedAt', r''),
      );
    }
    return null;
  }

  static List<TenantDocumentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantDocumentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantDocumentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantDocumentResponse> mapFromJson(dynamic json) {
    final map = <String, TenantDocumentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantDocumentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantDocumentResponse-objects as value to a dart map
  static Map<String, List<TenantDocumentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantDocumentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantDocumentResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum TenantDocumentResponseDocTypeEnum {
  LEASE_CONTRACT._(r'LEASE_CONTRACT'),
  VALID_ID._(r'VALID_ID'),
  RECEIPT._(r'RECEIPT'),
  TENANT_PHOTO._(r'TENANT_PHOTO'),
  PROPERTY_PHOTO._(r'PROPERTY_PHOTO'),
  OTHER._(r'OTHER'),
  ;

  /// Instantiate a new enum with the provided value.
  const TenantDocumentResponseDocTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TenantDocumentResponseDocTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TenantDocumentResponseDocTypeEnum? fromJson(dynamic value) => TenantDocumentResponseDocTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TenantDocumentResponseDocTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TenantDocumentResponseDocTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantDocumentResponseDocTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantDocumentResponseDocTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TenantDocumentResponseDocTypeEnum] to String,
/// and [decode] dynamic data back to [TenantDocumentResponseDocTypeEnum].
class TenantDocumentResponseDocTypeEnumTypeTransformer {
  factory TenantDocumentResponseDocTypeEnumTypeTransformer() => _instance ??= const TenantDocumentResponseDocTypeEnumTypeTransformer._();

  const TenantDocumentResponseDocTypeEnumTypeTransformer._();

  String encode(TenantDocumentResponseDocTypeEnum data) => data._value;

  /// Returns the instance of [TenantDocumentResponseDocTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TenantDocumentResponseDocTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is TenantDocumentResponseDocTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'LEASE_CONTRACT': return TenantDocumentResponseDocTypeEnum.LEASE_CONTRACT;
        case r'VALID_ID': return TenantDocumentResponseDocTypeEnum.VALID_ID;
        case r'RECEIPT': return TenantDocumentResponseDocTypeEnum.RECEIPT;
        case r'TENANT_PHOTO': return TenantDocumentResponseDocTypeEnum.TENANT_PHOTO;
        case r'PROPERTY_PHOTO': return TenantDocumentResponseDocTypeEnum.PROPERTY_PHOTO;
        case r'OTHER': return TenantDocumentResponseDocTypeEnum.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TenantDocumentResponseDocTypeEnumTypeTransformer? _instance;
}


