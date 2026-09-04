//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AcceptInvitationRequest {
  /// Returns a new [AcceptInvitationRequest] instance.
  AcceptInvitationRequest({
    required this.token,
    this.name,
    required this.password,
  });

  String token;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  String password;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AcceptInvitationRequest &&
    other.token == token &&
    other.name == name &&
    other.password == password;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (token.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (password.hashCode);

  @override
  String toString() => 'AcceptInvitationRequest[token=$token, name=$name, password=$password]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'token'] = this.token;
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
      json[r'password'] = this.password;
    return json;
  }

  /// Returns a new [AcceptInvitationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AcceptInvitationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'token'), 'Required key "AcceptInvitationRequest[token]" is missing from JSON.');
        assert(json[r'token'] != null, 'Required key "AcceptInvitationRequest[token]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "AcceptInvitationRequest[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "AcceptInvitationRequest[password]" has a null value in JSON.');
        return true;
      }());

      return AcceptInvitationRequest(
        token: mapValueOfType<String>(json, r'token')!,
        name: mapValueOfType<String>(json, r'name'),
        password: mapValueOfType<String>(json, r'password')!,
      );
    }
    return null;
  }

  static List<AcceptInvitationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AcceptInvitationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AcceptInvitationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AcceptInvitationRequest> mapFromJson(dynamic json) {
    final map = <String, AcceptInvitationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AcceptInvitationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AcceptInvitationRequest-objects as value to a dart map
  static Map<String, List<AcceptInvitationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AcceptInvitationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AcceptInvitationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'token',
    'password',
  };
}

