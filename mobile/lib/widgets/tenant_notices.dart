import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notice/notice_providers.dart';
import '../router.dart';
import 'lease_term.dart';

/// "From your landlord": what is up where a tenant lives, unread first.
///
/// Nothing at all when nothing is up. It used to say announcements "will
/// appear here" -- a sentence about a feature, to somebody who came to see
/// whether their landlord had said anything.
class TenantNotices extends ConsumerWidget {
  const TenantNotices({super.key, required this.notices});

  final List<MyNoticeResponse> notices;

  /// More than this and Home stops being about what is next.
  static const _shown = 5;

  /// Unread first, then newest; the server already sends newest first.
  static List<MyNoticeResponse> ordered(List<MyNoticeResponse> notices) => [
        ...notices.where((notice) => notice.read != true),
        ...notices.where((notice) => notice.read == true),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notices.isEmpty) return const SizedBox.shrink();
    final shown = ordered(notices).take(_shown).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        key: const ValueKey('tenant-notices'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
            child: Text(
              'FROM YOUR LANDLORD',
              style: LizmoType.rowSub.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final notice in shown) _NoticeRow(notice: notice),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});

  final MyNoticeResponse notice;

  @override
  Widget build(BuildContext context) {
    final unread = notice.read != true;
    final from = [
      if (notice.fromName case final name? when name.isNotEmpty) name.split(' ').first,
      if (notice.postedAt case final at?) _short(at.toLocal()),
      if (notice.unitNumber case final unit?) 'Unit $unit',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: unread ? LizmoColors.white : LizmoColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE3E8E6)),
        ),
        child: InkWell(
          key: ValueKey('tenant-notice-${notice.id}'),
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: () => context.openInTab(Detail.notice(notice.id!)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.campaign_outlined,
                    size: 20,
                    color: unread ? LizmoColors.coral : LizmoColors.slate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title ?? '',
                        style: LizmoType.rowName.copyWith(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notice.message ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LizmoType.rowSub,
                      ),
                      const SizedBox(height: 4),
                      Text(from, style: LizmoType.rowSub.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: LizmoColors.slate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _short(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

/// One announcement in full. Opening it is reading it: the landlord's
/// "Seen by" counts this, and only this.
class NoticeScreen extends ConsumerStatefulWidget {
  const NoticeScreen({super.key, required this.noticeId});

  final String noticeId;

  @override
  ConsumerState<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends ConsumerState<NoticeScreen> {
  bool _marked = false;

  /// Once, quietly: somebody reading a notice wants the notice, not an error
  /// because the count did not go up.
  Future<void> _markRead(MyNoticeResponse notice) async {
    if (_marked || notice.read == true) return;
    _marked = true;
    try {
      await ref.read(announcementsApiProvider).markNoticeRead(widget.noticeId);
      ref.invalidate(myNoticesProvider);
    } catch (_) {
      // Left unread, which is the truth, and tried again next time.
    }
  }

  @override
  Widget build(BuildContext context) {
    final notices = ref.watch(myNoticesProvider);

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text('Announcement',
            style: LizmoType.screenTitle.copyWith(fontSize: 18)),
      ),
      body: notices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const LizmoMessageState(
          icon: Icons.error_outline,
          title: 'Could not load it',
          detail: 'Pull down on Home to try again.',
        ),
        data: (all) {
          MyNoticeResponse? notice;
          for (final one in all) {
            if (one.id == widget.noticeId) notice = one;
          }
          if (notice == null) {
            // Taken down, past its last day, or from a place they have left.
            return const LizmoMessageState(
              icon: Icons.campaign_outlined,
              title: 'No longer up',
              detail: 'Your landlord has taken this down, or it has ended.',
            );
          }
          final shown = notice;
          WidgetsBinding.instance.addPostFrameCallback((_) => _markRead(shown));

          final from = [
            if (shown.fromName case final name? when name.isNotEmpty) name,
            ?shown.propertyName,
            if (shown.unitNumber case final unit?) 'Unit $unit',
          ].join(' · ');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: LizmoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3E8E6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shown.title ?? '',
                        style: LizmoType.sectionHeading.copyWith(fontSize: 19)),
                    const SizedBox(height: 6),
                    Text(from, style: LizmoType.rowSub),
                    if (shown.postedAt case final at?)
                      Text('Posted ${termDate(at.toLocal())}',
                          style: LizmoType.rowSub.copyWith(fontSize: 12)),
                    const SizedBox(height: 16),
                    SelectableText(
                      shown.message ?? '',
                      style: LizmoType.rowName.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                    if (shown.until case final until?) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Up until ${termDate(until)}.',
                        style: LizmoType.rowSub.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
