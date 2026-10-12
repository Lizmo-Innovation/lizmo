import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../notice/notice_providers.dart';
import '../property/property_providers.dart';
import '../widgets/lease_term.dart';
import '../widgets/post_notice_sheet.dart';

/// A building's announcements, as the landlord who posted them sees them:
/// what is up, who it went to, and how many have opened it.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key, required this.propertyId});

  final String propertyId;

  String? _name(WidgetRef ref) {
    for (final property in ref.watch(propertiesProvider).valueOrNull ?? const []) {
      if (property.id == propertyId) return property.name;
    }
    return null;
  }

  Future<void> _post(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await PostNoticeSheet.show(
      context,
      propertyId: propertyId,
      propertyName: _name(ref) ?? 'this building',
    );
    if (sent) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Sent. They have it in the app now.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(propertyNoticesProvider(propertyId));

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          'Announcements',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: notices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => LizmoMessageState(
                icon: Icons.error_outline,
                title: 'Could not load announcements',
                detail: ApiFailure.from(error).message,
              ),
              data: (all) => all.isEmpty
                  ? LizmoMessageState(
                      icon: Icons.campaign_outlined,
                      title: 'Nothing posted',
                      detail: 'Tell everybody at ${_name(ref) ?? 'this building'} '
                          'something at once: water off, a repair, the house rules.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(propertyNoticesProvider(propertyId)),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        children: [
                          for (final notice in all) ...[
                            _NoticeCard(notice: notice, propertyId: propertyId),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryActionButton(
                key: const ValueKey('post-notice'),
                label: 'Post an announcement',
                onPressed: () => _post(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends ConsumerStatefulWidget {
  const _NoticeCard({required this.notice, required this.propertyId});

  final NoticeResponse notice;
  final String propertyId;

  @override
  ConsumerState<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends ConsumerState<_NoticeCard> {
  bool _working = false;

  Future<void> _takeDown() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LizmoColors.white,
        title: Text('Take this down?', style: LizmoType.sectionHeading),
        content: Text(
          'It disappears from your tenants’ screens. They are not told.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep it', style: LizmoType.rowSub),
          ),
          TextButton(
            key: const ValueKey('confirm-take-down'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Take it down',
                style: LizmoType.rowName.copyWith(color: LizmoColors.red)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(announcementsApiProvider).takeDownNotice(widget.notice.id!);
      ref.invalidate(propertyNoticesProvider(widget.propertyId));
      messenger.showSnackBar(const SnackBar(content: Text('Taken down.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    final live = notice.live ?? true;
    final audience = notice.audience ?? 0;
    final seen = notice.seenBy ?? 0;

    final when = [
      if (notice.postedAt case final at?) 'Posted ${termDate(at.toLocal())}',
      if (notice.until case final until?)
        live ? 'until ${termDate(until)}' : 'ended ${termDate(until)}',
    ].join(', ');

    return Container(
      key: ValueKey('notice-${notice.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: live ? LizmoColors.white : LizmoColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notice.title ?? '',
                  style: LizmoType.rowName.copyWith(
                    color: live ? LizmoColors.ink : LizmoColors.slate,
                  ),
                ),
              ),
              if (notice.unitNumber case final unit?)
                _Tag('Unit $unit only')
              else if (!live)
                const _Tag('Over'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notice.message ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: LizmoType.rowSub,
          ),
          const SizedBox(height: 8),
          Text(when, style: LizmoType.rowSub.copyWith(fontSize: 11)),
          Row(
            children: [
              Expanded(
                child: Text(
                  // Of the people it is for now: who has actually seen it.
                  audience == 0
                      ? 'Nobody lives there now'
                      : 'Seen by $seen of $audience',
                  key: ValueKey('seen-${notice.id}'),
                  style: LizmoType.rowSub.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: seen == audience && audience > 0
                        ? LizmoColors.teal900
                        : LizmoColors.slate,
                  ),
                ),
              ),
              TextButton(
                key: ValueKey('take-down-${notice.id}'),
                onPressed: _working ? null : _takeDown,
                child: Text(
                  'Take down',
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: LizmoColors.tealTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: LizmoType.rowSub.copyWith(fontSize: 11, color: LizmoColors.teal900),
      ),
    );
  }
}
