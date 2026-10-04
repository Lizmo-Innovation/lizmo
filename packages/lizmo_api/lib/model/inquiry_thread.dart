//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InquiryThread {
  /// Returns a new [InquiryThread] instance.
  InquiryThread({
    this.inquiry,
    this.messages = const [],
    this.applicant,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  InquirySummary? inquiry;

  List<InquiryMessageResponse> messages;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Applicant? applicant;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InquiryThread &&
    other.inquiry == inquiry &&
    _deepEquality.equals(other.messages, messages) &&
    other.applicant == applicant;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (inquiry == null ? 0 : inquiry!.hashCode) +
    (messages.hashCode) +
    (applicant == null ? 0 : applicant!.hashCode);

  @override
  String toString() => 'InquiryThread[inquiry=$inquiry, messages=$messages, applicant=$applicant]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.inquiry != null) {
      json[r'inquiry'] = this.inquiry;
    } else {
      json[r'inquiry'] = null;
    }
      json[r'messages'] = this.messages;
    if (this.applicant != null) {
      json[r'applicant'] = this.applicant;
    } else {
      json[r'applicant'] = null;
    }
    return json;
  }

  /// Returns a new [InquiryThread] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InquiryThread? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return InquiryThread(
        inquiry: InquirySummary.fromJson(json[r'inquiry']),
        messages: InquiryMessageResponse.listFromJson(json[r'messages']),
        applicant: Applicant.fromJson(json[r'applicant']),
      );
    }
    return null;
  }

  static List<InquiryThread> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InquiryThread>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InquiryThread.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InquiryThread> mapFromJson(dynamic json) {
    final map = <String, InquiryThread>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InquiryThread.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InquiryThread-objects as value to a dart map
  static Map<String, List<InquiryThread>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InquiryThread>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InquiryThread.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

