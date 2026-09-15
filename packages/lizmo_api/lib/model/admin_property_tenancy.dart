//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminPropertyTenancy {
  /// Returns a new [AdminPropertyTenancy] instance.
  AdminPropertyTenancy({
    this.leaseId,
    this.tenantName,
    this.tenantPhone,
    this.tenantEmail,
    this.startDate,
    this.endDate,
    this.rent,
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
  String? tenantName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantPhone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantEmail;

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
  num? rent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdminPropertyTenancy &&
    other.leaseId == leaseId &&
    other.tenantName == tenantName &&
    other.tenantPhone == tenantPhone &&
    other.tenantEmail == tenantEmail &&
    other.startDate == startDate &&
    other.endDate == endDate &&
    other.rent == rent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (tenantName == null ? 0 : tenantName!.hashCode) +
    (tenantPhone == null ? 0 : tenantPhone!.hashCode) +
    (tenantEmail == null ? 0 : tenantEmail!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (rent == null ? 0 : rent!.hashCode);

  @override
  String toString() => 'AdminPropertyTenancy[leaseId=$leaseId, tenantName=$tenantName, tenantPhone=$tenantPhone, tenantEmail=$tenantEmail, startDate=$startDate, endDate=$endDate, rent=$rent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.leaseId != null) {
      json[r'leaseId'] = this.leaseId;
    } else {
      json[r'leaseId'] = null;
    }
    if (this.tenantName != null) {
      json[r'tenantName'] = this.tenantName;
    } else {
      json[r'tenantName'] = null;
    }
    if (this.tenantPhone != null) {
      json[r'tenantPhone'] = this.tenantPhone;
    } else {
      json[r'tenantPhone'] = null;
    }
    if (this.tenantEmail != null) {
      json[r'tenantEmail'] = this.tenantEmail;
    } else {
      json[r'tenantEmail'] = null;
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
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
    return json;
  }

  /// Returns a new [AdminPropertyTenancy] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminPropertyTenancy? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AdminPropertyTenancy(
        leaseId: mapValueOfType<String>(json, r'leaseId'),
        tenantName: mapValueOfType<String>(json, r'tenantName'),
        tenantPhone: mapValueOfType<String>(json, r'tenantPhone'),
        tenantEmail: mapValueOfType<String>(json, r'tenantEmail'),
        startDate: mapDateTime(json, r'startDate', r''),
        endDate: mapDateTime(json, r'endDate', r''),
        rent: json[r'rent'] == null
            ? null
            : num.parse('${json[r'rent']}'),
      );
    }
    return null;
  }

  static List<AdminPropertyTenancy> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdminPropertyTenancy>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminPropertyTenancy.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminPropertyTenancy> mapFromJson(dynamic json) {
    final map = <String, AdminPropertyTenancy>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminPropertyTenancy.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminPropertyTenancy-objects as value to a dart map
  static Map<String, List<AdminPropertyTenancy>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdminPropertyTenancy>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminPropertyTenancy.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

