import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// The landlord's three sections, and the bar that switches between them.
///
/// Each tab keeps its own navigation stack: pushing a property, then a unit,
/// then a bed, and switching to Tenants and back returns to the bed rather than
/// to the property list. That is what [StatefulShellRoute] buys, and it is why
/// the tabs are a shell rather than three top-level routes.
///
/// Not to be confused with the Tenant/Landlord control in the header. That
/// switches *persona* — which product you are using — while these switch
/// section within the landlord product. Different axes, deliberately kept in
/// different places.
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: shell,
      bottomNavigationBar: _TabBar(
        index: shell.currentIndex,
        // initialLocation: tapping the tab you are already on returns it to its
        // root, which is what a second tap on a tab means everywhere else.
        onTap: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _Tab(
                // Keyed so a test can address the tab rather than its label,
                // which also appears as a stat on the screens themselves.
                key: const ValueKey('tab-today'),
                icon: Icons.insights_outlined,
                label: 'Today',
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _Tab(
                key: const ValueKey('tab-properties'),
                icon: Icons.home_work_outlined,
                label: 'Properties',
                selected: index == 1,
                onTap: () => onTap(1),
              ),
              _Tab(
                key: const ValueKey('tab-tenants'),
                icon: Icons.people_outline,
                label: 'Tenants',
                selected: index == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Teal for the selected tab, not coral: coral is the action accent and
    // belongs to the one thing a screen wants you to do, not to navigation.
    final colour = selected ? LizmoColors.teal900 : LizmoColors.slate;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: colour),
            const SizedBox(height: 2),
            Text(
              label,
              style: LizmoType.rowSub.copyWith(
                color: colour,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
