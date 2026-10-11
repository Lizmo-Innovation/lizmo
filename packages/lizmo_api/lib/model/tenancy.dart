//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Tenancy {
  /// Returns a new [Tenancy] instance.
  Tenancy({
    this.leaseId,
    this.place,
    this.startDate,
    this.endDate,
    this.active,
  });

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
  String? place;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? active;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Tenancy &&
    other.leaseId == leaseId &&
    other.place == place &&
    other.startDate == startDate &&
    other.endDate == endDate &&
    other.active == active;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (place == null ? 0 : place!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (active == null ? 0 : active!.hashCode);

  @override
  String toString() => 'Tenancy[leaseId=$leaseId, place=$place, startDate=$startDate, endDate=$endDate, active=$active]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
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
    if (this.active != null) {
      json[r'active'] = this.active;
    } else {
      json[r'active'] = null;
    }
    return json;
  }

  /// Returns a new [Tenancy] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Tenancy? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Tenancy(
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        place: mapValueOfType<String>(json, r'place'),
        startDate: mapDateTime(json, r'startDate', r''),
        endDate: mapDateTime(json, r'endDate', r''),
        active: mapValueOfType<bool>(json, r'active'),
      );
    }
    return null;
  }

  static List<Tenancy> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Tenancy>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Tenancy.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Tenancy> mapFromJson(dynamic json) {
    final map = <String, Tenancy>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Tenancy.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Tenancy-objects as value to a dart map
  static Map<String, List<Tenancy>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Tenancy>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Tenancy.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

