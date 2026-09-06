import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notifications/notification_providers.dart';
import '../widgets/section_tab_bar.dart';

/// The landlord's three sections, and the bar that switches between them.
///
/// Each tab keeps its own navigation stack: pushing a property, then a unit,
/// then a bed, and switching to Tenants and back returns to the bed rather than
/// to the property list. That is what [StatefulShellRoute] buys, and it is why
/// the tabs are a shell rather than three top-level routes.
class LandlordShell extends ConsumerWidget {
  const LandlordShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    SectionTab(
      key: ValueKey('tab-today'),
      icon: Icons.insights_outlined,
      label: 'Today',
    ),
    SectionTab(
      key: ValueKey('tab-properties'),
      icon: Icons.home_work_outlined,
      label: 'Properties',
    ),
    SectionTab(
      key: ValueKey('tab-tenants'),
      icon: Icons.people_outline,
      label: 'Tenants',
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
        badges: {
          _tabs.first.key: ref.watch(unreadNotificationCountProvider),
        },
        // initialLocation: tapping the tab you are already on returns it to its
        // root, which is what a second tap on a tab means everywhere else.
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
