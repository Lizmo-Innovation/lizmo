import 'package:flutter/material.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/admin_shell.dart';

/// Payments landlords have made to Lizmo, waiting to be verified.
///
/// A queue across every landlord rather than something you hunt for one at a
/// time: checking proofs of payment is a batch job done at one sitting.
///
/// This screen used to render five hardcoded rows with Confirm and Reject
/// buttons wired to empty callbacks. It looked like a working console and was
/// a picture of one. Nothing raises a billing cycle yet, so there is nothing
/// to review, and it now says so.
class PlatformPaymentsScreen extends StatelessWidget {
  const PlatformPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Payments',
      child: LizmoMessageState(
        icon: Icons.receipt_long_outlined,
        title: 'Nothing to review',
        detail: 'Payments appear here when a landlord uploads proof against an '
            'invoice. No invoices are raised yet, so none can arrive.',
      ),
    );
  }
}
