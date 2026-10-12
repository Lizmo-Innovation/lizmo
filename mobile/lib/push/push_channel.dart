import 'package:firebase_messaging/firebase_messaging.dart';

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
}

class NoPushChannel implements PushChannel {
  const NoPushChannel();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<void> deleteToken() async {}
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
}
