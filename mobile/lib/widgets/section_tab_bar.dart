import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// One section of a product: its icon, its word, and how a test finds it.
class SectionTab {
  const SectionTab({
    required this.key,
    required this.icon,
    required this.label,
  });

  /// Keyed so a test can address the tab rather than its label, which often
  /// also appears on the screen the tab leads to.
  final Key key;
  final IconData icon;
  final String label;
}

/// The bar that switches between a product's sections.
///
/// Shared by the tenant and landlord shells, which are the same bar with
/// different destinations. Not to be confused with the Tenant/Landlord control
/// in the header: that switches *persona* — which product you are using —
/// while this switches section within one. Different axes, deliberately kept
/// in different places.
class SectionTabBar extends StatelessWidget {
  const SectionTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<SectionTab> tabs;
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
              for (final (position, tab) in tabs.indexed)
                _Tab(
                  key: tab.key,
                  icon: tab.icon,
                  label: tab.label,
                  selected: position == index,
                  onTap: () => onTap(position),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
