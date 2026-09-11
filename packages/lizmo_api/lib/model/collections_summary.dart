//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CollectionsSummary {
  /// Returns a new [CollectionsSummary] instance.
  CollectionsSummary({
    this.dueThisMonth,
    this.collectedThisMonth,
    this.outstandingAllTime,
    this.awaitingConfirmation,
    this.tenanciesInArrears,
    this.inArrears = const [],
    this.awaiting = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? dueThisMonth;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? collectedThisMonth;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? outstandingAllTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? awaitingConfirmation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? tenanciesInArrears;

  List<ArrearsRow> inArrears;

  List<AwaitingRow> awaiting;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CollectionsSummary &&
    other.dueThisMonth == dueThisMonth &&
    other.collectedThisMonth == collectedThisMonth &&
    other.outstandingAllTime == outstandingAllTime &&
    other.awaitingConfirmation == awaitingConfirmation &&
    other.tenanciesInArrears == tenanciesInArrears &&
    _deepEquality.equals(other.inArrears, inArrears) &&
    _deepEquality.equals(other.awaiting, awaiting);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (dueThisMonth == null ? 0 : dueThisMonth!.hashCode) +
    (collectedThisMonth == null ? 0 : collectedThisMonth!.hashCode) +
    (outstandingAllTime == null ? 0 : outstandingAllTime!.hashCode) +
    (awaitingConfirmation == null ? 0 : awaitingConfirmation!.hashCode) +
    (tenanciesInArrears == null ? 0 : tenanciesInArrears!.hashCode) +
    (inArrears.hashCode) +
    (awaiting.hashCode);

  @override
  String toString() => 'CollectionsSummary[dueThisMonth=$dueThisMonth, collectedThisMonth=$collectedThisMonth, outstandingAllTime=$outstandingAllTime, awaitingConfirmation=$awaitingConfirmation, tenanciesInArrears=$tenanciesInArrears, inArrears=$inArrears, awaiting=$awaiting]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.dueThisMonth != null) {
      json[r'dueThisMonth'] = this.dueThisMonth;
    } else {
      json[r'dueThisMonth'] = null;
    }
    if (this.collectedThisMonth != null) {
      json[r'collectedThisMonth'] = this.collectedThisMonth;
    } else {
      json[r'collectedThisMonth'] = null;
    }
    if (this.outstandingAllTime != null) {
      json[r'outstandingAllTime'] = this.outstandingAllTime;
    } else {
      json[r'outstandingAllTime'] = null;
    }
    if (this.awaitingConfirmation != null) {
      json[r'awaitingConfirmation'] = this.awaitingConfirmation;
    } else {
      json[r'awaitingConfirmation'] = null;
    }
    if (this.tenanciesInArrears != null) {
      json[r'tenanciesInArrears'] = this.tenanciesInArrears;
    } else {
      json[r'tenanciesInArrears'] = null;
    }
      json[r'inArrears'] = this.inArrears;
      json[r'awaiting'] = this.awaiting;
    return json;
  }

  /// Returns a new [CollectionsSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollectionsSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return CollectionsSummary(
        dueThisMonth: json[r'dueThisMonth'] == null
            ? null
            : num.parse('${json[r'dueThisMonth']}'),
        collectedThisMonth: json[r'collectedThisMonth'] == null
            ? null
            : num.parse('${json[r'collectedThisMonth']}'),
        outstandingAllTime: json[r'outstandingAllTime'] == null
            ? null
            : num.parse('${json[r'outstandingAllTime']}'),
        awaitingConfirmation: mapValueOfType<int>(json, r'awaitingConfirmation'),
        tenanciesInArrears: mapValueOfType<int>(json, r'tenanciesInArrears'),
        inArrears: ArrearsRow.listFromJson(json[r'inArrears']),
        awaiting: AwaitingRow.listFromJson(json[r'awaiting']),
      );
    }
    return null;
  }

  static List<CollectionsSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CollectionsSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollectionsSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollectionsSummary> mapFromJson(dynamic json) {
    final map = <String, CollectionsSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollectionsSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollectionsSummary-objects as value to a dart map
  static Map<String, List<CollectionsSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CollectionsSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollectionsSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

