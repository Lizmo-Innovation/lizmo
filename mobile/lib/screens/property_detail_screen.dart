import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../inquiry/inquiry_providers.dart';
import '../notice/notice_providers.dart';
import '../property/place_details.dart';
import '../property/property_providers.dart';
import '../router.dart';
import '../widgets/property_photos_card.dart';

/// One property and the units inside it.
///
/// This is where the bedspace/whole-unit distinction becomes visible: a
/// bedspace shows how many of its beds exist and what each is worth, a whole
/// unit shows one rent and nothing else.
class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  /// The floor being shown, or null for all of them.
  ///
  /// [_noFloor] stands for the units that have no floor recorded — they need a
  /// bucket of their own, or filtering would quietly hide them.
  String? _floor;

  static const _noFloor = '\u0000none';

  final _scroll = ScrollController();

  /// Scrolled past the hero: the bar above says whose property this is.
  bool _collapsed = false;

  /// Roughly where the hero's title goes under the bar.
  static const _collapseAt = 96.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed = _scroll.offset > _collapseAt;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(propertyOverviewProvider(widget.propertyId));
    ref.invalidate(unitsProvider(widget.propertyId));
    await ref.read(unitsProvider(widget.propertyId).future);
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.propertyId;
    final units = ref.watch(unitsProvider(propertyId));
    final overview = ref
        .watch(propertyOverviewProvider(propertyId))
        .valueOrNull;

    final all = units.valueOrNull;
    final floors = _floorsIn(all);

    // A filter over one floor is furniture, not a control.
    final showFilter = floors.length > 1;
    final selected = showFilter && floors.contains(_floor) ? _floor : null;

    final shown = selected == null
        ? all
        : all?.where((u) => _floorKey(u) == selected).toList();

    // Taken from the list rather than fetched by id: this screen is reached
    // from the list, so it is normally loaded. On a deep link it may not be,
    // which is why the name falls back below.
    final matches =
        ref
            .watch(propertiesProvider)
            .valueOrNull
            ?.where((p) => p.id == propertyId) ??
        const <PropertyResponse>[];
    final property = matches.isEmpty ? null : matches.first;
    final name = property?.name ?? 'Property';

    final occupancy = overview == null
        ? null
        : '${overview.occupied ?? 0}/${overview.rentable ?? 0}';

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      // Its own name, always: besides looking, the one thing this screen is
      // for, and the main action says what it does.
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-unit'),
        heroTag: null,
        backgroundColor: LizmoColors.coral,
        foregroundColor: LizmoColors.onCoral,
        elevation: 2,
        onPressed: () => context.push(Routes.unitNew(propertyId)),
        label: Text('+ Add a unit', style: LizmoType.buttonLabel),
      ),
      body: RefreshIndicator(
        color: LizmoColors.teal900,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: LizmoColors.teal900,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 56,
              flexibleSpace: const CustomPaint(
                painter: LatticePainter(),
                child: SizedBox.expand(),
              ),
              titleSpacing: 0,
              leading: const _BackButton(),
              // Hidden until the hero scrolls away, and not read aloud while
              // hidden: the hero below says the same.
              title: ExcludeSemantics(
                excluding: !_collapsed,
                child: AnimatedOpacity(
                  opacity: _collapsed ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LizmoType.screenTitle.copyWith(fontSize: 17),
                        ),
                      ),
                      if (occupancy != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          occupancy,
                          style: LizmoType.dataMedium.copyWith(
                            color: LizmoColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                _ShareButton(propertyId: propertyId),
                _EditButton(propertyId: propertyId),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: LatticeHeader(
                  eyebrow: property?.code == null
                      ? 'Property'
                      : 'Property · ${property!.code}',
                  title: name,
                  subtitle: property?.address,
                  stats: [
                    LatticeHeaderStat(
                      value: occupancy ?? '—',
                      label: 'Occupied',
                    ),
                    LatticeHeaderStat(
                      value: overview == null ? '—' : '${overview.vacant ?? 0}',
                      label: 'Vacant',
                    ),
                    LatticeHeaderStat(
                      value: overview == null
                          ? '—'
                          : LizmoMoney.peso(overview.overdueTotal ?? 0),
                      label: 'Overdue',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _WaitingRequests(propertyId: propertyId)),
            SliverToBoxAdapter(child: _BuildingTiles(propertyId: propertyId)),
            // Above the rooms: what the place looks like is what a stranger
            // decides on, and the unit list is for the landlord's own work.
            SliverToBoxAdapter(
              child: PropertyPhotosCard(propertyId: propertyId, compact: true),
            ),
            if ((property?.description ?? '').isNotEmpty)
              SliverToBoxAdapter(
                child: _Description(text: property!.description!),
              ),
            SliverToBoxAdapter(child: _UnitsHeading(units: all)),
            if (showFilter)
              SliverPersistentHeader(
                pinned: true,
                delegate: _FloorChips(
                  floors: floors,
                  selected: selected,
                  noFloor: _noFloor,
                  onChanged: (next) => setState(() => _floor = next),
                ),
              ),
            ...switch (units) {
              AsyncError(:final error) => [
                SliverToBoxAdapter(
                  child: _Failed(
                    failure: ApiFailure.from(error),
                    onRetry: () => ref.invalidate(unitsProvider(propertyId)),
                  ),
                ),
              ],
              AsyncData(:final value) when value.isEmpty => [
                const SliverToBoxAdapter(child: _Empty()),
              ],
              AsyncData() => _unitSlivers(
                context,
                shown ?? const [],
                overview,
                propertyId,
              ),
              _ => [const SliverToBoxAdapter(child: _Loading())],
            },
            // Clear of the button floating over the bottom of the list.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  /// The units, a labelled group per floor, two across on a tablet.
  List<Widget> _unitSlivers(
    BuildContext context,
    List<UnitResponse> units,
    PropertyOverview? overview,
    String propertyId,
  ) {
    final byFloor = <String, List<UnitResponse>>{};
    for (final unit in units) {
      byFloor.putIfAbsent(_floorKey(unit), () => []).add(unit);
    }
    final order = _floorsIn(units);
    final details = {
      for (final unit in overview?.units ?? const <UnitOverview>[])
        unit.id: unit,
    };
    final columns = context.pageSize == LizmoWidth.compact ? 1 : 2;

    return [
      for (final floor in order) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: context.pageInsets(16, 8),
            child: Text(
              _floorLabel(floor).toUpperCase(),
              key: ValueKey('floor-label-$floor'),
              style: LizmoType.eyebrow.copyWith(color: LizmoColors.slateText),
            ),
          ),
        ),
        SliverPadding(
          padding: context.pageInsets(0, 0),
          sliver: SliverList.builder(
            itemCount: (byFloor[floor]!.length / columns).ceil(),
            itemBuilder: (context, row) {
              final onFloor = byFloor[floor]!;
              final cards = [
                for (
                  var i = row * columns;
                  i < (row + 1) * columns && i < onFloor.length;
                  i++
                )
                  _UnitCard(
                    unit: onFloor[i],
                    detail: details[onFloor[i].id],
                    propertyId: propertyId,
                  ),
              ];
              if (columns == 1) return cards.single;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: cards.length > 1 ? cards[1] : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ];
  }

  /// The floor a unit belongs to for filtering, with a bucket for none.
  static String _floorKey(UnitResponse unit) {
    final floor = (unit.floor ?? '').trim();
    return floor.isEmpty ? _noFloor : floor;
  }

  /// "2nd floor", "Ground", or "No floor" for units nobody gave one.
  static String _floorLabel(String key) {
    if (key == _noFloor) return 'No floor';
    final number = int.tryParse(key);
    if (number == null) return key;
    final tens = number % 100;
    final suffix = tens >= 11 && tens <= 13
        ? 'th'
        : switch (number % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$number$suffix floor';
  }

  /// Distinct floors present, numerically where they look like numbers.
  ///
  /// "10" after "9" rather than before it, which is what plain string sorting
  /// would do — and a boarding house numbers its floors.
  static List<String> _floorsIn(List<UnitResponse>? units) {
    if (units == null) return const [];

    final keys = units.map(_floorKey).toSet().toList();
    keys.sort((a, b) {
      // Unfloored units last: they are the leftovers, not floor zero.
      if (a == _noFloor) return 1;
      if (b == _noFloor) return -1;
      final na = int.tryParse(a);
      final nb = int.tryParse(b);
      if (na != null && nb != null) return na.compareTo(nb);
      if (na != null) return -1;
      if (nb != null) return 1;
      return a.compareTo(b);
    });
    return keys;
  }
}

/// "Units" and how many, over the list.
class _UnitsHeading extends StatelessWidget {
  const _UnitsHeading({required this.units});

  final List<UnitResponse>? units;

  @override
  Widget build(BuildContext context) {
    final list = units;
    final beds =
        list?.fold<int>(
          0,
          (sum, unit) => unit.rentalMode == UnitResponseRentalModeEnum.BEDSPACE
              ? sum + (unit.bedCount ?? 0)
              : sum,
        ) ??
        0;
    return Padding(
      padding: context.pageInsets(20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Units',
              style: LizmoType.sectionHeading.copyWith(fontSize: 17),
            ),
          ),
          if (list != null && list.isNotEmpty)
            Text(
              [
                list.length == 1 ? '1 unit' : '${list.length} units',
                if (beds > 0) beds == 1 ? '1 bed' : '$beds beds',
              ].join(' · '),
              key: const ValueKey('units-count'),
              style: LizmoType.dataMedium.copyWith(
                fontSize: 13,
                color: LizmoColors.slateText,
              ),
            ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back),
      color: LizmoColors.white,
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: 'Back',
    );
  }
}

/// People waiting for an answer about this property.
///
/// Only when somebody is. A row that permanently reads "0 requests" is one a
/// landlord learns to stop seeing, and the whole point of this strip is that it
/// is unusual enough to notice.
class _WaitingRequests extends ConsumerWidget {
  const _WaitingRequests({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This property's share of the landlord's conversations, unanswered
    // first. The list is already loaded for Today, so this costs nothing.
    final threads = ref.watch(myInquiriesProvider).valueOrNull;
    final waiting = threads == null
        ? const <InquirySummary>[]
        : [
            for (final thread in threads)
              if (thread.propertyId == propertyId &&
                  thread.status == InquirySummaryStatusEnum.OPEN)
                thread,
          ];
    if (waiting.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = waiting.length;
    return Padding(
      padding: context.pageInsets(12, 0),
      child: Material(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          // Straight into the oldest unanswered one: a list of two is not
          // worth a screen of its own when the card is already a list.
          onTap: () => context.push(
            Routes.inquiry(
              (waiting.firstWhere(
                (thread) => thread.unread ?? false,
                orElse: () => waiting.first,
              )).id!,
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 20,
                  color: LizmoColors.amberText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count == 1
                        ? 'Somebody is asking about a room'
                        : '$count people are asking about rooms',
                    style: LizmoType.rowName.copyWith(
                      color: LizmoColors.amberText,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: LizmoColors.amberText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two things a landlord does about the building as a whole, side by side so
/// they take one row rather than two: telling everybody something, and
/// saying what anybody asking would want to know.
class _BuildingTiles extends ConsumerWidget {
  const _BuildingTiles({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(propertyNoticesProvider(propertyId)).valueOrNull;
    final up = notices?.where((notice) => notice.live ?? true).length ?? 0;
    final latest = notices?.where((notice) => notice.live ?? true).firstOrNull;
    final details = ref.watch(placeDetailsProvider(propertyId)).valueOrNull;
    final said = details != null && saysAnything(details);

    return Padding(
      padding: context.pageInsets(12, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Tile(
                key: const ValueKey('property-announcements'),
                icon: Icons.campaign_outlined,
                title: up == 0
                    ? 'Announce'
                    : up == 1
                    ? '1 announcement'
                    : '$up announcements',
                detail: latest != null && (latest.audience ?? 0) > 0
                    ? 'Seen by ${latest.seenBy ?? 0} of ${latest.audience}'
                    : 'Tell everybody at once',
                onTap: () =>
                    context.openInTab(Detail.announcements(propertyId)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                key: const ValueKey('property-place-details'),
                icon: Icons.rule_outlined,
                title: 'Place details',
                detail: said ? _summary(details) : 'Rules and deposit',
                // Amber until said: it is what strangers decide on.
                attention: details != null && !said,
                onTap: () => context.openInTab(Detail.placeDetails(propertyId)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Women only · Curfew 10pm · 2 months deposit", the first few said.
  static String _summary(PlaceDetailsDto details) {
    final bits = [
      ?whoCanRentLabel(details.whoCanRent?.toJson()),
      if (details.curfew case final curfew?) 'Curfew ${curfewLabel(curfew)}',
      if (details.depositMonths case final months? when months > 0)
        '${monthsLabel(months)} deposit',
      if (details.amenities.isNotEmpty) '${details.amenities.length} included',
    ];
    return bits.isEmpty ? 'Set' : bits.take(2).join(' · ');
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.attention = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final ink = attention ? LizmoColors.amberText : LizmoColors.teal900;
    return Material(
      color: attention ? LizmoColors.amberBg : LizmoColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: attention
            ? BorderSide.none
            : const BorderSide(color: Color(0xFFE3E8E6)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ink),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LizmoType.rowName.copyWith(
                        color: attention ? ink : LizmoColors.ink,
                      ),
                    ),
                    // One line, like the strip it replaced: the units below
                    // are what this screen is for, and every pixel above
                    // them comes out of their list.
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LizmoType.rowSub.copyWith(
                        fontSize: 11,
                        color: attention ? ink : null,
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

/// Opens the code and QR a landlord puts on the gate.
///
/// In the header rather than down with the units: it is about the property as a
/// whole, and a landlord showing it to somebody wants it in one tap rather than
/// after a scroll.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.openInTab(Detail.share(propertyId)),
      icon: const Icon(Icons.qr_code_2_outlined),
      color: LizmoColors.white,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: 'Share this place',
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(Routes.propertyEdit(propertyId)),
      icon: const Icon(Icons.edit_outlined),
      color: LizmoColors.white,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: 'Edit property',
    );
  }
}

/// One unit: its rent, a square for each bed -- filled when let -- and what
/// is late in it.
///
/// Built from the unit, and filled in from the building's overview once that
/// arrives; until then the beds are told apart only as far as the unit's own
/// status says.
class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.detail,
    required this.propertyId,
  });

  final UnitResponse unit;
  final UnitOverview? detail;
  final String propertyId;

  bool get _isBedspace =>
      unit.rentalMode == UnitResponseRentalModeEnum.BEDSPACE;

  bool get _isClosed => unit.status == UnitResponseStatusEnum.MAINTENANCE;

  @override
  Widget build(BuildContext context) {
    final overdue = detail?.overdueTenancies ?? 0;
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.2;

    return Container(
      key: ValueKey('unit-card-${unit.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: unit.id == null
              ? null
              : () => context.openInTab(Detail.unit(propertyId, unit.id!)),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The price drops under the name when the text is
                      // large, rather than the name being squeezed beside it.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 2,
                        spacing: 10,
                        children: [
                          Text(
                            'Unit ${unit.unitNumber ?? ''}',
                            style: LizmoType.rowName,
                          ),
                          Text(
                            _price(),
                            style: unit.rent == null
                                ? LizmoType.rowSub
                                : LizmoType.dataMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_isClosed)
                        const StatusChip(
                          status: LizmoStatus.pending,
                          label: 'Out of service',
                        )
                      else
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_isBedspace)
                              _Squares(beds: _beds(), size: large ? 13 : 10),
                            Text(
                              _summary(),
                              key: ValueKey('unit-summary-${unit.id}'),
                              style: LizmoType.rowSub,
                            ),
                          ],
                        ),
                      if (overdue > 0) ...[
                        const SizedBox(height: 6),
                        StatusChip(
                          status: LizmoStatus.overdue,
                          label: '$overdue overdue',
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: LizmoColors.slate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "₱2,500 a bed" for a bedspace room, "₱7,000" for a whole unit.
  String _price() {
    final rent = unit.rent;
    if (rent == null) return 'No rent set';
    return _isBedspace
        ? '${LizmoMoney.peso(rent)} a bed'
        : LizmoMoney.peso(rent);
  }

  /// Each bed, let or not: from the overview, or from the unit's status.
  List<bool> _beds() {
    final known = detail?.beds;
    if (known != null && known.isNotEmpty) {
      return [for (final bed in known) bed.let ?? false];
    }
    final count = (unit.bedCount ?? 0) - (unit.bedsUnderMaintenance ?? 0);
    final full = unit.status == UnitResponseStatusEnum.OCCUPIED;
    return List.filled(count < 0 ? 0 : count, full);
  }

  String _summary() {
    final ready = detail?.readyFrom ?? unit.readyFrom;
    final when = ready == null ? 'ready now' : 'from ${_short(ready)}';

    if (!_isBedspace) {
      final name = detail?.tenantName;
      final let =
          name != null || unit.status == UnitResponseStatusEnum.OCCUPIED;
      if (let) {
        return name == null ? 'Whole unit · Let' : 'Whole unit · Let to $name';
      }
      return 'Whole unit · Vacant, $when';
    }

    final known = detail?.beds ?? const <BedState>[];
    if (known.isEmpty) {
      if (unit.status == UnitResponseStatusEnum.PARTIALLY_OCCUPIED) {
        return 'Partly let';
      }
      final beds = _beds().length;
      if (unit.status == UnitResponseStatusEnum.OCCUPIED) {
        return '$beds of $beds let';
      }
      return beds == 1 ? '1 bed, vacant, $when' : '$beds beds, vacant, $when';
    }
    final let = known.where((bed) => bed.let ?? false).length;
    final vacant = known.where((bed) => !(bed.let ?? false)).toList();
    final head = '$let of ${known.length} let';
    if (vacant.isEmpty) return head;
    final which = vacant.length == 1
        ? '${vacant.single.label} vacant'
        : '${vacant.length} vacant';
    return '$head · $which, $when';
  }

  static String _short(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}';
  }
}

/// A square per bed: filled teal when let, outlined when vacant.
class _Squares extends StatelessWidget {
  const _Squares({required this.beds, required this.size});

  final List<bool> beds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final let = beds.where((bed) => bed).length;
    return Semantics(
      label: '$let of ${beds.length} beds let',
      excludeSemantics: true,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (final (i, bed) in beds.indexed)
            Container(
              key: ValueKey(bed ? 'bed-let-$i' : 'bed-vacant-$i'),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bed ? LizmoColors.teal900 : null,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: LizmoColors.teal900, width: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// The page's shape while the units load: three cards of grey.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEEC),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Semantics(
      label: 'Loading units',
      child: Padding(
        padding: context.pageInsets(16, 0),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LizmoColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3E8E6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [bar(80, 14), const Spacer(), bar(60, 14)]),
                    const SizedBox(height: 10),
                    bar(160, 10),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 40),
        LizmoMessageState(
          icon: Icons.meeting_room_outlined,
          title: 'No units yet',
          detail:
              'Add a unit for each space you rent out — a room, a bedspace, '
              'or the whole place.',
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        LizmoMessageState(
          tone: LizmoMessageTone.problem,
          icon: failure.isNetwork
              ? Icons.wifi_off_outlined
              : Icons.error_outline,
          title: failure.isNetwork
              ? "Can't reach Lizmo"
              : 'Something went wrong',
          detail: failure.message,
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ],
    );
  }
}

/// Floors as chips, pinned under the bar while the units scroll beneath.
///
/// Only rendered when there is more than one: a single chip reading "All"
/// beside one floor is a control that cannot do anything. They scroll
/// sideways, fading at the right edge, rather than shrinking their words.
class _FloorChips extends SliverPersistentHeaderDelegate {
  _FloorChips({
    required this.floors,
    required this.selected,
    required this.noFloor,
    required this.onChanged,
  });

  final List<String> floors;
  final String? selected;
  final String noFloor;
  final ValueChanged<String?> onChanged;

  static const _height = 60.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_FloorChips old) =>
      old.selected != selected || old.floors.join() != floors.join();

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: LizmoColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8E6))),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.92, 1.0],
          colors: [Colors.black, Colors.black, Colors.transparent],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: context.pageInsets(10, 10),
          children: [
            _Chip(
              label: 'All',
              selected: selected == null,
              onTap: () => onChanged(null),
            ),
            for (final floor in floors) ...[
              const SizedBox(width: 8),
              _Chip(
                label: _PropertyDetailScreenState._floorLabel(floor),
                selected: selected == floor,
                onTap: () => onChanged(floor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LizmoColors.tealBg : LizmoColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? LizmoColors.teal900 : const Color(0xFFE3E8E6),
            ),
          ),
          child: Text(
            label,
            style: LizmoType.chipLabel.copyWith(
              fontSize: 13,
              color: selected ? LizmoColors.teal900 : LizmoColors.slateText,
            ),
          ),
        ),
      ),
    );
  }
}

/// What the landlord wrote about the property.
///
/// Clamped to three lines with a tap to expand. A landlord may write three
/// hundred words, and this screen exists to show the units — letting the
/// description grow unbounded would push them off the phone.
class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Only offer "more" when there is more: the control is noise on a
    // one-line description.
    final overflows = _overflows(context);

    return Container(
      margin: context.pageInsets(14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bounded even when expanded, and scrollable within that bound.
          // Left unbounded, a three-hundred-word description grew this card
          // past the height of the screen and overflowed the column it sits
          // in — the units below it had nowhere left to go.
          // The whole screen scrolls now, so expanded is simply all of it.
          Text(
            widget.text,
            style: LizmoType.rowSub,
            maxLines: _expanded ? null : _lines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (overflows) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Less' : 'More',
                style: LizmoType.rowName.copyWith(
                  fontSize: 13,
                  color: LizmoColors.teal900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Two lines: enough to know what the landlord wrote, little enough to
  /// leave the units on the screen.
  static const _lines = 2;

  /// Whether the text needs more than [_lines] at this width.
  bool _overflows(BuildContext context) {
    final width = context.pageWidth - 2 * context.pageGutter - 28;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: LizmoType.rowSub),
      maxLines: _lines,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }
}
