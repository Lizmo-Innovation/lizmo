import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_providers.dart';
import '../widgets/account_sheet.dart';
import '../widgets/collections_card.dart';
import '../widgets/notification_bell.dart';
import '../widgets/occupancy_card.dart';
import '../widgets/role_switcher.dart';

/// The landlord's dashboard.
///
/// Deliberately half-built, and honest about which half. The figures a landlord
/// opens an app for — collected against expected, who is late, what is empty —
/// all need leases and billing, and neither exists yet. Rather than invent
/// them, the sections that cannot be filled say what they are waiting for.
///
/// What is real here is real: the portfolio totals come from the same figures
/// the property list shows, so the two can never disagree.
class LandlordHomeScreen extends ConsumerWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };

    final rows = properties.valueOrNull;

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'Today',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoleSwitcher(),
                SizedBox(width: 4),
                NotificationBell(),
                AccountButton(),
              ],
            ),
            stats: [
              LatticeHeaderStat(
                value: _portfolioRent(rows),
                label: 'Per month',
              ),
              LatticeHeaderStat(
                value: rows?.length.toString() ?? '—',
                label: 'Properties',
              ),
              LatticeHeaderStat(
                value: rows
                        ?.fold<int>(0, (sum, p) => sum + (p.unitCount ?? 0))
                        .toString() ??
                    '—',
                label: 'Units',
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(propertiesProvider);
                ref.invalidate(collectionsProvider);
                ref.invalidate(occupancyProvider);
              },
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              children: const [
                // Was a placeholder reading "Needs leases and billing" from
                // the first day this screen existed. Both now exist.
                CollectionsCard(),
                SizedBox(height: 10),
                // The second placeholder this screen carried. It read "Needs
                // leases", which stopped being true the day leases were built.
                OccupancyCard(),
                SizedBox(height: 10),
                _Awaiting(
                  icon: Icons.event_outlined,
                  title: 'Coming up',
                  detail: 'Move-ins, move-outs and leases about to end.',
                  needs: 'Needs leases',
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section that cannot be filled yet, saying so plainly.
///
/// Not a spinner and not fake numbers: either would be a lie about the state of
/// the product. Naming what each one is waiting for also makes the build order
/// visible to anyone holding the app.
class _Awaiting extends StatelessWidget {
  const _Awaiting({
    required this.icon,
    required this.title,
    required this.detail,
    required this.needs,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String needs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: LizmoColors.slate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LizmoType.rowName),
                const SizedBox(height: 2),
                Text(detail, style: LizmoType.rowSub),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LizmoColors.amberBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    needs,
                    style: LizmoType.rowSub.copyWith(color: LizmoColors.amberText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the whole portfolio brings in per month with everything let.
String _portfolioRent(List<PropertyResponse>? properties) {
  if (properties == null) return '—';

  num? total;
  for (final property in properties) {
    final rent = property.potentialMonthlyRent;
    if (rent == null) continue;
    total = (total ?? 0) + rent;
  }

  if (total == null) return '—';
  final asDouble = total.toDouble();
  final whole = asDouble == asDouble.roundToDouble();
  return '₱${whole ? asDouble.toStringAsFixed(0) : asDouble.toStringAsFixed(2)}';
}
