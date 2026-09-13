//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaymentChannelForLandlord {
  /// Returns a new [PaymentChannelForLandlord] instance.
  PaymentChannelForLandlord({
    this.id,
    this.channel,
    this.accountName,
    this.accountNumber,
    this.qrUrl,
    this.qrUrlExpiresInSeconds,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? channel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? accountName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? accountNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? qrUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? qrUrlExpiresInSeconds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentChannelForLandlord &&
    other.id == id &&
    other.channel == channel &&
    other.accountName == accountName &&
    other.accountNumber == accountNumber &&
    other.qrUrl == qrUrl &&
    other.qrUrlExpiresInSeconds == qrUrlExpiresInSeconds;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (channel == null ? 0 : channel!.hashCode) +
    (accountName == null ? 0 : accountName!.hashCode) +
    (accountNumber == null ? 0 : accountNumber!.hashCode) +
    (qrUrl == null ? 0 : qrUrl!.hashCode) +
    (qrUrlExpiresInSeconds == null ? 0 : qrUrlExpiresInSeconds!.hashCode);

  @override
  String toString() => 'PaymentChannelForLandlord[id=$id, channel=$channel, accountName=$accountName, accountNumber=$accountNumber, qrUrl=$qrUrl, qrUrlExpiresInSeconds=$qrUrlExpiresInSeconds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.channel != null) {
      json[r'channel'] = this.channel;
    } else {
      json[r'channel'] = null;
    }
    if (this.accountName != null) {
      json[r'accountName'] = this.accountName;
    } else {
      json[r'accountName'] = null;
    }
    if (this.accountNumber != null) {
      json[r'accountNumber'] = this.accountNumber;
    } else {
      json[r'accountNumber'] = null;
    }
    if (this.qrUrl != null) {
      json[r'qrUrl'] = this.qrUrl;
    } else {
      json[r'qrUrl'] = null;
    }
    if (this.qrUrlExpiresInSeconds != null) {
      json[r'qrUrlExpiresInSeconds'] = this.qrUrlExpiresInSeconds;
    } else {
      json[r'qrUrlExpiresInSeconds'] = null;
    }
    return json;
  }

  /// Returns a new [PaymentChannelForLandlord] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentChannelForLandlord? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PaymentChannelForLandlord(
        id: mapValueOfType<String>(json, r'id'),
        channel: mapValueOfType<String>(json, r'channel'),
        accountName: mapValueOfType<String>(json, r'accountName'),
        accountNumber: mapValueOfType<String>(json, r'accountNumber'),
        qrUrl: mapValueOfType<String>(json, r'qrUrl'),
        qrUrlExpiresInSeconds: mapValueOfType<int>(json, r'qrUrlExpiresInSeconds'),
      );
    }
    return null;
  }

  static List<PaymentChannelForLandlord> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentChannelForLandlord>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentChannelForLandlord.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentChannelForLandlord> mapFromJson(dynamic json) {
    final map = <String, PaymentChannelForLandlord>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentChannelForLandlord.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentChannelForLandlord-objects as value to a dart map
  static Map<String, List<PaymentChannelForLandlord>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentChannelForLandlord>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentChannelForLandlord.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

