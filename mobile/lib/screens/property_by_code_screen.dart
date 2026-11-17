import 'dart:math' as math;

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

/// What a stranger sees after entering the code.
///
/// In the order they decide in: what it looks like, what it is and who may
/// rent it, the three facts that settle whether it is worth asking -- the
/// price, how much is free, how soon -- then where the space is, then the
/// money and the rules, then who the landlord is. The Ask bar sits outside
/// the scroll, with what moving in costs beside the button.
class PropertyByCodeScreen extends ConsumerWidget {
  const PropertyByCodeScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyByCodeProvider(code));
    final loaded = property is AsyncData<PropertyByCodeResponse>;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      // The page draws its own bar once it has a place: over the photograph,
      // and white once that has scrolled away.
      appBar: loaded
          ? null
          : AppBar(
              backgroundColor: LizmoColors.canvas,
              foregroundColor: LizmoColors.ink,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
      // Pinned rather than the last item in the list. On a house with six
      // floors the one thing a tenant came here to do was below the fold.
      bottomNavigationBar: switch (property) {
        AsyncData(:final value) => _AskBar(place: value),
        _ => null,
      },
      body: switch (property) {
        AsyncData(:final value) => _Place(place: value),
        AsyncError(:final error) => _NotFound(failure: ApiFailure.from(error)),
        _ => const _Arriving(under: 0),
      },
    );
  }
}

/// The cheapest thing actually going, which is what "from" means.
///
/// Floors with nothing vacant are left out: quoting a price for a room nobody
/// can have is the kind of number people travel across town for.
num? lowestVacantRent(PropertyByCodeResponse place) {
  final asking = place.floors
      .where((floor) => (floor.wholeUnits ?? 0) + (floor.beds ?? 0) > 0)
      .map((floor) => floor.cheapestRent)
      .whereType<num>();
  return asking.isEmpty ? null : asking.reduce((a, b) => a < b ? a : b);
}

/// The soonest anybody could move in: null for now, a date when everything
/// vacant is still being readied, and nothing at all when nothing is vacant.
({bool now, DateTime? from})? earliestMoveIn(PropertyByCodeResponse place) {
  DateTime? soonest;
  var any = false;
  for (final floor in place.floors) {
    final vacant = (floor.wholeUnits ?? 0) + (floor.beds ?? 0);
    if (vacant == 0) continue;
    any = true;
    final later = floor.readyLater ?? 0;
    if (later < vacant || floor.readyFrom == null) {
      return (now: true, from: null);
    }
    final from = floor.readyFrom!;
    if (soonest == null || from.isBefore(soonest)) soonest = from;
  }
  return any ? (now: false, from: soonest) : null;
}

const _shortMonths = [
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

String _day(DateTime day) => '${day.day} ${_shortMonths[day.month - 1]}';

class _Place extends StatefulWidget {
  const _Place({required this.place});

  final PropertyByCodeResponse place;

  @override
  State<_Place> createState() => _PlaceState();
}

class _PlaceState extends State<_Place> {
  final _scroll = ScrollController();
  bool _collapsed = false;

  PropertyByCodeResponse get place => widget.place;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_track);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _hero {
    // Shorter at large text, where every pixel above the facts is one less
    // line of them; taller on a tablet, where there is room for the room.
    if (MediaQuery.textScalerOf(context).scale(10) > 12) return 150;
    return context.pageSize == LizmoWidth.compact ? 230 : 320;
  }

  void _track() {
    final at = place.photos.isEmpty ? 56.0 : _hero - kToolbarHeight - 8;
    final collapsed = _scroll.offset > at;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final photos = place.photos.isNotEmpty;
    final who = whoCanRentLabel(place.details?.whoCanRent?.toJson());
    final side = math.max(16.0, (context.pageWidth - 720) / 2);
    final vacantFloors = [
      for (final floor in place.floors)
        if ((floor.wholeUnits ?? 0) + (floor.beds ?? 0) > 0) floor,
    ];
    final free = (place.vacantWholeUnits ?? 0) + (place.vacantBeds ?? 0);
    final lowest = lowestVacantRent(place);
    final perBed = (place.vacantBeds ?? 0) > 0;
    // The bar's own back and title only once the photograph has gone, or
    // straight away with none.
    final barShown = _collapsed || !photos;

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: photos ? _hero : null,
          backgroundColor: LizmoColors.white,
          surfaceTintColor: Colors.transparent,
          foregroundColor: LizmoColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          shape: barShown
              ? const Border(bottom: BorderSide(color: Color(0xFFE3E8E6)))
              : null,
          leading: barShown
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : const _CloseOverPhoto(),
          titleSpacing: 0,
          // Only once the name in the body has scrolled away: before that
          // it would say the same thing twice.
          title: !_collapsed
              ? null
              : Row(
                  children: [
                    Flexible(
                      child: Text(
                        place.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LizmoType.rowName.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (who != null) ...[
                      const SizedBox(width: 8),
                      WhoCanRentBadge(
                        key: const ValueKey('bar-who-can-rent'),
                        label: who,
                      ),
                    ],
                  ],
                ),
          flexibleSpace: photos
              ? FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _Photos(
                    urls: place.photos,
                    name: place.name ?? 'This place',
                  ),
                )
              : null,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, 16, side, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if ((place.code ?? '').isNotEmpty)
                Text(
                  'CODE ${place.code}',
                  style: LizmoType.dataMedium.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: LizmoColors.slateText,
                  ),
                ),
              const SizedBox(height: 4),
              // Wraps rather than ellipsis: this is the name of the thing
              // they are reading about.
              Text(
                place.name ?? '',
                style: LizmoType.screenTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: LizmoColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(place.address ?? '', style: LizmoType.rowSub),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ?(who == null ? null : WhoCanRentBadge(label: who)),
                  _Kind(label: _kind(place)),
                ],
              ),
              if ((place.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _Description(text: place.description!),
              ],
              const SizedBox(height: 16),
              _KeyFacts(
                lowest: lowest,
                perBed: perBed,
                free: free,
                unitsOnly: (place.vacantBeds ?? 0) == 0,
                movesIn: earliestMoveIn(place),
              ),
              const SizedBox(height: 12),
              if (vacantFloors.isEmpty)
                Text(
                  'Nothing is vacant now. You can still ask — a landlord '
                  'usually knows what is coming free.',
                  key: const ValueKey('nothing-vacant'),
                  style: LizmoType.rowSub,
                )
              else ...[
                _Vacant(floors: vacantFloors),
                const SizedBox(height: 8),
                // Counts, not rooms: which one they get is settled with the
                // landlord.
                Text(
                  'The landlord picks which room, and you settle the rest '
                  'between you.',
                  style: LizmoType.rowSub,
                ),
              ],
              if (place.details case final details?)
                BeforeYouAsk(
                  details: details,
                  cheapestRent: lowest,
                  perBed: perBed,
                  utilitiesOnTop: vacantFloors.any(
                    (floor) => floor.utilitiesOnTop ?? false,
                  ),
                ),
              if (place.landlord case final landlord?)
                LandlordCardView(landlord: landlord),
            ]),
          ),
        ),
      ],
    );
  }

  static String _kind(PropertyByCodeResponse place) {
    final type = (place.type?.toString() ?? '')
        .toLowerCase()
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    final usage = place.usage == PropertyByCodeResponseUsageEnum.COMMERCIAL
        ? 'Commercial'
        : 'Residential';
    return type.isEmpty ? usage : '$usage · $type';
  }
}

/// Back, over a photograph that might be white sky or a dark stairwell: a
/// white circle that does not depend on what is underneath it.
class _CloseOverPhoto extends StatelessWidget {
  const _CloseOverPhoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: LizmoColors.white,
          shape: const CircleBorder(),
          elevation: 1,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: LizmoColors.ink),
            tooltip: 'Back',
          ),
        ),
      ),
    );
  }
}

/// The three facts that settle whether it is worth asking.
class _KeyFacts extends StatelessWidget {
  const _KeyFacts({
    required this.lowest,
    required this.perBed,
    required this.free,
    required this.unitsOnly,
    required this.movesIn,
  });

  final num? lowest;
  final bool perBed;
  final int free;
  final bool unitsOnly;
  final ({bool now, DateTime? from})? movesIn;

  @override
  Widget build(BuildContext context) {
    final moves = movesIn;
    final when = moves == null
        ? '—'
        : moves.now
        ? 'Now'
        : moves.from == null
        ? 'Soon'
        : _day(moves.from!);

    Widget fact(String value, String label, {Color? ink, Key? key}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                key: key,
                maxLines: 1,
                style: LizmoType.dataMedium.copyWith(
                  fontSize: 17,
                  color: ink ?? LizmoColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: LizmoType.rowSub),
          ],
        ),
      ),
    );
    const rule = SizedBox(
      width: 1,
      child: ColoredBox(color: Color(0xFFE3E8E6)),
    );

    return Container(
      key: const ValueKey('key-facts'),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fact(
              lowest == null ? 'Ask' : LizmoMoney.peso(lowest!),
              perBed ? 'a bed, monthly' : 'a unit, monthly',
              key: const ValueKey('fact-price'),
            ),
            rule,
            fact(
              '$free',
              unitsOnly
                  ? (free == 1 ? 'unit vacant' : 'units vacant')
                  : (free == 1 ? 'space vacant' : 'spaces vacant'),
              key: const ValueKey('fact-vacant'),
            ),
            rule,
            fact(
              when,
              'earliest move-in',
              ink: moves?.now == true ? LizmoColors.teal900 : null,
              key: const ValueKey('fact-move-in'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the space is, floor by floor, as counts.
///
/// Counts rather than rooms: a stranger with the code used to be handed every
/// unit number, every bed label and each one's price, which is more than
/// anybody needs to decide whether to ask. Floors with nothing are left out.
class _Vacant extends StatelessWidget {
  const _Vacant({required this.floors});

  final List<VacancyFloor> floors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('whats-vacant'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What's vacant",
            style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
          ),
          const SizedBox(height: 4),
          for (final (i, floor) in floors.indexed) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEFF2F1)),
            _Floor(floor: floor),
          ],
        ],
      ),
    );
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
          style: LizmoType.rowSub.copyWith(
            fontSize: 12,
            color: LizmoColors.teal900,
          ),
        ),
      ),
    );
  }
}

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
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const ValueKey('property-photos'),
          controller: _pages,
          itemCount: widget.urls.length,
          onPageChanged: (page) => setState(() => _showing = page),
          itemBuilder: (context, index) => GestureDetector(
            // A strip shows that a room exists. It does not show the damp in
            // the corner or how small the window really is, which is what
            // somebody travelling across town wants to know.
            onTap: () => FullScreenImage.show(
              context,
              widget.urls[index],
              widget.name,
              unavailable:
                  'That photograph could not be loaded. Close this '
                  'and scan the code again.',
            ),
            child: Container(
              color: LizmoColors.tealTint,
              child: Image.network(
                widget.urls[index],
                fit: BoxFit.cover,
                // A URL that has expired, or a phone on a bad signal. The
                // screen carries on: the counts and the price are what the
                // tenant came for.
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: LizmoColors.slate,
                  ),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              LizmoColors.teal900,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        // A count, not dots: eight dots at seven pixels is a smudge nobody
        // can count.
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
                '${_showing + 1} / ${widget.urls.length}',
                style: LizmoType.dataMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: LizmoColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One floor of what is vacant: how much, how soon, and for how much.
class _Floor extends StatelessWidget {
  const _Floor({required this.floor});

  final VacancyFloor floor;

  @override
  Widget build(BuildContext context) {
    final beds = floor.beds ?? 0;
    final units = floor.wholeUnits ?? 0;
    final later = (floor.readyLater ?? 0) > 0 && floor.readyFrom != null;
    final allLater = later && (floor.readyLater ?? 0) >= units + beds;

    return Padding(
      key: ValueKey('floor-${floor.floor ?? 'ground'}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _floorLabel(floor.floor).toUpperCase(),
            style: LizmoType.dataMedium.copyWith(
              fontSize: 11,
              letterSpacing: 0.8,
              color: LizmoColors.slateText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(_whatIsFree(units, beds), style: LizmoType.rowName),
                    // When somebody could move in: the question after "how
                    // much".
                    Container(
                      key: ValueKey('ready-${floor.floor ?? 'ground'}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: allLater
                            ? const Color(0xFFEEF2F0)
                            : LizmoColors.tealBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!allLater) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: LizmoColors.teal900,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            _ready(units + beds),
                            style: LizmoType.rowSub.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: allLater
                                  ? const Color(0xFF3E4D49)
                                  : LizmoColors.teal900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _price(),
                style: LizmoType.dataMedium.copyWith(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "2nd floor", "Ground level", or what the landlord wrote.
  ///
  /// The landlord writes this field themselves, so it arrives as "2" as often
  /// as "Ground" or "Mezzanine". A number becomes an ordinary English floor;
  /// anything else is shown as they wrote it. Null means they never said,
  /// which is normal in a single-storey house.
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

  /// "Ready now", "From 1 Nov", or "2 now, 1 from 1 Nov".
  String _ready(int vacant) {
    final later = floor.readyLater ?? 0;
    final from = floor.readyFrom;
    if (later == 0 || from == null) return 'Ready now';
    final day = _day(from);
    if (later >= vacant) return 'From $day';
    return '${vacant - later} now, $later from $day';
  }

  static String _whatIsFree(int units, int beds) {
    final parts = [
      if (units > 0) '$units ${units == 1 ? 'unit' : 'units'}',
      if (beds > 0) '$beds ${beds == 1 ? 'bedspace' : 'bedspaces'}',
    ];
    return parts.isEmpty ? 'No vacant' : parts.join(' and ');
  }

  /// One price when every free room here asks the same, a range when they do
  /// not. Utilities are flagged rather than added: they are charged per unit,
  /// and adding them to a bed's rent would overstate it.
  String _price() {
    final cheapest = floor.cheapestRent;
    final dearest = floor.dearestRent;
    if (cheapest == null) return 'Ask';

    final money = cheapest == dearest || dearest == null
        ? LizmoMoney.peso(cheapest)
        : '${LizmoMoney.peso(cheapest)}–${LizmoMoney.peso(dearest)}';
    return (floor.utilitiesOnTop ?? false) ? '$money + utilities' : money;
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
      final thread = await ref
          .read(inquiriesApiProvider)
          .startInquiry(StartInquiry(propertyId: _propertyId));
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

  @override
  Widget build(BuildContext context) {
    final free =
        (widget.place.vacantWholeUnits ?? 0) + (widget.place.vacantBeds ?? 0);
    final from = lowestVacantRent(widget.place);
    final cost = moveInCost(widget.place.details, from);
    final existing = _existing;
    // Stacked at large text: side by side, the price wraps to a column of
    // single words and the button's label is cut.
    final large = MediaQuery.textScalerOf(context).scale(10) > 12;

    final price = from == null
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'From ',
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.ink),
                  ),
                  Text(
                    LizmoMoney.peso(from),
                    key: const ValueKey('from-price'),
                    style: LizmoType.dataMedium.copyWith(
                      color: LizmoColors.ink,
                    ),
                  ),
                ],
              ),
              if (cost != null)
                Wrap(
                  key: const ValueKey('ask-move-in'),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      LizmoMoney.peso(cost.total),
                      style: LizmoType.dataMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(' to move in', style: LizmoType.rowSub),
                  ],
                ),
            ],
          );

    final button = SizedBox(
      height: large ? 60 : 52,
      child: existing != null
          ? _CoralButton(
              key: const ValueKey('open-conversation'),
              label: 'Open your conversation',
              onPressed: () => context.push(Routes.inquiry(existing.id!)),
            )
          : _CoralButton(
              key: const ValueKey('ask-about-place'),
              // Full is not a dead end. A landlord usually knows what is
              // coming free, and being asked is how they find out somebody
              // wants it.
              label: _asking
                  ? 'Asking…'
                  : free == 0
                  ? 'Ask anyway'
                  : 'Ask about this place',
              onPressed: _asking ? null : _ask,
            ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8E6))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            math.max(16.0, (context.pageWidth - 720) / 2),
            12,
            math.max(16.0, (context.pageWidth - 720) / 2),
            16,
          ),
          child: large
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (price != null) ...[price, const SizedBox(height: 10)],
                    button,
                  ],
                )
              : Row(
                  children: [
                    if (price != null) ...[price, const SizedBox(width: 16)],
                    Expanded(child: button),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The only coral on the page.
class _CoralButton extends StatelessWidget {
  const _CoralButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: LizmoColors.coral,
        foregroundColor: LizmoColors.onCoral,
        disabledBackgroundColor: LizmoColors.coral.withValues(alpha: 0.5),
        disabledForegroundColor: LizmoColors.onCoral.withValues(alpha: 0.6),
        textStyle: LizmoType.buttonLabel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, textAlign: TextAlign.center),
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
      title: failure.isNetwork
          ? "Can't reach Lizmo"
          : 'No place with that code',
      detail: failure.isNetwork
          ? failure.message
          : 'Check the code and try again. Letters and numbers only — no O or '
                'I, those are zero and one.',
      actionLabel: 'Try another code',
      onAction: () => Navigator.of(context).pop(),
    );
  }
}
