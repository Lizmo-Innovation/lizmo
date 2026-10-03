import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../app_version.dart';

/// The end of the road for a build that is no longer allowed in.
///
/// Wears the splash's teal and lattice because it replaces the splash
/// mid-launch: the app appears to stop where it was starting, rather than
/// flashing a white screen at somebody who has done nothing wrong.
///
/// There is deliberately no way past it. A build we have refused is one whose
/// payments or lease handling we do not trust, and letting somebody "continue
/// anyway" is how that lands in the data.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(appVersionProvider);
    final link = check is AppTooOld ? check.link : null;

    return Scaffold(
      backgroundColor: LizmoColors.teal900,
      body: LatticeBackground(
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  Image.asset(
                    'assets/icon/icon_foreground.png',
                    width: 110,
                    height: 110,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Time to update Lizmo',
                    textAlign: TextAlign.center,
                    style: LizmoType.screenTitle.copyWith(
                      color: LizmoColors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    link == null
                        ? 'This version is too old to keep using. Update Lizmo '
                            'from your app store to carry on.'
                        : 'This version is too old to keep using. Updating '
                            'takes a moment, and everything is where you left '
                            'it.',
                    textAlign: TextAlign.center,
                    style: LizmoType.tagline,
                  ),
                  const Spacer(flex: 5),
                  if (link != null)
                    PrimaryActionButton(
                      key: const ValueKey('open-update-link'),
                      label: 'Update Lizmo',
                      onPressed: () =>
                          ref.read(openLinkProvider)(Uri.parse(link)),
                    ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
