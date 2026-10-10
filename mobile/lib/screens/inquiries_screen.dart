import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../router.dart';
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
class InquiriesList extends ConsumerWidget {
  const InquiriesList({super.key, this.emptyDetail});

  /// What to say when there are none, which differs by who is reading.
  final String? emptyDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myInquiriesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myInquiriesProvider),
      child: switch (threads) {
        AsyncData(:final value) when value.isEmpty => LizmoMessageState(
            tone: LizmoMessageTone.neutral,
            icon: Icons.chat_bubble_outline,
            title: 'Nothing here yet',
            detail: emptyDetail ??
                'Conversations about a place appear here, from the first '
                    'message to the day somebody moves in.',
          ),
        AsyncData(:final value) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              for (final thread in ordered(value)) _ThreadRow(thread: thread),
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
    );
  }

  /// Waiting on you first, then the rest of the live ones, then tenancies,
  /// then what is over. Within each, the server's order — most recently
  /// spoken in.
  static List<InquirySummary> ordered(List<InquirySummary> threads) {
    int rank(InquirySummary thread) {
      if (thread.status == InquirySummaryStatusEnum.OPEN) {
        return (thread.unread ?? false) ? 0 : 1;
      }
      return thread.status == InquirySummaryStatusEnum.LEASED ? 2 : 3;
    }

    final sorted = [...threads];
    sorted.sort((a, b) => rank(a).compareTo(rank(b)));
    return sorted;
  }
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
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };
    final threads = ref.watch(myInquiriesProvider).valueOrNull;
    final waiting =
        threads?.where((thread) => thread.unread ?? false).length;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
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
            stats: [
              LatticeHeaderStat(
                value: waiting?.toString() ?? '—',
                label: 'New replies',
              ),
            ],
          ),
          const Expanded(
            child: InquiriesList(
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
                              ),
                            ),
                          ),
                          if (thread.status == InquirySummaryStatusEnum.LEASED)
                            const StatusChip(
                                status: LizmoStatus.paid, label: 'Renting'),
                          if (over)
                            const StatusChip(
                                status: LizmoStatus.vacant, label: 'Ended'),
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
}
