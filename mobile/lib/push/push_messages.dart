import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

import '../auth/active_role.dart';
import '../inquiry/inquiry_providers.dart';
import '../notice/notice_providers.dart';
import '../notifications/notification_links.dart';
import '../notifications/notification_providers.dart';
import '../router.dart';
import 'push_providers.dart';

/// What a push says it is about, read back as the notification it was raised
/// from, so a tap goes wherever a tap in the bell would.
///
/// Null when it carries no notification at all -- nothing Lizmo sent.
NotificationResponse? notificationOf(Map<String, String> data) {
  final id = data['notificationId'];
  if (id == null || id.isEmpty) return null;
  return NotificationResponse(
    id: id,
    type: NotificationResponseTypeEnum.fromJson(data['type']),
    relatedEntityType:
        NotificationResponseRelatedEntityTypeEnum.fromJson(data['relatedEntityType']),
    relatedEntityId: _present(data['relatedEntityId']),
    leaseId: _present(data['leaseId']),
    propertyId: _present(data['propertyId']),
    unread: true,
  );
}

String? _present(String? value) => value == null || value.isEmpty ? null : value;

/// Pushes the app hears about: one arriving while it is open, and one tapped
/// from the notification shade.
///
/// Open, Android shows nothing of its own, and neither does Lizmo: somebody
/// looking at the app is shown the news where it belongs -- the bell, and the
/// conversation if that is what is on screen -- rather than a banner over it.
final pushMessagesProvider = Provider<void>((ref) {
  final channel = ref.watch(pushChannelProvider);

  void arrived(Map<String, String> data) {
    ref.invalidate(myNotificationsProvider);
    if (data['relatedEntityType'] == 'NOTICE') {
      ref.invalidate(myNoticesProvider);
    }
    if (data['relatedEntityType'] == 'INQUIRY') {
      ref.invalidate(myInquiriesProvider);
      final thread = _present(data['relatedEntityId']);
      if (thread != null) ref.invalidate(inquiryThreadProvider(thread));
    }
  }

  void opened(Map<String, String> data) {
    if (notificationOf(data) == null) return;
    ref.read(pendingPushOpenProvider.notifier).state = data;
  }

  final subscriptions = [
    channel.arrived.listen(arrived, onError: (_) {}),
    channel.opened.listen(opened, onError: (_) {}),
  ];
  ref.onDispose(() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  });

  // Tapped while the app was not running at all: it starts with this.
  unawaited(channel.openedAtLaunch().then((data) {
    if (data != null) opened(data);
  }, onError: (_) {}));
});

/// A tapped push, waiting until there is somewhere to open it from.
///
/// From a cold start that is a while: the splash holds, the session is
/// restored, and the router lands on home. Opening before then would be
/// undone by the redirect that follows.
final pendingPushOpenProvider =
    StateProvider<Map<String, String>?>((ref) => null);

/// Opens the pending push once the app is signed in and showing a tab.
final pushOpenerProvider = Provider<void>((ref) {
  final pending = ref.watch(pendingPushOpenProvider);
  if (pending == null) return;

  final auth = ref.watch(authControllerProvider);
  if (auth is AuthSignedOut) {
    // Not theirs to open any more: the phone was signed out since.
    Future.microtask(
        () => ref.read(pendingPushOpenProvider.notifier).state = null);
    return;
  }
  final persona = ref.watch(activeRoleProvider);
  if (auth is! AuthSignedIn || persona == null) return;

  final router = ref.watch(routerProvider);
  final delegate = router.routerDelegate;

  void attempt() {
    final here = delegate.currentConfiguration.uri.path;
    if (!isSettled(here)) return;
    delegate.removeListener(attempt);
    ref.read(pendingPushOpenProvider.notifier).state = null;

    final notification = notificationOf(pending);
    if (notification == null) return;
    // Tapping it is reading it, as in the bell.
    unawaited(ref.read(notificationReaderProvider).one(notification.id!));

    switch (pushStep(destinationOf(notification, persona), here, persona)) {
      case PushGo(:final path):
        router.go(path);
      case PushPush(:final path):
        router.push(path);
      case PushReplace(:final path):
        router.pushReplacement(path);
      case null:
        break;
    }
  }

  delegate.addListener(attempt);
  ref.onDispose(() => delegate.removeListener(attempt));
  Future.microtask(attempt);
});

/// Somewhere a push can be opened from: a tab, or a conversation. Not the
/// splash, login, or a screen the router is about to redirect away from.
bool isSettled(String location) =>
    location.startsWith('/inquiry/') ||
    Routes.tabRoots
        .any((root) => location == root || location.startsWith('$root/'));

/// How to reach a push's destination from [here].
sealed class PushStep {
  const PushStep(this.path);

  final String path;
}

final class PushGo extends PushStep {
  const PushGo(super.path);
}

final class PushPush extends PushStep {
  const PushPush(super.path);
}

final class PushReplace extends PushStep {
  const PushReplace(super.path);
}

/// As the bell does it, with one difference: a push can land on top of a
/// conversation, which is above the tabs. A detail is then opened in the
/// home tab rather than inside a tab that is not showing, and a second
/// conversation replaces the first rather than stacking on it.
PushStep? pushStep(
  NotificationDestination? destination,
  String here,
  LizmoProfile persona,
) {
  final inATab = !here.startsWith('/inquiry/');
  final home = persona == LizmoProfile.tenant ? Routes.tenantHome : Routes.landlordHome;

  return switch (destination) {
    OpenDetail(:final detail) => inATab
        ? PushPush('${Routes.tabRootOf(here)}/$detail')
        : PushGo('$home/$detail'),
    OpenScreen(:final path) => inATab ? PushPush(path) : PushReplace(path),
    SwitchTab(:final tab) => PushGo(tab),
    null => null,
  };
}
