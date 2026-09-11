import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/section_tab_bar.dart';

/// The landlord's five sections, and the bar that switches between them.
///
/// Each tab keeps its own navigation stack: pushing a property, then a unit,
/// then a bed, and switching to Tenants and back returns to the bed rather than
/// to the property list. That is what [StatefulShellRoute] buys, and it is why
/// the tabs are a shell rather than three top-level routes.
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    SectionTab(
      key: ValueKey('tab-today'),
      icon: Icons.insights_outlined,
      label: 'Today',
    ),
    // Its own tab because collecting rent is the job a landlord does every
    // month, and it had no home: a banner on Today and a card inside each
    // tenant. Second, beside Today, because it is the next most visited.
    SectionTab(
      key: ValueKey('tab-rent'),
      icon: Icons.receipt_long_outlined,
      label: 'Rent',
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
    // Its own tab, at Ariel's choice over a card on Today: a landlord with a
    // building of bedspaces fields reports every week, and wants the list of
    // them rather than the latest one.
    SectionTab(
      key: ValueKey('tab-maintenance'),
      icon: Icons.build_outlined,
      label: 'Maintenance',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: shell,
      bottomNavigationBar: SectionTabBar(
        tabs: _tabs,
        index: shell.currentIndex,
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
