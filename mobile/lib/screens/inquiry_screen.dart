import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../billing/receipt_said.dart';
import '../inquiry/inquiry_providers.dart';
import '../property/property_providers.dart';
import '../push/push_offer.dart';
import '../router.dart';
import '../widgets/accept_terms_sheet.dart';
import '../widgets/declare_payment_sheet.dart';
import '../widgets/poller.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/report_problem_sheet.dart';

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
    final them = ref
        .read(inquiryThreadProvider(widget.id))
        .valueOrNull
        ?.inquiry
        ?.withName;
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
      // What they said is sent; the answer comes later, which is when a
      // notification is worth having.
      if (mounted) {
        unawaited(ref.read(pushOfferProvider).offer(
              context,
              title: them == null || them.isEmpty
                  ? 'Get told when they reply?'
                  : 'Get told when $them replies?',
              body: 'Lizmo will let you know the moment they answer, so you '
                  "don't have to keep checking.",
            ));
      }
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// The month to settle first: the oldest one not yet paid, which is the one
  /// a landlord would chase and the one a tenant would pay. The server sends
  /// months oldest first.
  static BillingPeriodResponse? _toSettle(List<BillingPeriodResponse> months) {
    for (final month in months) {
      if (month.status != BillingPeriodResponseStatusEnum.PAID &&
          (month.outstanding ?? 0) > 0) {
        return month;
      }
    }
    return null;
  }

  /// The tenant saying they have paid, from the conversation.
  ///
  /// Otherwise "paid na po" goes into the chat, the landlord reads it and
  /// never confirms it in the app, and the month stays unpaid on both sides.
  /// This is the same claim the Rent tab makes, about the oldest month owed.
  Future<void> _iHavePaid(String leaseId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final month = _toSettle(await ref.read(myBillingProvider(leaseId).future));
      if (!mounted) return;
      if (month == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Nothing is owed right now.')));
        return;
      }
      PaymentDetails? howToPay;
      try {
        howToPay = await ref.read(leasePaymentDetailsProvider(leaseId).future);
      } catch (_) {
        // The sheet leaves the list of accounts out without them.
      }
      if (!mounted) return;

      final said = await DeclarePaymentSheet.show(
        context,
        periodLabel: month.label ?? 'this month',
        outstanding: month.outstanding ?? 0,
        payment: howToPay,
      );
      if (said == null || !mounted) return;

      await sendDeclaration(ref, leaseId: leaseId, period: month, said: said);
      messenger.showSnackBar(const SnackBar(
        content: Text('Told your landlord. They will confirm it.'),
      ));
      if (mounted) offerPushesAfterDeclaring(context, ref);
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    }
  }

  /// A repair, from the conversation: the same tracked report Maintenance
  /// files, so it has a status both sides can follow rather than being a
  /// line in a chat that nobody marks as fixed.
  Future<void> _reportRepair() async {
    final problem = await ReportProblemSheet.show(context);
    if (problem == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final failed = await sendReportedProblem(ref, problem);
      messenger.showSnackBar(SnackBar(
        content: Text(failed == 0
            ? 'Reported. You can follow it under Maintenance.'
            : 'Reported, but $failed '
                '${failed == 1 ? 'photo' : 'photos'} did not upload.'),
      ));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    }
  }

  /// The landlord recording money they were handed, from the conversation
  /// where the tenant said they had paid it.
  Future<void> _recordPayment(String leaseId, String tenantName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final month = _toSettle(await ref.read(leaseBillingProvider(leaseId).future));
      if (!mounted) return;
      if (month == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Nothing is owed on this tenancy.')));
        return;
      }

      final request = await RecordPaymentSheet.show(
        context,
        billingPeriodId: month.id!,
        tenantName: tenantName,
        periodLabel: month.label ?? 'this month',
        outstanding: month.outstanding ?? 0,
      );
      if (request == null || !mounted) return;

      final made = await ref.read(rentApiProvider).recordPayment(leaseId, request);
      // The tenant's page and the dashboard read these same rows.
      ref.invalidate(leaseBillingProvider(leaseId));
      ref.invalidate(leasePaymentsProvider(leaseId));
      ref.invalidate(collectionsProvider);
      if (!mounted) return;
      messenger.showSnackBar(receiptSnackBar(
        context,
        done: 'Recorded.',
        leaseId: leaseId,
        payment: made,
        tenantName: tenantName,
      ));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(ApiFailure.from(error).message)));
    }
  }

  /// What can be done from here besides talking, during a tenancy.
  ///
  /// Only while it is current: before it there is nothing to pay, and after
  /// it the deposit is talked about, not filed.
  List<_Shortcut> _shortcutsFor(InquiryThread thread) {
    final tenancy = thread.inquiry?.tenancy;
    final leaseId = tenancy?.leaseId;
    if (tenancy?.active != true || leaseId == null) return const [];

    if (thread.applicant == null) {
      return [
        _Shortcut('I have paid', 'shortcut-paid', () => _iHavePaid(leaseId)),
        _Shortcut('Report a repair', 'shortcut-repair', _reportRepair),
      ];
    }
    return [
      _Shortcut(
        'Record a payment',
        'shortcut-record',
        () => _recordPayment(
            leaseId, thread.inquiry?.withName ?? 'Your tenant'),
      ),
    ];
  }

  /// The tenant's page, in the Tenants tab, where their rent, papers and
  /// details are.
  ///
  /// Gone to rather than pushed. A conversation sits above the tabs, and
  /// pushing a tab's page from it builds the tabs a second time underneath
  /// -- which the router refuses. The tenant's page has a way back into
  /// this conversation.
  void _openTenancy(String leaseId) =>
      context.go('${Routes.tenants}/${Detail.tenancy(leaseId)}');

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
        // Who you are talking to, and about where. It was the building's
        // name alone, which on a landlord's phone is the same title over
        // every tenant in the building.
        title: _Who(
          summary: thread.valueOrNull?.inquiry,
          onTap: switch (thread.valueOrNull) {
            InquiryThread(
              applicant: _?,
              inquiry: InquirySummary(tenancy: Tenancy(:final leaseId?))
            ) =>
              () => _openTenancy(leaseId),
            _ => null,
          },
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
              shortcuts: _shortcutsFor(value),
              onTenancy: switch (value) {
                InquiryThread(
                  applicant: _?,
                  inquiry: InquirySummary(tenancy: Tenancy(:final leaseId?))
                ) =>
                  () => _openTenancy(leaseId),
                _ => () => context.go(Routes.tenantPlace),
              },
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
    required this.shortcuts,
    required this.onTenancy,
  });

  final InquiryThread thread;
  final TextEditingController composer;
  final ScrollController scroll;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStartLease;
  final List<_Shortcut> shortcuts;

  /// Where the tenancy line leads: the tenant's page for a landlord, My
  /// place for the tenant.
  final VoidCallback onTenancy;

  @override
  Widget build(BuildContext context) {
    final applicant = thread.applicant;
    final status = thread.inquiry?.status;
    final tenancy = thread.inquiry?.tenancy;
    final messages = thread.messages;
    // A current tenancy replaces the panel that vets a stranger: who is
    // asking and what they still need are answered questions by now.
    final renting = tenancy?.active == true;
    final entries = _timeline(messages, tenancy);

    return Column(
      children: [
        if (renting)
          _TenancyLine(
            tenancy: tenancy!,
            asLandlord: applicant != null,
            onTap: onTenancy,
          )
        else if (applicant != null)
          _Applicant(applicant: applicant),
        Expanded(
          child: messages.isEmpty
              ? LizmoMessageState(
                  tone: LizmoMessageTone.neutral,
                  icon: Icons.chat_bubble_outline,
                  title: 'Nothing said yet',
                  detail: 'Whatever you write here goes straight to '
                      '${thread.inquiry?.withName ?? 'them'}.',
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
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      switch (entries[entries.length - 1 - index]) {
                    _Said(:final message) => _Message(message: message),
                    _Day(:final day) => _DayDivider(day: day),
                    _Mark(:final text, :final keyName) =>
                      _Marker(text: text, keyName: keyName),
                  },
                ),
        ),
        if (status == InquirySummaryStatusEnum.CLOSED)
          const _Ended()
        else ...[
          if (applicant != null && !renting)
            _StartLease(
              applicant: applicant,
              alreadyLeased: status == InquirySummaryStatusEnum.LEASED,
              onPressed: onStartLease,
            ),
          if (shortcuts.isNotEmpty) _Shortcuts(shortcuts: shortcuts),
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

// ---- the timeline ---------------------------------------------------------------

/// One row of a thread: something said, the day it was said on, or a point
/// where the tenancy began or ended.
sealed class _Entry {
  const _Entry();
}

final class _Said extends _Entry {
  const _Said(this.message);
  final InquiryMessageResponse message;
}

final class _Day extends _Entry {
  const _Day(this.day);
  final DateTime day;
}

final class _Mark extends _Entry {
  const _Mark(this.text, this.keyName);
  final String text;
  final String keyName;
}

/// The thread oldest first, with a divider at each new day and the tenancy's
/// start and end where they fall.
///
/// A conversation that runs the length of a tenancy is read months apart, so
/// each message carrying its own date was a column of dates. And the tenancy
/// is the most important thing that happened in it: from the first question
/// to moving out, the thread reads as the history of the two of them.
///
/// The start is put at the beginning of its day and the end at the end of
/// its, so the day's messages fall inside the tenancy they were about.
List<_Entry> _timeline(List<InquiryMessageResponse> messages, Tenancy? tenancy) {
  final events = <(DateTime, int, _Entry)>[];
  for (final message in messages) {
    events.add((message.sentAt?.toLocal() ?? DateTime.now(), 1, _Said(message)));
  }

  final start = tenancy?.startDate;
  if (tenancy != null && start != null) {
    final day = DateTime(start.year, start.month, start.day);
    final begun = !day.isAfter(DateTime.now());
    events.add((
      day,
      0,
      _Mark(
        '${begun ? 'Tenancy started' : 'Tenancy starts'} · ${tenancy.place ?? ''}',
        'tenancy-started',
      ),
    ));
  }
  final end = tenancy?.endDate;
  if (tenancy != null && tenancy.active != true && end != null) {
    events.add((
      DateTime(end.year, end.month, end.day, 23, 59, 59),
      2,
      const _Mark('Moved out', 'tenancy-ended'),
    ));
  }

  events.sort((a, b) {
    final when = a.$1.compareTo(b.$1);
    return when != 0 ? when : a.$2.compareTo(b.$2);
  });

  final entries = <_Entry>[];
  DateTime? shown;
  for (final (at, _, entry) in events) {
    final day = DateTime(at.year, at.month, at.day);
    if (shown == null || day != shown) {
      entries.add(_Day(day));
      shown = day;
    }
    entries.add(entry);
  }
  return entries;
}

String _dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final gap = today.difference(DateTime(day.year, day.month, day.day)).inDays;
  if (gap == 0) return 'Today';
  if (gap == 1) return 'Yesterday';
  return _shortDate(day, withYearIfNot: now.year);
}

String _shortDate(DateTime day, {required int withYearIfNot}) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final base = '${day.day} ${months[day.month - 1]}';
  return day.year == withYearIfNot ? base : '$base ${day.year}';
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          _dayLabel(day),
          style: LizmoType.rowSub.copyWith(fontSize: 11),
        ),
      ),
    );
  }
}

/// Where the tenancy began or ended, in the run of the conversation.
class _Marker extends StatelessWidget {
  const _Marker({required this.text, required this.keyName});

  final String text;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey(keyName),
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: LizmoColors.tealBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: LizmoType.rowSub
                .copyWith(fontSize: 12, color: LizmoColors.teal900),
          ),
        ),
      ),
    );
  }
}

// ---- around the thread ----------------------------------------------------------

/// Who you are talking to, and about where.
class _Who extends StatelessWidget {
  const _Who({required this.summary, this.onTap});

  final InquirySummary? summary;

  /// Set for a landlord with a tenant: the header opens their page.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tenancy = summary?.tenancy;
    final where = [
      if (tenancy?.active == true && tenancy?.place != null) tenancy!.place!,
      if (summary?.propertyName != null) summary!.propertyName!,
    ].join(' · ');

    final who = Column(
      key: const ValueKey('thread-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          summary?.withName ?? summary?.propertyName ?? 'Conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
        if (where.isNotEmpty && summary?.withName != null)
          Text(
            where,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LizmoType.rowSub.copyWith(
              fontSize: 12,
              color: LizmoColors.white.withValues(alpha: 0.75),
            ),
          ),
      ],
    );

    return onTap == null
        ? who
        : InkWell(onTap: onTap, child: who);
  }
}

/// The tenancy, in one line, where a stranger's details used to be.
class _TenancyLine extends StatelessWidget {
  const _TenancyLine({
    required this.tenancy,
    required this.asLandlord,
    required this.onTap,
  });

  final Tenancy tenancy;
  final bool asLandlord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = tenancy.startDate;
    final since = start == null
        ? ''
        : ' since ${_shortDate(start, withYearIfNot: DateTime.now().year)}';
    final text = asLandlord
        ? 'Renting ${tenancy.place ?? 'a room'}$since'
        : 'You rent ${tenancy.place ?? 'a room'}$since';

    return Material(
      color: LizmoColors.tealBg,
      child: InkWell(
        key: const ValueKey('tenancy-line'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              const Icon(Icons.home_outlined,
                  size: 18, color: LizmoColors.teal900),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: LizmoColors.teal900),
            ],
          ),
        ),
      ),
    );
  }
}

/// Something to do from the conversation that is not talking.
class _Shortcut {
  const _Shortcut(this.label, this.keyName, this.onTap);

  final String label;
  final String keyName;
  final VoidCallback onTap;
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.shortcuts});

  final List<_Shortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final shortcut in shortcuts)
              Material(
                color: LizmoColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(color: Color(0xFFE3E8E6)),
                ),
                child: InkWell(
                  key: ValueKey(shortcut.keyName),
                  customBorder: const StadiumBorder(),
                  onTap: shortcut.onTap,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      shortcut.label,
                      style: LizmoType.rowSub.copyWith(
                        color: LizmoColors.teal900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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

  /// The time alone: the divider above says which day.
  static String _when(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
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
