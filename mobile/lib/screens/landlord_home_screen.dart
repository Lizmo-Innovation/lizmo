import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/payment_channel_providers.dart';
import '../maintenance/maintenance_providers.dart';
import '../platform/lizmo_billing_providers.dart';
import '../property/property_providers.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/collections_card.dart';
import '../widgets/getting_started_card.dart';
import '../widgets/lizmo_statement_card.dart';
import '../widgets/notification_bell.dart';
import '../widgets/occupancy_card.dart';
import '../widgets/repairs_card.dart';
import '../widgets/role_switcher.dart';
import '../inquiry/inquiry_providers.dart';
import '../push/push_offer.dart';
import '../widgets/inquiries_card.dart';
import '../widgets/leases_ending_card.dart';
import '../widgets/todo_card.dart';

/// The landlord's day: what needs them, then how things stand.
///
/// A to-do list first. Everything under "Needs you" has somebody on the other
/// end waiting -- a stranger asking for a room, a tenant who says they have
/// paid, a tenant who has not -- and every row opens the one screen where it
/// gets dealt with. Below that are the figures, which nobody is waiting on.
///
/// The kinds come in a fixed order, the most perishable first, and never
/// re-sort by how many each has: a landlord learns where to look. With two
/// or more kinds each card shows its first two rows, so six of them still
/// fit; with one, that card has the screen and shows everything it can.
///
/// The header counts what is waiting, and each count is a way to its card,
/// so "do I need to do anything" is answered before the first scroll.
class LandlordHomeScreen extends ConsumerStatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  ConsumerState<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends ConsumerState<LandlordHomeScreen> {
  final _asking = GlobalKey();
  final _confirm = GlobalKey();
  final _repairs = GlobalKey();
  final _behind = GlobalKey();

  void _show(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _day(DateTime day) =>
      '${_days[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };
    final today = ref.watch(todayProvider);
    final inbox = ref.watch(myInquiriesProvider);
    final threads = inbox.valueOrNull;
    // Their first enquiry is when a landlord learns somebody may be waiting
    // on them -- the moment to offer to tell them next time.
    ref.listen(myInquiriesProvider, (_, next) {
      if (next.valueOrNull?.isNotEmpty ?? false) {
        ref
            .read(pushOfferProvider)
            .offer(
              context,
              title: 'Get told when somebody asks?',
              body:
                  'Lizmo will let you know the moment a tenant asks about '
                  'one of your places, so nobody waits on an answer.',
            );
      }
    });
    final collections = ref.watch(collectionsProvider);
    final rent = collections.valueOrNull;
    final lizmo = ref.watch(myLizmoStatementsProvider).valueOrNull;
    final repairs = ref.watch(maintenanceToHandleProvider).valueOrNull;
    final repairsWaiting = repairs == null ? null : repairsNeedingYou(repairs);
    final ending = ref.watch(leasesEndingProvider);

    // What is waiting on them: a conversation where the other side spoke
    // last. A thread they have already answered is not a chore.
    final unanswered = threads
        ?.where((thread) => thread.unread ?? false)
        .length;

    // No answer has come back yet: after a quiet spell the server
    // takes a while to wake, and blank cards would read as nothing to do.
    final firstLoad =
        (inbox.isLoading && !inbox.hasValue && !inbox.hasError) &&
        (collections.isLoading &&
            !collections.hasValue &&
            !collections.hasError);

    final asking = threads == null ? 0 : inquiriesWaiting(threads).length;
    final confirming = rent?.awaitingConfirmation ?? 0;
    final behind = rent?.inArrears.length ?? 0;
    final fixing = repairsWaiting?.length ?? 0;
    final kinds = [
      asking,
      confirming,
      fixing,
      behind,
      ending?.length ?? 0,
      lizmo?.where(lizmoStatementNeedsPaying).length ?? 0,
    ].where((count) => count > 0).length;
    final compact = kinds >= 2;

    // Only once every answer is in. Unknown is not nothing, and "nothing
    // needs you" over a queue that failed to load would be a lie told at the
    // worst possible moment.
    final caughtUp =
        unanswered != null &&
        asking == 0 &&
        rent != null &&
        confirming == 0 &&
        behind == 0 &&
        lizmo != null &&
        !lizmo.any(lizmoStatementNeedsPaying) &&
        repairsWaiting != null &&
        repairsWaiting.isEmpty &&
        ending != null &&
        ending.isEmpty;

    final needsYou = firstLoad
        ? const _FirstLoad()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // People asking come first: they are the most perishable.
              // Somebody told nothing for a week has found a room
              // elsewhere. Each card renders nothing when it has nothing.
              KeyedSubtree(
                key: _asking,
                child: InquiriesCard(compact: compact),
              ),
              KeyedSubtree(
                key: _confirm,
                child: ConfirmPaymentsCard(compact: compact),
              ),
              // Before arrears: a tenant is living with it now, and arrears
              // can wait a day.
              KeyedSubtree(
                key: _repairs,
                child: RepairsCard(compact: compact),
              ),
              KeyedSubtree(
                key: _behind,
                child: ArrearsCard(compact: compact),
              ),
              // A question only they can answer -- are they staying? -- but
              // rarely an urgent one, so below the money.
              LeasesEndingCard(compact: compact),
              // Last: nobody is standing at the door over it, but left alone
              // it locks every property they have.
              LizmoStatementCard(compact: compact),
              if (kinds == 1) const _NothingElse(),
              if (caughtUp) const _AllCaughtUp(),
            ],
          );

    final glance = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _SectionLabel('At a glance'),
        CollectionsCard(),
        SizedBox(height: 10),
        OccupancyCard(),
      ],
    );

    final wide = context.pageSize == LizmoWidth.expanded;
    final side = wide
        ? math.max(24.0, (context.pageWidth - 1040) / 2)
        : context.pageGutter;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: '${session?.name ?? 'Lizmo'} · ${_day(today)}',
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
                onTap: asking > 0 ? () => _show(_asking) : null,
              ),
              LatticeHeaderStat(
                value: _count(rent?.awaitingConfirmation),
                label: 'To confirm',
                onTap: confirming > 0 ? () => _show(_confirm) : null,
              ),
              LatticeHeaderStat(
                value: _count(rent?.tenanciesInArrears),
                label: 'Behind',
                onTap: behind > 0 ? () => _show(_behind) : null,
              ),
              // Its own count rather than inside To answer: a room request
              // and a leaking sink are different jobs.
              LatticeHeaderStat(
                value: _count(repairsWaiting?.length),
                label: 'Repairs',
                onTap: fixing > 0 ? () => _show(_repairs) : null,
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
                ref.invalidate(myTenantsProvider);
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(side, 18, side, 16),
                children: [
                  // Above what needs them: a property that is not set up has
                  // nothing waiting on it yet, and that is the problem.
                  const GettingStartedSection(),
                  if (wide)
                    // Side by side on a wide tablet: what to do on the left,
                    // where things stand on the right, both in view at once.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel('Needs you'),
                              needsYou,
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: glance),
                      ],
                    )
                  else ...[
                    const _SectionLabel('Needs you'),
                    needsYou,
                    const SizedBox(height: 8),
                    glance,
                  ],
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

/// Cards in the shape they will have, and after a few seconds a word on why
/// it is taking so long.
class _FirstLoad extends StatefulWidget {
  const _FirstLoad();

  /// How long before the wait is worth explaining.
  static const patience = Duration(seconds: 5);

  @override
  State<_FirstLoad> createState() => _FirstLoadState();
}

class _FirstLoadState extends State<_FirstLoad> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_FirstLoad.patience, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('today-loading'),
      label: 'Loading what needs you',
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_slow)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                key: const ValueKey('still-loading'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LizmoColors.tealBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 18,
                      color: LizmoColors.teal900,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Still loading. After a quiet spell the first load can '
                        'take up to 20 seconds.',
                        style: LizmoType.rowSub.copyWith(
                          color: LizmoColors.teal900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const ExcludeSemantics(child: TodoSkeleton()),
          const ExcludeSemantics(child: TodoSkeleton()),
        ],
      ),
    );
  }
}

/// Under a card that is alone on Today: the rest is clear, said outright.
class _NothingElse extends StatelessWidget {
  const _NothingElse();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('nothing-else'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: LizmoColors.teal900,
          ),
          const SizedBox(width: 6),
          Text(
            'Nothing else needs you today.',
            style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
          ),
        ],
      ),
    );
  }
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
          color: LizmoColors.slateText,
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
            const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: LizmoColors.teal900,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nothing needs you',
                    style: LizmoType.rowName.copyWith(color: LizmoColors.ink),
                  ),
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
