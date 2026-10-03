import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lizmo_api/api.dart';
import 'package:lizmo_core/lizmo_core.dart';
import 'package:lizmo_ui/lizmo_ui.dart';

import '../widgets/ask_for_number_sheet.dart';
import '../tenant/tenant_providers.dart';

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

    return Scaffold(
      backgroundColor: LizmoColors.canvas,
      appBar: AppBar(
        backgroundColor: LizmoColors.teal900,
        foregroundColor: LizmoColors.white,
        elevation: 0,
        title: Text(
          property.valueOrNull?.name ?? 'Finding…',
          style: LizmoType.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: switch (property) {
          AsyncData(:final value) => _Place(place: value),
          AsyncError(:final error) => _NotFound(failure: ApiFailure.from(error)),
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
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.place});

  final PropertyByCodeResponse place;

  @override
  Widget build(BuildContext context) {
    final floors = place.floors;
    final free = (place.vacantWholeUnits ?? 0) + (place.vacantBeds ?? 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(place.address ?? '', style: LizmoType.rowSub),
        const SizedBox(height: 4),
        Text(
          _kind(place),
          style: LizmoType.rowSub.copyWith(
            color: LizmoColors.slate,
            letterSpacing: 0.6,
          ),
        ),
        if ((place.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(place.description!, style: LizmoType.rowSub),
        ],

        const SizedBox(height: 20),
        Text(
          // The headline a tenant came for. Nothing free is a real answer and
          // says so plainly rather than showing an empty list.
          free == 0
              ? 'Nothing free here at the moment'
              : '$free ${free == 1 ? 'space' : 'spaces'} free',
          style: LizmoType.sectionHeading,
        ),
        const SizedBox(height: 12),

        for (final floor in floors) _Floor(floor: floor),

        if (free > 0) ...[
          const SizedBox(height: 10),
          _AskAboutThePlace(propertyId: place.id!),
        ],
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
    final usage =
        place.usage == PropertyByCodeResponseUsageEnum.COMMERCIAL
            ? 'Commercial'
            : 'Residential';
    return type.isEmpty ? usage : '$usage · $type';
  }
}

/// How much is free on one floor, and what it costs.
///
/// Counts rather than rooms: a stranger with the code used to be handed every
/// unit number, every bed label and each one's price, which is more than
/// anybody needs to decide whether to ask. Which room they get is settled with
/// the landlord.
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
                Text(
                  // Null means the landlord never said, which is normal in a
                  // single-storey house — not a floor called nothing.
                  floor.floor == null ? 'Ground level' : 'Floor ${floor.floor}',
                  style: LizmoType.rowName,
                ),
                const SizedBox(height: 2),
                Text(_whatIsFree(units, beds), style: LizmoType.rowSub),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(_price(), style: LizmoType.rowSub.copyWith(color: LizmoColors.ink)),
        ],
      ),
    );
  }

  static String _whatIsFree(int units, int beds) {
    final parts = [
      if (units > 0) '$units ${units == 1 ? 'unit' : 'units'}',
      if (beds > 0) '$beds ${beds == 1 ? 'bedspace' : 'bedspaces'}',
    ];
    return parts.isEmpty ? 'Nothing free' : '${parts.join(' and ')} free';
  }

  /// One price when every free room here asks the same, a range when they do
  /// not. Utilities are flagged rather than added: they are charged per unit,
  /// and adding them to a bed's rent would overstate it.
  String _price() {
    final cheapest = floor.cheapestRent;
    final dearest = floor.dearestRent;
    if (cheapest == null) return 'Price not set';

    final money = cheapest == dearest
        ? '₱$cheapest'
        : '₱$cheapest–₱$dearest';
    return (floor.utilitiesOnTop ?? false)
        ? '$money + utilities'
        : money;
  }
}

/// Asking about the place, with no room named.
///
/// The landlord chooses the room when they accept, which is how it gets
/// settled on the phone anyway — and it is why nothing here names one.
class _AskAboutThePlace extends ConsumerStatefulWidget {
  const _AskAboutThePlace({required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<_AskAboutThePlace> createState() => _AskAboutThePlaceState();
}

class _AskAboutThePlaceState extends ConsumerState<_AskAboutThePlace> {
  bool _asking = false;
  bool _asked = false;

  Future<void> _ask({bool retrying = false}) async {
    setState(() => _asking = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(askingForARoomApiProvider).sendRentalRequest(
            RentalRequestCreate(propertyId: widget.propertyId),
          );
      ref.invalidate(myRentalRequestsProvider);
      if (mounted) setState(() => _asked = true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Sent. The landlord will reply.')),
      );
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

  @override
  Widget build(BuildContext context) {
    if (_asked) {
      return Container(
        key: const ValueKey('asked-about-place'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LizmoColors.tealBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                size: 18, color: LizmoColors.teal900),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Asked. The landlord will reply, and says which room you can '
                'have.',
                style: LizmoType.rowSub.copyWith(color: LizmoColors.teal900),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryActionButton(
          key: const ValueKey('ask-about-place'),
          label: _asking ? 'Asking…' : 'Ask about this place',
          onPressed: _asking ? null : _ask,
        ),
        const SizedBox(height: 8),
        Text(
          'The landlord picks which room, and you settle the rest between you.',
          textAlign: TextAlign.center,
          style: LizmoType.rowSub,
        ),
      ],
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
