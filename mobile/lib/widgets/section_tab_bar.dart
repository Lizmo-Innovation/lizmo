import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

/// One section of a product: its icon, its word, and how a test finds it.
class SectionTab {
  const SectionTab({
    required this.key,
    required this.icon,
    required this.label,
    this.unread = false,
  });

  /// Keyed so a test can address the tab rather than its label, which often
  /// also appears on the screen the tab leads to.
  final Key key;
  final IconData icon;
  final String label;

  /// Something on this section nobody has read. A dot rather than a count:
  /// the number is on the screen itself, and a badge reading 11 on a 65px
  /// tab is a smudge.
  final bool unread;
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

  /// Above this text size the labels no longer fit five across.
  static const largeText = 1.2;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > largeText;
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
                  unread: tab.unread,
                  selected: position == index,
                  large: large,
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
    required this.unread,
    required this.selected,
    required this.large,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool unread;
  final bool selected;

  /// The reader's text is large: only the selected tab says its word, and it
  /// gets the room to say it whole. The others are icons, with their word
  /// for screen readers and on a long press.
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Teal for the selected tab, not coral: coral is the action accent and
    // belongs to the one thing a screen wants you to do, not to navigation.
    final colour = selected ? LizmoColors.teal900 : LizmoColors.slateText;

    final labelled = !large || selected;

    return Expanded(
      flex: large && selected ? 2 : 1,
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        excludeSemantics: true,
        child: Tooltip(
          message: labelled ? '' : label,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: colour),
                    if (unread)
                      Positioned(
                        top: -1,
                        right: -2,
                        child: Container(
                          key: const ValueKey('tab-unread'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: LizmoColors.coral,
                            shape: BoxShape.circle,
                            // A ring, so the dot reads as a dot against the icon
                            // rather than as part of it.
                            border: Border.all(
                              color: LizmoColors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (labelled) ...[
                  const SizedBox(height: 2),
                  // Shrinks rather than cutting. Five tabs on a 360dp phone leave
                  // 72px each and "Maintenance" at 11px takes 69 of them, so with
                  // the phone's larger-text setting on -- 115% is common -- it came
                  // out as "Maintenanc…", which is not a word anybody taps.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: LizmoType.rowSub.copyWith(
                          color: colour,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A section's screen with its way between sections: a bar along the bottom
/// on a phone, a rail down the side on a tablet.
///
/// On a tablet held upright the bar would be five buttons spread across the
/// width of a page, a long way from each other and from the thumb; the rail
/// keeps them together at the edge and gives the page back its height.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.tabs,
    required this.index,
    required this.onTap,
    required this.body,
  });

  final List<SectionTab> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final Widget body;

  /// From here up the sections go down the side.
  static const railFrom = 600.0;

  @override
  Widget build(BuildContext context) {
    final rail = MediaQuery.sizeOf(context).width >= railFrom;
    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: rail
          ? Row(
              children: [
                SectionRail(tabs: tabs, index: index, onTap: onTap),
                Expanded(child: PageArea(child: body)),
              ],
            )
          : PageArea(child: body),
      bottomNavigationBar: rail
          ? null
          : SectionTabBar(tabs: tabs, index: index, onTap: onTap),
    );
  }
}

/// The sections down the side of a tablet.
class SectionRail extends StatelessWidget {
  const SectionRail({
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
      width: 92,
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(right: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              for (final (position, tab) in tabs.indexed)
                _RailItem(
                  key: tab.key,
                  tab: tab,
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

class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final SectionTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? LizmoColors.teal900 : LizmoColors.slateText;
    return Semantics(
      label: tab.label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? LizmoColors.tealTint : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(tab.icon, size: 22, color: colour),
                    if (tab.unread)
                      Positioned(
                        top: 4,
                        right: 14,
                        child: Container(
                          key: const ValueKey('rail-unread'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: LizmoColors.coral,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: LizmoColors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // The rail is narrow and its words are not: "Maintenance" at
              // large text gives way by shrinking a little, never by cutting.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: LizmoType.rowSub.copyWith(
                    color: colour,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
