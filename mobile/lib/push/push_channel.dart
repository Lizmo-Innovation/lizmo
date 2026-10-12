import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import 'push_permission.dart';

/// Where this phone's push token comes from.
///
/// Firebase on a real phone; nothing at all in a widget test, on a desktop
/// build, or on a phone where Firebase would not start. A missing channel is
/// a phone that is not pushed to, never an app that will not open.
abstract class PushChannel {
  /// This install's token, or null when there is none to give.
  Future<String?> token();

  /// A new token, when Firebase replaces the old one.
  Stream<String> get tokenRefreshes;

  /// Throws the token away, so whatever still holds it reaches nobody.
  Future<void> deleteToken();

  Future<PushPermission> permission();

  /// Android's own prompt. Asked only after Lizmo's, never cold.
  Future<PushPermission> askPermission();

  /// The phone's notification settings for Lizmo, for a "no" that Android
  /// will not ask about again.
  Future<void> openSettings();

  /// A push that arrived while the app was open, as the data it carries.
  Stream<Map<String, String>> get arrived;

  /// A push tapped while the app was in the background.
  Stream<Map<String, String>> get opened;

  /// The push tapped to start the app, if that is how it started.
  Future<Map<String, String>?> openedAtLaunch();
}

class NoPushChannel implements PushChannel {
  const NoPushChannel();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Future<PushPermission> permission() async => PushPermission.unsupported;

  @override
  Future<PushPermission> askPermission() async => PushPermission.unsupported;

  @override
  Future<void> openSettings() async {}

  @override
  Stream<Map<String, String>> get arrived => const Stream.empty();

  @override
  Stream<Map<String, String>> get opened => const Stream.empty();

  @override
  Future<Map<String, String>?> openedAtLaunch() async => null;
}

/// Used only once `Firebase.initializeApp` has succeeded.
class FirebasePushChannel implements PushChannel {
  const FirebasePushChannel();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Future<PushPermission> permission() async =>
      _permission((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> askPermission() async =>
      _permission((await _messaging.requestPermission()).authorizationStatus);

  /// Firebase has no way to open settings; MainActivity does it.
  static const _settings = MethodChannel('app.lizmo/settings');

  @override
  Future<void> openSettings() =>
      _settings.invokeMethod<void>('openNotificationSettings');

  @override
  Stream<Map<String, String>> get arrived => FirebaseMessaging.onMessage.map(_data);

  @override
  Stream<Map<String, String>> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(_data);

  @override
  Future<Map<String, String>?> openedAtLaunch() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _data(message);
  }

  static Map<String, String> _data(RemoteMessage message) =>
      message.data.map((key, value) => MapEntry(key, '$value'));

  static PushPermission _permission(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          PushPermission.granted,
        AuthorizationStatus.notDetermined => PushPermission.notAsked,
        AuthorizationStatus.denied => PushPermission.denied,
        AuthorizationStatus.deniedPermanently => PushPermission.blocked,
      };
}
