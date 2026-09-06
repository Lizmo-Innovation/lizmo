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
    this.badges = const {},
  });

  final List<SectionTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  /// How many unread things sit behind each tab, by tab key. A tab missing
  /// from the map, or carrying zero, gets no badge -- an empty badge would
  /// claim there is something to see.
  final Map<Key, int> badges;

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
                  badge: badges[tab.key] ?? 0,
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
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
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
            // Coral here and nowhere else in the bar: a badge is not
            // navigation, it is the one thing asking to be dealt with, which
            // is exactly what the action accent is for.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: colour),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      decoration: BoxDecoration(
                        color: LizmoColors.coral,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: LizmoType.rowSub.copyWith(
                            color: LizmoColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
