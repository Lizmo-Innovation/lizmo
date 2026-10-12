import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';

import '../router.dart';

/// What a landlord is told after confirming or recording a payment: that it
/// is done, and that the tenant has the receipt -- with a way to see it.
///
/// "Confirmed." said nothing about the receipt the tenant had just been sent,
/// and a landlord asked "did you get my receipt?" had no way to know.
SnackBar receiptSnackBar(
  BuildContext context, {
  required String done,
  required String leaseId,
  required PaymentResponse? payment,
  String? tenantName,
}) {
  final number = payment?.receiptNumber;
  final receiptId = payment?.receiptId;
  if (number == null || receiptId == null) {
    return SnackBar(content: Text(done));
  }

  final router = GoRouter.of(context);
  return SnackBar(
    content: Text('$done Receipt $number is in ${_whose(tenantName)} app.'),
    action: SnackBarAction(
      key: const ValueKey('view-receipt'),
      label: 'View',
      // The router, not the context: by the time somebody taps, the screen
      // that showed this may have gone.
      onPressed: () {
        final here = router.routerDelegate.currentConfiguration.uri.path;
        final path =
            '${Routes.tabRootOf(here)}/${Detail.receipt(leaseId, receiptId)}';
        // A conversation sits above the tabs, and pushing a tab's page from
        // it builds the tabs a second time underneath -- which the router
        // refuses. Gone to instead, as the conversation does for a tenancy.
        if (here.startsWith('/inquiry/')) {
          router.go(path);
        } else {
          router.push(path);
        }
      },
    ),
  );
}

/// "Ana's", or "their" when the name is not known.
String _whose(String? name) {
  final first = name?.trim().split(' ').first ?? '';
  return first.isEmpty ? 'their' : "$first's";
}
