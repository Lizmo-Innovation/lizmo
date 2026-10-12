import 'package:flutter/material.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/place_details.dart';

/// "Women only", beside the kind of place: the first thing to know, before
/// photographs or prices, for half the people who scan the code.
class WhoCanRentBadge extends StatelessWidget {
  const WhoCanRentBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('who-can-rent'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: LizmoColors.amberBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: LizmoType.rowSub.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LizmoColors.amberText,
        ),
      ),
    );
  }
}

/// What people ask before anything else, answered before they ask it: the
/// money up front, the house rules, and what comes with the place.
///
/// Only what the landlord said. A part left unsaid is left out rather than
/// shown as "no", and with nothing said at all there is no section.
class BeforeYouAsk extends StatelessWidget {
  const BeforeYouAsk({super.key, required this.details, required this.cheapestRent});

  final PlaceDetailsDto details;

  /// The lowest rent on offer, to put the months up front in pesos.
  final num? cheapestRent;

  @override
  Widget build(BuildContext context) {
    final money = _money();
    final rules = ruleLines(details);
    final other = (details.otherRules ?? '').trim();
    final included = details.amenities;

    if (money == null && rules.isEmpty && other.isEmpty && included.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('before-you-ask'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Before you ask', style: LizmoType.sectionHeading),
        const SizedBox(height: 12),
        if (money != null) ...[
          _Block(
            icon: Icons.payments_outlined,
            title: 'Money up front',
            children: [
              Text(money.$1, style: LizmoType.rowName),
              if (money.$2 case final total?) ...[
                const SizedBox(height: 2),
                Text(total, key: const ValueKey('move-in-total'), style: LizmoType.rowSub),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (rules.isNotEmpty || other.isNotEmpty) ...[
          _Block(
            icon: Icons.rule_outlined,
            title: 'House rules',
            children: [
              for (final (icon, line) in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: LizmoColors.slate),
                      const SizedBox(width: 8),
                      Expanded(child: Text(line, style: LizmoType.rowName)),
                    ],
                  ),
                ),
              if (other.isNotEmpty) Text(other, style: LizmoType.rowSub),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (included.isNotEmpty)
          _Block(
            icon: Icons.check_circle_outline,
            title: 'Included',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amenity in included)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: LizmoColors.tealBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(amenityIcon(amenity.toJson()),
                              size: 14, color: LizmoColors.teal900),
                          const SizedBox(width: 6),
                          Text(
                            amenityLabel(amenity.toJson()),
                            style: LizmoType.rowSub.copyWith(
                                fontSize: 12, color: LizmoColors.teal900),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  /// "Deposit 2 months · Advance 1 month", and -- when both are said and a
  /// rent is known -- roughly what that comes to on the day.
  (String, String?)? _money() {
    final deposit = details.depositMonths;
    final advance = details.advanceMonths;
    if (deposit == null && advance == null) return null;

    final said = [
      if (deposit != null) deposit == 0 ? 'No deposit' : 'Deposit ${monthsLabel(deposit)}',
      if (advance != null) advance == 0 ? 'No advance' : 'Advance ${monthsLabel(advance)}',
    ].join(' · ');

    final rent = cheapestRent;
    if (deposit == null || advance == null || rent == null || rent <= 0) {
      return (said, null);
    }
    // The first month is due on move-in day whether or not it is paid ahead,
    // so moving in costs the deposit and at least one month.
    final months = deposit + (advance < 1 ? 1 : advance);
    return (
      said,
      'About ${LizmoMoney.peso(rent * months)} to move in, for a '
          '${LizmoMoney.peso(rent)} space',
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: LizmoColors.teal900),
              const SizedBox(width: 8),
              Text(title,
                  style: LizmoType.rowSub.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LizmoColors.teal900,
                  )),
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
/// how long they have been here, and whether they answer.
class LandlordCardView extends StatelessWidget {
  const LandlordCardView({super.key, required this.landlord});

  final LandlordCard landlord;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final name = landlord.name ?? 'The landlord';
    final replies = switch (landlord.replies?.toJson()) {
      'WITHIN_AN_HOUR' => 'Usually replies within an hour',
      'WITHIN_A_DAY' => 'Usually replies within a day',
      'WITHIN_DAYS' => 'Usually replies within a few days',
      _ => null,
    };
    final since = landlord.since;

    return Container(
      key: const ValueKey('landlord-card'),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: LizmoColors.tealBg,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: LizmoType.rowName.copyWith(color: LizmoColors.teal900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Let by $name', style: LizmoType.rowName),
                const SizedBox(height: 2),
                Text(
                  [
                    ?replies,
                    if (since != null)
                      'On Lizmo since ${_months[since.month - 1]} ${since.year}',
                  ].join(' · '),
                  style: LizmoType.rowSub.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
