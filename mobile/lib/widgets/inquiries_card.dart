import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../router.dart';
import '../screens/inquiries_screen.dart';
import '../screens/tenants_screen.dart';
import 'todo_card.dart';

/// Conversations waiting on this landlord, across every property.
///
/// Shown only when there are some. A card that permanently reads "nobody is
/// asking" is one a landlord learns to stop seeing.
///
/// Unread first, because that is what "waiting on you" means now: a thread
/// where the last word was theirs is one nobody has answered.
class InquiriesCard extends ConsumerWidget {
  const InquiriesCard({super.key, this.compact = false});

  /// Other kinds of to-do are on Today too: show the first two.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myInquiriesProvider);

    return threads.when(
      loading: () => const SizedBox.shrink(),
      // Said rather than hidden. Hidden, a failure reads as nobody asking,
      // which is the one thing this card must never say falsely.
      error: (error, _) => TodoCard(
        key: const ValueKey('inquiries-card'),
        icon: Icons.chat_bubble_outline,
        tone: TodoTone.asking,
        title: 'People asking',
        count: 0,
        rows: const [],
        body: Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
      ),
      data: (all) {
        final waiting = inquiriesWaiting(all);
        if (waiting.isEmpty) return const SizedBox.shrink();
        return TodoCard(
          key: const ValueKey('inquiries-card'),
          icon: Icons.chat_bubble_outline,
          tone: TodoTone.asking,
          title: 'People asking',
          count: waiting.length,
          compact: compact,
          seeAll: TodoSeeAll(
            key: const ValueKey('all-conversations'),
            onTap: () {
              // Straight to the Inquiries half, rather than landing on
              // Renting and leaving them to find the control.
              ref.read(tenantsTabProvider.notifier).state = true;
              context.go(Routes.tenants);
            },
          ),
          rows: [
            for (final thread in waiting)
              _ThreadRow(thread: thread, tenant: isCurrentTenancy(thread)),
          ],
        );
      },
    );
  }
}

/// Who is on the asking card, in order.
///
/// A tenant writing comes first, above anybody asking: a current tenant
/// comes before a maybe. Only unread -- a tenant's thread that has been read
/// is not waiting on anyone. Then everybody still asking: unread first, and
/// within that whoever has waited longest.
List<InquirySummary> inquiriesWaiting(List<InquirySummary> all) {
  DateTime at(InquirySummary thread) =>
      thread.lastMessageAt ?? thread.createdAt ?? DateTime(2000);
  final tenants = [
    for (final thread in all)
      if (isCurrentTenancy(thread) && (thread.unread ?? false)) thread,
  ]..sort((a, b) => at(a).compareTo(at(b)));
  final open =
      [
        for (final thread in all)
          if (thread.status == InquirySummaryStatusEnum.OPEN &&
              !isCurrentTenancy(thread))
            thread,
      ]..sort((a, b) {
        final unread = ((b.unread ?? false) ? 1 : 0).compareTo(
          (a.unread ?? false) ? 1 : 0,
        );
        return unread != 0 ? unread : at(a).compareTo(at(b));
      });
  return [...tenants, ...open];
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, this.tenant = false});

  final InquirySummary thread;

  /// Somebody who lives there, marked so a landlord can tell them from
  /// somebody asking.
  final bool tenant;

  @override
  Widget build(BuildContext context) {
    final last = thread.lastMessage;
    final place = thread.propertyName;
    final sub = [
      if (last != null && last.isNotEmpty)
        '“$last”'
      else
        'Asked about ${place ?? 'your place'}',
      if (last != null && last.isNotEmpty && place != null) place,
    ].join(' · ');
    final at = thread.lastMessageAt ?? thread.createdAt;

    return TodoRow(
      key: ValueKey('inquiry-${thread.id}'),
      leading: TodoAvatar(name: thread.withName, tone: TodoTone.asking),
      title: thread.withName ?? 'Somebody',
      unread: thread.unread ?? false,
      onTap: () => context.push(Routes.inquiry(thread.id!)),
      sub: Text(
        sub,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: LizmoType.rowSub,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tenant) ...[
            const StatusChip(status: LizmoStatus.paid, label: 'Tenant'),
            const SizedBox(width: 6),
          ],
          if (at != null)
            Text(ageShort(at), style: todoMono(LizmoColors.slateText)),
        ],
      ),
    );
  }
}
