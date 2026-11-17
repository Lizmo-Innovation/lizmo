import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/place_details.dart';

/// "Women only": the first thing to know, before photographs or prices, for
/// half the people who scan the code. Filled, because it decides whether the
/// rest of the page is worth reading.
class WhoCanRentBadge extends StatelessWidget {
  const WhoCanRentBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('who-can-rent'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: LizmoColors.teal900,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 14, color: LizmoColors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: LizmoType.rowSub.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LizmoColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// What it costs to move in: the deposit and the advance, and the first
/// month when nothing is paid ahead -- it falls due on move-in day anyway.
///
/// Null when the landlord has not said both, or no rent is known: a total
/// made of guesses is a number somebody travels across town for.
({num deposit, num advance, num firstMonth, num total})? moveInCost(
  PlaceDetailsDto? details,
  num? rent,
) {
  final depositMonths = details?.depositMonths;
  final advanceMonths = details?.advanceMonths;
  if (depositMonths == null ||
      advanceMonths == null ||
      rent == null ||
      rent <= 0) {
    return null;
  }
  final deposit = rent * depositMonths;
  final advance = rent * advanceMonths;
  final firstMonth = advanceMonths < 1 ? rent : 0;
  return (
    deposit: deposit,
    advance: advance,
    firstMonth: firstMonth,
    total: deposit + advance + firstMonth,
  );
}

/// What people ask before anything else, answered before they ask it: the
/// money up front, what comes with the rent, and the house rules.
///
/// Only what the landlord said. A part left unsaid is left out rather than
/// shown as "no", and with nothing said at all there is no section.
class BeforeYouAsk extends StatelessWidget {
  const BeforeYouAsk({
    super.key,
    required this.details,
    required this.cheapestRent,
    this.utilitiesOnTop = false,
    this.perBed = true,
  });

  final PlaceDetailsDto details;

  /// The lowest rent on offer, to put the months up front in pesos.
  final num? cheapestRent;

  /// Whether what is vacant is charged utilities on top of the rent.
  final bool utilitiesOnTop;

  /// "for a ₱2,500 bed", or "for a ₱7,000 unit".
  final bool perBed;

  @override
  Widget build(BuildContext context) {
    final rules = ruleLines(details);
    final other = (details.otherRules ?? '').trim();
    final included = details.amenities;
    final saysMoney =
        details.depositMonths != null || details.advanceMonths != null;

    if (!saysMoney &&
        rules.isEmpty &&
        other.isEmpty &&
        included.isEmpty &&
        !utilitiesOnTop) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('before-you-ask'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'Before you ask',
            style: LizmoType.screenTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: LizmoColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (saysMoney) ...[
          _MoneyUpFront(details: details, rent: cheapestRent, perBed: perBed),
          const SizedBox(height: 10),
        ],
        if (included.isNotEmpty || utilitiesOnTop) ...[
          _Card(
            title: 'In the rent',
            children: [
              if (included.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amenity in included)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: LizmoColors.tealBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: LizmoColors.teal900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              amenityLabel(amenity.toJson()),
                              style: LizmoType.rowSub.copyWith(
                                fontSize: 12,
                                color: LizmoColors.teal900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (utilitiesOnTop) ...[
                if (included.isNotEmpty) const SizedBox(height: 10),
                Text(
                  'Utilities are charged on top of the rent.',
                  key: const ValueKey('utilities-on-top'),
                  style: LizmoType.rowSub,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (rules.isNotEmpty || other.isNotEmpty)
          _Card(
            title: 'House rules',
            children: [
              for (final (_, line) in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: LizmoType.rowName),
                      Expanded(
                        child: Text(
                          line,
                          style: LizmoType.rowName.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (other.isNotEmpty) ...[
                if (rules.isNotEmpty) const SizedBox(height: 4),
                Text(other, style: LizmoType.rowSub),
              ],
            ],
          ),
      ],
    );
  }
}

class _MoneyUpFront extends StatelessWidget {
  const _MoneyUpFront({
    required this.details,
    required this.rent,
    required this.perBed,
  });

  final PlaceDetailsDto details;
  final num? rent;
  final bool perBed;

  @override
  Widget build(BuildContext context) {
    final cost = moveInCost(details, rent);
    final depositMonths = details.depositMonths;
    final advanceMonths = details.advanceMonths;
    Widget line(String label, String? amount, {Key? key, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: bold
                      ? LizmoType.rowName
                      : LizmoType.rowSub.copyWith(
                          fontSize: 13,
                          color: LizmoColors.ink,
                        ),
                ),
              ),
              if (amount != null)
                Text(
                  amount,
                  key: key,
                  style: LizmoType.dataMedium.copyWith(
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
            ],
          ),
        );

    return _Card(
      title: 'Money up front',
      trailing: rent == null
          ? null
          : 'for a ${LizmoMoney.peso(rent!)} ${perBed ? 'bed' : 'unit'}',
      children: [
        if (depositMonths != null)
          line(
            depositMonths == 0
                ? 'No deposit'
                : 'Deposit · ${monthsLabel(depositMonths).toLowerCase()}',
            cost == null || depositMonths == 0
                ? null
                : LizmoMoney.peso(cost.deposit),
          ),
        if (advanceMonths != null)
          line(
            advanceMonths == 0
                ? 'No advance'
                : 'Advance · ${monthsLabel(advanceMonths).toLowerCase()}',
            cost == null || advanceMonths == 0
                ? null
                : LizmoMoney.peso(cost.advance),
          ),
        if (cost != null && cost.firstMonth > 0)
          line('First month', LizmoMoney.peso(cost.firstMonth)),
        if (cost != null) ...[
          const SizedBox(height: 6),
          const _DashedRule(),
          const SizedBox(height: 6),
          line(
            'To move in',
            LizmoMoney.peso(cost.total),
            key: const ValueKey('move-in-total'),
            bold: true,
          ),
        ],
      ],
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dash = 4.0;
          final count = (constraints.maxWidth / (dash * 2)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < count; i++)
                const SizedBox(
                  width: dash,
                  height: 1,
                  child: ColoredBox(color: Color(0xFFCFD8D5)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children, this.trailing});

  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
              ),
              if (trailing case final trailing?)
                Text(trailing, style: LizmoType.rowSub),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// The landlord, as somebody deciding whether to ask sees them: a person,
/// and whether they answer.
class LandlordCardView extends StatelessWidget {
  const LandlordCardView({super.key, required this.landlord});

  final LandlordCard landlord;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

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

  @override
  Widget build(BuildContext context) {
    final name = landlord.name ?? 'The landlord';
    final replies = switch (landlord.replies?.toJson()) {
      'WITHIN_AN_HOUR' => 'usually answers within an hour',
      'WITHIN_A_DAY' => 'usually answers within a day',
      'WITHIN_DAYS' => 'usually answers within a few days',
      _ => null,
    };
    final since = landlord.since;

    return Container(
      key: const ValueKey('landlord-card'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: LizmoColors.tealBg,
            child: Text(
              _initials(name),
              style: LizmoType.rowName.copyWith(
                fontSize: 13,
                color: LizmoColors.teal900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: LizmoType.rowName),
                const SizedBox(height: 2),
                Text(
                  ['Landlord', ?replies].join(' · '),
                  style: LizmoType.rowSub,
                ),
                if (since != null)
                  Text(
                    'On Lizmo since ${_months[since.month - 1]} ${since.year}',
                    style: LizmoType.rowSub.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
