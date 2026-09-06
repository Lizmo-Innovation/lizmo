//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationResponse {
  /// Returns a new [NotificationResponse] instance.
  NotificationResponse({
    this.id,
    this.type,
    this.title,
    this.message,
    this.unread,
    this.relatedEntityType,
    this.relatedEntityId,
    this.createdAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  NotificationResponseTypeEnum? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? unread;

  NotificationResponseRelatedEntityTypeEnum? relatedEntityType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? relatedEntityId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationResponse &&
    other.id == id &&
    other.type == type &&
    other.title == title &&
    other.message == message &&
    other.unread == unread &&
    other.relatedEntityType == relatedEntityType &&
    other.relatedEntityId == relatedEntityId &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (unread == null ? 0 : unread!.hashCode) +
    (relatedEntityType == null ? 0 : relatedEntityType!.hashCode) +
    (relatedEntityId == null ? 0 : relatedEntityId!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode);

  @override
  String toString() => 'NotificationResponse[id=$id, type=$type, title=$title, message=$message, unread=$unread, relatedEntityType=$relatedEntityType, relatedEntityId=$relatedEntityId, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
    if (this.unread != null) {
      json[r'unread'] = this.unread;
    } else {
      json[r'unread'] = null;
    }
    if (this.relatedEntityType != null) {
      json[r'relatedEntityType'] = this.relatedEntityType;
    } else {
      json[r'relatedEntityType'] = null;
    }
    if (this.relatedEntityId != null) {
      json[r'relatedEntityId'] = this.relatedEntityId;
    } else {
      json[r'relatedEntityId'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    return json;
  }

  /// Returns a new [NotificationResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return NotificationResponse(
        id: mapValueOfType<String>(json, r'id'),
        type: NotificationResponseTypeEnum.fromJson(json[r'type']),
        title: mapValueOfType<String>(json, r'title'),
        message: mapValueOfType<String>(json, r'message'),
        unread: mapValueOfType<bool>(json, r'unread'),
        relatedEntityType: NotificationResponseRelatedEntityTypeEnum.fromJson(json[r'relatedEntityType']),
        relatedEntityId: mapValueOfType<String>(json, r'relatedEntityId'),
        createdAt: mapDateTime(json, r'createdAt', r''),
      );
    }
    return null;
  }

  static List<NotificationResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationResponse> mapFromJson(dynamic json) {
    final map = <String, NotificationResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationResponse-objects as value to a dart map
  static Map<String, List<NotificationResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


enum NotificationResponseTypeEnum {
  REQUEST_RECEIVED._(r'REQUEST_RECEIVED'),
  REQUEST_ACCEPTED._(r'REQUEST_ACCEPTED'),
  REQUEST_DECLINED._(r'REQUEST_DECLINED'),
  REQUEST_SUPERSEDED._(r'REQUEST_SUPERSEDED'),
  RENT_DUE_REMINDER._(r'RENT_DUE_REMINDER'),
  RENT_OVERDUE._(r'RENT_OVERDUE'),
  PAYMENT_CONFIRMED._(r'PAYMENT_CONFIRMED'),
  PAYMENT_REJECTED._(r'PAYMENT_REJECTED'),
  MAINTENANCE_STATUS_CHANGED._(r'MAINTENANCE_STATUS_CHANGED'),
  NEW_NOTICE_POSTED._(r'NEW_NOTICE_POSTED'),
  LEASE_EXPIRING._(r'LEASE_EXPIRING'),
  STAFF_ASSIGNED._(r'STAFF_ASSIGNED'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotificationResponseTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotificationResponseTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotificationResponseTypeEnum? fromJson(dynamic value) => NotificationResponseTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotificationResponseTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotificationResponseTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationResponseTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationResponseTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationResponseTypeEnum] to String,
/// and [decode] dynamic data back to [NotificationResponseTypeEnum].
class NotificationResponseTypeEnumTypeTransformer {
  factory NotificationResponseTypeEnumTypeTransformer() => _instance ??= const NotificationResponseTypeEnumTypeTransformer._();

  const NotificationResponseTypeEnumTypeTransformer._();

  String encode(NotificationResponseTypeEnum data) => data._value;

  /// Returns the instance of [NotificationResponseTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationResponseTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotificationResponseTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'REQUEST_RECEIVED': return NotificationResponseTypeEnum.REQUEST_RECEIVED;
        case r'REQUEST_ACCEPTED': return NotificationResponseTypeEnum.REQUEST_ACCEPTED;
        case r'REQUEST_DECLINED': return NotificationResponseTypeEnum.REQUEST_DECLINED;
        case r'REQUEST_SUPERSEDED': return NotificationResponseTypeEnum.REQUEST_SUPERSEDED;
        case r'RENT_DUE_REMINDER': return NotificationResponseTypeEnum.RENT_DUE_REMINDER;
        case r'RENT_OVERDUE': return NotificationResponseTypeEnum.RENT_OVERDUE;
        case r'PAYMENT_CONFIRMED': return NotificationResponseTypeEnum.PAYMENT_CONFIRMED;
        case r'PAYMENT_REJECTED': return NotificationResponseTypeEnum.PAYMENT_REJECTED;
        case r'MAINTENANCE_STATUS_CHANGED': return NotificationResponseTypeEnum.MAINTENANCE_STATUS_CHANGED;
        case r'NEW_NOTICE_POSTED': return NotificationResponseTypeEnum.NEW_NOTICE_POSTED;
        case r'LEASE_EXPIRING': return NotificationResponseTypeEnum.LEASE_EXPIRING;
        case r'STAFF_ASSIGNED': return NotificationResponseTypeEnum.STAFF_ASSIGNED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotificationResponseTypeEnumTypeTransformer? _instance;
}



enum NotificationResponseRelatedEntityTypeEnum {
  RENTAL_REQUEST._(r'RENTAL_REQUEST'),
  LEASE._(r'LEASE'),
  BILLING_PERIOD._(r'BILLING_PERIOD'),
  PAYMENT._(r'PAYMENT'),
  MAINTENANCE_REQUEST._(r'MAINTENANCE_REQUEST'),
  NOTICE._(r'NOTICE'),
  STAFF_ASSIGNMENT._(r'STAFF_ASSIGNMENT'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotificationResponseRelatedEntityTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotificationResponseRelatedEntityTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotificationResponseRelatedEntityTypeEnum? fromJson(dynamic value) => NotificationResponseRelatedEntityTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotificationResponseRelatedEntityTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotificationResponseRelatedEntityTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationResponseRelatedEntityTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationResponseRelatedEntityTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationResponseRelatedEntityTypeEnum] to String,
/// and [decode] dynamic data back to [NotificationResponseRelatedEntityTypeEnum].
class NotificationResponseRelatedEntityTypeEnumTypeTransformer {
  factory NotificationResponseRelatedEntityTypeEnumTypeTransformer() => _instance ??= const NotificationResponseRelatedEntityTypeEnumTypeTransformer._();

  const NotificationResponseRelatedEntityTypeEnumTypeTransformer._();

  String encode(NotificationResponseRelatedEntityTypeEnum data) => data._value;

  /// Returns the instance of [NotificationResponseRelatedEntityTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationResponseRelatedEntityTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotificationResponseRelatedEntityTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RENTAL_REQUEST': return NotificationResponseRelatedEntityTypeEnum.RENTAL_REQUEST;
        case r'LEASE': return NotificationResponseRelatedEntityTypeEnum.LEASE;
        case r'BILLING_PERIOD': return NotificationResponseRelatedEntityTypeEnum.BILLING_PERIOD;
        case r'PAYMENT': return NotificationResponseRelatedEntityTypeEnum.PAYMENT;
        case r'MAINTENANCE_REQUEST': return NotificationResponseRelatedEntityTypeEnum.MAINTENANCE_REQUEST;
        case r'NOTICE': return NotificationResponseRelatedEntityTypeEnum.NOTICE;
        case r'STAFF_ASSIGNMENT': return NotificationResponseRelatedEntityTypeEnum.STAFF_ASSIGNMENT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotificationResponseRelatedEntityTypeEnumTypeTransformer? _instance;
}


