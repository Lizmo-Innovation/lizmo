import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../billing/receipt_said.dart';
import '../inquiry/attachments.dart';
import '../inquiry/inquiry_providers.dart';
import '../property/place_details.dart';
import '../property/property_providers.dart';
import '../push/push_offer.dart';
import '../router.dart';
import '../widgets/accept_terms_sheet.dart';
import '../widgets/declare_payment_sheet.dart';
import '../widgets/poller.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/rent_schedule_list.dart';
import '../widgets/report_problem_sheet.dart';

/// One conversation about a place.
///
/// The same screen for both sides, because it is the same conversation.
///
/// Talking and doing are kept apart. Talking is the bubbles and the message
/// box. Doing is one panel pinned above the thread -- the one thing to do
/// now, for whoever is reading -- cards in the thread for whatever changed the
/// tenancy, and "+" beside the message box for the rest.
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

  /// Photos or a PDF chosen and not yet sent.
  final _pending = <PendingFile>[];

  static const _mostPhotos = 4;
  static const _mostBytes = 10 * 1024 * 1024;

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
    final files = [..._pending];
    if ((body.isEmpty && files.isEmpty) || _sending) return;

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
      final api = ref.read(inquiriesApiProvider);
      if (files.isEmpty) {
        await api.sendInquiryMessage(widget.id, NewMessage(body: body));
      } else {
        http.MultipartFile? part(int i) => i < files.length
            ? http.MultipartFile.fromBytes(
                'file${i + 1}',
                files[i].bytes,
                filename: files[i].name,
              )
            : null;
        await api.sendInquiryFiles(
          widget.id,
          body: body.isEmpty ? null : body,
          file1: part(0),
          file2: part(1),
          file3: part(2),
          file4: part(3),
        );
        if (mounted) setState(() => _pending.clear());
      }
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
        unawaited(
          ref
              .read(pushOfferProvider)
              .offer(
                context,
                title: them == null || them.isEmpty
                    ? 'Get told when they reply?'
                    : 'Get told when $them replies?',
                body:
                    'Lizmo will let you know the moment they answer, so you '
                    "don't have to keep checking.",
              ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
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
      final month = _toSettle(
        await ref.read(myBillingProvider(leaseId).future),
      );
      if (!mounted) return;
      if (month == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Nothing is owed right now.')),
        );
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Told your landlord. They will confirm it.'),
        ),
      );
      if (mounted) offerPushesAfterDeclaring(context, ref);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? 'Reported. You can follow it under Maintenance.'
                : 'Reported, but $failed '
                      '${failed == 1 ? 'photo' : 'photos'} did not upload.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
    }
  }

  /// The landlord recording money they were handed, from the conversation
  /// where the tenant said they had paid it.
  Future<void> _recordPayment(String leaseId, String tenantName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final month = _toSettle(
        await ref.read(leaseBillingProvider(leaseId).future),
      );
      if (!mounted) return;
      if (month == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Nothing is owed on this tenancy.')),
        );
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

      final made = await ref
          .read(rentApiProvider)
          .recordPayment(leaseId, request);
      // The tenant's page and the dashboard read these same rows.
      ref.invalidate(leaseBillingProvider(leaseId));
      ref.invalidate(leasePaymentsProvider(leaseId));
      ref.invalidate(collectionsProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        receiptSnackBar(
          context,
          done: 'Recorded.',
          leaseId: leaseId,
          payment: made,
          tenantName: tenantName,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
    }
  }

  /// The landlord agreeing the money arrived, from the panel above the
  /// conversation where the tenant said they sent it.
  Future<void> _confirm(String leaseId, ThreadEvent told) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rentApiProvider).confirmPayment(leaseId, told.entityId!);
      ref.invalidate(inquiryThreadProvider(widget.id));
      ref.invalidate(leaseBillingProvider(leaseId));
      ref.invalidate(leasePaymentsProvider(leaseId));
      ref.invalidate(collectionsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Confirmed ${LizmoMoney.peso(told.amount ?? 0)}.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
    }
  }

  Future<void> _call(String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text('Could not call $phone.')));
    }
  }

  /// Adds photos or a PDF to what will be sent, within what one message holds:
  /// four photos, or one PDF on its own.
  Future<void> _pick(Future<List<PendingFile>> Function() how) async {
    final messenger = ScaffoldMessenger.of(context);
    final List<PendingFile> chosen;
    try {
      chosen = await how();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('That could not be opened. Try another one.'),
        ),
      );
      return;
    }
    if (chosen.isEmpty || !mounted) return;

    String? refused;
    final pdf = chosen.any((file) => file.pdf);
    if (chosen.any((file) => file.bytes.length > _mostBytes)) {
      refused = 'That file is larger than 10MB. Choose a smaller one.';
    } else if (pdf && _pending.isNotEmpty) {
      refused = 'A PDF goes in a message of its own. Send these first.';
    } else if (!pdf && _pending.any((file) => file.pdf)) {
      refused = 'A PDF goes in a message of its own. Send it first.';
    } else if (_pending.length + chosen.length > _mostPhotos) {
      refused = 'Up to $_mostPhotos photos in one message.';
    }
    if (refused != null) {
      messenger.showSnackBar(SnackBar(content: Text(refused)));
      return;
    }
    setState(() => _pending.addAll(chosen));
  }

  /// Photos and PDFs, for both sides, while the conversation is open.
  List<_Action> _filesFor(InquiryThread thread) {
    if (thread.inquiry?.status == InquirySummaryStatusEnum.CLOSED) {
      return const [];
    }
    final picker = ref.read(attachmentPickerProvider);
    final room = _mostPhotos - _pending.length;
    return [
      _Action(
        'Take a photo',
        Icons.photo_camera_outlined,
        'action-camera',
        () => _pick(() async {
          final shot = await picker.camera();
          return shot == null ? const [] : [shot];
        }),
      ),
      _Action(
        'Choose photos',
        Icons.photo_library_outlined,
        'action-photos',
        () => _pick(() => picker.photos(room)),
      ),
      _Action(
        'Send a PDF',
        Icons.picture_as_pdf_outlined,
        'action-pdf',
        () => _pick(() async {
          final file = await picker.pdf();
          return file == null ? const [] : [file];
        }),
      ),
    ];
  }

  /// What can be done from here besides talking, for this side.
  ///
  /// Behind "+" rather than in a row of chips over the message box: the box
  /// is for talking, and a row of buttons above it read as part of the
  /// conversation.
  List<_Action> _actionsFor(InquiryThread thread) {
    final tenancy = thread.inquiry?.tenancy;
    final leaseId = tenancy?.leaseId;
    final current = tenancy?.active == true && leaseId != null;
    final applicant = thread.applicant;

    if (applicant == null) {
      // The tenant: only during a tenancy. Before it there is nothing to pay,
      // and after it the deposit is talked about, not filed.
      if (!current) return const [];
      return [
        _Action(
          'I have paid',
          Icons.payments_outlined,
          'shortcut-paid',
          () => _iHavePaid(leaseId),
        ),
        _Action(
          'Report a repair',
          Icons.build_outlined,
          'shortcut-repair',
          _reportRepair,
        ),
      ];
    }
    return [
      if (current)
        _Action(
          'Record a payment',
          Icons.payments_outlined,
          'shortcut-record',
          () => _recordPayment(
            leaseId,
            thread.inquiry?.withName ?? 'Your tenant',
          ),
        ),
      if (!current &&
          thread.inquiry?.status == InquirySummaryStatusEnum.OPEN &&
          applicant.stillNeeds.isEmpty)
        _Action(
          'Start a lease',
          Icons.key_outlined,
          'action-start-lease',
          () => _startLease(thread),
        ),
    ];
  }

  Future<void> _showActions(List<_Action> actions) async {
    final chosen = await showModalBottomSheet<_Action>(
      context: context,
      backgroundColor: LizmoColors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                ListTile(
                  key: ValueKey(action.keyName),
                  minTileHeight: 52,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: LizmoColors.tealTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      action.icon,
                      size: 18,
                      color: LizmoColors.teal900,
                    ),
                  ),
                  title: Text(action.label, style: LizmoType.rowName),
                  onTap: () => Navigator.of(context).pop(action),
                ),
            ],
          ),
        ),
      ),
    );
    chosen?.onTap();
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
    // What the place asks up front, to fill in. Without it the fields are
    // simply blank, as they were.
    PlaceDetailsDto? place;
    try {
      place = await ref.read(placeDetailsProvider(propertyId).future);
    } catch (_) {}
    if (!mounted) return;

    final terms = await AcceptTermsSheet.show(
      context,
      tenantName: applicant?.name ?? 'this tenant',
      slot: thread.inquiry?.propertyName ?? 'this place',
      askingRent: rooms.isEmpty ? null : rooms.first.rent,
      rooms: rooms,
      depositMonths: place?.depositMonths,
      advanceMonths: place?.advanceMonths,
    );
    if (terms == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inquiriesApiProvider)
          .startLeaseFromInquiry(widget.id, acceptRequest: terms);

      // The thread comes back with "Lease started" in it.
      ref.invalidate(inquiryThreadProvider(widget.id));
      ref.invalidate(myInquiriesProvider);
      // Everything the tenancy moved: the room's occupancy, the property's
      // figures, and who is living there.
      ref.invalidate(propertyLeasesProvider(propertyId));
      ref.invalidate(unitsProvider(propertyId));
      ref.invalidate(propertiesProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text('${applicant?.name ?? 'They'} now has a tenancy.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
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
            child: Text('End it', style: TextStyle(color: LizmoColors.redText)),
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
        SnackBar(content: Text(ApiFailure.from(error).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(inquiryThreadProvider(widget.id));
    final value = thread.valueOrNull;

    // A message arriving is activity too, not just one being sent: both sides
    // of a conversation keep it quick.
    final count = value?.messages.length ?? _messagesSeen;
    if (count != _messagesSeen) {
      _messagesSeen = count;
      _poller.currentState?.stirred();
    }

    final leaseId = value?.inquiry?.tenancy?.leaseId;
    // The header opens the tenancy: the tenant's page for a landlord, My
    // place for the tenant.
    final VoidCallback? onHeader = value == null
        ? null
        : value.applicant != null
        ? (leaseId == null || value.inquiry?.tenancy?.active != true
              ? null
              : () => _openTenancy(leaseId))
        : (value.inquiry?.tenancy?.active == true
              ? () => context.go(Routes.tenantPlace)
              : null);
    // Landlords only: a tenant already has the landlord's number from the
    // place's page, and a stranger ringing from a chat is what the chat is
    // for avoiding.
    final phone = value?.applicant?.phone;

    return Poller(
      key: _poller,
      interval: _whileTalking,
      slowAfter: _quietFor,
      slowInterval: _whenQuiet,
      onTick: _reread,
      child: Scaffold(
        backgroundColor: LizmoColors.canvas,
        appBar: AppBar(
          toolbarHeight: 64,
          backgroundColor: LizmoColors.teal900,
          foregroundColor: LizmoColors.white,
          elevation: 0,
          titleSpacing: 0,
          flexibleSpace: const CustomPaint(
            painter: LatticePainter(),
            size: Size.infinite,
          ),
          title: _Who(thread: value, onTap: onHeader),
          actions: [
            if (phone != null && phone.isNotEmpty)
              IconButton(
                key: const ValueKey('call'),
                tooltip: 'Call ${value?.applicant?.name ?? 'them'}',
                icon: const Icon(Icons.call_outlined),
                onPressed: () => _call(phone),
              ),
            if (value?.inquiry?.status == InquirySummaryStatusEnum.OPEN)
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
              actions: [..._actionsFor(value), ..._filesFor(value)],
              pending: _pending,
              onRemovePending: (index) =>
                  setState(() => _pending.removeAt(index)),
              onActions: _showActions,
              panel: _Panel(
                thread: value,
                onStartLease: () => _startLease(value),
                onIHavePaid: leaseId == null ? null : () => _iHavePaid(leaseId),
                onConfirm: leaseId == null
                    ? null
                    : (told) => _confirm(leaseId, told),
                onSeeRent: () => context.go(Routes.tenantPlace),
              ),
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

/// Something to do from the conversation that is not talking.
class _Action {
  const _Action(this.label, this.icon, this.keyName, this.onTap);

  final String label;
  final IconData icon;
  final String keyName;
  final VoidCallback onTap;
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.thread,
    required this.composer,
    required this.scroll,
    required this.sending,
    required this.onSend,
    required this.actions,
    required this.onActions,
    required this.panel,
    required this.pending,
    required this.onRemovePending,
  });

  final List<PendingFile> pending;
  final void Function(int index) onRemovePending;

  final InquiryThread thread;
  final TextEditingController composer;
  final ScrollController scroll;
  final bool sending;
  final VoidCallback onSend;
  final List<_Action> actions;
  final void Function(List<_Action>) onActions;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    final status = thread.inquiry?.status;
    final entries = _timeline(thread);
    final asLandlord = thread.applicant != null;
    // The two names the cards need: whose payment, and who is to confirm it.
    final them = thread.applicant?.name ?? thread.inquiry?.withName;

    return Column(
      children: [
        // The one thing to do now. Does not scroll: it is not part of the
        // conversation, and it should not leave when somebody reads back.
        panel,
        Expanded(
          child: entries.isEmpty
              ? LizmoMessageState(
                  tone: LizmoMessageTone.neutral,
                  icon: Icons.chat_bubble_outline,
                  title: 'Nothing said yet',
                  detail:
                      'Whatever you write here goes straight to '
                      '${thread.inquiry?.withName ?? 'them'}.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Most of a phone's width, and no wider than a line can
                    // be read across on a tablet.
                    final bubble = math.min(constraints.maxWidth * 0.78, 520.0);
                    return ListView.builder(
                      key: const ValueKey('thread-messages'),
                      controller: scroll,
                      // Anchored at the newest, as every chat is. Reversed,
                      // offset 0 is the bottom, so a new message appears in
                      // view on its own, and sending only has to return to 0
                      // if somebody had scrolled up.
                      reverse: true,
                      padding: context.pageInsets(16, 8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) =>
                          switch (entries[entries.length - 1 - index]) {
                            _Said(:final message) => _Message(
                              message: message,
                              maxWidth: bubble,
                            ),
                            _Day(:final day) => _DayDivider(day: day),
                            _Happened(:final event) => _EventCard(
                              event: event,
                              asLandlord: asLandlord,
                              them: them,
                              place: thread.inquiry?.tenancy?.place,
                            ),
                          },
                    );
                  },
                ),
        ),
        if (status == InquirySummaryStatusEnum.CLOSED)
          const _Ended()
        else
          _Composer(
            controller: composer,
            sending: sending,
            onSend: onSend,
            onMore: actions.isEmpty ? null : () => onActions(actions),
            pending: pending,
            onRemove: onRemovePending,
          ),
      ],
    );
  }
}

// ---- the panel ------------------------------------------------------------------

/// The one thing to do now, above the conversation.
///
/// What it is depends on who is reading and where things stand: a stranger
/// to let to, a payment to confirm, rent to pay or waiting to be confirmed.
/// With nothing to do there is no panel, rather than one that says so.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.thread,
    required this.onStartLease,
    required this.onIHavePaid,
    required this.onConfirm,
    required this.onSeeRent,
  });

  final InquiryThread thread;
  final VoidCallback onStartLease;
  final VoidCallback? onIHavePaid;
  final void Function(ThreadEvent told)? onConfirm;
  final VoidCallback onSeeRent;

  /// How many days ahead a month is due before it is worth a panel.
  static const _dueSoon = 7;

  /// The newest payment the tenant said they made and nobody has looked at.
  ThreadEvent? get _waiting {
    ThreadEvent? found;
    for (final event in thread.events) {
      if (event.kind == ThreadEventKindEnum.PAYMENT_REPORTED &&
          event.state == 'PENDING_VERIFICATION') {
        found = event;
      }
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final applicant = thread.applicant;
    final tenancy = thread.inquiry?.tenancy;
    final current = tenancy?.active == true;
    final status = thread.inquiry?.status;
    final waiting = current ? _waiting : null;

    if (status == InquirySummaryStatusEnum.CLOSED) {
      return const SizedBox.shrink();
    }

    if (applicant != null && !current) {
      if (status == InquirySummaryStatusEnum.LEASED) {
        return _Frame(
          key: const ValueKey('already-leased'),
          child: Text(
            'They have a tenancy from this conversation.',
            style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
          ),
        );
      }
      return _ApplicantPanel(applicant: applicant, onStartLease: onStartLease);
    }

    if (!current) return const SizedBox.shrink();

    if (applicant != null) {
      // The landlord, with the tenant saying they have paid.
      if (waiting == null || onConfirm == null) return const SizedBox.shrink();
      final amount = LizmoMoney.peso(waiting.amount ?? 0);
      return _Frame(
        key: const ValueKey('panel-confirm'),
        eyebrow: _eyebrow(waiting.label),
        child: _PanelRow(
          amount: amount,
          note:
              '${applicant.name ?? 'They'} said they paid · '
              '${waitedFor(waiting.at ?? DateTime.now())}',
          noteTone: StatusTone.amber,
          action: _Coral(
            key: const ValueKey('panel-confirm-button'),
            label: 'Confirm $amount',
            onPressed: () => onConfirm!(waiting),
          ),
        ),
      );
    }

    // The tenant.
    final landlord = thread.inquiry?.withName ?? 'your landlord';
    if (waiting != null) {
      return _Frame(
        key: const ValueKey('panel-waiting'),
        eyebrow: _eyebrow(waiting.label),
        child: _PanelRow(
          amount: LizmoMoney.peso(waiting.amount ?? 0),
          note:
              'Waiting for $landlord · ${waitedFor(waiting.at ?? DateTime.now())}',
          noteTone: StatusTone.amber,
          // Not coral: there is nothing for them to do but wait.
          action: TextButton(
            key: const ValueKey('panel-see-rent'),
            onPressed: onSeeRent,
            style: TextButton.styleFrom(
              foregroundColor: LizmoColors.teal900,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('See rent'),
          ),
        ),
      );
    }

    final rent = thread.rent;
    final due = rent?.dueDate;
    if (rent == null || due == null || onIHavePaid == null) {
      return const SizedBox.shrink();
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final left = DateUtils.dateOnly(due).difference(today).inDays;
    final overdue = rent.overdue ?? false;
    if (!overdue && left > _dueSoon) return const SizedBox.shrink();

    return _Frame(
      key: const ValueKey('panel-due'),
      eyebrow: _eyebrow(rent.label),
      child: _PanelRow(
        amount: LizmoMoney.peso(rent.outstanding ?? 0),
        note: overdue
            ? 'Overdue since ${_shortDate(due, withYearIfNot: today.year)}'
            : left == 0
            ? 'Due today'
            : 'Due ${_shortDate(due, withYearIfNot: today.year)}',
        noteTone: overdue ? StatusTone.red : StatusTone.amber,
        action: _Coral(
          key: const ValueKey('panel-paid'),
          label: 'I have paid',
          onPressed: onIHavePaid!,
        ),
      ),
    );
  }

  /// "NOVEMBER 2026", "DEPOSIT".
  static String _eyebrow(String? label) {
    final said = (label ?? 'Rent').replaceFirst(
      RegExp(r'^the (security )?'),
      '',
    );
    return said.toUpperCase();
  }
}

/// Who is asking, as far as the landlord is allowed to know before a tenancy,
/// and the button that lets to them.
///
/// The ID type without its number, no photographs, no emergency contact.
/// Anyone can print a code and stick it on a gate. What it does say is how
/// ready they are: a lease can be written the moment nothing is missing.
class _ApplicantPanel extends StatelessWidget {
  const _ApplicantPanel({required this.applicant, required this.onStartLease});

  final Applicant applicant;
  final VoidCallback onStartLease;

  @override
  Widget build(BuildContext context) {
    final missing = applicant.stillNeeds;
    final facts = <String>[
      if (applicant.age != null) '${applicant.age} years old',
      if ((applicant.occupation ?? '').isNotEmpty) applicant.occupation!,
      if ((applicant.permanentAddress ?? '').isNotEmpty)
        'from ${applicant.permanentAddress}',
    ];

    return _Frame(
      key: const ValueKey('applicant'),
      eyebrow: 'APPLICANT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (facts.isNotEmpty)
            Text(facts.join(' · '), style: LizmoType.rowSub),
          const SizedBox(height: 6),
          if (missing.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: LizmoColors.teal900,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ready to let to · ID and emergency contact shared',
                    key: const ValueKey('applicant-ready'),
                    style: LizmoType.rowSub.copyWith(
                      color: LizmoColors.teal900,
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              key: const ValueKey('tenant-still-needs'),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
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
          _Coral(
            key: const ValueKey('start-lease'),
            label: 'Start the lease',
            onPressed: missing.isEmpty ? onStartLease : null,
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

class _Frame extends StatelessWidget {
  const _Frame({super.key, this.eyebrow, required this.child});

  final String? eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.pageGutter,
        12,
        context.pageGutter,
        12,
      ),
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow case final eyebrow?) ...[
            Text(
              eyebrow,
              style: LizmoType.dataMedium.copyWith(
                fontSize: 11,
                letterSpacing: 0.8,
                color: LizmoColors.slateText,
              ),
            ),
            const SizedBox(height: 4),
          ],
          child,
        ],
      ),
    );
  }
}

enum StatusTone { amber, red, teal, slate }

(Color, Color) _toneColours(StatusTone tone) => switch (tone) {
  StatusTone.amber => (LizmoColors.amberBg, LizmoColors.amberText),
  StatusTone.red => (LizmoColors.redBg, LizmoColors.redText),
  StatusTone.teal => (LizmoColors.tealBg, LizmoColors.teal900),
  StatusTone.slate => (const Color(0xFFEFF2F1), LizmoColors.slateText),
};

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.tone);

  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, ink) = _toneColours(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: LizmoType.rowSub.copyWith(
          fontSize: 11,
          color: ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The amount, how it stands, and the one control.
class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.amount,
    required this.note,
    required this.noteTone,
    required this.action,
  });

  final String amount;
  final String note;
  final StatusTone noteTone;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(amount, style: LizmoType.dataMedium.copyWith(fontSize: 17)),
            _Chip(note, noteTone),
          ],
        ),
        action,
      ],
    );
  }
}

class _Coral extends StatelessWidget {
  const _Coral({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: LizmoColors.coral,
        foregroundColor: LizmoColors.onCoral,
        disabledBackgroundColor: LizmoColors.coral.withValues(alpha: 0.4),
        disabledForegroundColor: LizmoColors.onCoral.withValues(alpha: 0.6),
        minimumSize: const Size(0, 44),
        textStyle: LizmoType.buttonLabel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}

// ---- the timeline ---------------------------------------------------------------

/// One row of a thread: something said, the day it was said on, or something
/// that changed the tenancy.
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

final class _Happened extends _Entry {
  const _Happened(this.event);
  final ThreadEvent event;
}

/// The thread oldest first, with a divider at each new day and what happened
/// to the tenancy where it fell.
///
/// A conversation that runs the length of a tenancy is read months apart, so
/// each message carrying its own date was a column of dates. And the tenancy
/// is the most important thing in it: from the first question to moving out,
/// the thread reads as the history of the two of them.
List<_Entry> _timeline(InquiryThread thread) {
  final events = <(DateTime, int, _Entry)>[];
  for (final message in thread.messages) {
    events.add((
      message.sentAt?.toLocal() ?? DateTime.now(),
      1,
      _Said(message),
    ));
  }

  final happened = [...thread.events];
  final tenancy = thread.inquiry?.tenancy;
  // From the tenancy itself when the server sent no card for it, so the
  // start and the end are always where they fell.
  if (tenancy?.startDate case final start?
      when !happened.any((e) => e.kind == ThreadEventKindEnum.LEASE_STARTED)) {
    happened.add(
      ThreadEvent(
        kind: ThreadEventKindEnum.LEASE_STARTED,
        at: DateTime(start.year, start.month, start.day),
        entityId: tenancy!.leaseId,
      ),
    );
  }
  if (tenancy != null &&
      tenancy.active != true &&
      tenancy.endDate != null &&
      !happened.any((e) => e.kind == ThreadEventKindEnum.MOVED_OUT)) {
    final end = tenancy.endDate!;
    happened.add(
      ThreadEvent(
        kind: ThreadEventKindEnum.MOVED_OUT,
        at: DateTime(end.year, end.month, end.day, 23, 59, 59),
      ),
    );
  }
  for (final event in happened) {
    final at = event.at?.toLocal() ?? DateTime.now();
    // The start of a tenancy before the day's messages, moving out after.
    final rank = switch (event.kind) {
      ThreadEventKindEnum.LEASE_STARTED => 0,
      ThreadEventKindEnum.MOVED_OUT => 2,
      _ => 1,
    };
    events.add((at, rank, _Happened(event)));
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final base = '${day.day} ${months[day.month - 1]}';
  return day.year == withYearIfNot ? base : '$base ${day.year}';
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final label = _dayLabel(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Text(
            label.toUpperCase(),
            style: LizmoType.dataMedium.copyWith(
              fontSize: 11,
              letterSpacing: 0.8,
              color: LizmoColors.slateText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Something that changed the tenancy, as a card across the thread.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.asLandlord,
    required this.them,
    required this.place,
  });

  final ThreadEvent event;
  final bool asLandlord;

  /// The other side's name: the tenant's for a landlord, the landlord's for
  /// a tenant.
  final String? them;
  final String? place;

  @override
  Widget build(BuildContext context) {
    final amount = LizmoMoney.peso(event.amount ?? 0);
    final month = event.label;
    final now = DateTime.now();
    final payer = asLandlord ? (them ?? 'They') : 'You';
    final confirmer = asLandlord ? 'you' : (them ?? 'your landlord');

    final (
      IconData icon,
      StatusTone tone,
      String title,
      String? sub,
      _Chip? chip,
      String key,
    ) = switch (event.kind) {
      ThreadEventKindEnum.ID_SHARED => (
        Icons.badge_outlined,
        StatusTone.teal,
        'ID shared',
        asLandlord
            ? 'A photo of their ID, for the lease'
            : 'Your landlord can see the photo of your ID',
        null,
        'event-id',
      ),
      ThreadEventKindEnum.PAYMENT_REPORTED => (
        Icons.payments_outlined,
        StatusTone.amber,
        '$payer paid $amount',
        month == null ? null : 'For $month',
        switch (event.state) {
          'CONFIRMED' => const _Chip('Confirmed', StatusTone.teal),
          'REJECTED' => const _Chip('Not received', StatusTone.red),
          _ => _Chip('Waiting for $confirmer', StatusTone.amber),
        },
        'event-paid-${event.entityId}',
      ),
      ThreadEventKindEnum.PAYMENT_CONFIRMED => (
        Icons.receipt_long_outlined,
        StatusTone.teal,
        'Payment confirmed · $amount',
        [
          if (event.receiptNumber != null) 'Receipt No. ${event.receiptNumber}',
          ?month,
        ].join(' · '),
        null,
        'event-confirmed-${event.entityId}',
      ),
      ThreadEventKindEnum.PAYMENT_REJECTED => (
        Icons.report_gmailerrorred_outlined,
        StatusTone.red,
        '$amount not received',
        month == null ? null : 'For $month',
        null,
        'event-rejected-${event.entityId}',
      ),
      ThreadEventKindEnum.REPAIR_REPORTED => (
        Icons.build_outlined,
        StatusTone.amber,
        'Repair reported',
        event.label,
        switch (event.state) {
          'IN_PROGRESS' => const _Chip('Being fixed', StatusTone.amber),
          'RESOLVED' => const _Chip('Fixed', StatusTone.teal),
          'CLOSED' => const _Chip('Closed', StatusTone.slate),
          _ => const _Chip('New', StatusTone.amber),
        },
        'event-repair-${event.entityId}',
      ),
      ThreadEventKindEnum.LEASE_ENDING => (
        Icons.event_outlined,
        StatusTone.slate,
        'Lease ends ${_endDate(event.label, now)}',
        asLandlord
            ? 'Agree whether they are staying'
            : 'Talk to your landlord about staying',
        null,
        'event-ending',
      ),
      ThreadEventKindEnum.MOVED_OUT => (
        Icons.logout,
        StatusTone.slate,
        'Moved out',
        place,
        null,
        'tenancy-ended',
      ),
      _ => (
        Icons.key_outlined,
        StatusTone.teal,
        (event.at ?? now).isAfter(now)
            ? 'Tenancy starts · ${place ?? ''}'
            : 'Tenancy started · ${place ?? ''}',
        event.amount == null ? null : '$amount a month',
        null,
        'tenancy-started',
      ),
    };
    final (tint, ink) = _toneColours(tone);

    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LizmoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E8E6)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LizmoType.rowName.copyWith(
                      fontSize: 13,
                      color: LizmoColors.ink,
                    ),
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub, style: LizmoType.rowSub),
                  ],
                ],
              ),
            ),
            if (chip != null) ...[const SizedBox(width: 8), chip],
          ],
        ),
      ),
    );
  }

  static String _endDate(String? iso, DateTime now) {
    final day = iso == null ? null : DateTime.tryParse(iso);
    return day == null ? 'soon' : _shortDate(day, withYearIfNot: now.year);
  }
}

// ---- around the thread ----------------------------------------------------------

/// Who you are talking to, and about where.
class _Who extends StatelessWidget {
  const _Who({required this.thread, this.onTap});

  final InquiryThread? thread;

  /// Opens the tenancy, when there is one.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final summary = thread?.inquiry;
    final tenancy = summary?.tenancy;
    final property = summary?.propertyName;
    final asLandlord = thread?.applicant != null;
    final current = tenancy?.active == true;
    final name = summary?.withName ?? property ?? 'Conversation';

    // The name was the building's alone, which on a landlord's phone is the
    // same title over every tenant in the building.
    final sub = switch ((asLandlord, current)) {
      (true, true) => [tenancy?.place, property].nonNulls.join(' · '),
      (true, false) => property == null ? null : 'Asking about $property',
      (false, true) =>
        'Your landlord · ${[tenancy?.place, property].nonNulls.join(', ')}',
      (false, false) => property == null ? null : 'About $property',
    };

    final who = Row(
      key: const ValueKey('thread-header'),
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: LizmoColors.white,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(name),
            style: LizmoType.rowName.copyWith(
              fontSize: 13,
              color: LizmoColors.teal900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LizmoType.rowName.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LizmoColors.white,
                ),
              ),
              if (sub != null && sub.isNotEmpty && summary?.withName != null)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LizmoType.rowSub.copyWith(
                    color: LizmoColors.onTealMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return onTap == null
        ? who
        : InkWell(
            key: const ValueKey('tenancy-line'),
            onTap: onTap,
            child: who,
          );
  }

  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.maxWidth});

  final InquiryMessageResponse message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine ?? false;
    const big = Radius.circular(16);
    const small = Radius.circular(4);
    final said = message.body ?? '';
    final body = said.trim();
    final files = message.attachments;
    final ink = mine ? LizmoColors.white : LizmoColors.ink;

    return Padding(
      key: ValueKey('message-${message.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: files.isEmpty
                ? const EdgeInsets.fromLTRB(14, 10, 14, 10)
                : const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: mine ? LizmoColors.teal900 : LizmoColors.white,
              borderRadius: mine
                  ? const BorderRadius.only(
                      topLeft: big,
                      topRight: big,
                      bottomLeft: big,
                      bottomRight: small,
                    )
                  : const BorderRadius.only(
                      topLeft: big,
                      topRight: big,
                      bottomLeft: small,
                      bottomRight: big,
                    ),
              border: mine ? null : Border.all(color: const Color(0xFFE3E8E6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (files.isNotEmpty)
                  _Files(files: files, mine: mine, width: maxWidth - 12),
                if (body.isNotEmpty)
                  Padding(
                    padding: files.isEmpty
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text(
                      said,
                      style: LizmoType.rowSub.copyWith(
                        fontSize: 14,
                        color: ink,
                      ),
                    ),
                  ),
                // What it was, once it has gone: the year passed, or whoever
                // sent it closed their account.
                if (body.isEmpty && files.isEmpty)
                  Text(
                    'Attachment removed',
                    key: const ValueKey('attachment-removed'),
                    style: LizmoType.rowSub.copyWith(
                      fontStyle: FontStyle.italic,
                      color: mine
                          ? LizmoColors.onTealMuted
                          : LizmoColors.slateText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _when(message.sentAt),
            style: LizmoType.dataMedium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: LizmoColors.slateText,
            ),
          ),
        ],
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

/// Photos as a picture or a grid of them; a PDF as a chip that opens it.
class _Files extends StatelessWidget {
  const _Files({required this.files, required this.mine, required this.width});

  final List<MessageAttachment> files;
  final bool mine;
  final double width;

  @override
  Widget build(BuildContext context) {
    final photos = [
      for (final file in files)
        if (file.kind == MessageAttachmentKindEnum.PHOTO) file,
    ];
    final pdfs = [
      for (final file in files)
        if (file.kind == MessageAttachmentKindEnum.PDF) file,
    ];
    final across = math.min(width, 260.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (photos.length == 1)
          _Photo(
            photo: photos.first,
            width: across,
            height: across * 0.75,
            onTap: () => _Gallery.show(context, photos, 0),
          )
        else if (photos.isNotEmpty)
          SizedBox(
            width: across,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final (i, photo) in photos.indexed)
                  _Photo(
                    photo: photo,
                    width: (across - 4) / 2,
                    height: (across - 4) / 2,
                    onTap: () => _Gallery.show(context, photos, i),
                  ),
              ],
            ),
          ),
        for (final pdf in pdfs) _PdfChip(file: pdf, mine: mine, width: across),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.photo,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final MessageAttachment photo;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = photo.previewUrl ?? photo.url;
    return Semantics(
      button: true,
      label: 'Photo. Opens larger.',
      child: GestureDetector(
        key: ValueKey('attachment-${photo.id}'),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: width,
            height: height,
            color: LizmoColors.tealTint,
            child: url == null
                ? null
                : Image(
                    image: AttachmentImage(url, id: 'preview-${photo.id}'),
                    fit: BoxFit.cover,
                    // An hour-old link, or no signal: the conversation goes
                    // on without the picture.
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: LizmoColors.slate,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PdfChip extends StatelessWidget {
  const _PdfChip({required this.file, required this.mine, required this.width});

  final MessageAttachment file;
  final bool mine;
  final double width;

  @override
  Widget build(BuildContext context) {
    final name = file.name ?? 'A PDF';
    return Material(
      color: mine
          ? LizmoColors.white.withValues(alpha: 0.12)
          : LizmoColors.canvas,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('attachment-${file.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final url = file.url;
          if (url == null) return;
          final messenger = ScaffoldMessenger.of(context);
          final ok = await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('That PDF could not be opened. Try again.'),
              ),
            );
          }
        },
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LizmoColors.redBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 20,
                    color: LizmoColors.redText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LizmoType.rowName.copyWith(
                          fontSize: 13,
                          color: mine ? LizmoColors.white : LizmoColors.ink,
                        ),
                      ),
                      Text(
                        [
                          'PDF',
                          fileSize(file.byteSize),
                        ].where((part) => part.isNotEmpty).join(' · '),
                        style: LizmoType.rowSub.copyWith(
                          fontSize: 11,
                          color: mine
                              ? LizmoColors.onTealMuted
                              : LizmoColors.slateText,
                        ),
                      ),
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

/// A message's photos, full size, one at a time.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.photos, required this.start});

  final List<MessageAttachment> photos;
  final int start;

  static Future<void> show(
    BuildContext context,
    List<MessageAttachment> photos,
    int start,
  ) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _Gallery(photos: photos, start: start),
    );
  }

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  late final _pages = PageController(initialPage: widget.start);
  late int _showing = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      key: const ValueKey('attachment-gallery'),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.photos.length,
            onPageChanged: (page) => setState(() => _showing = page),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              final url = photo.url;
              return InteractiveViewer(
                child: Center(
                  child: url == null
                      ? const SizedBox.shrink()
                      : Image(
                          image: AttachmentImage(url, id: 'full-${photo.id}'),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            'That photo could not be loaded. Close this and '
                            'open the conversation again.',
                            textAlign: TextAlign.center,
                            style: LizmoType.rowSub.copyWith(
                              color: LizmoColors.white,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: LizmoColors.white),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_showing + 1} / ${widget.photos.length}',
                  style: LizmoType.dataMedium.copyWith(
                    fontSize: 12,
                    color: LizmoColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onMore,
    required this.pending,
    required this.onRemove,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  /// The things to do that are not talking. Null when there are none.
  final VoidCallback? onMore;

  /// Photos or a PDF chosen and not yet sent.
  final List<PendingFile> pending;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.pageGutter - 4,
        8,
        context.pageGutter - 4,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending.isNotEmpty) ...[
            SizedBox(
              key: const ValueKey('pending-tray'),
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pending.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _PendingTile(
                  file: pending[index],
                  onRemove: () => onRemove(index),
                  index: index,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onMore != null) ...[
                _Round(
                  key: const ValueKey('more-actions'),
                  tooltip: 'More',
                  fill: LizmoColors.tealTint,
                  onTap: onMore,
                  child: const Icon(
                    Icons.add,
                    color: LizmoColors.teal900,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  key: const ValueKey('message-field'),
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  style: LizmoType.rowName.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: pending.isEmpty
                        ? 'Write a message'
                        : 'Add a message',
                    hintStyle: LizmoType.rowSub.copyWith(fontSize: 14),
                    counterText: '',
                    filled: true,
                    fillColor: LizmoColors.canvas,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: LizmoColors.teal900),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              _Round(
                key: const ValueKey('send-message'),
                tooltip: 'Send',
                fill: LizmoColors.teal900,
                onTap: sending ? null : onSend,
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(LizmoColors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: LizmoColors.white,
                        size: 20,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One file waiting to go, with a way to take it back out.
class _PendingTile extends StatelessWidget {
  const _PendingTile({
    required this.file,
    required this.onRemove,
    required this.index,
  });

  final PendingFile file;
  final VoidCallback onRemove;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: file.pdf
              ? Container(
                  width: 150,
                  height: 64,
                  padding: const EdgeInsets.all(8),
                  color: LizmoColors.canvas,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: LizmoColors.redText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LizmoType.rowSub.copyWith(
                            color: LizmoColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Image.memory(
                  file.bytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: LizmoColors.tealTint,
                    child: const Icon(
                      Icons.image_outlined,
                      color: LizmoColors.teal900,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Semantics(
            button: true,
            label: 'Remove ${file.pdf ? file.name : 'this photo'}',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('pending-remove-$index'),
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: LizmoColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: LizmoColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    super.key,
    required this.tooltip,
    required this.fill,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final Color fill;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Material(
            color: fill,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(child: child),
            ),
          ),
        ),
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
