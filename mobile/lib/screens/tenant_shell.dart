import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notifications/notification_providers.dart';
import '../widgets/section_tab_bar.dart';

/// The tenant's four sections, and the bar that switches between them.
///
/// Organised around what a tenant thinks about rather than what the app can
/// do: what needs me, my room, my money, my problems.
///
/// Before this, the tenant side was one screen with everything on it — which
/// hid how little the app does once somebody has moved in. A bar makes that
/// visible, which is an argument for it rather than against.
class TenantShell extends ConsumerWidget {
  const TenantShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    SectionTab(
      key: ValueKey('tab-home'),
      icon: Icons.notifications_none,
      label: 'Home',
    ),
    // "My place" rather than "Lease": somebody still looking would see a tab
    // called Lease showing a search screen. This one reads correctly in both
    // states — find your place, then your place.
    SectionTab(
      key: ValueKey('tab-place'),
      icon: Icons.bed_outlined,
      label: 'My place',
    ),
    SectionTab(
      key: ValueKey('tab-payments'),
      icon: Icons.receipt_long_outlined,
      label: 'Payments',
    ),
    SectionTab(
      key: ValueKey('tab-maintenance'),
      icon: Icons.build_outlined,
      label: 'Maintenance',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: shell,
      bottomNavigationBar: SectionTabBar(
        tabs: _tabs,
        index: shell.currentIndex,
        // On Home because that is where the feed is. A badge on a tab that
        // does not answer it is a badge nobody can clear.
        badges: {
          _tabs.first.key: ref.watch(unreadNotificationCountProvider),
        },
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
