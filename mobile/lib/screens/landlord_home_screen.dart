import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/payment_channel_providers.dart';
import '../maintenance/maintenance_providers.dart';
import '../platform/lizmo_billing_providers.dart';
import '../property/property_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/collections_card.dart';
import '../widgets/getting_started_card.dart';
import '../widgets/lizmo_statement_card.dart';
import '../widgets/notification_bell.dart';
import '../widgets/occupancy_card.dart';
import '../widgets/repairs_card.dart';
import '../widgets/role_switcher.dart';
import '../inquiry/inquiry_providers.dart';
import '../widgets/inquiries_card.dart';

/// The landlord's day: what needs them, then how things stand.
///
/// A to-do list first. Everything under "Needs you" has somebody on the other
/// end waiting -- a stranger asking for a room, a tenant who says they have
/// paid, a tenant who has not -- and every row opens the one screen where it
/// gets dealt with. Below that are the figures, which nobody is waiting on.
///
/// The header used to repeat the Properties tab's own three figures, rent,
/// properties and units, on a different tab. It counts what is waiting instead,
/// so "do I need to do anything" is answered before the first scroll.
///
/// It also used to end on "Coming up — Needs leases", a placeholder from before
/// leases existed. Nothing here is a promise any more.
class LandlordHomeScreen extends ConsumerWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };
    final threads = ref.watch(myInquiriesProvider).valueOrNull;
    final rent = ref.watch(collectionsProvider).valueOrNull;
    final lizmo = ref.watch(myLizmoStatementsProvider).valueOrNull;
    final repairs = ref.watch(maintenanceToHandleProvider).valueOrNull;
    final repairsWaiting = repairs == null ? null : repairsNeedingYou(repairs);

    // Only once every answer is in. Unknown is not nothing, and "nothing
    // needs you" over a queue that failed to load would be a lie told at the
    // worst possible moment.
    // What is waiting on them: a conversation where the other side spoke
    // last. A thread they have already answered is not a chore.
    final unanswered =
        threads?.where((thread) => thread.unread ?? false).length;

    final caughtUp = unanswered != null &&
        unanswered == 0 &&
        rent != null &&
        (rent.awaitingConfirmation ?? 0) == 0 &&
        rent.inArrears.isEmpty &&
        lizmo != null &&
        !lizmo.any(lizmoStatementNeedsPaying) &&
        repairsWaiting != null &&
        repairsWaiting.isEmpty;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'Today',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            stats: [
              LatticeHeaderStat(
                value: _count(unanswered),
                label: 'To answer',
              ),
              LatticeHeaderStat(
                value: _count(rent?.awaitingConfirmation),
                label: 'To confirm',
              ),
              LatticeHeaderStat(
                value: _count(rent?.tenanciesInArrears),
                label: 'Behind',
              ),
              // Its own count rather than inside To answer: a room request
              // and a leaking sink are different jobs.
              LatticeHeaderStat(
                value: _count(repairsWaiting?.length),
                label: 'Repairs',
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(propertiesProvider);
                ref.invalidate(collectionsProvider);
                ref.invalidate(occupancyProvider);
                ref.invalidate(myInquiriesProvider);
                ref.invalidate(myLizmoStatementsProvider);
                ref.invalidate(maintenanceToHandleProvider);
                ref.invalidate(myPaymentChannelsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                children: [
                  // Above what needs them: a property that is not set up has
                  // nothing waiting on it yet, and that is the problem.
                  const GettingStartedSection(),
                  const _SectionLabel('Needs you'),
                  // People asking come first: they are the most perishable.
                  // Somebody told nothing for a week has found a room
                  // elsewhere. Each card renders nothing when it has nothing.
                  const InquiriesCard(),
                  const ConfirmPaymentsCard(),
                  // Before arrears: a tenant is living with it now, and
                  // arrears can wait a day.
                  const RepairsCard(),
                  const ArrearsCard(),
                  // Last of the four: nobody is standing at the door over it,
                  // but left alone it locks every property they have.
                  const LizmoStatementCard(),
                  if (caughtUp) const _AllCaughtUp(),
                  const SizedBox(height: 8),
                  const _SectionLabel('At a glance'),
                  const CollectionsCard(),
                  const SizedBox(height: 10),
                  const OccupancyCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A count, or a dash while it is not known. Never a zero it has not earned.
  static String _count(int? count) => count?.toString() ?? '—';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: LizmoType.rowSub.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: LizmoColors.slate,
        ),
      ),
    );
  }
}

/// Said when there is nothing to do, rather than leaving an empty space.
///
/// An empty "Needs you" reads as a section that failed to load. Saying it
/// outright is the payoff for clearing the list.
class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('all-caught-up'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 20, color: LizmoColors.teal900),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nothing needs you',
                      style: LizmoType.rowName.copyWith(color: LizmoColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    'Nobody is waiting for an answer, no payment is waiting '
                    'to be confirmed, no repair is waiting to be picked up, '
                    'and no tenant is late.',
                    style: LizmoType.rowSub,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
