import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../inquiry/tenancy_conversation.dart';
import '../tenant/tenant_providers.dart';
import 'lease_term.dart';
import 'leases_ending_card.dart';
import 'your_landlord_card.dart';

/// Whether a tenant should be told their lease is nearing its end: within a
/// month of it, or past it with nothing done.
bool leaseEndingSoon(LeaseResponse lease, DateTime today) {
  final ends = lease.termEndsOn;
  return ends != null &&
      lease.status == LeaseResponseStatusEnum.ACTIVE &&
      daysUntil(ends, today) <= leaseEndingWithinDays;
}

/// A tenant's lease coming to its end, and the one thing to do about it.
///
/// Asking to stay is a conversation, not a form, so the button opens the one
/// they already have with their landlord. Past the date it says so calmly:
/// nothing has ended, the landlord just has not said what happens next.
class LeaseEndingNotice extends ConsumerStatefulWidget {
  const LeaseEndingNotice({super.key, required this.lease});

  final LeaseResponse lease;

  @override
  ConsumerState<LeaseEndingNotice> createState() => _LeaseEndingNoticeState();
}

class _LeaseEndingNoticeState extends ConsumerState<LeaseEndingNotice> {
  bool _opening = false;

  Future<void> _talk(InquirySummary? thread) async {
    setState(() => _opening = true);
    try {
      await openTenancyConversation(context, ref, widget.lease.id!, known: thread);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lease = widget.lease;
    final today = ref.watch(todayProvider);
    if (!leaseEndingSoon(lease, today)) return const SizedBox.shrink();

    final ends = lease.termEndsOn!;
    final left = daysUntil(ends, today);
    final thread = threadForTenancy(
        ref.watch(myInquiriesProvider).valueOrNull ?? const [], lease);
    final landlord = _firstName(thread?.withName);
    final passed = left < 0;

    // Its own space below, so where there is nothing to say it leaves no gap.
    return Container(
      key: const ValueKey('lease-ending'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined,
                  size: 18, color: LizmoColors.amberText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passed
                      ? 'Your lease has reached its end date'
                      : 'Your lease ends ${inDays(left)}',
                  style: LizmoType.rowName.copyWith(color: LizmoColors.amberText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            passed
                ? 'It was due to end on ${termDate(ends)}. ${landlord ?? 'Your landlord'} '
                    'has not extended it or ended it yet, so nothing has changed. '
                    'Ask them what happens next.'
                : 'On ${termDate(ends)}. If you want to stay, ask '
                    '${landlord ?? 'your landlord'} to extend it.',
            style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('lease-ending-message'),
              onPressed: _opening ? null : () => _talk(thread),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(landlord == null ? 'Message your landlord' : 'Message $landlord'),
              style: TextButton.styleFrom(
                foregroundColor: LizmoColors.teal900,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _firstName(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split(' ').first;
  }
}
