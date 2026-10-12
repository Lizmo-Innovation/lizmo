import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import 'package:go_router/go_router.dart';

import '../inquiry/inquiry_providers.dart';
import '../router.dart';
import '../widgets/ask_for_number_sheet.dart';
import '../widgets/full_screen_image.dart';
import '../tenant/tenant_providers.dart';
import '../property/place_details.dart';
import '../widgets/before_you_ask.dart';

/// What a tenant sees after entering the code: the place, and what is free.
///
/// Grouped by floor, because "is there anything on the second floor?" is the
/// question people actually ask in a boarding house.
class PropertyByCodeScreen extends ConsumerWidget {
  const PropertyByCodeScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyByCodeProvider(code));

    // Everything except a photograph still needs the bar's height kept
    // clear: it floats over the body now rather than pushing it down.
    final under = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      // The photograph is the top of the screen. A teal bar across it was a
      // slab over the one thing somebody came to look at.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // No title: the name is in the body now, where it survives a scroll
        // and is not cut to eighteen pixels of ellipsis.
        leading: const _BackOverPhoto(),
      ),
      // Pinned rather than the last item in the list. On a house with six
      // floors the one thing a tenant came here to do was below the fold.
      bottomNavigationBar: switch (property) {
        AsyncData(:final value) => _AskBar(place: value),
        _ => null,
      },
      body: switch (property) {
        AsyncData(:final value) => _Place(place: value, under: under),
        AsyncError(:final error) => Padding(
            padding: EdgeInsets.only(top: under),
            child: _NotFound(failure: ApiFailure.from(error)),
          ),
        _ => _Arriving(under: under),
      },
    );
  }
}

/// Back, over a photograph that might be white sky or a dark stairwell.
///
/// A bare white arrow vanishes against the first and a bare dark one against
/// the second, so it carries its own scrim and stops depending on whatever
/// is underneath it.
class _BackOverPhoto extends StatelessWidget {
  const _BackOverPhoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: LizmoColors.white),
          tooltip: 'Back',
        ),
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.place, required this.under});

  final PropertyByCodeResponse place;

  /// How much room the floating bar needs when no photograph covers it.
  final double under;

  @override
  Widget build(BuildContext context) {
    final floors = place.floors;
    final free = (place.vacantWholeUnits ?? 0) + (place.vacantBeds ?? 0);

    return ListView(
      // No side padding on the list itself: the photographs run edge to edge,
      // and everything under them is inset on its own.
      // With no photograph to cover it, the floating bar gets its room back.
      padding: EdgeInsets.only(
        top: place.photos.isEmpty ? under + 8 : 0,
        bottom: 28,
      ),
      children: [
        // First, before the name: this is the thing somebody decides on,
        // and until now the answer to "what does it look like" was a trip
        // across town to stand outside it.
        if (place.photos.isNotEmpty) ...[
          _Photos(urls: place.photos, name: place.name ?? 'This place'),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // In the body rather than the bar. A name in a bar is cut to an
        // ellipsis and gone the moment somebody scrolls, and this is the
        // name of the thing they are reading about.
        Text(
          place.name ?? '',
          style: LizmoType.screenTitle
              .copyWith(fontSize: 22, color: LizmoColors.ink),
        ),
        const SizedBox(height: 4),
        Text(place.address ?? '', style: LizmoType.rowSub),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Kind(label: _kind(place)),
            if (whoCanRentLabel(place.details?.whoCanRent?.toJson()) case final who?)
              WhoCanRentBadge(label: who),
          ],
        ),
        if ((place.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          _Description(text: place.description!),
        ],

        const SizedBox(height: 20),
        Text(
          // The headline a tenant came for. No vacancy is a real answer and
          // says so plainly rather than showing an empty list.
          free == 0
              ? 'No vacant at the moment'
              : '$free ${free == 1 ? 'space' : 'spaces'} vacant',
          style: LizmoType.sectionHeading,
        ),
        const SizedBox(height: 12),

        for (final floor in floors) _Floor(floor: floor),

        const SizedBox(height: 6),
        // The explanation stays with the content; the bar below holds the
        // price and the button and nothing else.
        Text(
          free == 0
              ? 'Nothing is vacant now. You can still ask — a landlord '
                  'usually knows what is coming free.'
              : 'The landlord picks which room, and you settle the rest '
                  'between you.',
          style: LizmoType.rowSub,
        ),

        if (place.details case final details?)
          BeforeYouAsk(details: details, cheapestRent: _cheapest(floors)),

        if (place.landlord case final landlord?)
          LandlordCardView(landlord: landlord),
            ],
          ),
        ),
      ],
    );
  }

  /// The lowest rent on offer anywhere in the place, or null when none is set.
  static num? _cheapest(List<VacancyFloor> floors) {
    num? lowest;
    for (final floor in floors) {
      final rent = floor.cheapestRent;
      if (rent != null && (lowest == null || rent < lowest)) lowest = rent;
    }
    return lowest;
  }

  static String _kind(PropertyByCodeResponse place) {
    final type = (place.type?.toString() ?? '')
        .toLowerCase()
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    final usage =
        place.usage == PropertyByCodeResponseUsageEnum.COMMERCIAL
            ? 'Commercial'
            : 'Residential';
    return type.isEmpty ? usage : '$usage · $type';
  }
}

/// What the landlord wrote about the place, three lines at a time.
///
/// Uncapped, a landlord who writes a page pushes the vacancies -- the thing
/// somebody scanned the code to find -- off the bottom of the screen. "More"
/// appears only when there is more; a short description has no button
/// promising text that is not there.
class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  static const _lines = 3;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = LizmoType.rowSub;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              key: const ValueKey('property-description'),
              style: style,
              maxLines: _open ? null : _lines,
              overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (long)
              TextButton(
                key: const ValueKey('description-more'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => setState(() => _open = !_open),
                child: Text(
                  _open ? 'Less' : 'More',
                  style: style.copyWith(
                    color: LizmoColors.teal900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The page's shape while it loads.
///
/// It used to be a 24px spinner alone on an empty canvas, which on a slow
/// signal at somebody's gate reads as the app having frozen. Laid out as a
/// place with no photograph -- which is most places -- so nothing jumps when
/// the real page arrives. Still rather than shimmering: it is on screen for
/// a second, and a shimmer is one more thing moving.
class _Arriving extends StatelessWidget {
  const _Arriving({required this.under});

  final double under;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8E6),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return ListView(
      key: const ValueKey('property-loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, under + 8, 16, 28),
      children: [
        Align(alignment: Alignment.centerLeft, child: bar(220, 24)),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: bar(160, 14)),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: bar(150, 24)),
        const SizedBox(height: 28),
        Align(alignment: Alignment.centerLeft, child: bar(130, 18)),
        const SizedBox(height: 14),
        for (var i = 0; i < 2; i++) ...[
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: LizmoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3E8E6)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// What kind of place this is, as a chip rather than a line of its own.
///
/// "Residential · Boarding House" is taxonomy, not news. Somebody scanning a
/// code does want to know whether this is a boarding house or a block of
/// flats, so it stays — quieter, and under the name rather than competing
/// with the address for the same line of attention.
class _Kind extends StatelessWidget {
  const _Kind({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('property-kind'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: LizmoColors.tealBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: LizmoType.rowSub
              .copyWith(fontSize: 12, color: LizmoColors.teal900),
        ),
      ),
    );
  }
}

/// How much is free on one floor, and what it costs.
///
/// Counts rather than rooms: a stranger with the code used to be handed every
/// unit number, every bed label and each one's price, which is more than
/// anybody needs to decide whether to ask. Which room they get is settled with
/// the landlord.
/// What the place looks like, swipeable.
///
/// All of them rather than a cover: somebody deciding whether to spend an
/// afternoon travelling to a place wants the kitchen and the stairs as well
/// as the front of the building.
class _Photos extends StatefulWidget {
  const _Photos({required this.urls, required this.name});

  final List<String> urls;

  /// Named on the enlarged photograph, which otherwise arrives as a picture
  /// of a building with nothing saying which building.
  final String name;

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  final _pages = PageController();
  int _showing = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          key: const ValueKey('property-photos'),
          height: 260,
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.urls.length,
            onPageChanged: (page) => setState(() => _showing = page),
            itemBuilder: (context, index) => GestureDetector(
              // A 260px strip shows that a room exists. It does not show the
              // damp in the corner or how small the window really is, which
              // is what somebody travelling across town wants to know.
              onTap: () => FullScreenImage.show(
                context,
                widget.urls[index],
                widget.name,
                unavailable: 'That photograph could not be loaded. Close this '
                    'and scan the code again.',
              ),
              child: Container(
                color: LizmoColors.tealTint,
                child: Image.network(
                  widget.urls[index],
                  fit: BoxFit.cover,
                  // A URL that has expired, or a phone on a bad signal. The
                  // screen carries on: the counts and the price are what the
                  // tenant came for, and a broken image icon over half the
                  // screen reads as a broken app.
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: LizmoColors.slate),
                  ),
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      LizmoColors.teal900),
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ),
        ),
        // A count, not dots. Eight dots at seven pixels is a smudge nobody
        // can count, and the number says plainly that there is more here to
        // swipe through — which the dots never really did.
        if (widget.urls.length > 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              key: const ValueKey('photo-count'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_showing + 1}/${widget.urls.length}',
                style: LizmoType.rowSub
                    .copyWith(fontSize: 12, color: LizmoColors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _Floor extends StatelessWidget {
  const _Floor({required this.floor});

  final VacancyFloor floor;

  @override
  Widget build(BuildContext context) {
    final beds = floor.beds ?? 0;
    final units = floor.wholeUnits ?? 0;

    return Container(
      key: ValueKey('floor-${floor.floor ?? 'ground'}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_floorLabel(floor.floor), style: LizmoType.rowName),
                const SizedBox(height: 2),
                Text(_whatIsFree(units, beds), style: LizmoType.rowSub),
                // When somebody could move in: the question after "how much".
                Text(
                  _ready(units + beds),
                  key: ValueKey('ready-${floor.floor ?? 'ground'}'),
                  style: LizmoType.rowSub.copyWith(
                    fontSize: 12,
                    color: (floor.readyLater ?? 0) > 0
                        ? LizmoColors.amberText
                        : LizmoColors.teal900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(_price(), style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
        ],
      ),
    );
  }

  /// "2nd floor", "Ground", "Ground level".
  ///
  /// The landlord writes this field themselves, so it arrives as "2" as often
  /// as "Ground" or "Mezzanine". A number becomes an ordinary English floor;
  /// anything else is shown as they wrote it, because "Roof deck floor" is not
  /// a thing anybody says.
  ///
  /// Null means they never said, which is normal in a single-storey house —
  /// not a floor called nothing.
  static String _floorLabel(String? floor) {
    final text = (floor ?? '').trim();
    if (text.isEmpty) return 'Ground level';

    final number = int.tryParse(text);
    return number == null ? text : '${_ordinal(number)} floor';
  }

  /// 1st, 2nd, 3rd, 4th — and 11th, 12th, 13th, which break the pattern.
  static String _ordinal(int number) {
    final tens = number % 100;
    if (tens >= 11 && tens <= 13) return '${number}th';
    return switch (number % 10) {
      1 => '${number}st',
      2 => '${number}nd',
      3 => '${number}rd',
      _ => '${number}th',
    };
  }

  /// "Ready now", "Ready from 1 Nov", or "2 ready now, 1 from 1 Nov".
  String _ready(int vacant) {
    final later = floor.readyLater ?? 0;
    final from = floor.readyFrom;
    if (later == 0 || from == null) return 'Ready now';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = '${from.day} ${months[from.month - 1]}';
    if (later >= vacant) return 'Ready from $day';
    return '${vacant - later} ready now, $later from $day';
  }

  static String _whatIsFree(int units, int beds) {
    final parts = [
      if (units > 0) '$units ${units == 1 ? 'unit' : 'units'}',
      if (beds > 0) '$beds ${beds == 1 ? 'bedspace' : 'bedspaces'}',
    ];
    return parts.isEmpty ? 'No vacant' : '${parts.join(' and ')} vacant';
  }

  /// One price when every free room here asks the same, a range when they do
  /// not. Utilities are flagged rather than added: they are charged per unit,
  /// and adding them to a bed's rent would overstate it.
  String _price() {
    final cheapest = floor.cheapestRent;
    final dearest = floor.dearestRent;
    // "Price not set" was the landlord's unfinished paperwork, shown to a
    // stranger. This says the same thing as something they can do.
    if (cheapest == null) return 'Ask the landlord';

    final money = cheapest == dearest
        ? LizmoMoney.peso(cheapest)
        : '${LizmoMoney.peso(cheapest)}–${LizmoMoney.peso(dearest)}';
    return (floor.utilitiesOnTop ?? false)
        ? '$money + utilities'
        : money;
  }
}

/// The price, and the one thing to do on this screen.
///
/// Pinned to the bottom. It used to be the last item in a scrolling list,
/// which on a house with six floors put the only action below the fold — and
/// the price, the second thing anybody wants, was 13px at the right-hand edge
/// of a card.
///
/// No room is named. The landlord chooses when they accept, which is how it
/// gets settled on the phone anyway.
class _AskBar extends ConsumerStatefulWidget {
  const _AskBar({required this.place});

  final PropertyByCodeResponse place;

  @override
  ConsumerState<_AskBar> createState() => _AskBarState();
}

class _AskBarState extends ConsumerState<_AskBar> {
  bool _asking = false;

  String get _propertyId => widget.place.id!;

  Future<void> _ask({bool retrying = false}) async {
    setState(() => _asking = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final thread = await ref.read(inquiriesApiProvider).startInquiry(
            StartInquiry(propertyId: _propertyId),
          );
      ref.invalidate(myInquiriesProvider);
      if (!mounted) return;

      // Straight into the conversation rather than a message saying one has
      // started: the next thing to do is say what they want, and a tenant
      // left on the vacancy screen has nowhere to say it.
      final id = thread?.inquiry?.id;
      if (id != null) {
        await context.push(Routes.inquiry(id));
      }
    } catch (error) {
      final failure = ApiFailure.from(error);
      if (!mounted) return;

      if (failure.code == 'TENANT_PROFILE_INCOMPLETE' && !retrying) {
        // A number is the whole of what asking takes, so it is asked here,
        // on the place they are looking at, and the request goes again with
        // no second tap. Retrying only once: a second refusal is a real
        // problem and should be read, not looped over.
        await _askForANumberThenTryAgain();
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  Future<void> _askForANumberThenTryAgain() async {
    final profile = await ref.read(myTenantProfileProvider.future);
    if (!mounted) return;

    final saved = await AskForNumberSheet.show(context, profile);
    if (saved && mounted) await _ask(retrying: true);
  }

  /// The thread this tenant already has about this place, if there is one.
  ///
  /// Read from the server rather than remembered in this widget. It used to
  /// be local state, so somebody who asked, left and scanned the gate again
  /// was offered "Ask about this place" as though they never had.
  ///
  /// A closed one is left out on purpose: asking again is what reopens it,
  /// and that is the button they want.
  InquirySummary? get _existing {
    final threads = ref.watch(myInquiriesProvider).valueOrNull ?? const [];
    for (final thread in threads) {
      if (thread.propertyId == _propertyId &&
          thread.status != InquirySummaryStatusEnum.CLOSED) {
        return thread;
      }
    }
    return null;
  }

  /// The cheapest thing actually going, which is what "from" means.
  ///
  /// Floors with nothing vacant are left out: quoting a price for a room
  /// nobody can have is the kind of number people travel across town for.
  static num? _from(PropertyByCodeResponse place) {
    final asking = place.floors
        .where((floor) => (floor.wholeUnits ?? 0) + (floor.beds ?? 0) > 0)
        .map((floor) => floor.cheapestRent)
        .whereType<num>();
    return asking.isEmpty ? null : asking.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final free = (widget.place.vacantWholeUnits ?? 0) +
        (widget.place.vacantBeds ?? 0);
    final from = _from(widget.place);
    final existing = _existing;

    return Container(
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (from != null) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From',
                        style: LizmoType.rowSub.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      LizmoMoney.peso(from),
                      key: const ValueKey('from-price'),
                      style: LizmoType.dataMedium
                          .copyWith(color: LizmoColors.ink),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: existing != null
                    ? PrimaryActionButton(
                        key: const ValueKey('open-conversation'),
                        label: 'Open your conversation',
                        onPressed: () =>
                            context.push(Routes.inquiry(existing.id!)),
                      )
                    : PrimaryActionButton(
                        key: const ValueKey('ask-about-place'),
                        // Full is not a dead end. A landlord usually knows
                        // what is coming free, and being asked is how they
                        // find out somebody wants it.
                        label: _asking
                            ? 'Asking…'
                            : free == 0
                                ? 'Ask anyway'
                                : 'Ask about this place',
                        onPressed: _asking ? null : _ask,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    return LizmoMessageState(
      tone: LizmoMessageTone.problem,
      icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.search_off,
      title: failure.isNetwork ? "Can't reach Lizmo" : 'No place with that code',
      detail: failure.isNetwork
          ? failure.message
          : 'Check the code and try again. Letters and numbers only — no O or '
                'I, those are zero and one.',
      actionLabel: 'Try another code',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}
