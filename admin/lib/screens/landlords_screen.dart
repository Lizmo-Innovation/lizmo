import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/admin_shell.dart';

/// Who Lizmo's landlords are, and which of them needs chasing.
///
/// The console's home, rather than the payment queue: payments are a task you
/// sit down to do, landlords are the thing the business is made of. Somebody
/// opening the console is usually asking "how is this landlord doing" or "who
/// has not paid", and both start here.
///
/// Empty because nothing fills it yet — there is no endpoint that lists
/// landlords, and no billing cycle has ever been raised. Said plainly rather
/// than filled with plausible-looking rows: a screen that looks finished and
/// does nothing is worse than one that admits what it is.
class LandlordsScreen extends StatelessWidget {
  const LandlordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Landlords',
      child: LizmoMessageState(
        icon: Icons.apartment_outlined,
        title: 'No landlords yet',
        detail: 'Landlords appear here once they accept an invitation. '
            'Their properties, occupied slots and balance will show on this '
            'list.',
      ),
    );
  }
}
