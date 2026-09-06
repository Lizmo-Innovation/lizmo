import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notifications/notification_providers.dart';

/// What the app has told this person, newest first.
///
/// The same widget on both homes, because being told what happened is not a
/// landlord feature or a tenant feature. It renders the stored title and
/// message rather than rebuilding words from the type: a notification is a
/// record of what somebody was told, and rewriting it later would quietly
/// change history every time the copy changed.
///
/// Renders nothing at all when there is nothing to say. The homes it sits on
/// have their own empty states, and a second "no notifications" panel
/// underneath one of those reads as a fault.
class NotificationFeed extends ConsumerWidget {
  const NotificationFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    final rows = notifications.valueOrNull ?? const <NotificationResponse>[];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final unread = rows.where((row) => row.unread == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('What happened', style: LizmoType.sectionHeading),
              ),
              if (unread > 0)
                InkWell(
                  key: const ValueKey('mark-all-read'),
                  onTap: () => ref.read(notificationReaderProvider).all(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    child: Text(
                      'Mark all read',
                      style: LizmoType.rowSub.copyWith(
                        color: LizmoColors.teal900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

    return InkWell(
      onTap: unread
          ? () => ref
              .read(notificationReaderProvider)
              .one(notification.id!)
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
          ],
        ),
      ),
    );
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
