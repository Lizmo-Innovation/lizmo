import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

/// What the app has to tell whoever is signed in, newest first.
///
/// Not split by persona. A landlord who also has a tenancy — which the app no
/// longer allows, but old accounts exist — would otherwise lose half their
/// news depending on which side they were looking at.
final myNotificationsProvider =
    FutureProvider.autoDispose<List<NotificationResponse>>((ref) async {
  try {
    return await ref.watch(notificationsApiProvider).listMyNotifications() ??
        const [];
  } catch (error) {
    throw ApiFailure.from(error);
  }
});

/// The number on the tab badge.
///
/// Derived from the list rather than fetched from `/unread-count`: the badge
/// and the feed are on screen together, and two requests that can disagree is
/// worse than one. The endpoint stays for the day a badge is drawn somewhere
/// the list is not loaded.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider);
  return notifications.valueOrNull
          // `== true`: the field is nullable in the generated client, and a
          // notification whose state is missing must not light the badge.
          ?.where((notification) => notification.unread == true)
          .length ??
      0;
});

/// Marking things read.
///
/// Read state is the one thing a notification screen writes, and it must not
/// fail loudly: somebody who taps a card wants the thing the card is about,
/// not an error because the mark-read call did not land.
class NotificationReader {
  NotificationReader(this._ref);

  final Ref _ref;

  Future<void> one(String id) => _quietly(
        () => _ref.read(notificationsApiProvider).markNotificationRead(id),
      );

  Future<void> all() => _quietly(
        () => _ref.read(notificationsApiProvider).markAllNotificationsRead(),
      );

  Future<void> _quietly(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {
      // Deliberately swallowed. The list is refreshed either way, so a failed
      // mark-read shows up as a card that is still unread — which is the
      // truth, and self-correcting on the next tap.
    }
    _ref.invalidate(myNotificationsProvider);
  }
}

final notificationReaderProvider = Provider<NotificationReader>((ref) {
  return NotificationReader(ref);
});
