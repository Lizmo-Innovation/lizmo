import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../router.dart';

/// The frame every console screen sits in: a navigation rail and a title.
///
/// The console had no navigation at all — one screen, and a sign-out link. That
/// is fine for one screen and wrong for a tool somebody works in, where the
/// question being asked ("who hasn't paid", "who have we invited") decides where
/// you start.
///
/// A rail rather than a top tab bar because this is a desktop tool: vertical
/// space is what runs out on a laptop, and a rail costs none of it.
class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;

  /// Controls that belong to this screen, shown beside its title.
  final List<Widget>? actions;

  /// Below this, the rail drops its labels and keeps its icons.
  ///
  /// The console is a desktop tool, but a laptop with a browser window dragged
  /// to half the screen is a normal way to use one, and a rail that pushes the
  /// content off the edge is worse than a rail you have to recognise by icon.
  static const _labelsFitAbove = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLabels = constraints.maxWidth >= _labelsFitAbove;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavigationRail(current: location, showLabels: showLabels),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ScreenHeader(title: title, actions: actions),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One entry in the rail.
class _Destination {
  const _Destination(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

const _destinations = [
  _Destination(Routes.landlords, 'Landlords', Icons.apartment_outlined),
  _Destination(Routes.payments, 'Payments', Icons.receipt_long_outlined),
  _Destination(Routes.invitations, 'Invitations', Icons.mark_email_read_outlined),
  _Destination(Routes.settings, 'Settings', Icons.tune),
];

class _NavigationRail extends ConsumerWidget {
  const _NavigationRail({required this.current, required this.showLabels});

  final String current;
  final bool showLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };

    return Container(
      width: showLabels ? 188 : 64,
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(right: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: showLabels ? 8 : 0),
            child: Text(
              showLabels ? 'Lizmo admin' : 'L',
              textAlign: showLabels ? TextAlign.left : TextAlign.center,
              style: LizmoType.sectionHeading.copyWith(color: LizmoColors.teal900),
            ),
          ),
          const SizedBox(height: 18),
          for (final destination in _destinations)
            _NavItem(
              destination: destination,
              selected: current == destination.route,
              showLabel: showLabels,
            ),
          const Spacer(),
          if (session != null && showLabels) ...[
            const Divider(height: 1, color: Color(0xFFE3E8E6)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                session.name,
                overflow: TextOverflow.ellipsis,
                style: LizmoType.rowName.copyWith(fontSize: 13),
              ),
            ),
          ],
          const _SignOutButton(),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.showLabel,
  });

  final _Destination destination;
  final bool selected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? LizmoColors.teal900 : LizmoColors.slate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => context.go(destination.route),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 10 : 0,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected ? LizmoColors.tealBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
                showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(destination.icon, size: 19, color: colour),
              if (showLabel) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: LizmoType.rowName.copyWith(fontSize: 13, color: colour),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Present because an admin session can confirm payments to Lizmo, so leaving
/// one open on a shared desk should be easy to undo.
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(authControllerProvider.notifier).logout(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: Alignment.centerLeft,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Sign out',
        style: LizmoType.rowSub.copyWith(color: LizmoColors.slate),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: LizmoType.screenTitle.copyWith(
                fontSize: 20,
                color: LizmoColors.teal900,
              ),
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}
