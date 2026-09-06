import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notifications/notification_providers.dart';
import '../widgets/notification_feed.dart';

/// Everything the app has told this person.
///
/// Its own screen, behind the bell, rather than a section on the home screen.
/// The section had no way to announce itself: with nothing waiting it rendered
/// nothing at all, so somebody who had never received a notification had no
/// way to discover that notifications existed — and no way to go back and
/// re-read one they had already cleared.
///
/// Reached from both sides of the app. Being told what happened is not a
/// landlord feature or a tenant feature.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    final rows = notifications.valueOrNull ?? const <NotificationResponse>[];
    final unread = rows.where((row) => row.unread == true).length;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        // Teal, like every other pushed screen. It was canvas, which left
        // LizmoType.screenTitle -- white, because it is drawn on the teal
        // header -- as white text on an almost-white bar.
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              key: const ValueKey('mark-all-read'),
              onPressed: () => ref.read(notificationReaderProvider).all(),
              child: Text(
                'Mark all read',
                // White, now that the bar behind it is teal.
                style: LizmoType.rowSub.copyWith(
                  color: LizmoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LizmoMessageState(
          icon: Icons.error_outline,
          title: 'Could not load your notifications',
          detail: ApiFailure.from(error).message,
        ),
        data: (rows) => rows.isEmpty
            // Unlike the feed, this screen must say something. Somebody has
            // deliberately opened it, and a blank page would read as broken.
            ? const LizmoMessageState(
                icon: Icons.notifications_none,
                title: 'Nothing yet',
                detail: 'When a landlord answers a request, or somebody asks '
                    'about one of your rooms, you will find it here.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myNotificationsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: const [NotificationFeed()],
                ),
              ),
      ),
    );
  }
}
