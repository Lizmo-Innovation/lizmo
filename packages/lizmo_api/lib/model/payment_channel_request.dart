//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaymentChannelRequest {
  /// Returns a new [PaymentChannelRequest] instance.
  PaymentChannelRequest({
    required this.channel,
    required this.accountName,
    required this.accountNumber,
    this.visible,
  });

  String channel;

  String accountName;

  String accountNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? visible;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentChannelRequest &&
    other.channel == channel &&
    other.accountName == accountName &&
    other.accountNumber == accountNumber &&
    other.visible == visible;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (channel.hashCode) +
    (accountName.hashCode) +
    (accountNumber.hashCode) +
    (visible == null ? 0 : visible!.hashCode);

  @override
  String toString() => 'PaymentChannelRequest[channel=$channel, accountName=$accountName, accountNumber=$accountNumber, visible=$visible]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'channel'] = this.channel;
      json[r'accountName'] = this.accountName;
      json[r'accountNumber'] = this.accountNumber;
    if (this.visible != null) {
      json[r'visible'] = this.visible;
    } else {
      json[r'visible'] = null;
    }
    return json;
  }

  /// Returns a new [PaymentChannelRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentChannelRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'channel'), 'Required key "PaymentChannelRequest[channel]" is missing from JSON.');
        assert(json[r'channel'] != null, 'Required key "PaymentChannelRequest[channel]" has a null value in JSON.');
        assert(json.containsKey(r'accountName'), 'Required key "PaymentChannelRequest[accountName]" is missing from JSON.');
        assert(json[r'accountName'] != null, 'Required key "PaymentChannelRequest[accountName]" has a null value in JSON.');
        assert(json.containsKey(r'accountNumber'), 'Required key "PaymentChannelRequest[accountNumber]" is missing from JSON.');
        assert(json[r'accountNumber'] != null, 'Required key "PaymentChannelRequest[accountNumber]" has a null value in JSON.');
        return true;
      }());

      return PaymentChannelRequest(
        channel: mapValueOfType<String>(json, r'channel')!,
        accountName: mapValueOfType<String>(json, r'accountName')!,
        accountNumber: mapValueOfType<String>(json, r'accountNumber')!,
        visible: mapValueOfType<bool>(json, r'visible'),
      );
    }
    return null;
  }

  static List<PaymentChannelRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentChannelRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentChannelRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentChannelRequest> mapFromJson(dynamic json) {
    final map = <String, PaymentChannelRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentChannelRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentChannelRequest-objects as value to a dart map
  static Map<String, List<PaymentChannelRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentChannelRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentChannelRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'channel',
    'accountName',
    'accountNumber',
  };
}

