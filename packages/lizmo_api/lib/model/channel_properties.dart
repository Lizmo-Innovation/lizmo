//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ChannelProperties {
  /// Returns a new [ChannelProperties] instance.
  ChannelProperties({
    this.propertyIds = const [],
  });

  List<String> propertyIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChannelProperties &&
    _deepEquality.equals(other.propertyIds, propertyIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (propertyIds.hashCode);

  @override
  String toString() => 'ChannelProperties[propertyIds=$propertyIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'propertyIds'] = this.propertyIds;
    return json;
  }

  /// Returns a new [ChannelProperties] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ChannelProperties? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ChannelProperties(
        propertyIds: json[r'propertyIds'] is Iterable
            ? (json[r'propertyIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<ChannelProperties> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ChannelProperties>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChannelProperties.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ChannelProperties> mapFromJson(dynamic json) {
    final map = <String, ChannelProperties>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ChannelProperties.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ChannelProperties-objects as value to a dart map
  static Map<String, List<ChannelProperties>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ChannelProperties>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ChannelProperties.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

