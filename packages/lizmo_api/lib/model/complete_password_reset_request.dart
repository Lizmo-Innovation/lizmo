//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CompletePasswordResetRequest {
  /// Returns a new [CompletePasswordResetRequest] instance.
  CompletePasswordResetRequest({
    required this.email,
    required this.code,
    required this.password,
  });

  String email;

  String code;

  String password;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CompletePasswordResetRequest &&
    other.email == email &&
    other.code == code &&
    other.password == password;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (code.hashCode) +
    (password.hashCode);

  @override
  String toString() => 'CompletePasswordResetRequest[email=$email, code=$code, password=$password]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'code'] = this.code;
      json[r'password'] = this.password;
    return json;
  }

  /// Returns a new [CompletePasswordResetRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CompletePasswordResetRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'), 'Required key "CompletePasswordResetRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "CompletePasswordResetRequest[email]" has a null value in JSON.');
        assert(json.containsKey(r'code'), 'Required key "CompletePasswordResetRequest[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "CompletePasswordResetRequest[code]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "CompletePasswordResetRequest[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "CompletePasswordResetRequest[password]" has a null value in JSON.');
        return true;
      }());

      return CompletePasswordResetRequest(
        email: mapValueOfType<String>(json, r'email')!,
        code: mapValueOfType<String>(json, r'code')!,
        password: mapValueOfType<String>(json, r'password')!,
      );
    }
    return null;
  }

  static List<CompletePasswordResetRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CompletePasswordResetRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CompletePasswordResetRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CompletePasswordResetRequest> mapFromJson(dynamic json) {
    final map = <String, CompletePasswordResetRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CompletePasswordResetRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CompletePasswordResetRequest-objects as value to a dart map
  static Map<String, List<CompletePasswordResetRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CompletePasswordResetRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CompletePasswordResetRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'code',
    'password',
  };
}

