import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../router.dart';
import '../tenant/tenant_providers.dart';
import '../widgets/poller.dart';
import '../widgets/your_landlord_card.dart';
import '../widgets/account_sheet.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';

/// Every conversation, from whichever end the reader is at.
///
/// A tenant asks several landlords and a landlord fields several tenants, so
/// this is a list rather than a card: still going, housed, and ended, in that
/// order, because a conversation nobody has answered is more urgent than one
/// that is over.
///
/// Used twice: as the tenant's Messages tab, and as the Inquiries half of
/// landlord's Tenants tab, which is why the header is not in here.
class InquiriesList extends ConsumerStatefulWidget {
  const InquiriesList({
    super.key,
    this.emptyDetail,
    this.leading,
    this.restLabel,
    this.leaveOutTenancies = false,
  });

  /// What to say when there are none, which differs by who is reading.
  final String? emptyDetail;

  /// Pinned above the rest: the tenant's own landlord. Shown even when there
  /// is nothing else, because a renting tenant's inbox is not empty.
  final Widget? leading;

  /// Over the rest, when something is pinned above them.
  final String? restLabel;

  /// Leaves out conversations with a current tenancy, which are shown
  /// somewhere better -- pinned for the tenant, and on the Renting half of
  /// Tenants for the landlord.
  final bool leaveOutTenancies;

  /// How often the list re-reads itself while somebody is looking at it.
  ///
  /// Nobody stares at an inbox waiting for it to change, and half a minute
  /// is below the point where anybody would notice it was stale. The open
  /// conversation is the screen that polls quickly; this one only has to be
  /// right by the time you look down the list.
  static const every = Duration(seconds: 30);

  @override
  ConsumerState<InquiriesList> createState() => _InquiriesListState();
}

class _InquiriesListState extends ConsumerState<InquiriesList> {
  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(myInquiriesProvider);

    return Poller(
      interval: InquiriesList.every,
      onTick: () => ref.invalidate(myInquiriesProvider),
      child: RefreshIndicator(
      onRefresh: () async => ref.invalidate(myInquiriesProvider),
      child: switch (threads) {
        AsyncData(:final value)
            when _shown(value).isEmpty && widget.leading == null =>
          LizmoMessageState(
            tone: LizmoMessageTone.neutral,
            icon: Icons.chat_bubble_outline,
            title: 'Nothing here yet',
            detail: widget.emptyDetail ??
                'Conversations about a place appear here, from the first '
                    'message to the day somebody moves in.',
          ),
        AsyncData(:final value) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (widget.leading case final leading?) ...[
                leading,
                const SizedBox(height: 18),
                if (_shown(value).isNotEmpty && widget.restLabel != null) ...[
                  Text(widget.restLabel!, style: LizmoType.sectionHeading),
                  const SizedBox(height: 10),
                ],
              ],
              for (final thread in ordered(_shown(value)))
                _ThreadRow(thread: thread),
            ],
          ),
        AsyncError(:final error) => LizmoMessageState(
            icon: Icons.cloud_off_outlined,
            tone: LizmoMessageTone.problem,
            title: 'Could not read your conversations',
            detail: ApiFailure.from(error).message,
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(myInquiriesProvider),
          ),
        _ => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
              ),
            ),
          ),
      },
      ),
    );
  }

  List<InquirySummary> _shown(List<InquirySummary> threads) =>
      widget.leaveOutTenancies
          ? threads.where((thread) => !isCurrentTenancy(thread)).toList()
          : threads;
}

/// Whether a conversation belongs to somebody living there now.
///
/// By the tenancy it carries, or -- from an API that does not say -- by
/// being marked as one.
bool isCurrentTenancy(InquirySummary thread) =>
    thread.tenancy?.active == true ||
    (thread.tenancy == null &&
        thread.status == InquirySummaryStatusEnum.LEASED);

/// Waiting on you first, whatever it is about, then the rest of the live
/// ones, then tenancies, then what is over. Within each, the server's order
/// -- most recently spoken in.
///
/// Unread used to count only for conversations still asking about a room,
/// so a message from your own tenant or landlord sat below ones you had
/// already read.
List<InquirySummary> ordered(List<InquirySummary> threads) {
  int rank(InquirySummary thread) {
    final over = thread.status == InquirySummaryStatusEnum.CLOSED;
    if ((thread.unread ?? false) && !over) return 0;
    if (thread.status == InquirySummaryStatusEnum.OPEN) return 1;
    return thread.status == InquirySummaryStatusEnum.LEASED ? 2 : 3;
  }

  final sorted = [...threads];
  sorted.sort((a, b) => rank(a).compareTo(rank(b)));
  return sorted;
}

/// The tenant's Messages tab.
///
/// Somebody looking for a room is asking four landlords at once, and until
/// this tab existed their answers lived on cards on Home, two at a time,
/// under whatever else needed them that morning.
class TenantMessagesScreen extends ConsumerWidget {
  const TenantMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myInquiriesProvider).valueOrNull;
    final waiting =
        threads?.where((thread) => thread.unread ?? false).length;
    final lease = ref.watch(myLeasesProvider).valueOrNull?.firstOrNull;
    final renting = lease?.status == LeaseResponseStatusEnum.ACTIVE;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            // Lizmo, as on every other tab. It was the tenant's own name,
            // which they know, and which made this one tab look like it
            // belonged to somebody.
            eyebrow: 'Lizmo',
            title: 'Messages',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            // Not over an empty inbox: a full-width "0 New replies" above
            // "Nothing here yet" says nothing twice. Once there is a
            // conversation, a zero is news -- nobody has written back.
            stats: (threads?.isEmpty ?? true)
                ? const []
                : [
                    LatticeHeaderStat(
                      value: (waiting ?? 0).toString(),
                      label: 'New replies',
                    ),
                  ],
          ),
          Expanded(
            // The landlord pinned on top, and kept out of the list below it:
            // a tenant's landlord is not one more place they asked about.
            child: InquiriesList(
              leading: renting ? YourLandlordCard(lease: lease!) : null,
              restLabel: 'Places you asked about',
              leaveOutTenancies: true,
              emptyDetail: 'Scan a place you like and ask about it. Whatever '
                  'the landlord says back lands here.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread});

  final InquirySummary thread;

  @override
  Widget build(BuildContext context) {
    final unread = thread.unread ?? false;
    final over = thread.status == InquirySummaryStatusEnum.CLOSED;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('thread-${thread.id}'),
          onTap: () => context.push(Routes.inquiry(thread.id!)),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unread ? LizmoColors.coral : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.withName ?? 'Somebody',
                              style: LizmoType.rowName.copyWith(
                                color: over ? LizmoColors.slate : LizmoColors.ink,
                                // Weight as well as the dot. A dot and a
                                // shade of grey is thin for the one thing
                                // this list is read to find.
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (thread.status == InquirySummaryStatusEnum.LEASED)
                            const StatusChip(
                                status: LizmoStatus.paid, label: 'Renting')
                          else if (over)
                            const StatusChip(
                                status: LizmoStatus.vacant, label: 'Ended')
                          // Still open -- the deposit is being talked about --
                          // but not somebody asking about a room.
                          else if (thread.tenancy?.active == false)
                            const StatusChip(
                                status: LizmoStatus.vacant, label: 'Moved out'),
                          if (!over &&
                              thread.status != InquirySummaryStatusEnum.LEASED &&
                              thread.tenancy?.active != false)
                            Text(
                              _when(thread.lastMessageAt ?? thread.createdAt),
                              style: LizmoType.rowSub.copyWith(
                                color: unread
                                    ? LizmoColors.coral
                                    : LizmoColors.slate,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thread.propertyName ?? 'A property',
                        style: LizmoType.rowSub,
                      ),
                      if ((thread.lastMessage ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          thread.lastMessage!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LizmoType.rowSub.copyWith(
                            color: unread ? LizmoColors.ink : LizmoColors.slate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// How long ago, in the shape a messaging list uses: minutes within the
  /// hour, hours within the day, the weekday within the week, then the date.
  ///
  /// Without it you cannot tell this morning's unanswered message from one
  /// three weeks old, which is exactly what decides who gets answered first.
  static String _when(DateTime? at) {
    if (at == null) return '';

    final local = at.toLocal();
    final ago = DateTime.now().difference(local);

    if (ago.inMinutes < 1) return 'now';
    if (ago.inMinutes < 60) return '${ago.inMinutes}m';
    if (ago.inHours < 24) return '${ago.inHours}h';
    if (ago.inDays < 7) return _days[local.weekday - 1];
    return '${local.day} ${_months[local.month - 1]}';
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
