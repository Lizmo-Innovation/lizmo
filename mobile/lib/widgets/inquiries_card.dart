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

/// Conversations waiting on this landlord, across every property.
///
/// Shown only when there are some. A card that permanently reads "nobody is
/// asking" is one a landlord learns to stop seeing.
///
/// Unread first, because that is what "waiting on you" means now: a thread
/// where the last word was theirs is one nobody has answered.
class InquiriesCard extends ConsumerWidget {
  const InquiriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myInquiriesProvider);

    return threads.when(
      loading: () => const SizedBox.shrink(),
      // Said rather than hidden. Hidden, a failure reads as nobody asking,
      // which is the one thing this card must never say falsely.
      error: (error, _) => _Frame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversations', style: LizmoType.sectionHeading),
            const SizedBox(height: 6),
            Text(ApiFailure.from(error).message, style: LizmoType.rowSub),
          ],
        ),
      ),
      data: (all) {
        // A tenant writing comes first, above anybody asking: a current
        // tenant comes before a maybe. Only unread -- a tenant's thread that
        // has been read is not waiting on anyone. These never showed here,
        // because a tenancy's conversation is not an open inquiry.
        final tenants = [
          for (final thread in all)
            if (isCurrentTenancy(thread) && (thread.unread ?? false)) thread,
        ];
        final open = [
          for (final thread in all)
            if (thread.status == InquirySummaryStatusEnum.OPEN) thread,
        ]..sort((a, b) => ((b.unread ?? false) ? 1 : 0)
            .compareTo((a.unread ?? false) ? 1 : 0));

        return open.isEmpty && tenants.isEmpty
            ? const SizedBox.shrink()
            : _Queue(tenants: tenants, threads: open);
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('inquiries-card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: child,
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue({required this.tenants, required this.threads});

  /// Tenants who have written and not been read.
  final List<InquirySummary> tenants;

  /// Everybody else still talking.
  final List<InquirySummary> threads;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unanswered =
        tenants.length + threads.where((t) => t.unread ?? false).length;

    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Conversations', style: LizmoType.sectionHeading),
              ),
              if (unanswered > 0)
                Text(
                  unanswered == 1
                      ? '1 waiting on you'
                      : '$unanswered waiting on you',
                  style: LizmoType.rowSub.copyWith(
                    color: LizmoColors.amberText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final thread in tenants) _ThreadRow(thread: thread, tenant: true),
          // The three oldest-waiting, not all of them: this is a card on a
          // dashboard, and a landlord with twenty conversations would have
          // nothing else on the screen.
          for (final thread in threads.take(3)) _ThreadRow(thread: thread),
          if (threads.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('all-conversations'),
                onPressed: () {
                  // Straight to the Inquiries half, rather than landing
                  // on Renting and leaving them to find the control.
                  ref.read(tenantsTabProvider.notifier).state = true;
                  context.go(Routes.tenants);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'All ${threads.length} conversations',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, this.tenant = false});

  final InquirySummary thread;

  /// Somebody who lives there, marked so a landlord can tell them from
  /// somebody asking.
  final bool tenant;

  @override
  Widget build(BuildContext context) {
    final unread = thread.unread ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('inquiry-${thread.id}'),
        onTap: () => context.push(Routes.inquiry(thread.id!)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LizmoColors.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    color: LizmoColors.coral,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.withName ?? 'Somebody',
                      style: LizmoType.rowName,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessage ??
                          'Asked about ${thread.propertyName ?? 'your place'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LizmoType.rowSub,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (tenant) ...[
                const StatusChip(status: LizmoStatus.paid, label: 'Tenant'),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right,
                  size: 20, color: LizmoColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}
