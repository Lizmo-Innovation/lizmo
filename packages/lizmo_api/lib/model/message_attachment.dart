//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MessageAttachment {
  /// Returns a new [MessageAttachment] instance.
  MessageAttachment({
    this.id,
    this.kind,
    this.name,
    this.byteSize,
    this.url,
    this.previewUrl,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  /// What kind of file
  MessageAttachmentKindEnum? kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

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
  String? url;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? previewUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MessageAttachment &&
    other.id == id &&
    other.kind == kind &&
    other.name == name &&
    other.byteSize == byteSize &&
    other.url == url &&
    other.previewUrl == previewUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (kind == null ? 0 : kind!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (byteSize == null ? 0 : byteSize!.hashCode) +
    (url == null ? 0 : url!.hashCode) +
    (previewUrl == null ? 0 : previewUrl!.hashCode);

  @override
  String toString() => 'MessageAttachment[id=$id, kind=$kind, name=$name, byteSize=$byteSize, url=$url, previewUrl=$previewUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.byteSize != null) {
      json[r'byteSize'] = this.byteSize;
    } else {
      json[r'byteSize'] = null;
    }
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    if (this.previewUrl != null) {
      json[r'previewUrl'] = this.previewUrl;
    } else {
      json[r'previewUrl'] = null;
    }
    return json;
  }

  /// Returns a new [MessageAttachment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MessageAttachment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MessageAttachment(
        id: mapValueOfType<String>(json, r'id'),
        kind: MessageAttachmentKindEnum.fromJson(json[r'kind']),
        name: mapValueOfType<String>(json, r'name'),
        byteSize: mapValueOfType<int>(json, r'byteSize'),
        url: mapValueOfType<String>(json, r'url'),
        previewUrl: mapValueOfType<String>(json, r'previewUrl'),
      );
    }
    return null;
  }

  static List<MessageAttachment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MessageAttachment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MessageAttachment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MessageAttachment> mapFromJson(dynamic json) {
    final map = <String, MessageAttachment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MessageAttachment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MessageAttachment-objects as value to a dart map
  static Map<String, List<MessageAttachment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MessageAttachment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MessageAttachment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

/// What kind of file
enum MessageAttachmentKindEnum {
  PHOTO._(r'PHOTO'),
  PDF._(r'PDF'),
  ;

  /// Instantiate a new enum with the provided value.
  const MessageAttachmentKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MessageAttachmentKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MessageAttachmentKindEnum? fromJson(dynamic value) => MessageAttachmentKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MessageAttachmentKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MessageAttachmentKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MessageAttachmentKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MessageAttachmentKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MessageAttachmentKindEnum] to String,
/// and [decode] dynamic data back to [MessageAttachmentKindEnum].
class MessageAttachmentKindEnumTypeTransformer {
  factory MessageAttachmentKindEnumTypeTransformer() => _instance ??= const MessageAttachmentKindEnumTypeTransformer._();

  const MessageAttachmentKindEnumTypeTransformer._();

  String encode(MessageAttachmentKindEnum data) => data._value;

  /// Returns the instance of [MessageAttachmentKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MessageAttachmentKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is MessageAttachmentKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHOTO': return MessageAttachmentKindEnum.PHOTO;
        case r'PDF': return MessageAttachmentKindEnum.PDF;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MessageAttachmentKindEnumTypeTransformer? _instance;
}


