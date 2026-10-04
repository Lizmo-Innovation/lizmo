import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../auth/active_role.dart';
import '../notifications/notification_links.dart';
import '../notifications/notification_providers.dart';
import '../router.dart';

/// What the app has told this person, newest first.
///
/// The rows only. Its heading, its "mark all read" and its empty state belong
/// to [NotificationsScreen], which is the only thing that shows it — this used
/// to be a section on the home screens and carried all of that itself.
///
/// Renders the stored title and message rather than rebuilding words from the
/// type: a notification is a record of what somebody was told, and rewriting
/// it later would quietly change history every time the copy changed.
class NotificationFeed extends ConsumerWidget {
  const NotificationFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    final rows = notifications.valueOrNull ?? const <NotificationResponse>[];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          _Row(notification: row),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.notification});

  final NotificationResponse notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = notification.unread == true;
    final destination =
        destinationOf(notification, ref.watch(activeRoleProvider));

    return InkWell(
      key: ValueKey('notification-${notification.id}'),
      // Read or not, a row that leads somewhere stays tappable: going back to
      // a payment you were told about yesterday is a normal thing to do.
      onTap: unread || destination != null
          ? () => _open(context, ref, destination)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A dot rather than a bold row: read and unread sit next to each
            // other here, and weight alone is hard to tell apart at a glance.
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unread ? LizmoColors.coral : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title ?? '',
                    style: LizmoType.rowName.copyWith(
                      color: LizmoColors.ink,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message ?? '',
                    style: LizmoType.rowSub,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _when(notification.createdAt),
                    style: LizmoType.rowSub.copyWith(
                      fontSize: 11,
                      color: LizmoColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            if (destination != null)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: LizmoColors.slate,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    NotificationDestination? destination,
  ) {
    if (notification.unread == true) {
      // Not awaited. Somebody who taps a card wants the thing it is about, and
      // the reader already swallows a failed mark-read.
      ref.read(notificationReaderProvider).one(notification.id!);
    }

    switch (destination) {
      case OpenDetail(:final detail):
        context.openInTab(detail);
      case OpenScreen(:final path):
        context.push(path);
      case SwitchTab(:final tab):
        // Close the notifications before switching. Left open they would
        // still be sitting in this tab the next time the tenant came back.
        final router = GoRouter.of(context);
        router.pop();
        router.go(tab);
      case null:
        break;
    }
  }

  /// How long ago, in the words a person would use.
  ///
  /// A clock time is no use here — "3:42 PM" answers a question nobody asked
  /// of a notification — and an absolute date is only worth showing once the
  /// thing is old enough that "days ago" stops being readable.
  static String _when(DateTime? at) {
    if (at == null) return '';
    final gap = DateTime.now().difference(at.toLocal());
    if (gap.inMinutes < 1) return 'Just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes}m ago';
    if (gap.inHours < 24) return '${gap.inHours}h ago';
    if (gap.inDays < 7) return '${gap.inDays}d ago';
    final when = at.toLocal();
    return '${when.day}/${when.month}/${when.year}';
  }
}
