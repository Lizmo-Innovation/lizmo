//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LandlordCard {
  /// Returns a new [LandlordCard] instance.
  LandlordCard({
    this.name,
    this.since,
    this.replies,
  });

  /// First name and last initial
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// When they joined Lizmo; the apps show the month
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? since;

  /// How fast they usually answer somebody asking. Null until there have been enough conversations to say.
  LandlordCardRepliesEnum? replies;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LandlordCard &&
    other.name == name &&
    other.since == since &&
    other.replies == replies;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (since == null ? 0 : since!.hashCode) +
    (replies == null ? 0 : replies!.hashCode);

  @override
  String toString() => 'LandlordCard[name=$name, since=$since, replies=$replies]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.since != null) {
      json[r'since'] = _dateFormatter.format(this.since!);
    } else {
      json[r'since'] = null;
    }
    if (this.replies != null) {
      json[r'replies'] = this.replies;
    } else {
      json[r'replies'] = null;
    }
    return json;
  }

  /// Returns a new [LandlordCard] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LandlordCard? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LandlordCard(
        name: mapValueOfType<String>(json, r'name'),
        since: mapDateTime(json, r'since', r''),
        replies: LandlordCardRepliesEnum.fromJson(json[r'replies']),
      );
    }
    return null;
  }

  static List<LandlordCard> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LandlordCard>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LandlordCard.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LandlordCard> mapFromJson(dynamic json) {
    final map = <String, LandlordCard>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LandlordCard.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LandlordCard-objects as value to a dart map
  static Map<String, List<LandlordCard>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LandlordCard>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LandlordCard.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

/// How fast they usually answer somebody asking. Null until there have been enough conversations to say.
enum LandlordCardRepliesEnum {
  WITHIN_AN_HOUR._(r'WITHIN_AN_HOUR'),
  WITHIN_A_DAY._(r'WITHIN_A_DAY'),
  WITHIN_DAYS._(r'WITHIN_DAYS'),
  ;

  /// Instantiate a new enum with the provided value.
  const LandlordCardRepliesEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [LandlordCardRepliesEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static LandlordCardRepliesEnum? fromJson(dynamic value) => LandlordCardRepliesEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [LandlordCardRepliesEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<LandlordCardRepliesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LandlordCardRepliesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LandlordCardRepliesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LandlordCardRepliesEnum] to String,
/// and [decode] dynamic data back to [LandlordCardRepliesEnum].
class LandlordCardRepliesEnumTypeTransformer {
  factory LandlordCardRepliesEnumTypeTransformer() => _instance ??= const LandlordCardRepliesEnumTypeTransformer._();

  const LandlordCardRepliesEnumTypeTransformer._();

  String encode(LandlordCardRepliesEnum data) => data._value;

  /// Returns the instance of [LandlordCardRepliesEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LandlordCardRepliesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is LandlordCardRepliesEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WITHIN_AN_HOUR': return LandlordCardRepliesEnum.WITHIN_AN_HOUR;
        case r'WITHIN_A_DAY': return LandlordCardRepliesEnum.WITHIN_A_DAY;
        case r'WITHIN_DAYS': return LandlordCardRepliesEnum.WITHIN_DAYS;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static LandlordCardRepliesEnumTypeTransformer? _instance;
}


