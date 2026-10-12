//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AcceptRequest {
  /// Returns a new [AcceptRequest] instance.
  AcceptRequest({
    this.unitId,
    this.bedId,
    this.rentAmount,
    this.dueDateDay,
    this.startDate,
    this.depositAmount,
    this.advanceAmount,
    this.endsOn,
  });

  /// Which room to give them. Required when the request is about the property rather than one room, and ignored when it names one.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitId;

  /// Which bed, when that unit is let bed by bed
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bedId;

  /// Defaults to the asking rent
  ///
  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? rentAmount;

  /// Defaults to the start date's day
  ///
  /// Minimum value: 1
  /// Maximum value: 31
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? dueDateDay;

  /// Defaults to today
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startDate;

  /// Held against damage, and mostly given back. Not rent. Null means none was recorded, which is not the same as none being taken.
  ///
  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? depositAmount;

  /// Rent paid before moving in, which pays for the first month. Kept apart from the deposit because it is money the landlord has earned rather than money they are holding.
  ///
  /// Minimum value: 0.0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? advanceAmount;

  /// The last day of the lease, if it was agreed for a term. Null for month to month, which is the usual case. Both of them are warned as it nears; passing it ends nothing.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endsOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AcceptRequest &&
    other.unitId == unitId &&
    other.bedId == bedId &&
    other.rentAmount == rentAmount &&
    other.dueDateDay == dueDateDay &&
    other.startDate == startDate &&
    other.depositAmount == depositAmount &&
    other.advanceAmount == advanceAmount &&
    other.endsOn == endsOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (unitId == null ? 0 : unitId!.hashCode) +
    (bedId == null ? 0 : bedId!.hashCode) +
    (rentAmount == null ? 0 : rentAmount!.hashCode) +
    (dueDateDay == null ? 0 : dueDateDay!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (depositAmount == null ? 0 : depositAmount!.hashCode) +
    (advanceAmount == null ? 0 : advanceAmount!.hashCode) +
    (endsOn == null ? 0 : endsOn!.hashCode);

  @override
  String toString() => 'AcceptRequest[unitId=$unitId, bedId=$bedId, rentAmount=$rentAmount, dueDateDay=$dueDateDay, startDate=$startDate, depositAmount=$depositAmount, advanceAmount=$advanceAmount, endsOn=$endsOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.unitId != null) {
      json[r'unitId'] = this.unitId;
    } else {
      json[r'unitId'] = null;
    }
    if (this.bedId != null) {
      json[r'bedId'] = this.bedId;
    } else {
      json[r'bedId'] = null;
    }
    if (this.rentAmount != null) {
      json[r'rentAmount'] = this.rentAmount;
    } else {
      json[r'rentAmount'] = null;
    }
    if (this.dueDateDay != null) {
      json[r'dueDateDay'] = this.dueDateDay;
    } else {
      json[r'dueDateDay'] = null;
    }
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!);
    } else {
      json[r'startDate'] = null;
    }
    if (this.depositAmount != null) {
      json[r'depositAmount'] = this.depositAmount;
    } else {
      json[r'depositAmount'] = null;
    }
    if (this.advanceAmount != null) {
      json[r'advanceAmount'] = this.advanceAmount;
    } else {
      json[r'advanceAmount'] = null;
    }
    if (this.endsOn != null) {
      json[r'endsOn'] = _dateFormatter.format(this.endsOn!);
    } else {
      json[r'endsOn'] = null;
    }
    return json;
  }

  /// Returns a new [AcceptRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AcceptRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AcceptRequest(
        unitId: mapValueOfType<String>(json, r'unitId'),
        bedId: mapValueOfType<String>(json, r'bedId'),
        rentAmount: json[r'rentAmount'] == null
            ? null
            : num.parse('${json[r'rentAmount']}'),
        dueDateDay: mapValueOfType<int>(json, r'dueDateDay'),
        startDate: mapDateTime(json, r'startDate', r''),
        depositAmount: json[r'depositAmount'] == null
            ? null
            : num.parse('${json[r'depositAmount']}'),
        advanceAmount: json[r'advanceAmount'] == null
            ? null
            : num.parse('${json[r'advanceAmount']}'),
        endsOn: mapDateTime(json, r'endsOn', r''),
      );
    }
    return null;
  }

  static List<AcceptRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AcceptRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AcceptRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AcceptRequest> mapFromJson(dynamic json) {
    final map = <String, AcceptRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AcceptRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AcceptRequest-objects as value to a dart map
  static Map<String, List<AcceptRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AcceptRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AcceptRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

