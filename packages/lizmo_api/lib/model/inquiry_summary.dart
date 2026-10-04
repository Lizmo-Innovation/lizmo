//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InquirySummary {
  /// Returns a new [InquirySummary] instance.
  InquirySummary({
    this.id,
    this.propertyId,
    this.propertyName,
    this.withName,
    this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.unread,
    this.createdAt,
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
  String? withName;

  InquirySummaryStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lastMessage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastMessageAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? unread;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InquirySummary &&
    other.id == id &&
    other.propertyId == propertyId &&
    other.propertyName == propertyName &&
    other.withName == withName &&
    other.status == status &&
    other.lastMessage == lastMessage &&
    other.lastMessageAt == lastMessageAt &&
    other.unread == unread &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (propertyId == null ? 0 : propertyId!.hashCode) +
    (propertyName == null ? 0 : propertyName!.hashCode) +
    (withName == null ? 0 : withName!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (lastMessage == null ? 0 : lastMessage!.hashCode) +
    (lastMessageAt == null ? 0 : lastMessageAt!.hashCode) +
    (unread == null ? 0 : unread!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode);

  @override
  String toString() => 'InquirySummary[id=$id, propertyId=$propertyId, propertyName=$propertyName, withName=$withName, status=$status, lastMessage=$lastMessage, lastMessageAt=$lastMessageAt, unread=$unread, createdAt=$createdAt]';

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
    if (this.withName != null) {
      json[r'withName'] = this.withName;
    } else {
      json[r'withName'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.lastMessage != null) {
      json[r'lastMessage'] = this.lastMessage;
    } else {
      json[r'lastMessage'] = null;
    }
    if (this.lastMessageAt != null) {
      json[r'lastMessageAt'] = this.lastMessageAt!.toUtc().toIso8601String();
    } else {
      json[r'lastMessageAt'] = null;
    }
    if (this.unread != null) {
      json[r'unread'] = this.unread;
    } else {
      json[r'unread'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    return json;
  }

  /// Returns a new [InquirySummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InquirySummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return InquirySummary(
        id: mapValueOfType<String>(json, r'id'),
        propertyId: mapValueOfType<String>(json, r'propertyId'),
        propertyName: mapValueOfType<String>(json, r'propertyName'),
        withName: mapValueOfType<String>(json, r'withName'),
        status: InquirySummaryStatusEnum.fromJson(json[r'status']),
        lastMessage: mapValueOfType<String>(json, r'lastMessage'),
        lastMessageAt: mapDateTime(json, r'lastMessageAt', r''),
        unread: mapValueOfType<bool>(json, r'unread'),
        createdAt: mapDateTime(json, r'createdAt', r''),
      );
    }
    return null;
  }

  static List<InquirySummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InquirySummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InquirySummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InquirySummary> mapFromJson(dynamic json) {
    final map = <String, InquirySummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InquirySummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InquirySummary-objects as value to a dart map
  static Map<String, List<InquirySummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InquirySummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InquirySummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum InquirySummaryStatusEnum {
  OPEN._(r'OPEN'),
  CLOSED._(r'CLOSED'),
  LEASED._(r'LEASED'),
  ;

  /// Instantiate a new enum with the provided value.
  const InquirySummaryStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [InquirySummaryStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static InquirySummaryStatusEnum? fromJson(dynamic value) => InquirySummaryStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [InquirySummaryStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<InquirySummaryStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InquirySummaryStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InquirySummaryStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InquirySummaryStatusEnum] to String,
/// and [decode] dynamic data back to [InquirySummaryStatusEnum].
class InquirySummaryStatusEnumTypeTransformer {
  factory InquirySummaryStatusEnumTypeTransformer() => _instance ??= const InquirySummaryStatusEnumTypeTransformer._();

  const InquirySummaryStatusEnumTypeTransformer._();

  String encode(InquirySummaryStatusEnum data) => data._value;

  /// Returns the instance of [InquirySummaryStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InquirySummaryStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is InquirySummaryStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'OPEN': return InquirySummaryStatusEnum.OPEN;
        case r'CLOSED': return InquirySummaryStatusEnum.CLOSED;
        case r'LEASED': return InquirySummaryStatusEnum.LEASED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static InquirySummaryStatusEnumTypeTransformer? _instance;
}


