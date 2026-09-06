import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notifications/notification_providers.dart';
import '../router.dart';

/// The bell in the header, and the count on it.
///
/// The feed started life as a section on the home screen, which had the flaw
/// that a person with nothing waiting saw no trace of it — so there was no way
/// to go and look, and nothing to tell you the feature existed at all. A bell
/// is always there whether or not it has anything to say, which is the whole
/// argument for it.
///
/// Sits beside the account button on every header that carries one, so it is
/// in the same place on both sides of the app.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          key: const ValueKey('notification-bell'),
          onPressed: () => context.push(Routes.notifications),
          icon: const Icon(Icons.notifications_none),
          color: LizmoColors.white,
          iconSize: 24,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Notifications',
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 15),
                height: 15,
                decoration: BoxDecoration(
                  color: LizmoColors.coral,
                  borderRadius: BorderRadius.circular(8),
                  // The header is teal and the badge is coral; a ring of the
                  // header colour keeps the two from vibrating against each
                  // other where they touch.
                  border: Border.all(color: LizmoColors.teal900, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: LizmoType.rowSub.copyWith(
                      color: LizmoColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
