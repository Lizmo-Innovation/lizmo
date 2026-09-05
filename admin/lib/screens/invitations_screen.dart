import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/admin_shell.dart';

/// Invitations sent, and the ones still waiting to be taken up.
///
/// Its own screen rather than a button on the landlords list, because an
/// invitation has a life of its own: it is sent, it waits, it expires after
/// seven days, and somebody has to notice that it did.
class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Invitations',
      child: LizmoMessageState(
        icon: Icons.mark_email_read_outlined,
        title: 'No invitations sent from here yet',
        detail: 'Inviting somebody emails them a link to set up a landlord '
            'account. The API accepts invitations already; this screen does '
            'not send them yet.',
      ),
    );
  }
}
