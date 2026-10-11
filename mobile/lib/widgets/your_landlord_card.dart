import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../router.dart';

/// The conversation a tenancy is talked about in, if it has one yet.
///
/// By the tenancy it carries; failing that -- an API from before
/// conversations said which tenancy they belong to -- the thread about the
/// same property that is marked as one.
InquirySummary? threadForTenancy(
    List<InquirySummary> threads, LeaseResponse lease) {
  for (final thread in threads) {
    if (thread.tenancy?.leaseId == lease.id) return thread;
  }
  for (final thread in threads) {
    if (thread.propertyId == lease.propertyId &&
        thread.status == InquirySummaryStatusEnum.LEASED) {
      return thread;
    }
  }
  return null;
}

/// The person a tenant rents from, one tap from talking to them.
///
/// The same card on Messages, where it is pinned above the places they only
/// asked about, on My place, which is where somebody looks for anything to do
/// with their home, and on Home when there is something from them unread.
/// A name rather than "the landlord": it is a person they know.
///
/// A tenancy from before conversations has no thread. The card still offers
/// one, and it is made on the tap.
class YourLandlordCard extends ConsumerStatefulWidget {
  const YourLandlordCard({super.key, required this.lease});

  final LeaseResponse lease;

  @override
  ConsumerState<YourLandlordCard> createState() => _YourLandlordCardState();
}

class _YourLandlordCardState extends ConsumerState<YourLandlordCard> {
  bool _opening = false;

  Future<void> _open(InquirySummary? thread) async {
    if (thread?.id != null) {
      await context.push(Routes.inquiry(thread!.id!));
      return;
    }

    setState(() => _opening = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final made = await ref
          .read(inquiriesApiProvider)
          .openLeaseConversation(widget.lease.id!);
      ref.invalidate(myInquiriesProvider);
      final id = made?.id;
      if (!mounted || id == null) return;
      await context.push(Routes.inquiry(id));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lease = widget.lease;
    final threads = ref.watch(myInquiriesProvider).valueOrNull ?? const [];
    final thread = threadForTenancy(threads, lease);
    final unread = thread?.unread ?? false;
    final said = thread?.lastMessage;

    final place = lease.bedLabel == null
        ? 'Unit ${lease.unitNumber}'
        : '${lease.bedLabel}, ${lease.unitNumber}';
    final where = [place, if (lease.propertyName != null) lease.propertyName!]
        .join(' · ');

    return Material(
      color: LizmoColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE3E8E6)),
      ),
      child: InkWell(
        key: const ValueKey('your-landlord'),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: _opening ? null : () => _open(thread),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'YOUR LANDLORD',
                      style: LizmoType.rowSub.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: LizmoColors.slate,
                      ),
                    ),
                  ),
                  if (unread)
                    Container(
                      key: const ValueKey('your-landlord-unread'),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: LizmoColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                thread?.withName ?? 'Your landlord',
                style: LizmoType.rowName.copyWith(
                  fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(where, style: LizmoType.rowSub),
              const SizedBox(height: 6),
              Text(
                (said ?? '').isNotEmpty
                    ? said!
                    : 'Anything about your place: the water, the rent, the '
                        'deposit.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LizmoType.rowSub.copyWith(
                  color: unread ? LizmoColors.ink : LizmoColors.slate,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _opening
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(LizmoColors.teal900),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 16, color: LizmoColors.teal900),
                          const SizedBox(width: 6),
                          Text(
                            unread ? 'Reply' : 'Message',
                            style: LizmoType.rowSub.copyWith(
                              color: LizmoColors.teal900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
