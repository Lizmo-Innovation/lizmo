//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ThreadEvent {
  /// Returns a new [ThreadEvent] instance.
  ThreadEvent({
    this.kind,
    this.at,
    this.entityId,
    this.amount,
    this.label,
    this.receiptNumber,
    this.state,
  });

  /// What kind of thing happened
  ThreadEventKindEnum? kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? at;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? entityId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? amount;

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
  String? receiptNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? state;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ThreadEvent &&
    other.kind == kind &&
    other.at == at &&
    other.entityId == entityId &&
    other.amount == amount &&
    other.label == label &&
    other.receiptNumber == receiptNumber &&
    other.state == state;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind == null ? 0 : kind!.hashCode) +
    (at == null ? 0 : at!.hashCode) +
    (entityId == null ? 0 : entityId!.hashCode) +
    (amount == null ? 0 : amount!.hashCode) +
    (label == null ? 0 : label!.hashCode) +
    (receiptNumber == null ? 0 : receiptNumber!.hashCode) +
    (state == null ? 0 : state!.hashCode);

  @override
  String toString() => 'ThreadEvent[kind=$kind, at=$at, entityId=$entityId, amount=$amount, label=$label, receiptNumber=$receiptNumber, state=$state]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.at != null) {
      json[r'at'] = this.at!.toUtc().toIso8601String();
    } else {
      json[r'at'] = null;
    }
    if (this.entityId != null) {
      json[r'entityId'] = this.entityId;
    } else {
      json[r'entityId'] = null;
    }
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    if (this.receiptNumber != null) {
      json[r'receiptNumber'] = this.receiptNumber;
    } else {
      json[r'receiptNumber'] = null;
    }
    if (this.state != null) {
      json[r'state'] = this.state;
    } else {
      json[r'state'] = null;
    }
    return json;
  }

  /// Returns a new [ThreadEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ThreadEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ThreadEvent(
        kind: ThreadEventKindEnum.fromJson(json[r'kind']),
        at: mapDateTime(json, r'at', r''),
        entityId: mapValueOfType<String>(json, r'entityId'),
        amount: json[r'amount'] == null
            ? null
            : num.parse('${json[r'amount']}'),
        label: mapValueOfType<String>(json, r'label'),
        receiptNumber: mapValueOfType<String>(json, r'receiptNumber'),
        state: mapValueOfType<String>(json, r'state'),
      );
    }
    return null;
  }

  static List<ThreadEvent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ThreadEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ThreadEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ThreadEvent> mapFromJson(dynamic json) {
    final map = <String, ThreadEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ThreadEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ThreadEvent-objects as value to a dart map
  static Map<String, List<ThreadEvent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ThreadEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ThreadEvent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

/// What kind of thing happened
enum ThreadEventKindEnum {
  ID_SHARED._(r'ID_SHARED'),
  PAYMENT_REPORTED._(r'PAYMENT_REPORTED'),
  PAYMENT_CONFIRMED._(r'PAYMENT_CONFIRMED'),
  PAYMENT_REJECTED._(r'PAYMENT_REJECTED'),
  REPAIR_REPORTED._(r'REPAIR_REPORTED'),
  LEASE_STARTED._(r'LEASE_STARTED'),
  LEASE_ENDING._(r'LEASE_ENDING'),
  MOVED_OUT._(r'MOVED_OUT'),
  ;

  /// Instantiate a new enum with the provided value.
  const ThreadEventKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ThreadEventKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ThreadEventKindEnum? fromJson(dynamic value) => ThreadEventKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ThreadEventKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ThreadEventKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ThreadEventKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ThreadEventKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ThreadEventKindEnum] to String,
/// and [decode] dynamic data back to [ThreadEventKindEnum].
class ThreadEventKindEnumTypeTransformer {
  factory ThreadEventKindEnumTypeTransformer() => _instance ??= const ThreadEventKindEnumTypeTransformer._();

  const ThreadEventKindEnumTypeTransformer._();

  String encode(ThreadEventKindEnum data) => data._value;

  /// Returns the instance of [ThreadEventKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ThreadEventKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is ThreadEventKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ID_SHARED': return ThreadEventKindEnum.ID_SHARED;
        case r'PAYMENT_REPORTED': return ThreadEventKindEnum.PAYMENT_REPORTED;
        case r'PAYMENT_CONFIRMED': return ThreadEventKindEnum.PAYMENT_CONFIRMED;
        case r'PAYMENT_REJECTED': return ThreadEventKindEnum.PAYMENT_REJECTED;
        case r'REPAIR_REPORTED': return ThreadEventKindEnum.REPAIR_REPORTED;
        case r'LEASE_STARTED': return ThreadEventKindEnum.LEASE_STARTED;
        case r'LEASE_ENDING': return ThreadEventKindEnum.LEASE_ENDING;
        case r'MOVED_OUT': return ThreadEventKindEnum.MOVED_OUT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ThreadEventKindEnumTypeTransformer? _instance;
}


