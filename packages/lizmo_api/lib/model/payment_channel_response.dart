//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaymentChannelResponse {
  /// Returns a new [PaymentChannelResponse] instance.
  PaymentChannelResponse({
    this.id,
    this.channel,
    this.accountName,
    this.accountNumber,
    this.visible,
    this.sortOrder,
    this.qrUrl,
    this.qrUrlExpiresInSeconds,
    this.propertyIds = const [],
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
  bool? visible;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? sortOrder;

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

  List<String> propertyIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentChannelResponse &&
    other.id == id &&
    other.channel == channel &&
    other.accountName == accountName &&
    other.accountNumber == accountNumber &&
    other.visible == visible &&
    other.sortOrder == sortOrder &&
    other.qrUrl == qrUrl &&
    other.qrUrlExpiresInSeconds == qrUrlExpiresInSeconds &&
    _deepEquality.equals(other.propertyIds, propertyIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (channel == null ? 0 : channel!.hashCode) +
    (accountName == null ? 0 : accountName!.hashCode) +
    (accountNumber == null ? 0 : accountNumber!.hashCode) +
    (visible == null ? 0 : visible!.hashCode) +
    (sortOrder == null ? 0 : sortOrder!.hashCode) +
    (qrUrl == null ? 0 : qrUrl!.hashCode) +
    (qrUrlExpiresInSeconds == null ? 0 : qrUrlExpiresInSeconds!.hashCode) +
    (propertyIds.hashCode);

  @override
  String toString() => 'PaymentChannelResponse[id=$id, channel=$channel, accountName=$accountName, accountNumber=$accountNumber, visible=$visible, sortOrder=$sortOrder, qrUrl=$qrUrl, qrUrlExpiresInSeconds=$qrUrlExpiresInSeconds, propertyIds=$propertyIds]';

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
    if (this.visible != null) {
      json[r'visible'] = this.visible;
    } else {
      json[r'visible'] = null;
    }
    if (this.sortOrder != null) {
      json[r'sortOrder'] = this.sortOrder;
    } else {
      json[r'sortOrder'] = null;
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
      json[r'propertyIds'] = this.propertyIds;
    return json;
  }

  /// Returns a new [PaymentChannelResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentChannelResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PaymentChannelResponse(
        id: mapValueOfType<String>(json, r'id'),
        channel: mapValueOfType<String>(json, r'channel'),
        accountName: mapValueOfType<String>(json, r'accountName'),
        accountNumber: mapValueOfType<String>(json, r'accountNumber'),
        visible: mapValueOfType<bool>(json, r'visible'),
        sortOrder: mapValueOfType<int>(json, r'sortOrder'),
        qrUrl: mapValueOfType<String>(json, r'qrUrl'),
        qrUrlExpiresInSeconds: mapValueOfType<int>(json, r'qrUrlExpiresInSeconds'),
        propertyIds: json[r'propertyIds'] is Iterable
            ? (json[r'propertyIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<PaymentChannelResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentChannelResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentChannelResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentChannelResponse> mapFromJson(dynamic json) {
    final map = <String, PaymentChannelResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentChannelResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentChannelResponse-objects as value to a dart map
  static Map<String, List<PaymentChannelResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentChannelResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentChannelResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

