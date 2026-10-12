import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';

import '../router.dart';
import 'inquiry_providers.dart';

/// The conversation that goes with a lease, if the list has it.
InquirySummary? threadForLease(List<InquirySummary> threads, String? leaseId) {
  if (leaseId == null) return null;
  for (final thread in threads) {
    if (thread.tenancy?.leaseId == leaseId) return thread;
  }
  return null;
}

/// Opens the conversation that goes with a tenancy, starting one if a
/// tenancy from before conversations has none.
///
/// Every "Message" that starts from a tenancy goes through here -- the
/// tenant's card for their landlord, the landlord's tenant page and their
/// Renting list -- so all of them land in the same thread.
Future<void> openTenancyConversation(
  BuildContext context,
  WidgetRef ref,
  String leaseId, {
  InquirySummary? known,
}) async {
  final id = known?.id;
  if (id != null) {
    await context.push(Routes.inquiry(id));
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  try {
    final made =
        await ref.read(inquiriesApiProvider).openLeaseConversation(leaseId);
    ref.invalidate(myInquiriesProvider);
    final madeId = made?.id;
    if (madeId == null || !context.mounted) return;
    await context.push(Routes.inquiry(madeId));
  } catch (error) {
    messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)));
  }
}
