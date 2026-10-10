import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../widgets/section_tab_bar.dart';

/// The tenant's four sections, and the bar that switches between them.
///
/// Organised around what a tenant thinks about rather than what the app can
/// do: what needs me, my rent, my room, my problems. Rent second, as on the
/// landlord's side, because it is the thing somebody opens the app for every
/// month.
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
      // A house, not a bell. It was a bell, sitting under the notification
      // bell in the header, so the screen had two and they did different
      // things.
      icon: Icons.home_outlined,
      label: 'Home',
    ),
    // "Rent" rather than "Payments": the tab holds what is owed as much as
    // what was paid, and it is the landlord's word for the same ledger.
    SectionTab(
      key: ValueKey('tab-rent'),
      icon: Icons.receipt_long_outlined,
      label: 'Rent',
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
      key: ValueKey('tab-messages'),
      icon: Icons.forum_outlined,
      label: 'Messages',
    ),
    SectionTab(
      key: ValueKey('tab-maintenance'),
      icon: Icons.build_outlined,
      label: 'Maintenance',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A dot on Messages when a landlord has written back, so an answer is
    // not something a tenant has to go looking for.
    final unread = ref.watch(unreadInquiriesProvider) > 0;
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: shell,
      bottomNavigationBar: SectionTabBar(
        tabs: [
          for (final tab in _tabs)
            tab.key == const ValueKey('tab-messages')
                ? SectionTab(
                    key: tab.key,
                    icon: tab.icon,
                    label: tab.label,
                    unread: unread,
                  )
                : tab,
        ],
        index: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
