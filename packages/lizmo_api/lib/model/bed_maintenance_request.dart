//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BedMaintenanceRequest {
  /// Returns a new [BedMaintenanceRequest] instance.
  BedMaintenanceRequest({
    required this.underMaintenance,
  });

  bool underMaintenance;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BedMaintenanceRequest &&
    other.underMaintenance == underMaintenance;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (underMaintenance.hashCode);

  @override
  String toString() => 'BedMaintenanceRequest[underMaintenance=$underMaintenance]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'underMaintenance'] = this.underMaintenance;
    return json;
  }

  /// Returns a new [BedMaintenanceRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BedMaintenanceRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'underMaintenance'), 'Required key "BedMaintenanceRequest[underMaintenance]" is missing from JSON.');
        assert(json[r'underMaintenance'] != null, 'Required key "BedMaintenanceRequest[underMaintenance]" has a null value in JSON.');
        return true;
      }());

      return BedMaintenanceRequest(
        underMaintenance: mapValueOfType<bool>(json, r'underMaintenance')!,
      );
    }
    return null;
  }

  static List<BedMaintenanceRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BedMaintenanceRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BedMaintenanceRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BedMaintenanceRequest> mapFromJson(dynamic json) {
    final map = <String, BedMaintenanceRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BedMaintenanceRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BedMaintenanceRequest-objects as value to a dart map
  static Map<String, List<BedMaintenanceRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BedMaintenanceRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BedMaintenanceRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'underMaintenance',
  };
}

