import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../property/property_providers.dart';
import '../widgets/accept_terms_sheet.dart';
import '../widgets/poller.dart';

/// One conversation about a place.
///
/// The same screen for both sides, because it is the same conversation. What
/// differs is what sits above it: the landlord gets who is asking and what
/// they still need before a tenancy can exist, and the button that writes one.
class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _poller = GlobalKey<PollerState>();
  bool _sending = false;

  /// How often an open conversation is re-read.
  ///
  /// A reply landing within five seconds reads as instant to somebody in the
  /// middle of a conversation; three would cost half as much again in
  /// requests for a difference nobody could name. After two quiet minutes it
  /// drops to fifteen, because a thread left open on a desk should not keep
  /// a server awake all afternoon.
  static const _whileTalking = Duration(seconds: 5);
  static const _quietFor = Duration(minutes: 2);
  static const _whenQuiet = Duration(seconds: 15);

  /// What was there at the last tick, so a new message can reset the pace.
  int _messagesSeen = 0;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Reads the thread again. Quiet about it: a failed poll is not worth a
  /// snackbar over a conversation somebody is reading.
  void _reread() => ref.invalidate(inquiryThreadProvider(widget.id));

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;

    // Writing is activity, so the fast interval is worth paying for: a reply
    // usually follows one.
    _poller.currentState?.stirred();

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inquiriesApiProvider)
          .sendInquiryMessage(widget.id, NewMessage(body: body));
      _composer.clear();
      ref.invalidate(inquiryThreadProvider(widget.id));
      // Back to the newest, where what was just said is about to land. Only
      // on success: a send that failed leaves somebody reading where they
      // were, with the text still in the box.
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      // The list behind this one orders by who spoke last.
      ref.invalidate(myInquiriesProvider);
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// The landlord writing the tenancy they have agreed on.
  ///
  /// The room is chosen here from what is actually free right now: the tenant
  /// was shown how many beds are free per floor, never which rooms exist.
  Future<void> _startLease(InquiryThread thread) async {
    final applicant = thread.applicant;
    final propertyId = thread.inquiry?.propertyId;
    if (propertyId == null) return;

    final rooms = await ref.read(freeRoomsProvider(propertyId).future);
    if (!mounted) return;

    final terms = await AcceptTermsSheet.show(
      context,
      tenantName: applicant?.name ?? 'this tenant',
      slot: thread.inquiry?.propertyName ?? 'this place',
      askingRent: rooms.isEmpty ? null : rooms.first.rent,
      rooms: rooms,
    );
    if (terms == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inquiriesApiProvider)
          .startLeaseFromInquiry(widget.id, acceptRequest: terms);

      ref.invalidate(inquiryThreadProvider(widget.id));
      ref.invalidate(myInquiriesProvider);
      // Everything the tenancy moved: the room's occupancy, the property's
      // figures, and who is living there.
      ref.invalidate(propertyLeasesProvider(propertyId));
      ref.invalidate(unitsProvider(propertyId));
      ref.invalidate(propertiesProvider);

      messenger.showSnackBar(SnackBar(
        content: Text('${applicant?.name ?? 'They'} now has a tenancy.'),
      ));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
      ref.invalidate(inquiryThreadProvider(widget.id));
    }
  }

  Future<void> _close(InquiryThread thread) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LizmoColors.white,
        title: Text('End this conversation?', style: LizmoType.sectionHeading),
        content: Text(
          'They will be told it is closed. Say why in the conversation first '
          'if you want them to know.',
          style: LizmoType.rowSub,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it open'),
          ),
          TextButton(
            key: const ValueKey('confirm-close-inquiry'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('End it', style: TextStyle(color: LizmoColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(inquiriesApiProvider).closeInquiry(widget.id);
      ref.invalidate(inquiryThreadProvider(widget.id));
      ref.invalidate(myInquiriesProvider);
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(inquiryThreadProvider(widget.id));

    // A message arriving is activity too, not just one being sent: both sides
    // of a conversation keep it quick.
    final count = thread.valueOrNull?.messages.length ?? _messagesSeen;
    if (count != _messagesSeen) {
      _messagesSeen = count;
      _poller.currentState?.stirred();
    }

    return Poller(
      key: _poller,
      interval: _whileTalking,
      slowAfter: _quietFor,
      slowInterval: _whenQuiet,
      onTick: _reread,
      child: Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          thread.valueOrNull?.inquiry?.propertyName ?? 'Conversation',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          if (thread.valueOrNull?.inquiry?.status ==
              InquirySummaryStatusEnum.OPEN)
            IconButton(
              key: const ValueKey('close-inquiry'),
              tooltip: 'End this conversation',
              icon: const Icon(Icons.do_not_disturb_on_outlined),
              onPressed: () => _close(thread.value!),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (thread) {
          AsyncData(:final value) => _Thread(
              thread: value,
              composer: _composer,
              scroll: _scroll,
              sending: _sending,
              onSend: _send,
              onStartLease: () => _startLease(value),
            ),
          AsyncError(:final error) => LizmoMessageState(
              icon: Icons.cloud_off_outlined,
              tone: LizmoMessageTone.problem,
              title: 'Could not open this',
              detail: ApiFailure.from(error).message,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(inquiryThreadProvider(widget.id)),
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
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.thread,
    required this.composer,
    required this.scroll,
    required this.sending,
    required this.onSend,
    required this.onStartLease,
  });

  final InquiryThread thread;
  final TextEditingController composer;
  final ScrollController scroll;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStartLease;

  @override
  Widget build(BuildContext context) {
    final applicant = thread.applicant;
    final status = thread.inquiry?.status;
    final messages = thread.messages;

    return Column(
      children: [
        if (applicant != null) _Applicant(applicant: applicant),
        Expanded(
          child: messages.isEmpty
              ? const LizmoMessageState(
                  tone: LizmoMessageTone.neutral,
                  icon: Icons.chat_bubble_outline,
                  title: 'Nothing said yet',
                  detail: 'Whatever you write here goes straight to them.',
                )
              : ListView.builder(
                  key: const ValueKey('thread-messages'),
                  controller: scroll,
                  // Anchored at the newest, as every chat is. Top-down, a
                  // thread opened on its oldest message and nothing ever
                  // scrolled it: what was just sent, or just received, landed
                  // below the fold. Reversed, offset 0 is the bottom, so a
                  // new message appears in view on its own, and sending only
                  // has to return to 0 if somebody had scrolled up.
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _Message(
                      message: messages[messages.length - 1 - index]),
                ),
        ),
        if (status == InquirySummaryStatusEnum.CLOSED)
          const _Ended()
        else ...[
          if (applicant != null)
            _StartLease(
              applicant: applicant,
              alreadyLeased: status == InquirySummaryStatusEnum.LEASED,
              onPressed: onStartLease,
            ),
          _Composer(
            controller: composer,
            sending: sending,
            onSend: onSend,
          ),
        ],
      ],
    );
  }
}

/// Who is asking, as far as the landlord is allowed to know before a tenancy.
///
/// The ID type without its number, no photographs, no emergency contact.
/// Anyone can print a code and stick it on a gate.
class _Applicant extends StatelessWidget {
  const _Applicant({required this.applicant});

  final Applicant applicant;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      if (applicant.age != null) '${applicant.age} years old',
      if ((applicant.occupation ?? '').isNotEmpty) applicant.occupation!,
      if ((applicant.permanentAddress ?? '').isNotEmpty)
        'from ${applicant.permanentAddress}',
    ];

    return Container(
      key: const ValueKey('applicant'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(applicant.name ?? 'Somebody', style: LizmoType.rowName),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(facts.join(' · '), style: LizmoType.rowSub),
          ],
          if ((applicant.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(applicant.phone!, style: LizmoType.rowSub),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});

  final InquiryMessageResponse message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine ?? false;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: mine ? LizmoColors.tealTint : LizmoColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [LizmoColors.cardShadow],
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.body ?? '', style: LizmoType.rowSub
                .copyWith(color: LizmoColors.ink)),
            const SizedBox(height: 4),
            Text(_when(message.sentAt), style: LizmoType.rowSub),
          ],
        ),
      ),
    );
  }

  /// The time, or the date once it is not today: a thread is read days apart,
  /// and "14:05" on its own could be any of them.
  static String _when(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return sameDay ? time : '${local.day}/${local.month} $time';
  }
}

/// The button that turns an agreement into a tenancy.
class _StartLease extends StatelessWidget {
  const _StartLease({
    required this.applicant,
    required this.alreadyLeased,
    required this.onPressed,
  });

  final Applicant applicant;
  final bool alreadyLeased;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final missing = applicant.stillNeeds;

    if (alreadyLeased) {
      return Container(
        key: const ValueKey('already-leased'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: LizmoColors.tealBg,
        child: Text(
          'They have a tenancy from this conversation.',
          style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (missing.isNotEmpty) ...[
            Container(
              key: const ValueKey('tenant-still-needs'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LizmoColors.amberBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'You can write a lease once they add ${_list(missing)}.',
                style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: PrimaryActionButton(
              key: const ValueKey('start-lease'),
              label: 'Start a lease',
              onPressed: missing.isEmpty ? onPressed : null,
            ),
          ),
        ],
      ),
    );
  }

  static String _list(List<String> items) {
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('message-field'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              style: LizmoType.rowName,
              decoration: InputDecoration(
                hintText: 'Write a message',
                hintStyle: LizmoType.rowSub,
                counterText: '',
                filled: true,
                fillColor: LizmoColors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: LizmoColors.teal900),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            width: 46,
            child: Material(
              color: LizmoColors.coral,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const ValueKey('send-message'),
                borderRadius: BorderRadius.circular(14),
                onTap: sending ? null : onSend,
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: LizmoColors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A closed conversation keeps what was said, and takes nothing more.
class _Ended extends StatelessWidget {
  const _Ended();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('inquiry-closed'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      color: LizmoColors.white,
      child: Text(
        'This conversation is closed. Ask about the place again to reopen it.',
        textAlign: TextAlign.center,
        style: LizmoType.rowSub,
      ),
    );
  }
}
