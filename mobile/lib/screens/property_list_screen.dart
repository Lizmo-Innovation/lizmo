import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:go_router/go_router.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../property/property_labels.dart';
import '../property/property_providers.dart';
import '../router.dart';
import '../widgets/account_sheet.dart';
import '../widgets/notification_bell.dart';
import '../widgets/role_switcher.dart';

/// A landlord's properties — the first screen backed by real data.
///
/// The four states it can be in (loading, failed, empty, populated) are the
/// pattern every later data screen follows, so they are handled explicitly here
/// rather than collapsed into a spinner and a shrug.
class PropertyListScreen extends ConsumerWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final session = switch (ref.watch(authControllerProvider)) {
      AuthSignedIn(:final session) => session,
      _ => null,
    };

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      body: Column(
        children: [
          LatticeHeader(
            eyebrow: session?.name ?? 'Lizmo',
            title: 'My properties',
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
                // Counts come from the loaded list, so they cannot disagree
                // with the rows below them.
                value: properties.valueOrNull?.length.toString() ?? '—',
                label: 'Properties',
              ),
              LatticeHeaderStat(
                value: properties.valueOrNull
                        ?.fold<int>(0, (sum, p) => sum + (p.unitCount ?? 0))
                        .toString() ??
                    '—',
                label: 'Units',
              ),
              LatticeHeaderStat(
                // The first screen a landlord opens was the only one without a
                // figure on it, while every screen below it had one.
                value: _portfolioRent(properties.valueOrNull),
                label: 'Per month',
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: LizmoColors.teal900,
              onRefresh: () => ref.refresh(propertiesProvider.future),
              child: switch (properties) {
                AsyncLoading() => const _Loading(),
                AsyncError(:final error) => _Failed(
                    failure: ApiFailure.from(error),
                    onRetry: () => ref.invalidate(propertiesProvider),
                  ),
                AsyncData(:final value) when value.isEmpty => const _Empty(),
                AsyncData(:final value) => _PropertyList(properties: value),
                // Riverpod's AsyncValue is not exhaustively matched by the three
                // cases above; a refresh carries data and loading together.
                _ => const _Loading(),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryActionButton(
                label: '+ Add a property',
                onPressed: () => context.push(Routes.propertyNew),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(LizmoColors.teal900),
        ),
      ),
    );
  }
}

/// Distinguishes losing the connection from being refused.
///
/// A landlord locked out for an unpaid platform invoice needs to know that is
/// why, not be told to check their signal.
class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh still works when the list failed to load.
    return ListView(
      children: [
        const SizedBox(height: 80),
        LizmoMessageState(
          tone: LizmoMessageTone.problem,
          icon: failure.isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
          title: failure.isNetwork ? "Can't reach Lizmo" : 'Something went wrong',
          detail: failure.message,
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 80),
        LizmoMessageState(
          icon: Icons.home_work_outlined,
          title: 'No properties yet',
          detail: 'Add your first property to start tracking units, tenants and rent.',
        ),
      ],
    );
  }
}

class _PropertyList extends StatelessWidget {
  const _PropertyList({required this.properties});

  final List<PropertyResponse> properties;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      itemCount: properties.length,
      itemBuilder: (context, index) => _PropertyCard(property: properties[index]),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertyResponse property;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: LizmoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [LizmoColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: property.id == null
              ? null
              : () => context.openInTab(Detail.property(property.id!)),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name ?? '', style: LizmoType.rowName),
                      const SizedBox(height: 2),
                      // Kind and address on one line. The type had a line of
                      // its own to carry two words, on the screen with the
                      // least room to spare.
                      Text(
                        [_kindLabel(property), property.address ?? '']
                            .where((part) => part.isNotEmpty)
                            .join(' · '),
                        style: LizmoType.rowSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Money, not the unit count. The count had the card's
                    // biggest visual weight while being the least interesting
                    // thing on it; it moves to the line below.
                    Text(_rentLabel(property.potentialMonthlyRent),
                        style: LizmoType.dataMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${property.unitCount} '
                      '${(property.unitCount ?? 0) == 1 ? 'unit' : 'units'}',
                      style: LizmoType.rowSub,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// "Not set" rather than ₱0, which would claim the property is free.
  static String _rentLabel(num? rent) {
    if (rent == null) return '—';
    return LizmoMoney.peso(rent);
  }

  static String _kindLabel(PropertyResponse property) =>
      propertyKindLabel(property);
}

/// What the whole portfolio brings in per month with everything let.
///
/// Properties with nothing priced contribute nothing rather than zero, the
/// same distinction the property and unit screens make.
String _portfolioRent(List<PropertyResponse>? properties) {
  if (properties == null) return '—';

  num? total;
  for (final property in properties) {
    final rent = property.potentialMonthlyRent;
    if (rent == null) continue;
    total = (total ?? 0) + rent;
  }

  return LizmoMoney.peso(total);
}
