import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../router.dart';

/// Every conversation, from whichever end the reader is at.
///
/// Today's card shows only the live ones, which is right for a to-do list and
/// wrong for "what did that person say in March". This is the whole list:
/// still going, housed, and ended, in that order, because a conversation
/// nobody has answered is more urgent than one that is over.
class InquiriesScreen extends ConsumerWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myInquiriesProvider);

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Conversations',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myInquiriesProvider),
          child: switch (threads) {
            AsyncData(:final value) when value.isEmpty => const LizmoMessageState(
                tone: LizmoMessageTone.neutral,
                icon: Icons.chat_bubble_outline,
                title: 'Nothing here yet',
                detail: 'Conversations about a place appear here, from the '
                    'first message to the day somebody moves in.',
              ),
            AsyncData(:final value) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  for (final thread in _ordered(value))
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
      ),
    );
  }

  /// Waiting on you first, then the rest of the live ones, then tenancies,
  /// then what is over. Within each, the server's order — most recently
  /// spoken in.
  static List<InquirySummary> _ordered(List<InquirySummary> threads) {
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
